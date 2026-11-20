import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { RedisService } from '../src/infra/redis/redis.service';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { ConsoleMailProvider } from '../src/modules/mail/console-mail.provider';
import { MailProvider } from '../src/modules/mail/mail.provider';
import { createTestApp } from './utils/app';
import { registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Quên mật khẩu bằng OTP (e2e)', () => {
  let app: INestApplication;
  let mail: ConsoleMailProvider;
  let redis: RedisService;

  beforeAll(async () => {
    app = await createTestApp();
    mail = app.get(MailProvider);
    redis = app.get(RedisService);
  });

  beforeEach(async () => {
    await resetDb(app.get(PrismaService));
    await resetRedis(app);
    mail.lastMessages.length = 0;
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  const requestOtp = async (email: string): Promise<string> => {
    await http()
      .post('/api/v1/auth/forgot-password')
      .send({ email })
      .expect(200);
    const msg = mail.lastMessages.at(-1);
    const otp = /\b(\d{6})\b/.exec(msg?.html ?? '')?.[1];
    if (!otp) throw new Error('Không tìm thấy OTP trong thư');
    return otp;
  };

  it('gửi thư chứa OTP 6 số và lưu Redis với TTL tối đa 300 giây', async () => {
    await registerUser(app, { email: 'otp@example.com' });
    const res = await http()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'OTP@example.com' })
      .expect(200);
    expect(res.body.message).toBe('Nếu email tồn tại, mã xác nhận đã được gửi');
    expect(mail.lastMessages).toHaveLength(1);
    expect(mail.lastMessages[0].to).toBe('otp@example.com');
    expect(mail.lastMessages[0].html).toMatch(/\b\d{6}\b/);
    const ttl = await redis.client.ttl('otp:reset:otp@example.com');
    expect(ttl).toBeGreaterThan(0);
    expect(ttl).toBeLessThanOrEqual(300);
  });

  it('email không tồn tại vẫn trả 200 với cùng thông báo và không gửi thư', async () => {
    const res = await http()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'ghost@example.com' })
      .expect(200);
    expect(res.body.message).toBe('Nếu email tồn tại, mã xác nhận đã được gửi');
    expect(mail.lastMessages).toHaveLength(0);
  });

  it('OTP đúng đặt lại được mật khẩu và thu hồi phiên cũ', async () => {
    const u = await registerUser(app, { email: 'reset@example.com' });
    const otp = await requestOtp('reset@example.com');
    await http()
      .post('/api/v1/auth/reset-password')
      .send({ email: 'reset@example.com', otp, newPassword: 'NewPass456' })
      .expect(200);
    await http()
      .post('/api/v1/auth/login')
      .send({ email: 'reset@example.com', password: 'NewPass456' })
      .expect(200);
    await http()
      .post('/api/v1/auth/login')
      .send({ email: 'reset@example.com', password: u.password })
      .expect(401);
    await http()
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: u.refreshToken })
      .expect(401);
    // OTP chỉ dùng được một lần
    await http()
      .post('/api/v1/auth/reset-password')
      .send({ email: 'reset@example.com', otp, newPassword: 'Another789' })
      .expect(400);
  });

  it('OTP sai trả 400 OTP_INVALID; sai 5 lần thì OTP đúng cũng bị huỷ', async () => {
    await registerUser(app, { email: 'wrong@example.com' });
    const otp = await requestOtp('wrong@example.com');
    const wrong = otp === '000000' ? '111111' : '000000';
    for (let i = 0; i < 5; i++) {
      const res = await http()
        .post('/api/v1/auth/reset-password')
        .send({
          email: 'wrong@example.com',
          otp: wrong,
          newPassword: 'NewPass456',
        })
        .expect(400);
      expect(res.body.errorCode).toBe('OTP_INVALID');
    }
    await http()
      .post('/api/v1/auth/reset-password')
      .send({ email: 'wrong@example.com', otp, newPassword: 'NewPass456' })
      .expect(400);
  });

  it('mật khẩu mới yếu trả 400 VALIDATION_ERROR', async () => {
    await http()
      .post('/api/v1/auth/reset-password')
      .send({ email: 'x@example.com', otp: '123456', newPassword: 'weak' })
      .expect(400);
  });

  it('gọi forgot-password lần thứ 4 trong 15 phút bị 429', async () => {
    for (let i = 0; i < 3; i++) {
      await http()
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'spam@example.com' })
        .expect(200);
    }
    await http()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'spam@example.com' })
      .expect(429);
  });
});
