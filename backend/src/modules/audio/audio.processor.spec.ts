import { PrismaService } from '../../infra/prisma/prisma.service';
import { AudioProcessor } from './audio.processor';

function setup(vocab: Record<string, unknown> | null) {
  const prisma = {
    vocabulary: {
      findUnique: jest.fn().mockResolvedValue(vocab),
      update: jest.fn().mockResolvedValue({}),
    },
  };
  const tts = {
    synthesize: jest.fn((text: string, accent: string) =>
      Promise.resolve(Buffer.from(`${text}-${accent}`)),
    ),
  };
  const storage = {
    putObject: jest.fn((key: string) =>
      Promise.resolve(`https://cdn.test/${key}`),
    ),
  };
  const processor = new AudioProcessor(
    prisma as unknown as PrismaService,
    tts,
    storage,
  );
  return { processor, prisma, tts, storage };
}

describe('AudioProcessor', () => {
  it('từ chưa có audio: sinh MP3 giọng UK và US, upload và cập nhật URL', async () => {
    const { processor, prisma, tts, storage } = setup({
      id: 'v1',
      term: 'coherent',
      audioUkUrl: null,
      audioUsUrl: null,
    });
    await processor.handle('v1');
    expect(tts.synthesize).toHaveBeenCalledWith('coherent', 'uk');
    expect(tts.synthesize).toHaveBeenCalledWith('coherent', 'us');
    expect(storage.putObject).toHaveBeenCalledWith(
      'audio/v1-uk.mp3',
      Buffer.from('coherent-uk'),
      'audio/mpeg',
    );
    expect(storage.putObject).toHaveBeenCalledWith(
      'audio/v1-us.mp3',
      Buffer.from('coherent-us'),
      'audio/mpeg',
    );
    expect(prisma.vocabulary.update).toHaveBeenCalledWith({
      where: { id: 'v1' },
      data: {
        audioUkUrl: 'https://cdn.test/audio/v1-uk.mp3',
        audioUsUrl: 'https://cdn.test/audio/v1-us.mp3',
      },
    });
  });

  it('chỉ sinh giọng còn thiếu', async () => {
    const { processor, tts, prisma } = setup({
      id: 'v2',
      term: 'souvenir',
      audioUkUrl: 'https://cdn.test/audio/v2-uk.mp3',
      audioUsUrl: null,
    });
    await processor.handle('v2');
    expect(tts.synthesize).toHaveBeenCalledTimes(1);
    expect(tts.synthesize).toHaveBeenCalledWith('souvenir', 'us');
    expect(prisma.vocabulary.update).toHaveBeenCalledWith({
      where: { id: 'v2' },
      data: { audioUsUrl: 'https://cdn.test/audio/v2-us.mp3' },
    });
  });

  it('từ đã có đủ audio thì không gọi TTS', async () => {
    const { processor, tts, prisma } = setup({
      id: 'v3',
      term: 'explore',
      audioUkUrl: 'a',
      audioUsUrl: 'b',
    });
    await processor.handle('v3');
    expect(tts.synthesize).not.toHaveBeenCalled();
    expect(prisma.vocabulary.update).not.toHaveBeenCalled();
  });

  it('từ đã bị xoá thì kết thúc êm, không lỗi', async () => {
    const { processor, tts } = setup(null);
    await expect(processor.handle('gone')).resolves.toBeUndefined();
    expect(tts.synthesize).not.toHaveBeenCalled();
  });

  it('từ bị xoá giữa chừng (update báo P2025) thì không ném lỗi', async () => {
    const { processor, prisma } = setup({
      id: 'v4',
      term: 'itinerary',
      audioUkUrl: null,
      audioUsUrl: null,
    });
    prisma.vocabulary.update.mockRejectedValue(
      Object.assign(new Error('not found'), { code: 'P2025' }),
    );
    await expect(processor.handle('v4')).resolves.toBeUndefined();
  });
});
