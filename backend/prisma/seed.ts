import { PrismaClient } from '@prisma/client';
import { BADGES } from '../src/modules/gamification/badge-catalog';

/** Seed cho dev/test; production tự đồng bộ huy hiệu khi app khởi động (BadgeSeeder). */
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
