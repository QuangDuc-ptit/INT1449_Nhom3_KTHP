import { Role } from '@prisma/client';

/** Thông tin người dùng giải mã từ access token, gắn vào request. */
export interface AuthUser {
  id: string;
  email: string;
  role: Role;
  jti: string;
  /** Thời điểm hết hạn của access token (giây, epoch). */
  exp: number;
}

export interface AccessTokenPayload {
  sub: string;
  email: string;
  role: Role;
  jti: string;
  exp?: number;
}
