import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AppException } from '../http/app.exception';
import { RATE_LIMIT_KEY, RateLimitOptions } from './rate-limit.options';

/** Bộ đếm theo cửa sổ cố định; bản chạy thật dùng Redis. */
export abstract class RateLimitStore {
  abstract hit(
    key: string,
    windowSec: number,
  ): Promise<{ count: number; ttlSec: number }>;
}

export class RateLimitException extends AppException {
  constructor(readonly retryAfter: number) {
    super(429, 'RATE_LIMITED', 'Bạn thao tác quá nhanh, vui lòng thử lại sau');
  }
}

interface RateLimitedRequest {
  ip?: string;
  body?: { email?: unknown };
  user?: { id: string };
}

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly store: RateLimitStore,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const opts = this.reflector.getAllAndOverride<RateLimitOptions | undefined>(
      RATE_LIMIT_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!opts) return true;

    const http = context.switchToHttp();
    const req = http.getRequest<RateLimitedRequest>();
    const key = `rl:${opts.key}:${identity(opts.by, req)}`;
    const { count, ttlSec } = await this.store.hit(key, opts.windowSec);
    if (count > opts.limit) {
      const retryAfter = Math.max(1, ttlSec);
      http
        .getResponse<{ setHeader(name: string, value: string): void }>()
        .setHeader('Retry-After', String(retryAfter));
      throw new RateLimitException(retryAfter);
    }
    return true;
  }
}

function identity(by: RateLimitOptions['by'], req: RateLimitedRequest): string {
  const ip = req.ip ?? 'unknown';
  const email =
    typeof req.body?.email === 'string'
      ? req.body.email.trim().toLowerCase()
      : '';
  switch (by) {
    case 'ip':
      return ip;
    case 'user':
      return req.user?.id ?? ip;
    case 'email':
      return email || ip;
    case 'ip+email':
      return `${ip}|${email}`;
  }
}
