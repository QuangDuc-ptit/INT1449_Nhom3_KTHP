import { PrismaClient } from '@prisma/client';

/** Danh mục huy hiệu cố định (xem kế hoạch, Quyết định bổ sung #13). */
export const BADGES = [
  {
    code: 'streak_7',
    title: 'Chuỗi 7 Ngày',
    description: 'Học liên tục 7 ngày',
    requiredPoints: 7,
  },
  {
    code: 'first_100',
    title: 'Bách Khoa 100 Từ',
    description: 'Học 100 từ vựng',
    requiredPoints: 100,
  },
  {
    code: 'explorer_5',
    title: 'Nhà Thám Hiểm',
    description: 'Tạo 5 học phần',
    requiredPoints: 5,
  },
] as const;

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    for (const b of BADGES) {
      await prisma.badge.upsert({
        where: { code: b.code },
        update: {
          title: b.title,
          description: b.description,
          requiredPoints: b.requiredPoints,
        },
        create: { ...b },
      });
    }
  } finally {
    await prisma.$disconnect();
  }
}

void main();
