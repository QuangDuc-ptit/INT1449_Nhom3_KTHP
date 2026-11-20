import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { AiService } from './ai.service';
import { GenerateVocabDto, GeneratedWordDto } from './dto/generate-vocab.dto';

@ApiTags('AI')
@ApiBearerAuth()
@Controller('ai')
export class AiController {
  constructor(private readonly ai: AiService) {}

  @Post('generate-vocab')
  @HttpCode(200)
  @RateLimit({ key: 'ai', limit: 5, windowSec: 60, by: 'user' })
  @ApiOperation({
    summary: 'Sinh danh sách từ vựng theo chủ đề bằng AI để xem trước (Màn 13)',
  })
  generate(
    @CurrentUser() user: AuthUser,
    @Body() dto: GenerateVocabDto,
  ): Promise<{ words: GeneratedWordDto[] }> {
    return this.ai.generate(user.id, dto);
  }
}
