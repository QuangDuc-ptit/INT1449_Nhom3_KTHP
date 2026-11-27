import { randomUUID } from 'node:crypto';
import { Injectable, Logger } from '@nestjs/common';
import { CefrLevel, PartOfSpeech } from '@prisma/client';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsService } from '../collections/collections.service';
import { termKey } from '../vocabularies/vocabulary.mapper';
import {
  AiProviderError,
  AiVocabProvider,
  DEFAULT_AI_TIMING,
  GenerateVocabInput,
} from './ai-vocab.provider';
import { GenerateVocabDto, GeneratedWordDto } from './dto/generate-vocab.dto';

/** Thời gian chờ tối đa cho MỘT lần gọi model. */
export const AI_TIMEOUT_MS = DEFAULT_AI_TIMING.attemptTimeoutMs;

/**
 * Chính sách retry, ưu tiên phản hồi nhanh:
 * - 503/504: thử lại cùng model tối đa `maxRetries` lần, chờ 0.5s -> 1s (±jitter),
 *   hết lượt thì chuyển sang model dự phòng.
 * - Timeout: model đang chậm, chuyển ngay sang model dự phòng (nếu còn).
 * - 404/429: model không dùng được, chuyển ngay sang model dự phòng.
 * Thời gian một lần gọi và tổng thời gian lấy từ `provider.timing` (mặc định 15s / 30s,
 * xem DEFAULT_AI_TIMING); app chờ tối đa 50s nên mọi provider phải giữ tổng dưới mốc đó.
 */
export const AI_RETRY = {
  maxRetries: 2,
  baseDelayMs: 500,
  maxDelayMs: 4_000,
  jitterRatio: 0.2,
  totalBudgetMs: DEFAULT_AI_TIMING.totalBudgetMs,
  /** Còn ít hơn mức này thì không bắt đầu lần gọi mới (gần như chắc chắn timeout). */
  minAttemptMs: 3_000,
} as const;

/** Còn ít nhất chừng này thời gian mới gọi bù khi lọc xong vẫn thiếu từ. */
export const AI_TOPUP_MIN_MS = 6_000;
/** Số từ đã có tối đa đưa vào prompt để tránh trùng (giữ prompt ngắn, phản hồi nhanh). */
export const AI_MAX_EXCLUDE_TERMS = 200;

/** Xin dư vài từ để sau khi lọc (sai định dạng, trùng, đã có) vẫn đủ số người dùng chọn. */
export const requestCountFor = (wordCount: number): number =>
  Math.min(wordCount + Math.max(2, Math.ceil(wordCount * 0.2)), 25);

const POS_ALIASES: Record<string, PartOfSpeech> = {
  noun: 'noun',
  n: 'noun',
  verb: 'verb',
  v: 'verb',
  adj: 'adj',
  adjective: 'adj',
  adv: 'adv',
  adverb: 'adv',
  idiom: 'idiom',
  phrase: 'idiom',
};
const CEFR = new Set<string>(Object.values(CefrLevel));
/** Từ tiếng Anh: chữ cái Latin không dấu, có thể có khoảng trắng, gạch nối, nháy; tối đa 4 chữ. */
const ENGLISH_TERM = /^[A-Za-z][A-Za-z'’-]*(?: [A-Za-z][A-Za-z'’-]*){0,3}$/;

const badResponse = () =>
  new AppException(
    502,
    'AI_BAD_RESPONSE',
    'AI trả về dữ liệu không hợp lệ, vui lòng thử lại',
  );

class AiTimeoutError extends Error {
  constructor(readonly timeoutMs: number) {
    super(`timeout sau ${timeoutMs}ms`);
  }
}

const isRetryable = (err: unknown): boolean =>
  err instanceof AiTimeoutError ||
  (err instanceof AiProviderError && err.retryable);

const canSwitchModel = (err: unknown): boolean =>
  err instanceof AiTimeoutError ||
  (err instanceof AiProviderError && err.switchModel);

/** Mô tả ngắn gọn lỗi để ghi log: "503 UNAVAILABLE", "timeout sau 15000ms"... */
const describeError = (err: unknown): string => {
  if (err instanceof AiTimeoutError) return err.message;
  if (err instanceof AiProviderError) {
    return `${err.status ?? '-'} ${err.reason}`;
  }
  return err instanceof Error ? err.message : String(err);
};

/** Backoff luỹ thừa: lần thử lại thứ n chờ base * 2^(n-1), cộng/trừ jitter. */
export function backoffDelayMs(retry: number, random = Math.random): number {
  const exp = Math.min(
    AI_RETRY.maxDelayMs,
    AI_RETRY.baseDelayMs * 2 ** (retry - 1),
  );
  const jitter = 1 + AI_RETRY.jitterRatio * (2 * random() - 1);
  return Math.round(exp * jitter);
}

const sleep = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, ms));

const str = (v: unknown, max: number): string | null =>
  typeof v === 'string' && v.trim() && v.trim().length <= max ? v.trim() : null;

type Word = Omit<GeneratedWordDto, 'existsInCollection'>;

/** Kiểm tra một từ AI trả về; trả null nếu thiếu trường hoặc sai giá trị. */
export function parseGeneratedWord(raw: unknown): Word | null {
  if (!raw || typeof raw !== 'object') return null;
  const w = raw as Record<string, unknown>;
  const term = str(w.term, 100)?.replace(/\s+/g, ' ') ?? null;
  const pos =
    typeof w.partOfSpeech === 'string'
      ? POS_ALIASES[w.partOfSpeech.trim().toLowerCase()]
      : undefined;
  const cefr =
    typeof w.cefrLevel === 'string' ? w.cefrLevel.trim().toUpperCase() : '';
  const definitionEn = str(w.definitionEn, 1000);
  const definitionVi = str(w.definitionVi, 500);
  const exampleSentence = str(w.exampleSentence, 1000);
  if (!term || !ENGLISH_TERM.test(term) || !pos || !CEFR.has(cefr)) {
    return null;
  }
  if (!definitionEn || !definitionVi || !exampleSentence) return null;
  const ipa = str(w.ipa, 100);
  return {
    term,
    partOfSpeech: pos,
    ...(ipa ? { ipa } : {}),
    definitionEn,
    definitionVi,
    exampleSentence,
    cefrLevel: cefr as CefrLevel,
  };
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    private readonly provider: AiVocabProvider,
    private readonly collections: CollectionsService,
    private readonly prisma: PrismaService,
  ) {}

  async generate(
    userId: string,
    dto: GenerateVocabDto,
  ): Promise<{ words: GeneratedWordDto[] }> {
    const startedAt = Date.now();
    const requestId = randomUUID().slice(0, 8);
    let existingTerms: string[] = [];
    if (dto.collectionId) {
      await this.collections.assertOwned(userId, dto.collectionId);
      const rows = await this.prisma.vocabulary.findMany({
        where: { collectionId: dto.collectionId },
        select: { term: true },
      });
      existingTerms = rows.map((r) => r.term);
    }
    const existing = new Set(existingTerms.map(termKey));
    const deadline = startedAt + this.provider.timing.totalBudgetMs;
    const base = { topic: dto.topic, cefrLevel: dto.cefrLevel };
    const exclude = existingTerms.slice(0, AI_MAX_EXCLUDE_TERMS);

    const words = this.extractWords(
      await this.callWithRetry(
        {
          ...base,
          wordCount: requestCountFor(dto.wordCount),
          excludeTerms: exclude,
        },
        deadline,
        requestId,
      ),
    );

    // Lọc xong vẫn thiếu từ mới: gọi bù phần còn thiếu nếu còn thời gian
    const freshCount = () =>
      words.filter((w) => !existing.has(termKey(w.term))).length;
    const missing = dto.wordCount - freshCount();
    if (missing > 0 && deadline - Date.now() >= AI_TOPUP_MIN_MS) {
      this.logger.log(
        `[AI ${requestId}] Thiếu ${missing}/${dto.wordCount} từ hợp lệ, gọi bù`,
      );
      try {
        const more = this.extractWords(
          await this.callWithRetry(
            {
              ...base,
              wordCount: requestCountFor(missing),
              excludeTerms: [...words.map((w) => w.term), ...exclude].slice(
                0,
                AI_MAX_EXCLUDE_TERMS,
              ),
            },
            deadline,
            requestId,
          ),
        );
        const seen = new Set(words.map((w) => termKey(w.term)));
        for (const w of more) {
          if (!seen.has(termKey(w.term))) {
            seen.add(termKey(w.term));
            words.push(w);
          }
        }
      } catch (err) {
        // Đã có từ dùng được: trả phần đang có thay vì báo lỗi cả request
        this.logger.warn(
          `[AI ${requestId}] Gọi bù thất bại, trả ${words.length} từ đang có: ${describeError(err)}`,
        );
      }
    }

    const chosen = this.pick(words, existing, dto.wordCount);
    this.logger.log(
      `[AI ${requestId}] Hoàn tất trong ${Date.now() - startedAt}ms: ${chosen.length}/${dto.wordCount} từ`,
    );
    return {
      words: chosen.map((w) => ({
        ...w,
        existsInCollection: existing.has(termKey(w.term)),
      })),
    };
  }

  /** Chọn `wordCount` từ, ưu tiên từ chưa có trong học phần; giữ thứ tự AI trả về. */
  private pick(words: Word[], existing: Set<string>, wordCount: number) {
    const fresh = words.filter((w) => !existing.has(termKey(w.term)));
    const old = words.filter((w) => existing.has(termKey(w.term)));
    const keep = new Set(
      [...fresh, ...old].slice(0, wordCount).map((w) => termKey(w.term)),
    );
    return words.filter((w) => keep.has(termKey(w.term)));
  }

  /**
   * Gọi provider có retry + fallback model. Chỉ lỗi tạm thời mới được thử lại;
   * lỗi do request (400, sai khoá...) trả về ngay, không đổi model.
   */
  private async callWithRetry(
    input: GenerateVocabInput,
    deadline: number,
    requestId: string,
  ): Promise<unknown> {
    const models: readonly (string | undefined)[] = this.provider.models.length
      ? this.provider.models
      : [undefined];
    const maxAttempts = AI_RETRY.maxRetries + 1;
    let lastError: unknown;
    let lastModel: string | undefined;

    modelLoop: for (const [index, model] of models.entries()) {
      const hasFallback = index < models.length - 1;
      if (index > 0) {
        this.logger.warn(
          `[AI ${requestId}] Chuyển sang model dự phòng ${model} ` +
            `(model ${lastModel} thất bại: ${describeError(lastError)})`,
        );
      }
      lastModel = model;

      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const remaining = deadline - Date.now();
        if (remaining < AI_RETRY.minAttemptMs) {
          this.logger.warn(
            `[AI ${requestId}] Hết ngân sách thời gian ${this.provider.timing.totalBudgetMs}ms, dừng thử lại`,
          );
          break modelLoop;
        }

        try {
          const raw = await this.callWithTimeout(
            input,
            model,
            Math.min(this.provider.timing.attemptTimeoutMs, remaining),
          );
          if (attempt > 1 || index > 0) {
            this.logger.log(
              `[AI ${requestId}] Thành công ở lần thử ${attempt}/${maxAttempts} (model ${model})`,
            );
          }
          return raw;
        } catch (err) {
          lastError = err;
          const failed = `[AI ${requestId}] Lần thử ${attempt}/${maxAttempts} (model ${model}) thất bại: ${describeError(err)}`;

          if (!isRetryable(err) && !canSwitchModel(err)) {
            this.logger.error(
              `${failed}, lỗi không thể thử lại`,
              (err as Error)?.stack,
            );
            throw this.toAppException(err);
          }
          if (
            !isRetryable(err) ||
            (err instanceof AiTimeoutError && hasFallback)
          ) {
            this.logger.warn(`${failed}, không thử lại model này`);
            break;
          }
          if (attempt === maxAttempts) {
            this.logger.warn(`${failed}, đã hết lượt thử lại`);
            break;
          }

          const delay = backoffDelayMs(attempt);
          if (Date.now() + delay + AI_RETRY.minAttemptMs > deadline) {
            // Không chờ nữa; model dự phòng (nếu có) được gọi ngay
            this.logger.warn(
              `${failed}, không đủ thời gian chờ ${delay}ms để thử lại`,
            );
            break;
          }
          this.logger.warn(
            `${failed}, thử lại lần ${attempt}/${AI_RETRY.maxRetries} sau ${delay}ms`,
          );
          await sleep(delay);
        }
      }
    }

    this.logger.error(
      `[AI ${requestId}] Thất bại sau khi thử ${models.join(', ')}: ${describeError(lastError)}`,
      (lastError as Error)?.stack,
    );
    throw this.toAppException(lastError);
  }

  /** Một lần gọi model, tự huỷ request sau `timeoutMs`. */
  private async callWithTimeout(
    input: GenerateVocabInput,
    model: string | undefined,
    timeoutMs: number,
  ): Promise<unknown> {
    const controller = new AbortController();
    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(() => {
        controller.abort();
        reject(new AiTimeoutError(timeoutMs));
      }, timeoutMs);
    });
    try {
      return await Promise.race([
        this.provider.generate(input, controller.signal, model),
        timeout,
      ]);
    } catch (err) {
      // abort() khiến provider reject gần như cùng lúc, nên dựa vào cờ abort để phân loại
      if (err instanceof AiTimeoutError || controller.signal.aborted) {
        throw new AiTimeoutError(timeoutMs);
      }
      throw err;
    } finally {
      clearTimeout(timer);
    }
  }

  private toAppException(err: unknown): AppException {
    if (err instanceof AiTimeoutError) {
      return new AppException(
        504,
        'AI_TIMEOUT',
        'AI đang phản hồi chậm, vui lòng thử lại',
      );
    }
    return new AppException(
      502,
      'AI_UNAVAILABLE',
      'Dịch vụ AI tạm thời không khả dụng, vui lòng thử lại sau',
    );
  }

  /** Mọi từ hợp lệ, không trùng (chưa cắt theo số lượng). */
  private extractWords(raw: unknown): Word[] {
    let data = raw;
    if (typeof data === 'string') {
      try {
        data = JSON.parse(data);
      } catch {
        throw badResponse();
      }
    }
    const list = (data as { words?: unknown } | null)?.words;
    if (!Array.isArray(list)) throw badResponse();

    const seen = new Set<string>();
    const words: Word[] = [];
    for (const item of list) {
      const w = parseGeneratedWord(item);
      if (!w || seen.has(termKey(w.term))) continue;
      seen.add(termKey(w.term));
      words.push(w);
    }
    if (!words.length) throw badResponse();
    return words;
  }
}
