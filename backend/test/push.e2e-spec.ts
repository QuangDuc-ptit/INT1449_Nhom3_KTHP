import { INestApplication } from '@nestjs/common';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { MockPushProvider } from '../src/modules/notifications/mock-push.provider';
import { PushProvider } from '../src/modules/notifications/push.provider';
import { PushService } from '../src/modules/notifications/push.service';
import { createTestApp } from './utils/app';
import { registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Push notification (e2e, provider mock)', () => {
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

  it('gửi tới thiết bị của user và xoá token chết khỏi DB', async () => {
    const u = await registerUser(app);
    await prisma.userDevice.createMany({
      data: [
        { userId: u.user.id, fcmToken: 'good-1', platform: 'android' },
        { userId: u.user.id, fcmToken: 'invalid-1', platform: 'ios' },
      ],
    });
    const provider = app.get<MockPushProvider>(PushProvider);
    const before = provider.sent.length;

    const res = await app
      .get(PushService)
      .sendPushNotification(u.user.id, 'KarVocab', 'Đến giờ ôn tập rồi!');

    expect(res).toEqual({ sent: 1, removed: 1 });
    expect(provider.sent.length).toBe(before + 1);
    expect(provider.sent.at(-1)?.message.body).toBe('Đến giờ ôn tập rồi!');
    const left = await prisma.userDevice.findMany();
    expect(left.map((d) => d.fcmToken)).toEqual(['good-1']);
  });
});
