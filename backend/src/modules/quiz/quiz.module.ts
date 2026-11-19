import { Module } from '@nestjs/common';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsModule } from '../collections/collections.module';
import { CollectionsService } from '../collections/collections.service';
import { GamificationService } from '../gamification/gamification.service';
import { PracticeController } from './practice.controller';
import { QuestionService } from './question.service';
import { SessionCompletionHook, SubmitService } from './submit.service';

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
    // Huy hiệu được kiểm tra cuối mỗi phiên học
    { provide: SessionCompletionHook, useExisting: GamificationService },
  ],
  exports: [QuestionService, SubmitService],
})
export class QuizModule {}
