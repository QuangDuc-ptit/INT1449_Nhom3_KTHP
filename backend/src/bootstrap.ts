import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { resolve } from 'node:path';
import { AllExceptionsFilter } from './common/http/all-exceptions.filter';
import { ResponseInterceptor } from './common/http/response.interceptor';
import { Clock } from './common/time/clock';
import { createValidationPipe } from './common/validation/validation.pipe';
import { Env } from './config/env.schema';
import { UPLOADS_ROUTE } from './modules/storage/local-storage.service';

export const API_PREFIX = 'api/v1';

/** Cấu hình dùng chung cho main.ts và test e2e. */
export function configureApp(app: INestApplication): void {
  const clock = app.get(Clock);
  const config = app.get<ConfigService<Env, true>>(ConfigService);
  app.setGlobalPrefix(API_PREFIX);
  app.useGlobalPipes(createValidationPipe());
  app.useGlobalInterceptors(new ResponseInterceptor(app.get(Reflector), clock));
  app.useGlobalFilters(new AllExceptionsFilter(clock));

  // Storage cục bộ: phục vụ file tĩnh (audio, avatar) tại /uploads
  if (config.get('STORAGE_PROVIDER', { infer: true }) === 'local') {
    (app as NestExpressApplication).useStaticAssets(
      resolve(config.get('UPLOAD_DIR', { infer: true })),
      { prefix: UPLOADS_ROUTE, dotfiles: 'deny', index: false },
    );
  }

  const doc = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('KarVocab API')
      .setDescription('API backend ứng dụng học từ vựng KarVocab')
      .setVersion('1.0')
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup('api/docs', app, doc, {
    jsonDocumentUrl: 'api/docs-json',
  });
}
