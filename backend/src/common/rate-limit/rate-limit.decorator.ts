import { SetMetadata, UseGuards, applyDecorators } from '@nestjs/common';
import { RateLimitGuard } from './rate-limit.guard';
import { RATE_LIMIT_KEY, RateLimitOptions } from './rate-limit.options';

export { RATE_LIMIT_KEY } from './rate-limit.options';
export type { RateLimitOptions } from './rate-limit.options';

/** Giới hạn số request trong một cửa sổ thời gian, đếm bằng Redis. */
export const RateLimit = (options: RateLimitOptions) =>
  applyDecorators(
    SetMetadata(RATE_LIMIT_KEY, options),
    UseGuards(RateLimitGuard),
  );
