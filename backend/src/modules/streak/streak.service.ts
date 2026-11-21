import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  dateOnlyToString,
  dateStringToDateOnly,
  localDateString,
} from '../../common/time/tz.util';
import { computeStreak } from './streak';

export interface StreakSummary {
  currentStreak: number;
  highestStreak: number;
  isStreakActiveToday: boolean;
}

@Injectable()
export class StreakService {
  /** Ghi nhận user vừa học lúc `now` (theo múi giờ của user) và trả streak mới. */
  async recordActivity(
    tx: Prisma.TransactionClient,
    userId: string,
    now: Date,
  ): Promise<StreakSummary> {
    const user = await tx.user.findUniqueOrThrow({ where: { id: userId } });
    const today = localDateString(now, user.timezone);
    const next = computeStreak(
      {
        currentStreak: user.currentStreak,
        highestStreak: user.highestStreak,
        lastStreakDate: dateOnlyToString(user.lastStreakDate),
      },
      today,
    );
    await tx.user.update({
      where: { id: userId },
      data: {
        currentStreak: next.currentStreak,
        highestStreak: next.highestStreak,
        lastStreakDate: dateStringToDateOnly(today),
      },
    });
    return {
      currentStreak: next.currentStreak,
      highestStreak: next.highestStreak,
      isStreakActiveToday: true,
    };
  }

  /** Đọc streak hiện tại mà không thay đổi. */
  summarize(
    user: {
      currentStreak: number;
      highestStreak: number;
      lastStreakDate: Date | null;
      timezone: string;
    },
    now: Date,
  ): StreakSummary {
    return {
      currentStreak: user.currentStreak,
      highestStreak: user.highestStreak,
      isStreakActiveToday:
        dateOnlyToString(user.lastStreakDate) ===
        localDateString(now, user.timezone),
    };
  }
}
