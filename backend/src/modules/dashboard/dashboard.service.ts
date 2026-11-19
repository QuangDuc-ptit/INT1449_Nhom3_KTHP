import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/http/app.exception';
import { Clock } from '../../common/time/clock';
import { startOfLocalDayUtc } from '../../common/time/tz.util';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { toCollectionDto } from '../collections/collections.service';
import { CollectionDto } from '../collections/dto/collection.dto';
import { StreakService, StreakSummary } from '../streak/streak.service';

export interface DashboardDto {
  streak: StreakSummary;
  dailyGoal: {
    targetWords: number;
    wordsLearnedToday: number;
    progressPercentage: number;
  };
  reviewReminder: { hasPendingReview: boolean; dueWordsCount: number };
  quickCollections: CollectionDto[];
}

@Injectable()
export class DashboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly streak: StreakService,
    private readonly clock: Clock,
  ) {}

  async getDashboard(userId: string): Promise<DashboardDto> {
    const now = this.clock.now();
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new AppException(401, 'UNAUTHORIZED', 'Tài khoản không tồn tại');
    }
    const dayStart = startOfLocalDayUtc(now, user.timezone);

    const [learnedToday, dueWordsCount, collections] = await Promise.all([
      // Số từ khác nhau trả lời đúng trong các phiên hoàn thành hôm nay (giờ địa phương)
      this.prisma.quizAnswer.findMany({
        where: {
          isCorrect: true,
          session: { userId, completedAt: { gte: dayStart, lte: now } },
        },
        distinct: ['vocabularyId'],
        select: { vocabularyId: true },
      }),
      this.prisma.userVocabProgress.count({
        where: {
          userId,
          nextReviewAt: { lte: now },
          vocabulary: { collection: { userId } },
        },
      }),
      this.prisma.collection.findMany({
        where: { userId },
        orderBy: [{ updatedAt: 'desc' }, { id: 'asc' }],
        take: 3,
      }),
    ]);

    const wordsLearnedToday = learnedToday.length;
    return {
      streak: this.streak.summarize(user, now),
      dailyGoal: {
        targetWords: user.dailyGoalWords,
        wordsLearnedToday,
        progressPercentage: Math.min(
          100,
          Math.round((wordsLearnedToday / user.dailyGoalWords) * 100),
        ),
      },
      reviewReminder: {
        hasPendingReview: dueWordsCount > 0,
        dueWordsCount,
      },
      quickCollections: collections.map(toCollectionDto),
    };
  }
}
