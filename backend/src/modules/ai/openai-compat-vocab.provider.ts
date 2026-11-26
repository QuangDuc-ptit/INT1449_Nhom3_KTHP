import { AiVocabProvider, GenerateVocabInput } from './ai-vocab.provider';
import { buildPrompt } from './gemini-ai-vocab.provider';

export interface OpenAiCompatConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
}

const SYSTEM_PROMPT =
  'Chỉ trả về một JSON object hợp lệ có dạng {"words": [...]}, không kèm markdown hay giải thích.';

/**
 * Loại bỏ cặp ```json ... ``` nếu model bọc JSON trong markdown code block.
 */
function stripCodeFence(text: string): string {
  const trimmed = text.trim();
  const match = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(trimmed);
  return match ? match[1].trim() : trimmed;
}

/**
 * Sinh từ vựng qua API chuẩn OpenAI Chat Completions (OpenRouter, OpenAI, Groq...).
 */
export class OpenAiCompatVocabProvider extends AiVocabProvider {
  constructor(
    private readonly config: OpenAiCompatConfig,
    private readonly fetchFn: typeof fetch = fetch,
  ) {
    super();
  }

  async generate(
    input: GenerateVocabInput,
    signal: AbortSignal,
  ): Promise<unknown> {
    const base = this.config.baseUrl.replace(/\/+$/, '');
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: buildPrompt(input) },
    ];

    let res = await this.postChat(base, messages, true, signal);
    // Một số model miễn phí trên OpenRouter không hỗ trợ response_format=json_object
    if (res.status === 400) {
      res = await this.postChat(base, messages, false, signal);
    }

    if (!res.ok) {
      const detail = await res.text().catch(() => '');
      throw new Error(
        `OpenAI-compatible API lỗi ${res.status}: ${detail.slice(0, 300)}`,
      );
    }

    const data = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = data.choices?.[0]?.message?.content ?? '';
    return stripCodeFence(content);
  }

  private postChat(
    base: string,
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
        model: this.config.model,
        temperature: 0.7,
        ...(useJsonFormat ? { response_format: { type: 'json_object' } } : {}),
        messages,
      }),
      signal,
    });
  }
}
