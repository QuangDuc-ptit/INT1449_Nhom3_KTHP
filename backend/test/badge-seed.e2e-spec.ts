import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';

describe('Seed huy hiệu khi khởi động (e2e)', () => {
  it('DB chưa có huy hiệu thì app tự tạo đủ 3 huy hiệu khi khởi động', async () => {
    const prisma = new PrismaService();
    await prisma.$connect();
    await prisma.badge.deleteMany();
    expect(await prisma.badge.count()).toBe(0);

    const app = await createTestApp();
    try {
      const badges = await prisma.badge.findMany({ orderBy: { code: 'asc' } });
      expect(badges.map((b) => b.code)).toEqual([
        'explorer_5',
        'first_100',
        'streak_7',
      ]);
      expect(badges.find((b) => b.code === 'streak_7')).toMatchObject({
        title: 'Chuỗi 7 Ngày',
        requiredPoints: 7,
      });
    } finally {
      await app.close();
      await prisma.$disconnect();
    }
  });

  it('khởi động lại không tạo trùng huy hiệu', async () => {
    const app = await createTestApp();
    await app.close();
    const prisma = new PrismaService();
    expect(await prisma.badge.count()).toBe(3);
    await prisma.$disconnect();
  });
});
