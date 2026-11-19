import { INestApplication } from '@nestjs/common';

export const API_PREFIX = 'api/v1';

/** Cấu hình dùng chung cho main.ts và test e2e. */
export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix(API_PREFIX);
}
