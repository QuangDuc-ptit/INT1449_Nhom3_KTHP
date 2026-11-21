import { PrismaService } from '../../infra/prisma/prisma.service';
import { PushMessage, PushProvider } from './push.provider';
import { PushService } from './push.service';

class FakeProvider extends PushProvider {
  calls: { tokens: string[]; msg: PushMessage }[] = [];
  constructor(private readonly invalid: string[] = []) {
    super();
  }
  sendMulticast(tokens: string[], msg: PushMessage) {
    this.calls.push({ tokens, msg });
    const invalidTokens = tokens.filter((t) => this.invalid.includes(t));
    return Promise.resolve({
      invalidTokens,
      successCount: tokens.length - invalidTokens.length,
    });
  }
}

function prismaWith(tokens: string[]) {
  return {
    userDevice: {
      findMany: jest
        .fn()
        .mockResolvedValue(tokens.map((fcmToken) => ({ fcmToken }))),
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
  };
}

describe('PushService', () => {
  it('gửi tới mọi thiết bị của user và tự dọn token không còn hợp lệ', async () => {
    const prisma = prismaWith(['tok-a', 'tok-b']);
    const provider = new FakeProvider(['tok-b']);
    const service = new PushService(
      prisma as unknown as PrismaService,
      provider,
    );

    const result = await service.sendPushNotification(
      'u1',
      'Đến giờ ôn tập',
      'Bạn có 3 từ cần ôn',
      { screen: 'review' },
    );

    expect(result).toEqual({ sent: 1, removed: 1 });
    expect(prisma.userDevice.findMany).toHaveBeenCalledWith({
      where: { userId: 'u1' },
      select: { fcmToken: true },
    });
    expect(provider.calls[0]).toEqual({
      tokens: ['tok-a', 'tok-b'],
      msg: {
        title: 'Đến giờ ôn tập',
        body: 'Bạn có 3 từ cần ôn',
        data: { screen: 'review' },
      },
    });
    expect(prisma.userDevice.deleteMany).toHaveBeenCalledWith({
      where: { fcmToken: { in: ['tok-b'] } },
    });
  });

  it('user không có thiết bị thì không gọi provider', async () => {
    const prisma = prismaWith([]);
    const provider = new FakeProvider();
    const service = new PushService(
      prisma as unknown as PrismaService,
      provider,
    );
    await expect(service.sendPushNotification('u1', 't', 'b')).resolves.toEqual(
      {
        sent: 0,
        removed: 0,
      },
    );
    expect(provider.calls).toHaveLength(0);
    expect(prisma.userDevice.deleteMany).not.toHaveBeenCalled();
  });
});
