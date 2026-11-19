import { z } from 'zod';

const bool = z
  .enum(['true', 'false'])
  .default('false')
  .transform((v) => v === 'true');

export const envSchema = z
  .object({
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development'),
    PORT: z.coerce.number().int().positive().default(3100),
    DATABASE_URL: z.string().min(1),
    REDIS_HOST: z.string().min(1),
    REDIS_PORT: z.coerce.number().int().positive(),
    REDIS_DB: z.coerce.number().int().min(0).default(0),
    JWT_ACCESS_SECRET: z.string().min(1),
    JWT_ACCESS_TTL: z
      .string()
      .regex(/^\d+[smhd]$/, 'Định dạng như 15m, 1h, 900s')
      .default('15m'),
    REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(7),
    CORS_ORIGINS: z.string().default(''),
    AI_PROVIDER: z.enum(['mock', 'gemini']).default('mock'),
    GEMINI_API_KEY: z.string().default(''),
    GEMINI_MODEL: z.string().default('gemini-2.0-flash'),
    TTS_PROVIDER: z.enum(['mock', 'google']).default('mock'),
    STORAGE_PROVIDER: z.enum(['local', 's3']).default('local'),
    PUBLIC_BASE_URL: z.string().default('http://localhost:3100'),
    UPLOAD_DIR: z.string().default('uploads'),
    S3_ENDPOINT: z.string().default(''),
    S3_REGION: z.string().default('auto'),
    S3_BUCKET: z.string().default(''),
    S3_ACCESS_KEY_ID: z.string().default(''),
    S3_SECRET_ACCESS_KEY: z.string().default(''),
    S3_PUBLIC_URL: z.string().default(''),
    PUSH_PROVIDER: z.enum(['mock', 'fcm']).default('mock'),
    FIREBASE_SERVICE_ACCOUNT_PATH: z.string().default(''),
    MAIL_PROVIDER: z.enum(['console', 'resend']).default('console'),
    RESEND_API_KEY: z.string().default(''),
    MAIL_FROM: z.string().default('KarVocab <no-reply@karvocab.app>'),
    SOCIAL_AUTH_MODE: z.enum(['mock', 'real']).default('mock'),
    GOOGLE_CLIENT_ID: z.string().default(''),
    FACEBOOK_APP_ID: z.string().default(''),
    FACEBOOK_APP_SECRET: z.string().default(''),
    JOBS_ENABLED: bool,
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV !== 'test' && env.JWT_ACCESS_SECRET.length < 16) {
      ctx.addIssue({
        code: 'custom',
        path: ['JWT_ACCESS_SECRET'],
        message: 'JWT_ACCESS_SECRET phải dài ít nhất 16 ký tự',
      });
    }
    if (env.AI_PROVIDER === 'gemini' && !env.GEMINI_API_KEY) {
      ctx.addIssue({
        code: 'custom',
        path: ['GEMINI_API_KEY'],
        message: 'Cần GEMINI_API_KEY khi AI_PROVIDER=gemini',
      });
    }
  });

export type Env = z.infer<typeof envSchema>;

const UNIT_SECONDS = { s: 1, m: 60, h: 3600, d: 86400 } as const;

/** Đổi chuỗi thời lượng ("15m", "1h", "900s", "7d") sang số giây. */
export function durationToSeconds(value: string): number {
  const match = /^(\d+)([smhd])$/.exec(value);
  if (!match) throw new Error(`Thời lượng không hợp lệ: ${value}`);
  return Number(match[1]) * UNIT_SECONDS[match[2] as keyof typeof UNIT_SECONDS];
}

export function validateEnv(raw: Record<string, unknown>): Env {
  const result = envSchema.safeParse(raw);
  if (!result.success) {
    const details = result.error.issues
      .map((i) => `${i.path.join('.')}: ${i.message}`)
      .join('; ');
    throw new Error(`Biến môi trường không hợp lệ: ${details}`);
  }
  return result.data;
}
