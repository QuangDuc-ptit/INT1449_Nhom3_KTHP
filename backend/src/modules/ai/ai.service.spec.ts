import { Logger } from '@nestjs/common';
import { CollectionsService } from '../collections/collections.service';
import { PrismaService } from '../../infra/prisma/prisma.service';
import {
  AiProviderError,
  AiVocabProvider,
  GenerateVocabInput,
} from './ai-vocab.provider';
import {
  AI_RETRY,
  AI_TIMEOUT_MS,
  AiService,
  backoffDelayMs,
  requestCountFor,
} from './ai.service';

const word = (term: string, extra: Record<string, unknown> = {}) => ({
  term,
  partOfSpeech: 'noun',
  ipa: '/x/',
  definitionEn: `meaning of ${term}`,
  definitionVi: `nghĩa của ${term}`,
  exampleSentence: `This is ${term}.`,
  cefrLevel: 'B2',
  ...extra,
});
const fiveWords = () => ({
  words: ['solar', 'wind', 'grid', 'battery', 'turbine'].map((t) => word(t)),
});

type Impl = (
  signal: AbortSignal,
  model: string | undefined,
  input: GenerateVocabInput,
) => Promise<unknown>;

class FakeProvider extends AiVocabProvider {
  constructor(
    private readonly impl: Impl,
    readonly models: readonly string[] = ['primary'],
  ) {
    super();
  }
  generate(input: GenerateVocabInput, signal: AbortSignal, model?: string) {
    return this.impl(signal, model, input);
  }
}

const unavailable = () =>
  new AiProviderError('high demand', 503, 'UNAVAILABLE', true);
const badRequest = () =>
  new AiProviderError('invalid argument', 400, 'INVALID_ARGUMENT', false);
const notFound = () =>
  new AiProviderError('model not found', 404, 'NOT_FOUND', false, true);

function serviceWith(
  impl: Impl,
  existingTerms: string[] = [],
  models?: readonly string[],
) {
  const collections = {
    assertOwned: jest.fn().mockResolvedValue({ id: 'c1' }),
  };
  const prisma = {
    vocabulary: {
      findMany: jest
        .fn()
        .mockResolvedValue(existingTerms.map((term) => ({ term }))),
    },
  };
  return {
    service: new AiService(
      new FakeProvider(impl, models),
      collections as unknown as CollectionsService,
      prisma as unknown as PrismaService,
    ),
    collections,
  };
}

const dto = { topic: 'Green energy', cefrLevel: 'B2' as const, wordCount: 5 };

describe('AiService.generate', () => {
  let warn: jest.SpyInstance;
  beforeEach(() => {
    // Bỏ jitter cho kết quả xác định: random() = 0.5 => đúng 0.5s, 1s
    jest.spyOn(Math, 'random').mockReturnValue(0.5);
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'error').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });
  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  it('trả đúng các từ hợp lệ', async () => {
    const { service } = serviceWith(() => Promise.resolve(fiveWords()));
    const res = await service.generate('u1', dto);
    expect(res.words.map((w) => w.term)).toEqual([
      'solar',
      'wind',
      'grid',
      'battery',
      'turbine',
    ]);
    expect(res.words[0]).toEqual({
      term: 'solar',
      partOfSpeech: 'noun',
      ipa: '/x/',
      definitionEn: 'meaning of solar',
      definitionVi: 'nghĩa của solar',
      exampleSentence: 'This is solar.',
      cefrLevel: 'B2',
      existsInCollection: false,
    });
  });

  it('xin dư từ để bù phần bị lọc, chủ đề và cấp độ truyền đúng', async () => {
    const impl = jest.fn<Promise<unknown>, Parameters<Impl>>(() =>
      Promise.resolve(fiveWords()),
    );
    const { service } = serviceWith(impl);
    await service.generate('u1', dto);
    expect(impl.mock.calls[0][2]).toEqual({
      topic: 'Green energy',
      cefrLevel: 'B2',
      wordCount: requestCountFor(5),
      excludeTerms: [],
    });
    expect(requestCountFor(5)).toBe(7);
    expect(requestCountFor(20)).toBe(24);
  });

  it('chấp nhận JSON dạng chuỗi', async () => {
    const { service } = serviceWith(() =>
      Promise.resolve(JSON.stringify({ words: [word('solar')] })),
    );
    const res = await service.generate('u1', { ...dto, wordCount: 3 });
    expect(res.words).toHaveLength(1);
  });

  it('lọc bỏ từ thiếu trường, sai từ loại, sai CEFR hoặc không phải tiếng Anh', async () => {
    const { definitionVi: _drop, ...noVi } = word('broken');
    void _drop;
    const { service } = serviceWith(() =>
      Promise.resolve({
        words: [
          word('ok'),
          noVi,
          word('pron', { partOfSpeech: 'pronoun' }),
          word('lvl', { cefrLevel: 'Z9' }),
          word('blank', { term: '   ' }),
          word('vi', { term: 'năng lượng' }),
          word('long', { term: 'a very long phrase here' }),
          word('num', { term: 'co2' }),
          'not an object',
        ],
      }),
    );
    const res = await service.generate('u1', dto);
    expect(res.words.map((w) => w.term)).toEqual(['ok']);
  });

  it('chuẩn hoá từ loại viết đầy đủ và cấp độ viết thường', async () => {
    const { service } = serviceWith(() =>
      Promise.resolve({
        words: [
          word('quickly', { partOfSpeech: 'Adverb', cefrLevel: 'b1' }),
          word('green', { partOfSpeech: 'adjective' }),
        ],
      }),
    );
    const res = await service.generate('u1', dto);
    expect(res.words.map((w) => [w.partOfSpeech, w.cefrLevel])).toEqual([
      ['adv', 'B1'],
      ['adj', 'B2'],
    ]);
  });

  it('bỏ từ trùng (không phân biệt hoa thường) và cắt theo wordCount', async () => {
    const { service } = serviceWith(() =>
      Promise.resolve({
        words: [
          word('Solar'),
          word('solar'),
          word('a'),
          word('b'),
          word('c'),
          word('d'),
          word('e'),
        ],
      }),
    );
    const res = await service.generate('u1', { ...dto, wordCount: 3 });
    expect(res.words.map((w) => w.term)).toEqual(['Solar', 'a', 'b']);
  });

  it('lọc xong còn thiếu thì gọi bù đúng phần thiếu, không lặp từ đã có', async () => {
    const impl = jest
      .fn<Promise<unknown>, Parameters<Impl>>()
      .mockResolvedValueOnce({ words: [word('solar'), word('wind')] })
      .mockResolvedValueOnce({ words: [word('wind'), word('grid')] });
    const { service } = serviceWith(impl);
    const res = await service.generate('u1', { ...dto, wordCount: 3 });
    expect(res.words.map((w) => w.term)).toEqual(['solar', 'wind', 'grid']);
    expect(impl).toHaveBeenCalledTimes(2);
    expect(impl.mock.calls[1][2]).toMatchObject({
      wordCount: requestCountFor(1),
      excludeTerms: ['solar', 'wind'],
    });
  });

  it('gọi bù thất bại thì vẫn trả phần từ đang có', async () => {
    const impl = jest
      .fn<Promise<unknown>, Parameters<Impl>>()
      .mockResolvedValueOnce({ words: [word('solar')] })
      .mockRejectedValueOnce(badRequest());
    const { service } = serviceWith(impl);
    const res = await service.generate('u1', dto);
    expect(res.words.map((w) => w.term)).toEqual(['solar']);
  });

  it.each([['not json'], [{}], [{ words: 'x' }], [null]])(
    'dữ liệu %j trả 502 AI_BAD_RESPONSE',
    async (payload) => {
      const { service } = serviceWith(() => Promise.resolve(payload));
      await expect(service.generate('u1', dto)).rejects.toMatchObject({
        errorCode: 'AI_BAD_RESPONSE',
        message: 'AI trả về dữ liệu không hợp lệ, vui lòng thử lại',
      });
      await expect(service.generate('u1', dto)).rejects.toHaveProperty(
        'status',
        502,
      );
    },
  );

  it('lọc xong không còn từ nào thì 502 AI_BAD_RESPONSE', async () => {
    const { service } = serviceWith(() =>
      Promise.resolve({ words: [word('x', { cefrLevel: 'Z9' })] }),
    );
    await expect(service.generate('u1', dto)).rejects.toMatchObject({
      errorCode: 'AI_BAD_RESPONSE',
    });
  });

  it('chỉ có một model: quá 15 giây thì huỷ, thử lại trong ngân sách rồi trả 504 AI_TIMEOUT', async () => {
    jest.useFakeTimers();
    let aborted = 0;
    const impl = jest.fn(
      (signal: AbortSignal) =>
        new Promise((_resolve, reject) => {
          signal.addEventListener('abort', () => {
            aborted++;
            reject(new Error('aborted'));
          });
        }),
    );
    const { service } = serviceWith(impl);
    const p = service.generate('u1', dto);
    const assertion = expect(p).rejects.toMatchObject({
      errorCode: 'AI_TIMEOUT',
      message: 'AI đang phản hồi chậm, vui lòng thử lại',
    });
    await jest.advanceTimersByTimeAsync(AI_RETRY.totalBudgetMs);
    await assertion;
    expect(AI_TIMEOUT_MS).toBe(15000);
    // 15s + chờ 0.5s + 14.5s (cắt theo ngân sách 30s) => hết giờ
    expect(impl).toHaveBeenCalledTimes(2);
    expect(aborted).toBe(2);
  });

  it('model chính timeout thì chuyển ngay sang model dự phòng, không chờ thử lại', async () => {
    jest.useFakeTimers();
    const impl = jest.fn<Promise<unknown>, Parameters<Impl>>((signal, model) =>
      model === 'primary'
        ? new Promise((_resolve, reject) =>
            signal.addEventListener('abort', () => reject(new Error('x'))),
          )
        : Promise.resolve(fiveWords()),
    );
    const { service } = serviceWith(impl, [], ['primary', 'backup']);
    const p = service.generate('u1', dto);
    await jest.advanceTimersByTimeAsync(AI_TIMEOUT_MS);
    await expect(p).resolves.toMatchObject({ words: expect.any(Array) });
    expect(impl.mock.calls.map((c) => c[1])).toEqual(['primary', 'backup']);
  });

  it('dùng mốc thời gian riêng của provider chậm (40s/lần) thay cho 15s mặc định', async () => {
    jest.useFakeTimers();
    class SlowProvider extends FakeProvider {
      override readonly timing = {
        attemptTimeoutMs: 40_000,
        totalBudgetMs: 45_000,
      };
    }
    let aborted = false;
    const provider = new SlowProvider((signal) => {
      signal.addEventListener('abort', () => (aborted = true));
      return new Promise((resolve) =>
        setTimeout(() => resolve(fiveWords()), 30_000),
      );
    });
    const service = new AiService(
      provider,
      { assertOwned: jest.fn() } as unknown as CollectionsService,
      {} as PrismaService,
    );
    const p = service.generate('u1', dto);
    await jest.advanceTimersByTimeAsync(30_000);
    await expect(p).resolves.toMatchObject({ words: expect.any(Array) });
    expect(aborted).toBe(false);
  });

  it('503 UNAVAILABLE thì thử lại với backoff 0.5s -> 1s rồi thành công', async () => {
    jest.useFakeTimers();
    const impl = jest
      .fn<Promise<unknown>, Parameters<Impl>>()
      .mockRejectedValueOnce(unavailable())
      .mockRejectedValueOnce(unavailable())
      .mockResolvedValue(fiveWords());
    const { service } = serviceWith(impl);
    const p = service.generate('u1', dto);

    await jest.advanceTimersByTimeAsync(499);
    expect(impl).toHaveBeenCalledTimes(1);
    await jest.advanceTimersByTimeAsync(1);
    expect(impl).toHaveBeenCalledTimes(2);
    await jest.advanceTimersByTimeAsync(1000);
    expect(impl).toHaveBeenCalledTimes(3);

    await expect(p).resolves.toMatchObject({ words: expect.any(Array) });
    expect(warn.mock.calls.map((c: unknown[]) => c[0])).toEqual([
      expect.stringMatching(
        /Lần thử 1\/3 \(model primary\) thất bại: 503 UNAVAILABLE, thử lại lần 1\/2 sau 500ms/,
      ),
      expect.stringMatching(
        /Lần thử 2\/3 .*503 UNAVAILABLE, thử lại lần 2\/2 sau 1000ms/,
      ),
    ]);
  });

  it('400 thì không retry, không fallback, trả 502 AI_UNAVAILABLE ngay', async () => {
    const impl = jest.fn().mockRejectedValue(badRequest());
    const { service } = serviceWith(impl, [], ['primary', 'backup']);
    await expect(service.generate('u1', dto)).rejects.toMatchObject({
      errorCode: 'AI_UNAVAILABLE',
      status: 502,
    });
    expect(impl).toHaveBeenCalledTimes(1);
  });

  it('404 (model không tồn tại) thì chuyển ngay sang model dự phòng', async () => {
    const impl = jest.fn<Promise<unknown>, Parameters<Impl>>((_s, model) =>
      model === 'primary'
        ? Promise.reject(notFound())
        : Promise.resolve(fiveWords()),
    );
    const { service } = serviceWith(impl, [], ['primary', 'backup']);
    await expect(service.generate('u1', dto)).resolves.toMatchObject({
      words: expect.any(Array),
    });
    expect(impl.mock.calls.map((c) => c[1])).toEqual(['primary', 'backup']);
  });

  it('model chính 503 hết lượt retry thì chuyển sang model dự phòng', async () => {
    jest.useFakeTimers();
    const impl = jest.fn<Promise<unknown>, Parameters<Impl>>((_s, model) =>
      model === 'primary'
        ? Promise.reject(unavailable())
        : Promise.resolve(fiveWords()),
    );
    const { service } = serviceWith(impl, [], ['primary', 'backup']);
    const p = service.generate('u1', dto);
    await jest.advanceTimersByTimeAsync(500 + 1000);
    await expect(p).resolves.toMatchObject({ words: expect.any(Array) });
    expect(impl.mock.calls.map((c) => c[1])).toEqual([
      'primary',
      'primary',
      'primary',
      'backup',
    ]);
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('Chuyển sang model dự phòng backup'),
    );
  });

  it('mọi model đều 503 thì trả 502 AI_UNAVAILABLE', async () => {
    jest.useFakeTimers();
    const impl = jest.fn().mockRejectedValue(unavailable());
    const { service } = serviceWith(impl, [], ['primary', 'backup']);
    const p = service.generate('u1', dto);
    const assertion = expect(p).rejects.toMatchObject({
      errorCode: 'AI_UNAVAILABLE',
    });
    await jest.advanceTimersByTimeAsync(AI_RETRY.totalBudgetMs);
    await assertion;
    expect(impl).toHaveBeenCalledTimes(6);
  });

  it('provider ném lỗi lạ thì 502 AI_UNAVAILABLE, không retry', async () => {
    const impl = jest.fn().mockRejectedValue(new Error('quota exceeded'));
    const { service } = serviceWith(impl);
    await expect(service.generate('u1', dto)).rejects.toMatchObject({
      errorCode: 'AI_UNAVAILABLE',
    });
    expect(impl).toHaveBeenCalledTimes(1);
  });

  it('có collectionId: kiểm tra quyền sở hữu và đánh dấu từ đã có', async () => {
    const { service, collections } = serviceWith(
      () => Promise.resolve({ words: [word('Solar'), word('wind')] }),
      ['solar'],
    );
    const res = await service.generate('u1', { ...dto, collectionId: 'c1' });
    expect(collections.assertOwned).toHaveBeenCalledWith('u1', 'c1');
    expect(res.words.map((w) => [w.term, w.existsInCollection])).toEqual([
      ['Solar', true],
      ['wind', false],
    ]);
  });

  it('có collectionId: báo AI tránh từ đã có và ưu tiên từ mới khi cắt', async () => {
    const impl = jest.fn<Promise<unknown>, Parameters<Impl>>(() =>
      Promise.resolve({
        words: [word('solar'), word('wind'), word('grid'), word('battery')],
      }),
    );
    const { service } = serviceWith(impl, ['solar']);
    const res = await service.generate('u1', {
      ...dto,
      wordCount: 3,
      collectionId: 'c1',
    });
    expect(impl.mock.calls[0][2].excludeTerms).toEqual(['solar']);
    expect(res.words.map((w) => w.term)).toEqual(['wind', 'grid', 'battery']);
  });
});

describe('backoffDelayMs', () => {
  it('tăng luỹ thừa 0.5s -> 1s -> 2s, jitter trong ±20%', () => {
    expect([1, 2, 3].map((n) => backoffDelayMs(n, () => 0.5))).toEqual([
      500, 1000, 2000,
    ]);
    expect(backoffDelayMs(1, () => 0)).toBe(400);
    expect(backoffDelayMs(1, () => 1)).toBe(600);
    expect(backoffDelayMs(10, () => 0.5)).toBe(AI_RETRY.maxDelayMs);
  });
});
