import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Role, User } from '@prisma/client';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { AccessTokenPayload, blacklistKey } from '../../common/auth/auth-user';
import { AppException } from '../../common/http/app.exception';
import { Clock } from '../../common/time/clock';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface TokenSubject {
  id: string;
  email: string;
  role: Role;
}

export const sha256 = (value: string) =>
  createHash('sha256').update(value).digest('hex');

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly config: ConfigService<Env, true>,
    private readonly redis: RedisService,
  ) {}

  /** Phát access token (JWT) và refresh token (chuỗi ngẫu nhiên, DB chỉ lưu SHA-256). */
  async issuePair(user: TokenSubject): Promise<TokenPair> {
    const payload: AccessTokenPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      jti: randomUUID(),
    };
    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = randomBytes(64).toString('hex');
    const ttlDays = this.config.get('REFRESH_TOKEN_TTL_DAYS', { infer: true });
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: sha256(refreshToken),
        expiresAt: new Date(this.clock.now().getTime() + ttlDays * DAY_MS),
      },
    });
    return { accessToken, refreshToken };
  }

  /**
   * Đổi refresh token lấy cặp token mới (rotation).
   * Token đã bị thu hồi mà vẫn được dùng lại => coi như bị đánh cắp, thu hồi toàn bộ.
   */
  async rotate(refreshToken: string): Promise<{ pair: TokenPair; user: User }> {
    const record = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: sha256(refreshToken) },
      include: { user: true },
    });
    if (!record) throw refreshInvalid();
    if (record.isRevoked) {
      await this.revokeAllForUser(record.userId);
      throw refreshReused();
    }
    if (record.expiresAt.getTime() <= this.clock.now().getTime()) {
      throw refreshInvalid();
    }
    // Chỉ một request thắng khi hai request cùng dùng một token song song
    const { count } = await this.prisma.refreshToken.updateMany({
      where: { id: record.id, isRevoked: false },
      data: { isRevoked: true },
    });
    if (count === 0) {
      await this.revokeAllForUser(record.userId);
      throw refreshReused();
    }
    return { pair: await this.issuePair(record.user), user: record.user };
  }

  async revokeAllForUser(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, isRevoked: false },
      data: { isRevoked: true },
    });
  }

  /** Thu hồi một refresh token, chỉ khi nó thuộc về đúng user. */
  async revokeRefreshToken(
    userId: string,
    refreshToken: string,
  ): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, tokenHash: sha256(refreshToken), isRevoked: false },
      data: { isRevoked: true },
    });
  }

  /** Đưa access token vào blacklist Redis tới khi nó tự hết hạn. */
  async blacklistAccess(jti: string, exp: number): Promise<void> {
    const ttl = exp - Math.floor(this.clock.now().getTime() / 1000);
    if (ttl > 0) {
      await this.redis.client.set(blacklistKey(jti), '1', 'EX', ttl);
    }
  }

  async isBlacklisted(jti: string): Promise<boolean> {
    return (await this.redis.client.exists(blacklistKey(jti))) === 1;
  }
}

const refreshInvalid = () =>
  new AppException(
    401,
    'REFRESH_TOKEN_INVALID',
    'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
  );

const refreshReused = () =>
  new AppException(
    401,
    'REFRESH_TOKEN_REUSED',
    'Phiên đăng nhập không còn hợp lệ, vui lòng đăng nhập lại',
  );
