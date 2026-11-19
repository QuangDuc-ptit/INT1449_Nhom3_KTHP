import { durationToSeconds, validateEnv } from './env.schema';

const base = {
  DATABASE_URL: 'postgresql://x',
  REDIS_HOST: 'localhost',
  REDIS_PORT: '6380',
  JWT_ACCESS_SECRET: 'a-very-long-secret-value',
};

describe('env.schema', () => {
  it('đổi thời lượng sang giây', () => {
    expect(durationToSeconds('15m')).toBe(900);
    expect(durationToSeconds('1h')).toBe(3600);
    expect(durationToSeconds('900s')).toBe(900);
    expect(durationToSeconds('7d')).toBe(604800);
  });

  it('báo lỗi khi thiếu biến bắt buộc', () => {
    expect(() => validateEnv({})).toThrow(/DATABASE_URL/);
  });

  it('JWT secret ngắn hơn 16 ký tự bị từ chối ngoài môi trường test', () => {
    expect(() =>
      validateEnv({ ...base, NODE_ENV: 'production', JWT_ACCESS_SECRET: 'x' }),
    ).toThrow(/JWT_ACCESS_SECRET/);
    expect(() =>
      validateEnv({ ...base, NODE_ENV: 'test', JWT_ACCESS_SECRET: 'x' }),
    ).not.toThrow();
  });

  it('áp giá trị mặc định', () => {
    const env = validateEnv(base);
    expect(env.PORT).toBe(3100);
    expect(env.AI_PROVIDER).toBe('mock');
    expect(env.JOBS_ENABLED).toBe(false);
  });
});
