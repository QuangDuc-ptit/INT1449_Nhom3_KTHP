import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../../infra/redis/redis.service';
import { AppException } from '../http/app.exception';
import { AccessTokenPayload, AuthUser, blacklistKey } from './auth-user';
import { IS_PUBLIC_KEY } from './public.decorator';

interface RequestWithUser {
  headers: Record<string, string | string[] | undefined>;
  user?: AuthUser;
}

export const unauthorized = (message = 'Bạn cần đăng nhập để tiếp tục') =>
  new AppException(401, 'UNAUTHORIZED', message);

/** Guard toàn cục: mọi route cần Bearer token trừ khi gắn @Public(). */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    private readonly redis: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const req = context.switchToHttp().getRequest<RequestWithUser>();
    const header = req.headers.authorization;
    const value = Array.isArray(header) ? header[0] : header;
    const [scheme, token] = value?.split(' ') ?? [];
    if (scheme !== 'Bearer' || !token) throw unauthorized();

    let payload: AccessTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<AccessTokenPayload>(token);
    } catch {
      throw unauthorized('Phiên đăng nhập không hợp lệ hoặc đã hết hạn');
    }
    if ((await this.redis.client.exists(blacklistKey(payload.jti))) === 1) {
      throw unauthorized('Phiên đăng nhập đã kết thúc, vui lòng đăng nhập lại');
    }
    req.user = {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
      jti: payload.jti,
      exp: payload.exp ?? 0,
    };
    return true;
  }
}
