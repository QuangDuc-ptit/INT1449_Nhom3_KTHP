import { PrismaService } from '../infra/prisma/prisma.service';
import { StreakResetJob } from './streak-reset.job';

describe('StreakResetJob (chống race với người vừa nộp bài)', () => {
  it('reset bằng một câu UPDATE có điều kiện ngày cho từng múi giờ', async () => {
    const updateMany = jest
      .fn()
      .mockResolvedValueOnce({ count: 2 })
      .mockResolvedValueOnce({ count: 1 });
    const prisma = {
      user: {
        findMany: jest
          .fn()
          .mockResolvedValue([
            { timezone: 'Asia/Ho_Chi_Minh' },
            { timezone: 'America/New_York' },
          ]),
        updateMany,
      },
    };
    const clock = { now: () => new Date('2026-11-19T17:30:00.000Z') };
    const job = new StreakResetJob(prisma as unknown as PrismaService, clock);

    expect(await job.run()).toBe(3);

    // Điều kiện lastStreakDate nằm ngay trong UPDATE: ai vừa học (cập nhật
    // lastStreakDate) giữa lúc job chạy sẽ không bị reset nhầm
    expect(updateMany).toHaveBeenCalledWith({
      where: {
        timezone: 'Asia/Ho_Chi_Minh',
        currentStreak: { gt: 0 },
        OR: [
          { lastStreakDate: null },
          { lastStreakDate: { lt: new Date('2026-11-19T00:00:00.000Z') } },
        ],
      },
      data: { currentStreak: 0 },
    });
    expect(updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          timezone: 'America/New_York',
          OR: [
            { lastStreakDate: null },
            { lastStreakDate: { lt: new Date('2026-11-18T00:00:00.000Z') } },
          ],
        }),
      }),
    );
  });
});
