export const RATE_LIMIT_KEY = 'rate_limit';

export interface RateLimitOptions {
  /** Tên nhóm giới hạn, ví dụ "login", "ai". */
  key: string;
  limit: number;
  windowSec: number;
  /** Đếm theo IP, user đăng nhập, email trong body, hoặc IP + email. */
  by: 'ip' | 'user' | 'email' | 'ip+email';
}
