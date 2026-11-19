import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { Env } from '../../config/env.schema';

@Injectable()
export class RedisService implements OnModuleDestroy {
  readonly client: Redis;

  constructor(config: ConfigService<Env, true>) {
    this.client = new Redis({
      host: config.get('REDIS_HOST', { infer: true }),
      port: config.get('REDIS_PORT', { infer: true }),
      db: config.get('REDIS_DB', { infer: true }),
      maxRetriesPerRequest: 3,
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.quit();
  }
}
