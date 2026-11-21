import { Controller, Get } from '@nestjs/common';
import { Public } from '../../common/auth/public.decorator';
import { ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';

type Status = 'up' | 'down';

@ApiTags('Health')
@Public()
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Get()
  async check(): Promise<{ db: Status; redis: Status }> {
    const [db, redis] = await Promise.all([
      this.prisma.$queryRaw`SELECT 1`
        .then((): Status => 'up')
        .catch((): Status => 'down'),
      this.redis.client
        .ping()
        .then((r): Status => (r === 'PONG' ? 'up' : 'down'))
        .catch((): Status => 'down'),
    ]);
    return { db, redis };
  }
}
