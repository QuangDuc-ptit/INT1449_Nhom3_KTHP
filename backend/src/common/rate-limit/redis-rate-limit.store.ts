import { Injectable } from '@nestjs/common';
import { RedisService } from '../../infra/redis/redis.service';
import { RateLimitStore } from './rate-limit.guard';

@Injectable()
export class RedisRateLimitStore extends RateLimitStore {
  constructor(private readonly redis: RedisService) {
    super();
  }

  async hit(
    key: string,
    windowSec: number,
  ): Promise<{ count: number; ttlSec: number }> {
    const results = await this.redis.client
      .multi()
      .incr(key)
      .expire(key, windowSec, 'NX')
      .ttl(key)
      .exec();
    const count = Number(results?.[0]?.[1] ?? 0);
    const ttl = Number(results?.[2]?.[1] ?? windowSec);
    return { count, ttlSec: ttl > 0 ? ttl : windowSec };
  }
}
