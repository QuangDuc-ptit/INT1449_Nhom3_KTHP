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
import { OpenAiCompatVocabProvider } from './openai-compat-vocab.provider';

@Module({
  imports: [CollectionsModule],
  controllers: [AiController],
  providers: [
    AiService,
    {
      provide: AiVocabProvider,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): AiVocabProvider => {
        const provider = config.get('AI_PROVIDER', { infer: true });
        if (provider === 'gemini') {
          return new GeminiAiVocabProvider(
            new GoogleGenAI({
              apiKey: config.get('GEMINI_API_KEY', { infer: true }),
            }),
            config.get('GEMINI_MODEL', { infer: true }),
          );
        }
        if (provider === 'openai') {
          return new OpenAiCompatVocabProvider({
            apiKey: config.get('OPENAI_API_KEY', { infer: true }),
            baseUrl: config.get('OPENAI_BASE_URL', { infer: true }),
            model: config.get('OPENAI_MODEL', { infer: true }),
          });
        }
        return new MockAiVocabProvider();
      },
    },
  ],
})
export class AiModule {}
