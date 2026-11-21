import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Clock } from '../common/time/clock';
import {
  addDays,
  localDateString,
  localTimeHHmm,
} from '../common/time/tz.util';
import { PrismaService } from '../infra/prisma/prisma.service';
import { RedisService } from '../infra/redis/redis.service';
import { PushService } from '../modules/notifications/push.service';

export const REMINDER_WINDOW_MIN = 15;
const DAY_MIN = 24 * 60;
const NOTIFIED_TTL_SEC = 36 * 60 * 60;

const toMinutes = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

/**
 * Chạy mỗi 15 phút: gửi push nhắc ôn tập cho user có từ đến hạn, khi giờ địa
 * phương nằm trong [reminderTime, reminderTime + 15 phút). Mỗi ngày nhắc tối đa một lần.
 */
@Injectable()
export class ReviewReminderJob {
  private readonly logger = new Logger(ReviewReminderJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly push: PushService,
    private readonly clock: Clock,
  ) {}

  @Cron('*/15 * * * *', { name: 'review-reminder' })
  async handleCron(): Promise<void> {
    const n = await this.run();
    if (n) this.logger.log(`Đã nhắc ôn tập cho ${n} người dùng`);
  }

  async run(): Promise<number> {
    const now = this.clock.now();
    const users = await this.prisma.user.findMany({
      where: { isNotificationEnabled: true, devices: { some: {} } },
      select: { id: true, timezone: true, reminderTime: true },
    });

    let notified = 0;
    for (const u of users) {
      const nowMin = toMinutes(localTimeHHmm(now, u.timezone));
      const startMin = toMinutes(u.reminderTime);
      const elapsed = (nowMin - startMin + DAY_MIN) % DAY_MIN;
      if (elapsed >= REMINDER_WINDOW_MIN) continue;

      const dueCount = await this.prisma.userVocabProgress.count({
        where: {
          userId: u.id,
          nextReviewAt: { lte: now },
          vocabulary: { collection: { userId: u.id } },
        },
      });
      if (!dueCount) continue;

      // Khoá theo ngày bắt đầu khung nhắc (khung 23:50 kéo sang 00:05 vẫn là ngày cũ)
      const today = localDateString(now, u.timezone);
      const windowDate = nowMin >= startMin ? today : addDays(today, -1);
      const key = `notified:${u.id}:${windowDate}`;
      const firstTime = await this.redis.client.set(
        key,
        '1',
        'EX',
        NOTIFIED_TTL_SEC,
        'NX',
      );
      if (firstTime !== 'OK') continue;

      try {
        await this.push.sendPushNotification(
          u.id,
          'KarVocab - Đến giờ ôn tập',
          `Bạn có ${dueCount} từ cần ôn tập hôm nay`,
          { screen: 'review', dueCount: String(dueCount) },
        );
        notified++;
      } catch (err) {
        // Lỗi của một user không được chặn những user sau; bỏ khoá để lượt quét sau gửi lại
        await this.redis.client.del(key);
        this.logger.warn(
          `Gửi nhắc ôn tập cho ${u.id} thất bại: ${(err as Error).message}`,
        );
      }
    }
    return notified;
  }
}
