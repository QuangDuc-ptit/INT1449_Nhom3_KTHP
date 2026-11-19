import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { AccessTokenPayload } from '../../common/auth/auth-user';
import { Clock } from '../../common/time/clock';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../infra/prisma/prisma.service';

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
}
