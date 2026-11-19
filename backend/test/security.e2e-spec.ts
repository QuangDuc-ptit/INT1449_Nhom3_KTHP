import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { resetDb, resetRedis } from './utils/db';

describe('Bảo mật HTTP (e2e)', () => {
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

  const http = () => request(app.getHttpServer());

  it('có header bảo mật của helmet', async () => {
    const res = await http().get('/api/v1/health').expect(200);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-powered-by']).toBeUndefined();
  });

  it('CORS chỉ cho phép origin trong CORS_ORIGINS', async () => {
    const allowed = await http()
      .get('/api/v1/health')
      .set('Origin', 'http://localhost:3100')
      .expect(200);
    expect(allowed.headers['access-control-allow-origin']).toBe(
      'http://localhost:3100',
    );
    const denied = await http()
      .get('/api/v1/health')
      .set('Origin', 'https://evil.example.com')
      .expect(200);
    expect(denied.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('body JSON lớn hơn 1 MB trả 413 với body lỗi chuẩn', async () => {
    const res = await http()
      .post('/api/v1/auth/login')
      .set('Content-Type', 'application/json')
      .send(
        JSON.stringify({
          email: 'a@b.com',
          password: 'x'.repeat(1024 * 1024 + 10),
        }),
      )
      .expect(413);
    expect(res.body).toMatchObject({
      success: false,
      errorCode: 'PAYLOAD_TOO_LARGE',
    });
  });

  it('body 500 KB vẫn được nhận (giới hạn không quá chặt)', async () => {
    await http()
      .post('/api/v1/auth/login')
      .set('Content-Type', 'application/json')
      .send(
        JSON.stringify({ email: 'a@b.com', password: 'x'.repeat(500 * 1024) }),
      )
      .expect(400);
  });

  it('JSON hỏng trả 400 với body lỗi chuẩn', async () => {
    const res = await http()
      .post('/api/v1/auth/login')
      .set('Content-Type', 'application/json')
      .send('{"email": ')
      .expect(400);
    expect(res.body.success).toBe(false);
  });

  it('gửi thừa trường role khi đăng ký trả 400 (không leo thang quyền)', async () => {
    const res = await http()
      .post('/api/v1/auth/register')
      .send({
        email: 'r@example.com',
        password: 'Password123',
        fullName: 'R',
        role: 'admin',
      })
      .expect(400);
    expect(res.body.errors).toContainEqual({
      field: 'role',
      message: 'Trường role không được phép',
    });
    expect(await prisma.user.count()).toBe(0);
  });
});
