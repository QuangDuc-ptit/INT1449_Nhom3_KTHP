import { Logger } from '@nestjs/common';
import { AiProviderError, DEFAULT_AI_TIMING } from './ai-vocab.provider';
import {
  OPENAI_COMPAT_TIMING,
  OPENAI_SYSTEM_PROMPT,
  OpenAiCompatVocabProvider,
} from './openai-compat-vocab.provider';
import { SYSTEM_INSTRUCTION } from './gemini-ai-vocab.provider';

type ChatBody = {
  model: string;
  response_format?: { type: string };
  messages: Array<{ role: string; content: string }>;
};

const okResponse = (content: string) => ({
  ok: true,
  status: 200,
  json: () => Promise.resolve({ choices: [{ message: { content } }] }),
});
const errorResponse = (status: number, text = 'error') => ({
  ok: false,
  status,
  text: () => Promise.resolve(text),
});

const input = {
  topic: 'Space travel',
  cefrLevel: 'B2' as const,
  wordCount: 5,
};

function providerWith(
  fetchMock: jest.Mock,
  extra: { model?: string; fallbackModels?: string[] } = {},
) {
  return new OpenAiCompatVocabProvider(
    {
      apiKey: 'sk-test',
      baseUrl: 'https://openrouter.ai/api/v1/',
      model: extra.model ?? 'main/model',
      fallbackModels: extra.fallbackModels,
    },
    fetchMock,
  );
}

const bodyOf = (fetchMock: jest.Mock, call = 0) =>
  JSON.parse(
    (fetchMock.mock.calls[call] as [string, RequestInit])[1].body as string,
  ) as ChatBody;

async function errorOf(p: Promise<unknown>): Promise<AiProviderError> {
  try {
    await p;
  } catch (err) {
    return err as AiProviderError;
  }
  throw new Error('không ném lỗi');
}

describe('OpenAiCompatVocabProvider', () => {
  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
  });
  afterEach(() => jest.restoreAllMocks());

  it('gửi request đúng chuẩn Chat Completions với chỉ thị chi tiết và bóc tách JSON', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValue(okResponse('```json\n{"words":[]}\n```'));
    const controller = new AbortController();

    const out = await providerWith(fetchMock).generate(
      input,
      controller.signal,
    );

    expect(out).toBe('{"words":[]}');
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://openrouter.ai/api/v1/chat/completions');
    expect(init.method).toBe('POST');
    expect(init.signal).toBe(controller.signal);
    expect(init.headers).toEqual({
      Authorization: 'Bearer sk-test',
      'Content-Type': 'application/json',
    });
    const body = bodyOf(fetchMock);
    expect(body.model).toBe('main/model');
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[0]).toEqual({
      role: 'system',
      content: OPENAI_SYSTEM_PROMPT,
    });
    expect(OPENAI_SYSTEM_PROMPT).toContain(SYSTEM_INSTRUCTION);
    expect(body.messages[1].content).toContain('"Space travel"');
    expect(body.messages[1].content).toContain('đúng 5 từ');
  });

  it('đưa danh sách từ cần tránh vào prompt', async () => {
    const fetchMock = jest.fn().mockResolvedValue(okResponse('{"words":[]}'));
    await providerWith(fetchMock).generate(
      { ...input, excludeTerms: ['rocket', 'orbit'] },
      new AbortController().signal,
    );
    expect(bodyOf(fetchMock).messages[1].content).toContain(
      '["rocket","orbit"]',
    );
  });

  it('models gồm model chính rồi model dự phòng, bỏ trùng; gọi đúng model được chỉ định', async () => {
    const fetchMock = jest.fn().mockResolvedValue(okResponse('{"words":[]}'));
    const provider = providerWith(fetchMock, {
      model: 'a',
      fallbackModels: ['b', 'a', 'c'],
    });
    expect(provider.models).toEqual(['a', 'b', 'c']);
    await provider.generate(input, new AbortController().signal, 'b');
    expect(bodyOf(fetchMock).model).toBe('b');
  });

  it('chờ lâu hơn Gemini nhưng vẫn dưới mốc 50s của app', () => {
    const provider = providerWith(jest.fn());
    expect(provider.timing).toBe(OPENAI_COMPAT_TIMING);
    expect(OPENAI_COMPAT_TIMING.attemptTimeoutMs).toBeGreaterThan(
      DEFAULT_AI_TIMING.attemptTimeoutMs,
    );
    expect(OPENAI_COMPAT_TIMING.totalBudgetMs).toBeLessThan(50_000);
  });

  it('model trả 400 với response_format: gọi lại không kèm và nhớ cho lần sau', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce(errorResponse(400, 'response_format unsupported'))
      .mockResolvedValue(okResponse('{"words":[]}'));
    const provider = providerWith(fetchMock);

    await expect(
      provider.generate(input, new AbortController().signal),
    ).resolves.toBe('{"words":[]}');
    await provider.generate(input, new AbortController().signal);

    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(bodyOf(fetchMock, 1).response_format).toBeUndefined();
    expect(bodyOf(fetchMock, 2).response_format).toBeUndefined();
  });

  it('vẫn 400 khi đã bỏ response_format: lỗi không retry, không đổi model', async () => {
    const fetchMock = jest.fn().mockResolvedValue(errorResponse(400, 'bad'));
    const err = await errorOf(
      providerWith(fetchMock).generate(input, new AbortController().signal),
    );
    expect(err).toBeInstanceOf(AiProviderError);
    expect(err).toMatchObject({
      status: 400,
      retryable: false,
      switchModel: false,
    });
  });

  it.each([
    [503, true, true],
    [500, true, true],
    [429, false, true],
    [404, false, true],
    [401, false, false],
  ])(
    'HTTP %i -> retryable=%s, switchModel=%s',
    async (status, retryable, switchModel) => {
      const fetchMock = jest.fn().mockResolvedValue(errorResponse(status));
      const err = await errorOf(
        providerWith(fetchMock).generate(input, new AbortController().signal),
      );
      expect(err).toBeInstanceOf(AiProviderError);
      expect(err).toMatchObject({ status, retryable, switchModel });
      expect(err.message).toContain(String(status));
    },
  );

  it('lỗi mạng thì thử lại được', async () => {
    const fetchMock = jest
      .fn()
      .mockRejectedValue(new TypeError('fetch failed'));
    const err = await errorOf(
      providerWith(fetchMock).generate(input, new AbortController().signal),
    );
    expect(err).toMatchObject({ reason: 'NETWORK', retryable: true });
  });

  it('bị huỷ do timeout thì ném nguyên lỗi để AiService tự phân loại', async () => {
    const controller = new AbortController();
    const abortError = new Error('aborted');
    const fetchMock = jest.fn().mockImplementation(() => {
      controller.abort();
      return Promise.reject(abortError);
    });
    await expect(
      providerWith(fetchMock).generate(input, controller.signal),
    ).rejects.toBe(abortError);
  });
});
