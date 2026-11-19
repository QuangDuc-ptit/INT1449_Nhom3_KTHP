import { INestApplication } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AllExceptionsFilter } from './common/http/all-exceptions.filter';
import { ResponseInterceptor } from './common/http/response.interceptor';
import { Clock } from './common/time/clock';
import { createValidationPipe } from './common/validation/validation.pipe';

export const API_PREFIX = 'api/v1';

/** Cấu hình dùng chung cho main.ts và test e2e. */
export function configureApp(app: INestApplication): void {
  const clock = app.get(Clock);
  app.setGlobalPrefix(API_PREFIX);
  app.useGlobalPipes(createValidationPipe());
  app.useGlobalInterceptors(new ResponseInterceptor(app.get(Reflector), clock));
  app.useGlobalFilters(new AllExceptionsFilter(clock));

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
