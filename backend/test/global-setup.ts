import { execSync } from 'node:child_process';

/** Áp migration còn thiếu và seed (upsert) cho DB test một lần trước toàn bộ e2e. */
export default function globalSetup(): void {
  if (!process.env.DATABASE_URL?.includes('karvocab_test')) {
    throw new Error(
      'E2E phải chạy trên DB karvocab_test (dùng npm run test:e2e)',
    );
  }
  execSync('npx prisma migrate deploy && npx prisma db seed', {
    stdio: 'ignore',
    env: process.env,
  });
}
