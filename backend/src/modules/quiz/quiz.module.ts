import { Module } from '@nestjs/common';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsModule } from '../collections/collections.module';
import { CollectionsService } from '../collections/collections.service';
import { PracticeController } from './practice.controller';
import { QuestionService } from './question.service';
import { SessionCompletionHook, SubmitService } from './submit.service';

/** Mặc định chưa có huy hiệu; module gamification thay thế provider này. */
class NoopSessionCompletionHook extends SessionCompletionHook {
  onSessionCompleted() {
    return Promise.resolve([]);
  }
}

@Module({
  imports: [CollectionsModule],
  controllers: [PracticeController],
  providers: [
    {
      provide: QuestionService,
      inject: [PrismaService, CollectionsService, Clock],
      useFactory: (
        prisma: PrismaService,
        collections: CollectionsService,
        clock: Clock,
      ) => new QuestionService(prisma, collections, clock),
    },
    SubmitService,
    { provide: SessionCompletionHook, useClass: NoopSessionCompletionHook },
  ],
  exports: [QuestionService, SubmitService],
})
export class QuizModule {}
