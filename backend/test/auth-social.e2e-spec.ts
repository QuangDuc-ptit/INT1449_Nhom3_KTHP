import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Đăng nhập mạng xã hội (e2e, verifier mock)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
  });

  afterAll(async () => {
    await app.close();
  });

  const social = (provider: string, idToken: string) =>
    request(app.getHttpServer())
      .post('/api/v1/auth/social-login')
      .send({ provider, idToken });

  it('lần đầu đăng nhập Google tạo tài khoản mới không có mật khẩu', async () => {
    const res = await social(
      'google',
      'mock:g-123:New@Example.com:Lan Anh',
    ).expect(200);
    expect(res.body.data.accessToken).toEqual(expect.any(String));
    expect(res.body.data.user).toMatchObject({
      email: 'new@example.com',
      fullName: 'Lan Anh',
    });
    const user = await prisma.user.findUniqueOrThrow({
      where: { email: 'new@example.com' },
    });
    expect(user.authProvider).toBe('google');
    expect(user.providerId).toBe('g-123');
    expect(user.passwordHash).toBeNull();
  });

  it('đăng nhập lại cùng providerId trả cùng một user', async () => {
    const a = await social('google', 'mock:g-1:a@example.com:A').expect(200);
    const b = await social('google', 'mock:g-1:a@example.com:A').expect(200);
    expect(b.body.data.user.id).toBe(a.body.data.user.id);
    expect(await prisma.user.count()).toBe(1);
  });

  it('email trùng tài khoản local thì liên kết vào tài khoản đó', async () => {
    const local = await registerUser(app, { email: 'link@example.com' });
    const res = await social('facebook', 'mock:fb-9:link@example.com:L').expect(
      200,
    );
    expect(res.body.data.user.id).toBe(local.user.id);
    await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'link@example.com', password: local.password })
      .expect(200);
  });

  it('tài khoản social không có mật khẩu không đăng nhập bằng mật khẩu được', async () => {
    await social('google', 'mock:g-2:nopass@example.com:N').expect(200);
    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'nopass@example.com', password: 'Password123' })
      .expect(401);
    expect(res.body.errorCode).toBe('INVALID_CREDENTIALS');
  });

  it('token sai định dạng trả 401 SOCIAL_TOKEN_INVALID', async () => {
    const res = await social('google', 'garbage').expect(401);
    expect(res.body.errorCode).toBe('SOCIAL_TOKEN_INVALID');
  });

  it('provider không hỗ trợ trả 400', async () => {
    await social('twitter', 'mock:x:a@b.com:A').expect(400);
  });
});
