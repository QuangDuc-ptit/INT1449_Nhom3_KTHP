import { Module } from '@nestjs/common';
import { ReviewReminderJob } from './review-reminder.job';
import { StreakResetJob } from './streak-reset.job';

/**
 * Các job định kỳ. Lịch @Cron chỉ chạy khi ScheduleModule được nạp
 * (JOBS_ENABLED=true, xem AppModule); test gọi trực tiếp run().
 */
@Module({
  providers: [StreakResetJob, ReviewReminderJob],
  exports: [StreakResetJob, ReviewReminderJob],
})
export class JobsModule {}
