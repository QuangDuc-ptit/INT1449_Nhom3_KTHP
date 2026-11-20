import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Auth (e2e)', () => {
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

  describe('POST /auth/register', () => {
    it('tạo tài khoản, trả cặp token và email đã chuẩn hoá', async () => {
      const res = await http()
        .post('/api/v1/auth/register')
        .send({
          email: '  A@Example.com ',
          password: 'Password123',
          fullName: 'Nguyen Van A',
        })
        .expect(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.accessToken).toEqual(expect.any(String));
      expect(res.body.data.refreshToken).toEqual(expect.any(String));
      expect(res.body.data.user).toMatchObject({
        email: 'a@example.com',
        fullName: 'Nguyen Van A',
      });
      expect(res.body.data.user.passwordHash).toBeUndefined();
      const user = await prisma.user.findUniqueOrThrow({
        where: { email: 'a@example.com' },
      });
      expect(user.passwordHash).toMatch(/^\$2/);
      expect(await prisma.refreshToken.count()).toBe(1);
    });

    it('email đã tồn tại trả 409 EMAIL_EXISTS', async () => {
      await registerUser(app, { email: 'dup@example.com' });
      const res = await http()
        .post('/api/v1/auth/register')
        .send({
          email: 'DUP@example.com',
          password: 'Password123',
          fullName: 'B',
        })
        .expect(409);
      expect(res.body.errorCode).toBe('EMAIL_EXISTS');
    });

    it('mật khẩu yếu trả 400 VALIDATION_ERROR ở trường password', async () => {
      const res = await http()
        .post('/api/v1/auth/register')
        .send({ email: 'c@example.com', password: 'password', fullName: 'C' })
        .expect(400);
      expect(res.body.errorCode).toBe('VALIDATION_ERROR');
      expect(res.body.errors[0].field).toBe('password');
    });

    it('email sai định dạng trả 400', async () => {
      await http()
        .post('/api/v1/auth/register')
        .send({ email: 'not-an-email', password: 'Password123', fullName: 'D' })
        .expect(400);
    });
  });

  describe('POST /auth/login', () => {
    it('đăng nhập đúng trả 200 và cặp token', async () => {
      await registerUser(app, {
        email: 'e@example.com',
        password: 'Password123',
      });
      const res = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'E@example.com', password: 'Password123' })
        .expect(200);
      expect(res.body.data.accessToken).toEqual(expect.any(String));
      expect(res.body.data.user.email).toBe('e@example.com');
    });

    it('sai mật khẩu và email không tồn tại trả cùng một lỗi 401', async () => {
      await registerUser(app, { email: 'f@example.com' });
      const wrongPass = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'f@example.com', password: 'Wrong12345' })
        .expect(401);
      const noUser = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'nobody@example.com', password: 'Password123' })
        .expect(401);
      expect(wrongPass.body.errorCode).toBe('INVALID_CREDENTIALS');
      expect(noUser.body.errorCode).toBe('INVALID_CREDENTIALS');
      expect(wrongPass.body.message).toBe('Email hoặc mật khẩu không đúng');
      expect(noUser.body.message).toBe(wrongPass.body.message);
    });
  });

  describe('JWT guard', () => {
    it('route công khai không cần token', async () => {
      await http().get('/api/v1/health').expect(200);
    });

    it('route được bảo vệ không có token trả 401', async () => {
      const res = await http().get('/api/v1/auth/me').expect(401);
      expect(res.body.errorCode).toBe('UNAUTHORIZED');
    });

    it('token sai chữ ký trả 401', async () => {
      await http()
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer abc.def.ghi')
        .expect(401);
    });

    it('token hợp lệ trả thông tin user', async () => {
      const { accessToken, user } = await registerUser(app);
      const res = await http()
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.data).toMatchObject({ id: user.id, email: user.email });
    });
  });

  describe('POST /auth/refresh', () => {
    it('cấp cặp token mới và thu hồi refresh token cũ', async () => {
      const { refreshToken } = await registerUser(app);
      const res = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken })
        .expect(200);
      expect(res.body.data.accessToken).toEqual(expect.any(String));
      expect(res.body.data.refreshToken).not.toBe(refreshToken);
    });

    it('dùng lại refresh token cũ thì thu hồi toàn bộ token của user', async () => {
      const { refreshToken: oldToken } = await registerUser(app);
      const first = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: oldToken })
        .expect(200);
      const reused = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: oldToken })
        .expect(401);
      expect(reused.body.errorCode).toBe('REFRESH_TOKEN_REUSED');
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: first.body.data.refreshToken })
        .expect(401);
    });

    it('refresh token hết hạn trả 401 REFRESH_TOKEN_INVALID', async () => {
      const { refreshToken } = await registerUser(app);
      await prisma.refreshToken.updateMany({
        data: { expiresAt: new Date('2020-01-01T00:00:00Z') },
      });
      const res = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken })
        .expect(401);
      expect(res.body.errorCode).toBe('REFRESH_TOKEN_INVALID');
    });

    it('refresh token không tồn tại trả 401 REFRESH_TOKEN_INVALID', async () => {
      const res = await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: 'abc' })
        .expect(401);
      expect(res.body.errorCode).toBe('REFRESH_TOKEN_INVALID');
    });
  });

  describe('Chống brute-force đăng nhập', () => {
    it('đăng nhập sai quá 5 lần trong 60 giây thì lần thứ 6 bị 429', async () => {
      await registerUser(app, { email: 'bf@example.com' });
      for (let i = 0; i < 5; i++) {
        await http()
          .post('/api/v1/auth/login')
          .send({ email: 'bf@example.com', password: 'Wrong12345' })
          .expect(401);
      }
      const res = await http()
        .post('/api/v1/auth/login')
        .send({ email: 'bf@example.com', password: 'Password123' })
        .expect(429);
      expect(res.body.errorCode).toBe('RATE_LIMITED');
      expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    });
  });

  describe('POST /auth/logout', () => {
    it('vô hiệu hoá access token hiện tại và refresh token', async () => {
      const { accessToken, refreshToken } = await registerUser(app);
      await http()
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken })
        .expect(200);
      await http()
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(401);
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken })
        .expect(401);
    });

    it('không thu hồi được refresh token của người khác', async () => {
      const a = await registerUser(app);
      const b = await registerUser(app);
      await http()
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${a.accessToken}`)
        .send({ refreshToken: b.refreshToken })
        .expect(200);
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: b.refreshToken })
        .expect(200);
    });
  });
});
