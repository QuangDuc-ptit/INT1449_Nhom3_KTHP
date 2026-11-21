import { Module } from '@nestjs/common';
import { ConditionalModule, ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { CommonModule } from './common/common.module';
import { validateEnv } from './config/env.schema';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { AiModule } from './modules/ai/ai.module';
import { AudioModule } from './modules/audio/audio.module';
import { AuthModule } from './modules/auth/auth.module';
import { CollectionsModule } from './modules/collections/collections.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { GamificationModule } from './modules/gamification/gamification.module';
import { JobsModule } from './jobs/jobs.module';
import { HealthModule } from './modules/health/health.module';
import { MailModule } from './modules/mail/mail.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { QuizModule } from './modules/quiz/quiz.module';
import { StorageModule } from './modules/storage/storage.module';
import { StreakModule } from './modules/streak/streak.module';
import { SyncModule } from './modules/sync/sync.module';
import { UsersModule } from './modules/users/users.module';
import { VocabulariesModule } from './modules/vocabularies/vocabularies.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    EventEmitterModule.forRoot(),
    // Chỉ bật lịch cron khi JOBS_ENABLED=true (test và môi trường phụ để false)
    ConditionalModule.registerWhen(
      ScheduleModule.forRoot(),
      (env) => env.JOBS_ENABLED === 'true',
    ),
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
    SyncModule,
    AiModule,
    StreakModule,
    GamificationModule,
    QuizModule,
    DashboardModule,
    JobsModule,
  ],
})
export class AppModule {}
