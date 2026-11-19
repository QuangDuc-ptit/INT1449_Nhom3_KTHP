import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { QuizMode } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';
import { VocabularyDto } from '../../vocabularies/dto/vocabulary.dto';

const MODE_MESSAGE =
  'mode phải là một trong: listen_choose, listen_type, choose_meaning, type_meaning';

export class QuestionsQueryDto {
  @ApiPropertyOptional({
    description: 'Bỏ trống để ôn các từ đến hạn trên mọi học phần (Màn 16)',
  })
  @IsOptional()
  @IsUUID('all', { message: 'collectionId không hợp lệ' })
  collectionId?: string;

  @ApiProperty({ enum: QuizMode })
  @IsEnum(QuizMode, { message: MODE_MESSAGE })
  mode!: QuizMode;

  @ApiPropertyOptional({ default: 10, minimum: 1, maximum: 50 })
  @Type(() => Number)
  @IsInt({ message: 'limit phải là số nguyên' })
  @Min(1, { message: 'limit phải từ 1 đến 50' })
  @Max(50, { message: 'limit phải từ 1 đến 50' })
  limit: number = 10;
}

export class DueQueryDto {
  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 200 })
  @Type(() => Number)
  @IsInt({ message: 'limit phải là số nguyên' })
  @Min(1, { message: 'limit phải từ 1 đến 200' })
  @Max(200, { message: 'limit phải từ 1 đến 200' })
  limit: number = 50;
}

export class RetryMissedQueryDto {
  @ApiProperty()
  @IsUUID('all', { message: 'sessionId không hợp lệ' })
  sessionId!: string;
}

export interface QuestionDto {
  vocabularyId: string;
  /** Nội dung đề theo chế độ; trường không dùng thì không có. */
  prompt: {
    term?: string;
    ipa?: string;
    audioUrl?: string;
    definitionVi?: string;
  };
  /** Chỉ có ở chế độ chọn (listen_choose, choose_meaning). */
  options?: { vocabularyId: string; text: string }[];
  /** Đáp án đúng để FE phản hồi ngay (Màn 11); server vẫn tự chấm khi nộp bài. */
  answer: string;
}

export interface QuestionsDto {
  mode: QuizMode;
  questions: QuestionDto[];
}

export interface DueDto {
  dueCount: number;
  words: VocabularyDto[];
}
