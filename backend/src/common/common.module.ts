import { Global, Module } from '@nestjs/common';
import { RateLimitGuard, RateLimitStore } from './rate-limit/rate-limit.guard';
import { RedisRateLimitStore } from './rate-limit/redis-rate-limit.store';
import { Clock, SystemClock } from './time/clock';

@Global()
@Module({
  providers: [
    { provide: Clock, useClass: SystemClock },
    { provide: RateLimitStore, useClass: RedisRateLimitStore },
    RateLimitGuard,
  ],
  exports: [Clock, RateLimitStore, RateLimitGuard],
})
export class CommonModule {}
