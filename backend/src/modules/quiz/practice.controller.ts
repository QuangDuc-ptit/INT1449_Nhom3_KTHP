import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import {
  DueDto,
  DueQueryDto,
  QuestionsDto,
  QuestionsQueryDto,
  RetryMissedQueryDto,
} from './dto/practice.dto';
import { QuestionService } from './question.service';

@ApiTags('Practice')
@ApiBearerAuth()
@Controller('practice')
export class PracticeController {
  constructor(private readonly questions: QuestionService) {}

  @Get('questions')
  @ApiOperation({
    summary: 'Lấy câu hỏi luyện tập cho 4 chế độ (Màn 08, 19, 20, 25)',
  })
  getQuestions(
    @CurrentUser() user: AuthUser,
    @Query() q: QuestionsQueryDto,
  ): Promise<QuestionsDto> {
    return this.questions.getQuestions(user.id, q);
  }

  @Get('due')
  @ApiOperation({ summary: 'Hàng đợi từ cần ôn hôm nay (Màn 16)' })
  getDue(
    @CurrentUser() user: AuthUser,
    @Query() q: DueQueryDto,
  ): Promise<DueDto> {
    return this.questions.getDue(user.id, q.limit);
  }

  @Get('retry-missed')
  @ApiOperation({ summary: 'Luyện lại các câu sai trong phiên vừa xong' })
  retryMissed(
    @CurrentUser() user: AuthUser,
    @Query() q: RetryMissedQueryDto,
  ): Promise<QuestionsDto> {
    return this.questions.retryMissed(user.id, q.sessionId);
  }
}
