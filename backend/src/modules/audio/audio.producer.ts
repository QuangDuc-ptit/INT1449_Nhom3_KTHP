import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { Queue } from 'bullmq';
import {
  VOCABULARY_CREATED,
  VOCABULARY_AUDIO_MISSING,
  VOCABULARY_TERM_CHANGED,
} from '../vocabularies/vocabularies.service';
import type { VocabularyCreatedEvent } from '../vocabularies/vocabularies.service';
import {
  AUDIO_QUEUE,
  GENERATE_VOCAB_AUDIO,
  GenerateVocabAudioJob,
} from './audio.constants';

@Injectable()
export class AudioProducer {
  private readonly logger = new Logger(AudioProducer.name);

  constructor(
    @InjectQueue(AUDIO_QUEUE)
    private readonly queue: Queue<GenerateVocabAudioJob>,
  ) {}

  /** Đẩy job sinh audio; jobId = vocabularyId nên không tạo job trùng. */
  async enqueue(vocabularyIds: string[]): Promise<void> {
    if (!vocabularyIds.length) return;
    await this.queue.addBulk(
      vocabularyIds.map((vocabularyId) => ({
        name: GENERATE_VOCAB_AUDIO,
        data: { vocabularyId },
        opts: {
          jobId: vocabularyId,
          attempts: 3,
          backoff: { type: 'exponential', delay: 5000 },
          removeOnComplete: true,
          removeOnFail: 100,
        },
      })),
    );
  }

  @OnEvent(VOCABULARY_CREATED, { async: true, promisify: true })
  @OnEvent(VOCABULARY_TERM_CHANGED, { async: true, promisify: true })
  @OnEvent(VOCABULARY_AUDIO_MISSING, { async: true, promisify: true })
  async onVocabularyCreated(event: VocabularyCreatedEvent): Promise<void> {
    try {
      await this.enqueue(event.ids);
    } catch (err) {
      // Không để lỗi hàng đợi làm hỏng request thêm từ; audio có thể sinh lại sau
      this.logger.error('Không đẩy được job sinh audio', err as Error);
    }
  }
}
