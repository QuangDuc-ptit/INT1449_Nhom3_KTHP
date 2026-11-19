import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../../config/env.schema';
import { AUDIO_QUEUE } from './audio.constants';
import { AudioProcessor } from './audio.processor';
import { AudioProducer } from './audio.producer';
import { GoogleTtsProvider } from './google-tts.provider';
import { MockTtsProvider } from './mock-tts.provider';
import { TtsProvider } from './tts.provider';

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => {
        const host: string = config.get('REDIS_HOST', { infer: true });
        const port: number = config.get('REDIS_PORT', { infer: true });
        const db: number = config.get('REDIS_DB', { infer: true });
        return { prefix: 'karvocab', connection: { host, port, db } };
      },
    }),
    BullModule.registerQueue({ name: AUDIO_QUEUE }),
  ],
  providers: [
    AudioProducer,
    AudioProcessor,
    {
      provide: TtsProvider,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): TtsProvider =>
        config.get('TTS_PROVIDER', { infer: true }) === 'google'
          ? new GoogleTtsProvider()
          : new MockTtsProvider(),
    },
  ],
  exports: [AudioProducer],
})
export class AudioModule {}
