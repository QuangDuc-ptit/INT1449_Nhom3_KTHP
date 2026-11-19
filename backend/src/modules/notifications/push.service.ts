import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { PushProvider } from './push.provider';

@Injectable()
export class PushService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly provider: PushProvider,
  ) {}

  /** Gửi thông báo tới mọi thiết bị của user; xoá token đã chết. */
  async sendPushNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<{ sent: number; removed: number }> {
    const devices = await this.prisma.userDevice.findMany({
      where: { userId },
      select: { fcmToken: true },
    });
    if (!devices.length) return { sent: 0, removed: 0 };

    const res = await this.provider.sendMulticast(
      devices.map((d) => d.fcmToken),
      { title, body, ...(data ? { data } : {}) },
    );
    if (res.invalidTokens.length) {
      await this.prisma.userDevice.deleteMany({
        where: { fcmToken: { in: res.invalidTokens } },
      });
    }
    return { sent: res.successCount, removed: res.invalidTokens.length };
  }
}
