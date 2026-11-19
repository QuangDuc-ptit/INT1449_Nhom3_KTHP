import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Job } from 'bullmq';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { AUDIO_QUEUE, GenerateVocabAudioJob } from './audio.constants';
import { ACCENTS, TtsProvider } from './tts.provider';

const URL_FIELD = { uk: 'audioUkUrl', us: 'audioUsUrl' } as const;

/** Worker BullMQ: sinh file phát âm cho từ vựng và cập nhật URL vào DB. */
@Processor(AUDIO_QUEUE)
export class AudioProcessor extends WorkerHost {
  private readonly logger = new Logger(AudioProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly tts: TtsProvider,
    private readonly storage: StorageService,
    private readonly clock: Clock,
  ) {
    super();
  }

  async process(job: Job<GenerateVocabAudioJob>): Promise<void> {
    await this.handle(job.data.vocabularyId);
  }

  async handle(vocabularyId: string): Promise<void> {
    const vocab = await this.prisma.vocabulary.findUnique({
      where: { id: vocabularyId },
    });
    if (!vocab) return; // từ đã bị xoá trước khi job chạy

    const data: Prisma.VocabularyUpdateInput = {};
    // Tên file có phiên bản để CDN/app không phát lại audio cũ sau khi đổi từ
    const version = this.clock.now().getTime();
    for (const accent of ACCENTS) {
      if (vocab[URL_FIELD[accent]]) continue;
      const mp3 = await this.tts.synthesize(vocab.term, accent);
      data[URL_FIELD[accent]] = await this.storage.putObject(
        `audio/${vocab.id}-${accent}-${version}.mp3`,
        mp3,
        'audio/mpeg',
      );
    }
    if (Object.keys(data).length === 0) return;

    try {
      await this.prisma.vocabulary.update({ where: { id: vocab.id }, data });
    } catch (err) {
      if ((err as { code?: string }).code === 'P2025') {
        this.logger.debug(`Từ ${vocab.id} đã bị xoá khi đang sinh audio`);
        return;
      }
      throw err;
    }
  }
}
