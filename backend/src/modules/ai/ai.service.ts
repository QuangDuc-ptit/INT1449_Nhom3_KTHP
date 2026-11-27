import { Injectable, Logger } from '@nestjs/common';
import { CefrLevel, PartOfSpeech } from '@prisma/client';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsService } from '../collections/collections.service';
import { termKey } from '../vocabularies/vocabulary.mapper';
import { AiVocabProvider } from './ai-vocab.provider';
import { GenerateVocabDto, GeneratedWordDto } from './dto/generate-vocab.dto';

export const AI_TIMEOUT_MS = 45_000;

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

const badResponse = () =>
  new AppException(
    502,
    'AI_BAD_RESPONSE',
    'AI trả về dữ liệu không hợp lệ, vui lòng thử lại',
  );

class AiTimeoutError extends Error {}

const str = (v: unknown, max: number): string | null =>
  typeof v === 'string' && v.trim() && v.trim().length <= max ? v.trim() : null;

/** Kiểm tra một từ AI trả về; trả null nếu thiếu trường hoặc sai giá trị. */
export function parseGeneratedWord(
  raw: unknown,
): Omit<GeneratedWordDto, 'existsInCollection'> | null {
  if (!raw || typeof raw !== 'object') return null;
  const w = raw as Record<string, unknown>;
  const term = str(w.term, 100);
  const pos =
    typeof w.partOfSpeech === 'string'
      ? POS_ALIASES[w.partOfSpeech.trim().toLowerCase()]
      : undefined;
  const cefr =
    typeof w.cefrLevel === 'string' ? w.cefrLevel.trim().toUpperCase() : '';
  const definitionEn = str(w.definitionEn, 1000);
  const definitionVi = str(w.definitionVi, 500);
  const exampleSentence = str(w.exampleSentence, 1000);
  if (!term || !pos || !CEFR.has(cefr)) return null;
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
    let existing = new Set<string>();
    if (dto.collectionId) {
      await this.collections.assertOwned(userId, dto.collectionId);
      const rows = await this.prisma.vocabulary.findMany({
        where: { collectionId: dto.collectionId },
        select: { term: true },
      });
      existing = new Set(rows.map((r) => termKey(r.term)));
    }

    const raw = await this.callWithTimeout(dto);
    const words = this.extractWords(raw, dto.wordCount);
    return {
      words: words.map((w) => ({
        ...w,
        existsInCollection: existing.has(termKey(w.term)),
      })),
    };
  }

  private async callWithTimeout(dto: GenerateVocabDto): Promise<unknown> {
    const controller = new AbortController();
    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(() => {
        controller.abort();
        reject(new AiTimeoutError());
      }, AI_TIMEOUT_MS);
    });
    try {
      return await Promise.race([
        this.provider.generate(
          {
            topic: dto.topic,
            cefrLevel: dto.cefrLevel,
            wordCount: dto.wordCount,
          },
          controller.signal,
        ),
        timeout,
      ]);
    } catch (err) {
      // abort() khiến provider reject gần như cùng lúc, nên dựa vào cờ abort để phân loại
      if (err instanceof AiTimeoutError || controller.signal.aborted) {
        throw new AppException(
          504,
          'AI_TIMEOUT',
          'AI đang phản hồi chậm, vui lòng thử lại',
        );
      }
      this.logger.error('Gọi AI thất bại', err as Error);
      throw new AppException(
        502,
        'AI_UNAVAILABLE',
        'Dịch vụ AI tạm thời không khả dụng, vui lòng thử lại sau',
      );
    } finally {
      clearTimeout(timer);
    }
  }

  private extractWords(
    raw: unknown,
    wordCount: number,
  ): Omit<GeneratedWordDto, 'existsInCollection'>[] {
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
    const words: Omit<GeneratedWordDto, 'existsInCollection'>[] = [];
    for (const item of list) {
      const w = parseGeneratedWord(item);
      if (!w || seen.has(termKey(w.term))) continue;
      seen.add(termKey(w.term));
      words.push(w);
      if (words.length === wordCount) break;
    }
    if (!words.length) throw badResponse();
    return words;
  }
}
