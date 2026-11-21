import { CefrLevel } from '@prisma/client';

export interface GenerateVocabInput {
  topic: string;
  cefrLevel: CefrLevel;
  wordCount: number;
}

/**
 * Gọi mô hình AI sinh danh sách từ. Trả dữ liệu thô (object hoặc chuỗi JSON);
 * AiService chịu trách nhiệm kiểm tra và lọc.
 */
export abstract class AiVocabProvider {
  abstract generate(
    input: GenerateVocabInput,
    signal: AbortSignal,
  ): Promise<unknown>;
}
