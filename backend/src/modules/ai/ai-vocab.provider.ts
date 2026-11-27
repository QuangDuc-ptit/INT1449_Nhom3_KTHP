import { CefrLevel } from '@prisma/client';

export interface GenerateVocabInput {
  topic: string;
  cefrLevel: CefrLevel;
  /** Số từ yêu cầu model sinh (AiService có thể xin dư vài từ để bù phần bị lọc). */
  wordCount: number;
  /** Các từ không được sinh lại (đã có trong học phần, hoặc đã nhận ở lượt trước). */
  excludeTerms?: readonly string[];
}

/**
 * Lỗi provider đã được chuẩn hoá để AiService quyết định retry mà không cần
 * biết SDK cụ thể.
 * - `retryable`: lỗi tạm thời (quá tải, hết giờ phía server), gọi lại cùng model sau một lúc.
 * - `switchModel`: đổi sang model khác có thể thành công (model quá tải, không tồn tại,
 *   hết quota riêng của model). Lỗi do request sai (400) thì cả hai đều false.
 */
export class AiProviderError extends Error {
  constructor(
    message: string,
    readonly status: number | undefined,
    readonly reason: string,
    readonly retryable: boolean,
    readonly switchModel: boolean = retryable,
    readonly cause?: unknown,
  ) {
    super(message);
    this.name = 'AiProviderError';
  }
}

/**
 * Gọi mô hình AI sinh danh sách từ. Trả dữ liệu thô (object hoặc chuỗi JSON);
 * AiService chịu trách nhiệm kiểm tra, lọc, retry và fallback.
 */
/** Thời gian chờ một lần gọi model và tổng thời gian của cả request. */
export interface AiTiming {
  attemptTimeoutMs: number;
  totalBudgetMs: number;
}

/** Mặc định chỉnh cho Gemini: một lần gọi 15s, cả request (kể cả retry/fallback) 30s. */
export const DEFAULT_AI_TIMING: AiTiming = {
  attemptTimeoutMs: 15_000,
  totalBudgetMs: 30_000,
};

export abstract class AiVocabProvider {
  /** Provider phản hồi chậm hơn Gemini (VD model miễn phí trên OpenRouter) ghi đè giá trị này. */
  readonly timing: AiTiming = DEFAULT_AI_TIMING;

  /** Các model theo thứ tự ưu tiên: phần tử đầu là model chính, sau là fallback. */
  abstract readonly models: readonly string[];

  /** `model` bỏ trống = dùng model chính. */
  abstract generate(
    input: GenerateVocabInput,
    signal: AbortSignal,
    model?: string,
  ): Promise<unknown>;
}
