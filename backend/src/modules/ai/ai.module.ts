import { GoogleGenAI } from '@google/genai';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../../config/env.schema';
import { CollectionsModule } from '../collections/collections.module';
import { AiVocabProvider } from './ai-vocab.provider';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { GeminiAiVocabProvider } from './gemini-ai-vocab.provider';
import { MockAiVocabProvider } from './mock-ai-vocab.provider';

@Module({
  imports: [CollectionsModule],
  controllers: [AiController],
  providers: [
    AiService,
    {
      provide: AiVocabProvider,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): AiVocabProvider =>
        config.get('AI_PROVIDER', { infer: true }) === 'gemini'
          ? new GeminiAiVocabProvider(
              new GoogleGenAI({
                apiKey: config.get('GEMINI_API_KEY', { infer: true }),
              }),
              config.get('GEMINI_MODEL', { infer: true }),
              config.get('GEMINI_FALLBACK_MODELS', { infer: true }),
            )
          : new MockAiVocabProvider(),
    },
  ],
})
export class AiModule {}
