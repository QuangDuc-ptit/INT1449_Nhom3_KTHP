import { OpenAiCompatVocabProvider } from './openai-compat-vocab.provider';

describe('OpenAiCompatVocabProvider', () => {
  it('gửi request đúng chuẩn OpenAI Chat Completions và bóc tách JSON', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: () =>
        Promise.resolve({
          choices: [{ message: { content: '```json\n{"words":[]}\n```' } }],
        }),
    });

    const provider = new OpenAiCompatVocabProvider(
      {
        apiKey: 'sk-xt-test',
        baseUrl: 'https://api.xkiro.com/v1/',
        model: 'openai/gpt-5.6-sol',
      },
      fetchMock,
    );
    const controller = new AbortController();

    const out = await provider.generate(
      { topic: 'Space travel', cefrLevel: 'B2', wordCount: 5 },
      controller.signal,
    );

    expect(out).toBe('{"words":[]}');
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://api.xkiro.com/v1/chat/completions');
    expect(init.method).toBe('POST');
    expect(init.signal).toBe(controller.signal);
    expect(init.headers).toEqual({
      Authorization: 'Bearer sk-xt-test',
      'Content-Type': 'application/json',
    });
    const body = JSON.parse(init.body as string) as {
      model: string;
      response_format: { type: string };
      messages: Array<{ role: string; content: string }>;
    };
    expect(body.model).toBe('openai/gpt-5.6-sol');
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[1].content).toContain('"Space travel"');
  });

  it('tự động thử lại không dùng response_format nếu model trả 400', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 400,
        text: () => Promise.resolve('response_format is not supported'),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            choices: [{ message: { content: '{"words":[]}' } }],
          }),
      });

    const provider = new OpenAiCompatVocabProvider(
      {
        apiKey: 'sk-or-v1-test',
        baseUrl: 'https://openrouter.ai/api/v1',
        model: 'openrouter/free',
      },
      fetchMock,
    );

    const out = await provider.generate(
      { topic: 'Travel', cefrLevel: 'A2', wordCount: 3 },
      new AbortController().signal,
    );

    expect(out).toBe('{"words":[]}');
    expect(fetchMock).toHaveBeenCalledTimes(2);
    const secondBody = JSON.parse(
      (fetchMock.mock.calls[1] as [string, RequestInit])[1].body as string,
    ) as Record<string, unknown>;
    expect(secondBody.response_format).toBeUndefined();
  });

  it('ném lỗi khi API trả về HTTP không thành công', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: false,
      status: 401,
      text: () => Promise.resolve('Unauthorized'),
    });
    const provider = new OpenAiCompatVocabProvider(
      {
        apiKey: 'bad-key',
        baseUrl: 'https://api.xkiro.com/v1',
        model: 'openai/gpt-5.6-sol',
      },
      fetchMock,
    );

    await expect(
      provider.generate(
        { topic: 'Travel', cefrLevel: 'A2', wordCount: 3 },
        new AbortController().signal,
      ),
    ).rejects.toThrow(/401/);
  });
});
