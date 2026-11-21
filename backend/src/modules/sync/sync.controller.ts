import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiPropertyOptional,
  ApiTags,
} from '@nestjs/swagger';
import { IsISO8601, IsOptional } from 'class-validator';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { SyncDeltaDto, SyncService } from './sync.service';

export class SyncDeltaQueryDto {
  @ApiPropertyOptional({
    example: '2026-11-19T10:00:00.000Z',
    description: 'serverTime của lần đồng bộ trước; bỏ trống để lấy toàn bộ',
  })
  @IsOptional()
  @IsISO8601(
    { strict: true },
    { message: 'since phải là thời điểm ISO 8601, ví dụ 2026-11-19T10:00:00Z' },
  )
  since?: string;
}

@ApiTags('Sync')
@ApiBearerAuth()
@Controller('sync')
export class SyncController {
  constructor(private readonly sync: SyncService) {}

  @Get('delta')
  @ApiOperation({
    summary: 'Đồng bộ offline: dữ liệu thay đổi kể từ lần đồng bộ trước',
  })
  delta(
    @CurrentUser() user: AuthUser,
    @Query() q: SyncDeltaQueryDto,
  ): Promise<SyncDeltaDto> {
    return this.sync.delta(user.id, q.since ? new Date(q.since) : undefined);
  }
}
