import { INestApplication } from '@nestjs/common';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { ReviewReminderJob } from '../src/jobs/review-reminder.job';
import { StreakResetJob } from '../src/jobs/streak-reset.job';
import { MockPushProvider } from '../src/modules/notifications/mock-push.provider';
import { PushProvider } from '../src/modules/notifications/push.provider';
import { TestClock, createTestApp } from './utils/app';
import { registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { seedCollection } from './utils/fixtures';

const day = (s: string) => new Date(`${s}T00:00:00.000Z`);

describe('Cron jobs (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const clock = new TestClock();

  beforeAll(async () => {
    app = await createTestApp({ clock });
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
  });

  afterAll(async () => {
    await app.close();
  });

  describe('StreakResetJob', () => {
    it('chỉ reset người đã bỏ lỡ cả ngày hôm qua theo múi giờ của họ', async () => {
      clock.set('2026-11-19T17:30:00.000Z'); // 00:30 ngày 20 ở VN, 12:30 ngày 19 ở New York
      const a = await registerUser(app);
      const b = await registerUser(app);
      const c = await registerUser(app);
      const d = await registerUser(app);
      await prisma.user.update({
        where: { id: a.user.id },
        data: { currentStreak: 5, lastStreakDate: day('2026-11-19') },
      });
      await prisma.user.update({
        where: { id: b.user.id },
        data: { currentStreak: 3, lastStreakDate: day('2026-11-18') },
      });
      await prisma.user.update({
        where: { id: c.user.id },
        data: {
          currentStreak: 4,
          lastStreakDate: day('2026-11-18'),
          timezone: 'America/New_York',
        },
      });
      await prisma.user.update({
        where: { id: d.user.id },
        data: { currentStreak: 2, lastStreakDate: null },
      });

      const count = await app.get(StreakResetJob).run();

      expect(count).toBe(2);
      const streak = async (id: string) =>
        (await prisma.user.findUniqueOrThrow({ where: { id } })).currentStreak;
      expect(await streak(a.user.id)).toBe(5);
      expect(await streak(b.user.id)).toBe(0);
      expect(await streak(c.user.id)).toBe(4);
      expect(await streak(d.user.id)).toBe(0);
      // highestStreak không bị đụng tới
      const bUser = await prisma.user.findUniqueOrThrow({
        where: { id: b.user.id },
      });
      expect(bUser.lastStreakDate).toEqual(day('2026-11-18'));
    });
  });

  describe('ReviewReminderJob', () => {
    const provider = () => app.get<MockPushProvider>(PushProvider);

    const userWithDue = async (
      opts: {
        reminderTime?: string;
        isNotificationEnabled?: boolean;
        due?: number;
      } = {},
    ) => {
      const u = await registerUser(app);
      await prisma.user.update({
        where: { id: u.user.id },
        data: {
          reminderTime: opts.reminderTime ?? '20:00',
          isNotificationEnabled: opts.isNotificationEnabled ?? true,
        },
      });
      await prisma.userDevice.create({
        data: {
          userId: u.user.id,
          fcmToken: `tok-${u.user.id}`,
          platform: 'android',
        },
      });
      const due = opts.due ?? 3;
      await seedCollection(
        prisma,
        u.user.id,
        'IELTS',
        Array.from({ length: due + 1 }, (_, i) => ({
          term: `w${i}`,
          progress: {
            status: 'review' as const,
            nextReviewAt:
              i < due
                ? new Date('2026-11-19T01:00:00.000Z')
                : new Date('2026-11-25T01:00:00.000Z'),
          },
        })),
      );
      return u;
    };

    const sentTo = (userId: string) =>
      provider().sent.filter((s) => s.tokens.includes(`tok-${userId}`));

    it('gửi đúng một lần trong khung giờ nhắc của user', async () => {
      clock.set('2026-11-19T13:05:00.000Z'); // 20:05 giờ VN
      const u = await userWithDue();
      const job = app.get(ReviewReminderJob);

      expect(await job.run()).toBe(1);
      const sent = sentTo(u.user.id);
      expect(sent).toHaveLength(1);
      expect(sent[0].message.body).toBe('Bạn có 3 từ cần ôn tập hôm nay');

      // Lần quét sau trong cùng ngày không gửi lại
      clock.set('2026-11-19T13:10:00.000Z');
      expect(await job.run()).toBe(0);
      expect(sentTo(u.user.id)).toHaveLength(1);
    });

    it('không nhắc khi tắt thông báo, không có từ đến hạn hoặc chưa tới giờ', async () => {
      clock.set('2026-11-19T13:05:00.000Z'); // 20:05 giờ VN
      const off = await userWithDue({ isNotificationEnabled: false });
      const none = await userWithDue({ due: 0 });
      const later = await userWithDue({ reminderTime: '21:00' });
      expect(await app.get(ReviewReminderJob).run()).toBe(0);
      expect(sentTo(off.user.id)).toHaveLength(0);
      expect(sentTo(none.user.id)).toHaveLength(0);
      expect(sentTo(later.user.id)).toHaveLength(0);
    });

    it('khung 15 phút qua nửa đêm: nhắc 23:50 vẫn gửi lúc 00:02', async () => {
      clock.set('2026-11-19T17:02:00.000Z'); // 00:02 ngày 20 giờ VN
      const u = await userWithDue({ reminderTime: '23:50' });
      expect(await app.get(ReviewReminderJob).run()).toBe(1);
      expect(sentTo(u.user.id)).toHaveLength(1);
    });
  });
});
