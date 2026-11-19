import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
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
import { SessionResultDto, SubmitSessionDto } from './dto/submit.dto';
import { QuestionService } from './question.service';
import { SubmitService } from './submit.service';
import { ResponseMessage } from '../../common/http/response-message.decorator';

@ApiTags('Practice')
@ApiBearerAuth()
@Controller('practice')
export class PracticeController {
  constructor(
    private readonly questions: QuestionService,
    private readonly submitService: SubmitService,
  ) {}

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

  @Post('submit-session')
  @HttpCode(200)
  @ApiOperation({
    summary:
      'Nộp kết quả phiên luyện tập: chấm điểm, cập nhật SM-2, streak (Màn 12)',
  })
  @ResponseMessage('Đã ghi nhận kết quả phiên học')
  submit(
    @CurrentUser() user: AuthUser,
    @Body() dto: SubmitSessionDto,
  ): Promise<SessionResultDto> {
    return this.submitService.submit(user.id, dto);
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
