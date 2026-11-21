import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

/** PNG 1x1 hợp lệ (67 byte). */
const PNG_1X1 = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  'base64',
);

describe('Người dùng: hồ sơ, cài đặt, thiết bị (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let u: RegisteredUser;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
    u = await registerUser(app, { fullName: 'Lê Anh Tuấn' });
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  describe('GET /users/profile', () => {
    it('user mới: thống kê bằng 0, cài đặt mặc định, 3 huy hiệu chưa mở', async () => {
      const res = await http()
        .get('/api/v1/users/profile')
        .set(bearer(u.accessToken))
        .expect(200);
      expect(res.body.data.user).toMatchObject({
        id: u.user.id,
        fullName: 'Lê Anh Tuấn',
        authProvider: 'local',
      });
      expect(res.body.data.stats).toEqual({
        learnedWords: 0,
        masteredWords: 0,
        collectionsCount: 0,
        currentStreak: 0,
        highestStreak: 0,
      });
      expect(res.body.data.settings).toEqual({
        dailyGoalWords: 10,
        reminderTime: '20:00',
        isNotificationEnabled: true,
        timezone: 'Asia/Ho_Chi_Minh',
        language: 'vi',
      });
      expect(res.body.data.badges).toHaveLength(3);
      for (const b of res.body.data.badges) {
        expect(b).toMatchObject({
          unlocked: false,
          unlockedAt: null,
          progress: 0,
        });
      }
    });

    it('thống kê và tiến độ huy hiệu phản ánh dữ liệu thật', async () => {
      const col = await prisma.collection.create({
        data: { userId: u.user.id, title: 'A' },
      });
      await prisma.collection.create({
        data: { userId: u.user.id, title: 'B' },
      });
      const mk = (term: string) =>
        prisma.vocabulary.create({
          data: {
            collectionId: col.id,
            term,
            termKey: term,
            partOfSpeech: 'noun',
            definitionVi: term,
            cefrLevel: 'A1',
          },
        });
      const [v1, v2, v3] = await Promise.all([mk('a'), mk('b'), mk('c')]);
      await prisma.userVocabProgress.createMany({
        data: [
          { userId: u.user.id, vocabularyId: v1.id, status: 'review' },
          { userId: u.user.id, vocabularyId: v2.id, status: 'mastered' },
          { userId: u.user.id, vocabularyId: v3.id, status: 'new' },
        ],
      });
      await prisma.user.update({
        where: { id: u.user.id },
        data: { currentStreak: 3, highestStreak: 9 },
      });
      const streakBadge = await prisma.badge.findUniqueOrThrow({
        where: { code: 'streak_7' },
      });
      await prisma.userBadge.create({
        data: { userId: u.user.id, badgeId: streakBadge.id },
      });

      const res = await http()
        .get('/api/v1/users/profile')
        .set(bearer(u.accessToken))
        .expect(200);
      expect(res.body.data.stats).toEqual({
        learnedWords: 2,
        masteredWords: 1,
        collectionsCount: 2,
        currentStreak: 3,
        highestStreak: 9,
      });
      const byCode = Object.fromEntries(
        res.body.data.badges.map((b: { code: string }) => [b.code, b]),
      );
      expect(byCode.streak_7).toMatchObject({ unlocked: true, progress: 3 });
      expect(byCode.streak_7.unlockedAt).toEqual(expect.any(String));
      expect(byCode.first_100).toMatchObject({ unlocked: false, progress: 2 });
      expect(byCode.explorer_5).toMatchObject({ unlocked: false, progress: 2 });
    });
  });

  describe('PATCH /users/settings', () => {
    it('cập nhật mục tiêu ngày và giờ nhắc', async () => {
      await http()
        .patch('/api/v1/users/settings')
        .set(bearer(u.accessToken))
        .send({ dailyGoalWords: 15, reminderTime: '21:30', language: 'en' })
        .expect(200);
      const res = await http()
        .get('/api/v1/users/profile')
        .set(bearer(u.accessToken))
        .expect(200);
      expect(res.body.data.settings).toMatchObject({
        dailyGoalWords: 15,
        reminderTime: '21:30',
        language: 'en',
      });
    });

    it.each([
      [{ dailyGoalWords: 31 }],
      [{ dailyGoalWords: 4 }],
      [{ reminderTime: '25:00' }],
      [{ reminderTime: '8:00' }],
      [{ timezone: 'Mars/Base' }],
      [{ language: 'fr' }],
    ])('giá trị không hợp lệ %j trả 400', async (body) => {
      await http()
        .patch('/api/v1/users/settings')
        .set(bearer(u.accessToken))
        .send(body)
        .expect(400);
    });
  });

  it('PATCH /users/profile đổi họ tên', async () => {
    const res = await http()
      .patch('/api/v1/users/profile')
      .set(bearer(u.accessToken))
      .send({ fullName: '  Tuấn Lê ' })
      .expect(200);
    expect(res.body.data.fullName).toBe('Tuấn Lê');
  });

  describe('PATCH /users/password', () => {
    it('mật khẩu hiện tại sai trả 400 PASSWORD_INCORRECT', async () => {
      const res = await http()
        .patch('/api/v1/users/password')
        .set(bearer(u.accessToken))
        .send({ currentPassword: 'Wrong12345', newPassword: 'NewPass456' })
        .expect(400);
      expect(res.body.errorCode).toBe('PASSWORD_INCORRECT');
    });

    it('đổi thành công: trả cặp token mới, phiên cũ bị thu hồi', async () => {
      const res = await http()
        .patch('/api/v1/users/password')
        .set(bearer(u.accessToken))
        .send({ currentPassword: u.password, newPassword: 'NewPass456' })
        .expect(200);
      expect(res.body.data.accessToken).toEqual(expect.any(String));
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(401);
      await http()
        .get('/api/v1/auth/me')
        .set(bearer(u.accessToken))
        .expect(401);
      await http()
        .get('/api/v1/auth/me')
        .set(bearer(res.body.data.accessToken))
        .expect(200);
      await http()
        .post('/api/v1/auth/login')
        .send({ email: u.user.email, password: 'NewPass456' })
        .expect(200);
    });

    it('tài khoản social chưa có mật khẩu đặt được mật khẩu không cần currentPassword', async () => {
      const social = await http()
        .post('/api/v1/auth/social-login')
        .send({ provider: 'google', idToken: 'mock:g-77:s@example.com:S' })
        .expect(200);
      await http()
        .patch('/api/v1/users/password')
        .set(bearer(social.body.data.accessToken))
        .send({ newPassword: 'NewPass456' })
        .expect(200);
    });
  });

  describe('POST /users/avatar', () => {
    it('upload PNG hợp lệ trả avatarUrl', async () => {
      const res = await http()
        .post('/api/v1/users/avatar')
        .set(bearer(u.accessToken))
        .attach('file', PNG_1X1, {
          filename: 'a.png',
          contentType: 'image/png',
        })
        .expect(201);
      expect(res.body.data.avatarUrl).toMatch(
        /^http:\/\/localhost:3100\/uploads\/avatars\//,
      );
      const user = await prisma.user.findUniqueOrThrow({
        where: { id: u.user.id },
      });
      expect(user.avatarUrl).toBe(res.body.data.avatarUrl);
    });

    it('file .txt trả 400 FILE_TYPE_INVALID', async () => {
      const res = await http()
        .post('/api/v1/users/avatar')
        .set(bearer(u.accessToken))
        .attach('file', Buffer.from('hello'), {
          filename: 'a.txt',
          contentType: 'text/plain',
        })
        .expect(400);
      expect(res.body.errorCode).toBe('FILE_TYPE_INVALID');
    });

    it('nội dung không phải ảnh dù khai báo image/png trả 400', async () => {
      await http()
        .post('/api/v1/users/avatar')
        .set(bearer(u.accessToken))
        .attach('file', Buffer.from('not really a png'), {
          filename: 'fake.png',
          contentType: 'image/png',
        })
        .expect(400);
    });

    it('thiếu file trả 400 FILE_REQUIRED', async () => {
      const res = await http()
        .post('/api/v1/users/avatar')
        .set(bearer(u.accessToken))
        .expect(400);
      expect(res.body.errorCode).toBe('FILE_REQUIRED');
    });

    it('file lớn hơn 2 MB trả 413', async () => {
      const big = Buffer.concat([PNG_1X1, Buffer.alloc(2 * 1024 * 1024)]);
      await http()
        .post('/api/v1/users/avatar')
        .set(bearer(u.accessToken))
        .attach('file', big, { filename: 'big.png', contentType: 'image/png' })
        .expect(413);
    });
  });

  describe('Thiết bị nhận push', () => {
    it('cùng fcmToken đăng ký bởi A rồi B thì chỉ còn 1 dòng thuộc B', async () => {
      const b = await registerUser(app);
      await http()
        .post('/api/v1/users/devices')
        .set(bearer(u.accessToken))
        .send({ fcmToken: 'tok-1', platform: 'android' })
        .expect(201);
      await http()
        .post('/api/v1/users/devices')
        .set(bearer(b.accessToken))
        .send({ fcmToken: 'tok-1', platform: 'ios' })
        .expect(201);
      const devices = await prisma.userDevice.findMany();
      expect(devices).toHaveLength(1);
      expect(devices[0]).toMatchObject({ userId: b.user.id, platform: 'ios' });
    });

    it('platform sai trả 400; xoá thiết bị của mình được', async () => {
      await http()
        .post('/api/v1/users/devices')
        .set(bearer(u.accessToken))
        .send({ fcmToken: 'tok-2', platform: 'windows' })
        .expect(400);
      await http()
        .post('/api/v1/users/devices')
        .set(bearer(u.accessToken))
        .send({ fcmToken: 'tok-2', platform: 'android' })
        .expect(201);
      await http()
        .delete('/api/v1/users/devices')
        .set(bearer(u.accessToken))
        .send({ fcmToken: 'tok-2' })
        .expect(200);
      expect(await prisma.userDevice.count()).toBe(0);
    });
  });
});
