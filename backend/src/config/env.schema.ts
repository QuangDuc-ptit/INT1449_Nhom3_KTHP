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
    JWT_ACCESS_TTL: z.string().default('15m'),
    REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(7),
    CORS_ORIGINS: z.string().default(''),
    AI_PROVIDER: z.enum(['mock', 'gemini']).default('mock'),
    GEMINI_API_KEY: z.string().default(''),
    GEMINI_MODEL: z.string().default('gemini-2.0-flash'),
    TTS_PROVIDER: z.enum(['mock', 'google']).default('mock'),
    STORAGE_PROVIDER: z.enum(['local', 's3']).default('local'),
    PUBLIC_BASE_URL: z.string().default('http://localhost:3100'),
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
