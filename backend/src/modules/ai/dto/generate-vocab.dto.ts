import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CefrLevel, PartOfSpeech } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Max,
  Min,
} from 'class-validator';

/** Cấp độ được phép khi sinh bằng AI (BE2-S1-03: A1 đến C1). */
export const AI_CEFR_LEVELS: CefrLevel[] = ['A1', 'A2', 'B1', 'B2', 'C1'];

export class GenerateVocabDto {
  @ApiProperty({ example: 'Sustainable Energy & Green Tech' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'Chủ đề phải là chuỗi' })
  @Length(3, 100, { message: 'Chủ đề phải từ 3 đến 100 ký tự' })
  topic!: string;

  @ApiProperty({ enum: AI_CEFR_LEVELS, example: 'B2' })
  @IsIn(AI_CEFR_LEVELS, { message: 'cefrLevel phải từ A1 đến C1' })
  cefrLevel!: CefrLevel;

  @ApiProperty({ minimum: 3, maximum: 20, example: 5 })
  @Type(() => Number)
  @IsInt({ message: 'Số lượng từ phải là số nguyên' })
  @Min(3, { message: 'Số lượng từ từ 3 đến 20' })
  @Max(20, { message: 'Số lượng từ từ 3 đến 20' })
  wordCount!: number;

  @ApiPropertyOptional({
    description: 'Học phần đích, dùng để đánh dấu từ đã có',
  })
  @IsOptional()
  @IsUUID('all', { message: 'collectionId không hợp lệ' })
  collectionId?: string;
}

export interface GeneratedWordDto {
  term: string;
  partOfSpeech: PartOfSpeech;
  ipa?: string;
  definitionEn: string;
  definitionVi: string;
  exampleSentence: string;
  cefrLevel: CefrLevel;
  /** Từ đã có trong học phần đích (FE bỏ chọn sẵn ở Màn 14). */
  existsInCollection: boolean;
}
