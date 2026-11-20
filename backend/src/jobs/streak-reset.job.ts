import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Clock } from '../common/time/clock';
import {
  addDays,
  dateStringToDateOnly,
  localDateString,
} from '../common/time/tz.util';
import { PrismaService } from '../infra/prisma/prisma.service';

/**
 * Chạy mỗi giờ: reset streak về 0 cho user đã qua trọn một ngày (theo múi giờ
 * của họ) mà không học. Học hôm qua thì vẫn còn cả hôm nay để giữ chuỗi.
 */
@Injectable()
export class StreakResetJob {
  private readonly logger = new Logger(StreakResetJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  @Cron('0 * * * *', { name: 'streak-reset' })
  async handleCron(): Promise<void> {
    const n = await this.run();
    if (n) this.logger.log(`Đã reset streak cho ${n} người dùng`);
  }

  async run(): Promise<number> {
    const now = this.clock.now();
    const timezones = await this.prisma.user.findMany({
      where: { currentStreak: { gt: 0 } },
      distinct: ['timezone'],
      select: { timezone: true },
    });
    let total = 0;
    for (const { timezone } of timezones) {
      const yesterday = addDays(localDateString(now, timezone), -1);
      // Điều kiện ngày nằm ngay trong UPDATE nên user vừa nộp bài (đã cập nhật
      // lastStreakDate) trong lúc job chạy sẽ không bị reset nhầm
      const { count } = await this.prisma.user.updateMany({
        where: {
          timezone,
          currentStreak: { gt: 0 },
          OR: [
            { lastStreakDate: null },
            { lastStreakDate: { lt: dateStringToDateOnly(yesterday) } },
          ],
        },
        data: { currentStreak: 0 },
      });
      total += count;
    }
    return total;
  }
}
