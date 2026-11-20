import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { BADGES } from './badge-catalog';

/**
 * Đảm bảo bảng badges luôn đủ danh mục mỗi lần app khởi động (upsert, chạy lại
 * an toàn). Nhờ vậy môi trường production không cần chạy `prisma db seed`.
 */
@Injectable()
export class BadgeSeeder implements OnApplicationBootstrap {
  private readonly logger = new Logger(BadgeSeeder.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    for (const b of BADGES) {
      await this.prisma.badge.upsert({
        where: { code: b.code },
        update: {
          title: b.title,
          description: b.description,
          requiredPoints: b.requiredPoints,
        },
        create: { ...b },
      });
    }
    this.logger.log(`Đã đồng bộ ${BADGES.length} huy hiệu`);
  }
}
