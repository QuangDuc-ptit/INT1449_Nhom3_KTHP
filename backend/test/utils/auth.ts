import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';

export interface RegisteredUser {
  accessToken: string;
  refreshToken: string;
  user: { id: string; email: string; fullName: string };
  password: string;
}

/** Đăng ký nhanh một user qua API và trả về token. */
export async function registerUser(
  app: INestApplication,
  overrides: { email?: string; password?: string; fullName?: string } = {},
): Promise<RegisteredUser> {
  const password = overrides.password ?? 'Password123';
  const res = await request(app.getHttpServer())
    .post('/api/v1/auth/register')
    .send({
      email: overrides.email ?? `u-${randomUUID()}@example.com`,
      password,
      fullName: overrides.fullName ?? 'Người Dùng Test',
    })
    .expect(201);
  return { ...(res.body.data as Omit<RegisteredUser, 'password'>), password };
}

export const bearer = (token: string) => ({
  Authorization: `Bearer ${token}`,
});
