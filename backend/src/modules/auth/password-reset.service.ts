import { Injectable, Logger } from '@nestjs/common';
import { randomInt, timingSafeEqual } from 'node:crypto';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';
import { MailProvider } from '../mail/mail.provider';
import { hashPassword } from './password.util';
import { TokenService, sha256 } from './token.service';

export const OTP_TTL_SEC = 300;
export const OTP_MAX_ATTEMPTS = 5;

const otpKey = (email: string) => `otp:reset:${email}`;
const attemptsKey = (email: string) => `otp:reset:attempts:${email}`;

const otpInvalid = () =>
  new AppException(
    400,
    'OTP_INVALID',
    'Mã xác nhận không đúng hoặc đã hết hạn',
  );

@Injectable()
export class PasswordResetService {
  private readonly logger = new Logger(PasswordResetService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly mail: MailProvider,
    private readonly tokens: TokenService,
  ) {}

  /** Luôn kết thúc bình thường dù email có tồn tại hay không (chống dò email). */
  async requestOtp(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true, fullName: true },
    });
    if (!user) return;

    const otp = randomInt(0, 1_000_000).toString().padStart(6, '0');
    await this.redis.client
      .multi()
      .set(otpKey(email), sha256(otp), 'EX', OTP_TTL_SEC)
      .del(attemptsKey(email))
      .exec();
    try {
      await this.mail.send({
        to: email,
        subject: 'KarVocab - Mã xác nhận đặt lại mật khẩu',
        html: `<p>Xin chào ${escapeHtml(user.fullName)},</p>
<p>Mã xác nhận đặt lại mật khẩu của bạn là: <strong>${otp}</strong></p>
<p>Mã có hiệu lực trong 5 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>`,
      });
    } catch (err) {
      // Không để lỗi gửi thư lộ ra ngoài (sẽ tiết lộ email tồn tại)
      this.logger.error('Gửi email OTP thất bại', err as Error);
    }
  }

  async resetPassword(
    email: string,
    otp: string,
    newPassword: string,
  ): Promise<void> {
    const stored = await this.redis.client.get(otpKey(email));
    if (!stored) throw otpInvalid();

    if (!safeEqual(stored, sha256(otp))) {
      const attempts = await this.redis.client.incr(attemptsKey(email));
      await this.redis.client.expire(attemptsKey(email), OTP_TTL_SEC);
      if (attempts >= OTP_MAX_ATTEMPTS) {
        await this.redis.client.del(otpKey(email), attemptsKey(email));
      }
      throw otpInvalid();
    }

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw otpInvalid();
    await this.redis.client.del(otpKey(email), attemptsKey(email));
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: await hashPassword(newPassword) },
    });
    await this.tokens.revokeAllForUser(user.id);
  }
}

function safeEqual(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
