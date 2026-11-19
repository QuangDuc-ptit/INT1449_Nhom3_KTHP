import { CollectionsService } from '../collections/collections.service';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { AiVocabProvider } from './ai-vocab.provider';
import { AI_TIMEOUT_MS, AiService } from './ai.service';

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

class FakeProvider extends AiVocabProvider {
  constructor(
    private readonly impl: (signal: AbortSignal) => Promise<unknown>,
  ) {
    super();
  }
  generate(_input: unknown, signal: AbortSignal) {
    return this.impl(signal);
  }
}

function serviceWith(
  impl: (signal: AbortSignal) => Promise<unknown>,
  existingTerms: string[] = [],
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
      new FakeProvider(impl),
      collections as unknown as CollectionsService,
      prisma as unknown as PrismaService,
    ),
    collections,
  };
}

const dto = { topic: 'Green energy', cefrLevel: 'B2' as const, wordCount: 5 };

describe('AiService.generate', () => {
  afterEach(() => jest.useRealTimers());

  it('trả đúng các từ hợp lệ', async () => {
    const words = ['solar', 'wind', 'grid', 'battery', 'turbine'].map((t) =>
      word(t),
    );
    const { service } = serviceWith(() => Promise.resolve({ words }));
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

  it('chấp nhận JSON dạng chuỗi', async () => {
    const { service } = serviceWith(() =>
      Promise.resolve(JSON.stringify({ words: [word('solar')] })),
    );
    const res = await service.generate('u1', { ...dto, wordCount: 3 });
    expect(res.words).toHaveLength(1);
  });

  it('lọc bỏ từ thiếu trường, sai từ loại hoặc sai cấp độ CEFR', async () => {
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

  it('quá 15 giây thì huỷ request và trả 504 AI_TIMEOUT', async () => {
    jest.useFakeTimers();
    let aborted = false;
    const { service } = serviceWith(
      (signal) =>
        new Promise((_resolve, reject) => {
          signal.addEventListener('abort', () => {
            aborted = true;
            reject(new Error('aborted'));
          });
        }),
    );
    const p = service.generate('u1', dto);
    const assertion = expect(p).rejects.toMatchObject({
      errorCode: 'AI_TIMEOUT',
      message: 'AI đang phản hồi chậm, vui lòng thử lại',
    });
    await jest.advanceTimersByTimeAsync(AI_TIMEOUT_MS);
    await assertion;
    expect(AI_TIMEOUT_MS).toBe(15000);
    expect(aborted).toBe(true);
  });

  it('provider ném lỗi thì 502 AI_UNAVAILABLE', async () => {
    const { service } = serviceWith(() =>
      Promise.reject(new Error('quota exceeded')),
    );
    await expect(service.generate('u1', dto)).rejects.toMatchObject({
      errorCode: 'AI_UNAVAILABLE',
    });
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
});
