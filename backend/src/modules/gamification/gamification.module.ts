import { Global, Module } from '@nestjs/common';
import { BadgeSeeder } from './badge-seeder';
import { GamificationService } from './gamification.service';

@Global()
@Module({
  providers: [GamificationService, BadgeSeeder],
  exports: [GamificationService],
})
export class GamificationModule {}
