import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { QuizMode } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import type { StreakSummary } from '../../streak/streak.service';

export class SubmitAnswerDto {
  @ApiProperty()
  @IsUUID('all', { message: 'vocabularyId không hợp lệ' })
  vocabularyId!: string;

  @ApiProperty({ example: 'coherent' })
  @IsString({ message: 'userAnswer phải là chuỗi' })
  @MaxLength(200, { message: 'Câu trả lời tối đa 200 ký tự' })
  userAnswer!: string;

  @ApiPropertyOptional({
    description: 'Kết quả FE tự chấm; server bỏ qua và tự chấm lại',
  })
  @IsOptional()
  @IsBoolean()
  isCorrect?: boolean;

  @ApiProperty({ example: 2300 })
  @Type(() => Number)
  @IsInt({ message: 'responseTimeMs phải là số nguyên' })
  @Min(0, { message: 'responseTimeMs không hợp lệ' })
  @Max(600_000, { message: 'responseTimeMs tối đa 600000' })
  responseTimeMs!: number;
}

export class SubmitSessionDto {
  @ApiPropertyOptional({
    description:
      'UUID do FE sinh cho mỗi phiên; gửi lại cùng giá trị khi retry',
  })
  @IsOptional()
  @IsUUID('all', { message: 'clientSessionId phải là UUID' })
  clientSessionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID('all', { message: 'collectionId không hợp lệ' })
  collectionId?: string;

  @ApiProperty({ enum: QuizMode })
  @IsEnum(QuizMode, {
    message:
      'mode phải là một trong: listen_choose, listen_type, choose_meaning, type_meaning',
  })
  mode!: QuizMode;

  @ApiProperty({ example: 145 })
  @Type(() => Number)
  @IsInt({ message: 'durationSeconds phải là số nguyên' })
  @Min(0, { message: 'durationSeconds từ 0 đến 86400' })
  @Max(86_400, { message: 'durationSeconds từ 0 đến 86400' })
  durationSeconds!: number;

  @ApiProperty({ type: [SubmitAnswerDto] })
  @IsArray({ message: 'answers phải là danh sách' })
  @ArrayMinSize(1, { message: 'Phiên học phải có ít nhất 1 câu trả lời' })
  @ArrayMaxSize(100, { message: 'Tối đa 100 câu trả lời mỗi phiên' })
  @ValidateNested({ each: true })
  @Type(() => SubmitAnswerDto)
  answers!: SubmitAnswerDto[];
}

export interface BadgeDto {
  code: string;
  title: string;
  description: string;
  iconUrl: string | null;
  requiredPoints: number;
}

export interface SessionResultDto {
  sessionId: string;
  totalQuestions: number;
  correctCount: number;
  incorrectCount: number;
  scorePercentage: number;
  durationSeconds: number;
  streak: StreakSummary;
  newBadges: BadgeDto[];
  answers: {
    vocabularyId: string;
    isCorrect: boolean;
    correctAnswer: string;
  }[];
}
