import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Clock } from '../common/time/clock';
import {
  addDays,
  dateOnlyToString,
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
    const users = await this.prisma.user.findMany({
      where: { currentStreak: { gt: 0 } },
      select: { id: true, timezone: true, lastStreakDate: true },
    });
    const yesterdayByTz = new Map<string, string>();
    const expired = users.filter((u) => {
      let yesterday = yesterdayByTz.get(u.timezone);
      if (!yesterday) {
        yesterday = addDays(localDateString(now, u.timezone), -1);
        yesterdayByTz.set(u.timezone, yesterday);
      }
      const last = dateOnlyToString(u.lastStreakDate);
      return !last || last < yesterday;
    });
    if (!expired.length) return 0;
    const { count } = await this.prisma.user.updateMany({
      where: { id: { in: expired.map((u) => u.id) }, currentStreak: { gt: 0 } },
      data: { currentStreak: 0 },
    });
    return count;
  }
}
