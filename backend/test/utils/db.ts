import { INestApplication } from '@nestjs/common';
import { RedisService } from '../../src/infra/redis/redis.service';
import { PrismaClient } from '@prisma/client';

const KEEP = new Set(['_prisma_migrations', 'badges']);

/** Xoá sạch dữ liệu mọi bảng (giữ bảng badges đã seed). */
export async function resetDb(prisma: PrismaClient): Promise<void> {
  const rows = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'`;
  const tables = rows
    .map((r) => r.tablename)
    .filter((t) => !KEEP.has(t))
    .map((t) => `"public"."${t}"`);
  if (tables.length) {
    await prisma.$executeRawUnsafe(`TRUNCATE ${tables.join(', ')} CASCADE`);
  }
}

/** Xoá toàn bộ key trong Redis DB dành cho test (REDIS_DB=1). */
export async function resetRedis(app: INestApplication): Promise<void> {
  if (process.env.REDIS_DB !== '1') {
    throw new Error('resetRedis chỉ chạy trên Redis DB test (REDIS_DB=1)');
  }
  await app.get(RedisService).client.flushdb();
}
