import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { DashboardDto, DashboardService } from './dashboard.service';

@ApiTags('Home')
@ApiBearerAuth()
@Controller('home')
export class DashboardController {
  constructor(private readonly dashboard: DashboardService) {}

  @Get('dashboard')
  @ApiOperation({
    summary: 'Tổng quan trang chủ: streak, mục tiêu ngày, từ cần ôn (Màn 04)',
  })
  get(@CurrentUser() user: AuthUser): Promise<DashboardDto> {
    return this.dashboard.getDashboard(user.id);
  }
}
