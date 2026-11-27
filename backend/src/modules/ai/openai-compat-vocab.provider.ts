import { Logger } from '@nestjs/common';
import {
  AiProviderError,
  AiTiming,
  AiVocabProvider,
  GenerateVocabInput,
} from './ai-vocab.provider';
import { SYSTEM_INSTRUCTION, buildPrompt } from './gemini-ai-vocab.provider';

export interface OpenAiCompatConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
  fallbackModels?: readonly string[];
}

/**
 * Model miễn phí trên OpenRouter mất 15–20s (model nhanh) tới hơn 40s (model chậm) cho một lần sinh.
 * Mỗi lần chờ tối đa 25s để nếu model chính treo vẫn còn khoảng 20s cho model dự phòng;
 * tổng 45s vẫn dưới mốc app chờ (ApiConfig.aiRequestTimeout = 50s).
 */
export const OPENAI_COMPAT_TIMING: AiTiming = {
  attemptTimeoutMs: 25_000,
  totalBudgetMs: 45_000,
};

/** Chat Completions không có JSON Schema bắt buộc như Gemini: mô tả định dạng ngay trong chỉ thị. */
export const OPENAI_SYSTEM_PROMPT = [
  SYSTEM_INSTRUCTION,
  'Chỉ trả về một JSON object hợp lệ có dạng {"words": [...]}, mỗi phần tử có đủ các trường',
  'term, partOfSpeech, ipa, definitionEn, definitionVi, exampleSentence, cefrLevel;',
  'không kèm markdown hay giải thích.',
].join('\n');

/** 5xx: lỗi tạm thời phía nhà cung cấp, gọi lại cùng model có thể được. */
const RETRYABLE_STATUS = new Set([500, 502, 503, 504]);
/** 404 (model không tồn tại), 429 (hết lượt / rate limit): đổi model khác có thể chạy. */
const SWITCH_MODEL_STATUS = new Set([404, 429]);

/** Loại bỏ cặp ```json ... ``` nếu model bọc JSON trong markdown code block. */
function stripCodeFence(text: string): string {
  const trimmed = text.trim();
  const match = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(trimmed);
  return match ? match[1].trim() : trimmed;
}

/**
 * Sinh từ vựng qua API chuẩn OpenAI Chat Completions (OpenRouter, OpenAI, Groq...).
 * Dùng chung chỉ thị, prompt và danh sách từ cần tránh với Gemini; AiService lo retry/fallback.
 */
export class OpenAiCompatVocabProvider extends AiVocabProvider {
  private readonly logger = new Logger(OpenAiCompatVocabProvider.name);
  readonly models: readonly string[];
  override readonly timing = OPENAI_COMPAT_TIMING;
  /** Model đã từ chối response_format=json_object: lần sau gửi không kèm. */
  private readonly noJsonFormat = new Set<string>();

  constructor(
    private readonly config: OpenAiCompatConfig,
    private readonly fetchFn: typeof fetch = fetch,
  ) {
    super();
    this.models = [
      ...new Set([config.model, ...(config.fallbackModels ?? [])]),
    ].filter(Boolean);
  }

  async generate(
    input: GenerateVocabInput,
    signal: AbortSignal,
    model: string = this.models[0],
  ): Promise<unknown> {
    const base = this.config.baseUrl.replace(/\/+$/, '');
    const messages = [
      { role: 'system', content: OPENAI_SYSTEM_PROMPT },
      { role: 'user', content: buildPrompt(input) },
    ];

    let res: Response;
    try {
      const useJson = !this.noJsonFormat.has(model);
      res = await this.postChat(base, model, messages, useJson, signal);
      // Một số model miễn phí trên OpenRouter không hỗ trợ response_format=json_object
      if (res.status === 400 && useJson) {
        this.logger.warn(
          `Model ${model} không nhận response_format, gọi lại không kèm`,
        );
        this.noJsonFormat.add(model);
        res = await this.postChat(base, model, messages, false, signal);
      }
    } catch (err) {
      // Bị huỷ do timeout: để nguyên, AiService tự phân loại qua signal
      if (signal.aborted) throw err;
      // Lỗi mạng (DNS, mất kết nối...): tạm thời, thử lại được
      throw new AiProviderError(
        err instanceof Error ? err.message : String(err),
        undefined,
        'NETWORK',
        true,
        true,
        err,
      );
    }

    if (!res.ok) {
      const detail = await res.text().catch(() => '');
      const retryable = RETRYABLE_STATUS.has(res.status);
      throw new AiProviderError(
        `OpenAI-compatible API lỗi ${res.status}: ${detail.slice(0, 300)}`,
        res.status,
        `HTTP_${res.status}`,
        retryable,
        retryable || SWITCH_MODEL_STATUS.has(res.status),
      );
    }

    const data = (await res.json()) as {
      choices?: Array<{ message?: { content?: string | null } }>;
    };
    return stripCodeFence(data.choices?.[0]?.message?.content ?? '');
  }

  private postChat(
    base: string,
    model: string,
    messages: Array<{ role: string; content: string }>,
    useJsonFormat: boolean,
    signal: AbortSignal,
  ): Promise<Response> {
    return this.fetchFn(`${base}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        temperature: 0.6,
        ...(useJsonFormat ? { response_format: { type: 'json_object' } } : {}),
        messages,
      }),
      signal,
    });
  }
}
