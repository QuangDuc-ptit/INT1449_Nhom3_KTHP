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
