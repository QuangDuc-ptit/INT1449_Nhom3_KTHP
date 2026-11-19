import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { CommonModule } from './common/common.module';
import { validateEnv } from './config/env.schema';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { AudioModule } from './modules/audio/audio.module';
import { AuthModule } from './modules/auth/auth.module';
import { CollectionsModule } from './modules/collections/collections.module';
import { HealthModule } from './modules/health/health.module';
import { MailModule } from './modules/mail/mail.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { StorageModule } from './modules/storage/storage.module';
import { UsersModule } from './modules/users/users.module';
import { VocabulariesModule } from './modules/vocabularies/vocabularies.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    EventEmitterModule.forRoot(),
    CommonModule,
    PrismaModule,
    RedisModule,
    HealthModule,
    MailModule,
    AuthModule,
    StorageModule,
    CollectionsModule,
    VocabulariesModule,
    AudioModule,
    UsersModule,
    NotificationsModule,
  ],
})
export class AppModule {}
