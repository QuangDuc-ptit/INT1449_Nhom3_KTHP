import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RATE_LIMIT_KEY, RateLimitOptions } from './rate-limit.decorator';
import { RateLimitGuard, RateLimitStore } from './rate-limit.guard';

/** Store trong bộ nhớ: đếm theo key, TTL cố định bằng cửa sổ. */
class MemoryStore implements RateLimitStore {
  counts = new Map<string, number>();
  hit(key: string, windowSec: number) {
    const count = (this.counts.get(key) ?? 0) + 1;
    this.counts.set(key, count);
    return Promise.resolve({ count, ttlSec: windowSec });
  }
}

function makeContext(req: Record<string, unknown>, headers: string[][]) {
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
    switchToHttp: () => ({
      getRequest: () => req,
      getResponse: () => ({
        setHeader: (k: string, v: string) => headers.push([k, v]),
      }),
    }),
  } as unknown as ExecutionContext;
}

function guardWith(opts: RateLimitOptions, store = new MemoryStore()) {
  const reflector = new Reflector();
  jest
    .spyOn(reflector, 'getAllAndOverride')
    .mockImplementation((key) => (key === RATE_LIMIT_KEY ? opts : undefined));
  return { guard: new RateLimitGuard(reflector, store), store };
}

describe('RateLimitGuard', () => {
  it('cho qua trong giới hạn và chặn request vượt giới hạn với 429', async () => {
    const { guard } = guardWith({
      key: 'login',
      limit: 2,
      windowSec: 60,
      by: 'ip',
    });
    const headers: string[][] = [];
    const ctx = makeContext({ ip: '1.2.3.4' }, headers);
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    await expect(guard.canActivate(ctx)).rejects.toMatchObject({
      errorCode: 'RATE_LIMITED',
      retryAfter: 60,
    });
    expect(headers).toContainEqual(['Retry-After', '60']);
  });

  it('đếm riêng theo ip + email (email không phân biệt hoa thường)', async () => {
    const { guard, store } = guardWith({
      key: 'login',
      limit: 5,
      windowSec: 60,
      by: 'ip+email',
    });
    await guard.canActivate(
      makeContext({ ip: '1.1.1.1', body: { email: 'A@x.com' } }, []),
    );
    await guard.canActivate(
      makeContext({ ip: '1.1.1.1', body: { email: 'a@x.com ' } }, []),
    );
    await guard.canActivate(
      makeContext({ ip: '1.1.1.1', body: { email: 'b@x.com' } }, []),
    );
    expect(store.counts.get('rl:login:1.1.1.1|a@x.com')).toBe(2);
    expect(store.counts.get('rl:login:1.1.1.1|b@x.com')).toBe(1);
  });

  it('đếm theo user khi by = user', async () => {
    const { guard, store } = guardWith({
      key: 'ai',
      limit: 5,
      windowSec: 60,
      by: 'user',
    });
    await guard.canActivate(makeContext({ user: { id: 'u1' } }, []));
    expect(store.counts.get('rl:ai:u1')).toBe(1);
  });
});
