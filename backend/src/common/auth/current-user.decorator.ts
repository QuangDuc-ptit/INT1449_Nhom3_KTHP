import { ExecutionContext, createParamDecorator } from '@nestjs/common';
import { AuthUser } from './auth-user';

/** Lấy người dùng đã xác thực từ request (do JwtAuthGuard gắn vào). */
export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthUser =>
    ctx.switchToHttp().getRequest<{ user: AuthUser }>().user,
);
