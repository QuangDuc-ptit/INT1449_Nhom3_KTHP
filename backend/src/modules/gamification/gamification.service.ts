import { Injectable } from '@nestjs/common';
import { Badge, Prisma } from '@prisma/client';
import { BadgeDto } from '../quiz/dto/submit.dto';
import { SessionCompletionHook } from '../quiz/submit.service';
import { BADGE_RULES, UserMetrics } from './badge-rules';

export const toBadgeDto = (b: Badge): BadgeDto => ({
  code: b.code,
  title: b.title,
  description: b.description,
  iconUrl: b.iconUrl,
  requiredPoints: b.requiredPoints,
});

/** Kiểm tra và mở khoá huy hiệu sau mỗi phiên học (chạy trong transaction nộp bài). */
@Injectable()
export class GamificationService extends SessionCompletionHook {
  async getMetrics(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<UserMetrics> {
    const [user, learnedWords, collectionsCount] = await Promise.all([
      tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { currentStreak: true },
      }),
      tx.userVocabProgress.count({
        where: { userId, status: { not: 'new' } },
      }),
      tx.collection.count({ where: { userId } }),
    ]);
    return {
      currentStreak: user.currentStreak,
      learnedWords,
      collectionsCount,
    };
  }

  /** Trả các huy hiệu MỚI mở khoá (huy hiệu đã có thì không trả lại). */
  async evaluate(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<BadgeDto[]> {
    const locked = await tx.badge.findMany({
      where: { users: { none: { userId } } },
      orderBy: { requiredPoints: 'asc' },
    });
    if (!locked.length) return [];
    const metrics = await this.getMetrics(tx, userId);
    const earned = locked.filter((b) => {
      const rule = BADGE_RULES[b.code];
      return rule ? rule(metrics) >= b.requiredPoints : false;
    });
    if (!earned.length) return [];
    await tx.userBadge.createMany({
      data: earned.map((b) => ({ userId, badgeId: b.id })),
      skipDuplicates: true,
    });
    return earned.map(toBadgeDto);
  }

  onSessionCompleted(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<BadgeDto[]> {
    return this.evaluate(tx, userId);
  }
}
