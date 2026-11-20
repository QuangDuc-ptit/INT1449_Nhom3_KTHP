import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  CefrLevel,
  PartOfSpeech,
  ProgressStatus,
  VocabSource,
} from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  MaxLength,
  ValidateNested,
} from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class CreateVocabularyDto {
  @ApiProperty({ example: 'coherent' })
  @Transform(trim)
  @IsString({ message: 'Từ vựng phải là chuỗi' })
  @Length(1, 100, { message: 'Từ vựng phải từ 1 đến 100 ký tự' })
  term!: string;

  @ApiProperty({ enum: PartOfSpeech, example: 'adj' })
  @IsEnum(PartOfSpeech, {
    message: 'partOfSpeech phải là một trong: noun, verb, adj, adv, idiom',
  })
  partOfSpeech!: PartOfSpeech;

  @ApiPropertyOptional({ example: '/kəʊˈhɪərənt/' })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100, { message: 'Phiên âm tối đa 100 ký tự' })
  ipaUk?: string;

  @ApiPropertyOptional({ example: '/koʊˈhɪrənt/' })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100, { message: 'Phiên âm tối đa 100 ký tự' })
  ipaUs?: string;

  @ApiPropertyOptional({ example: 'logical and consistent' })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(1000, { message: 'Định nghĩa tiếng Anh tối đa 1000 ký tự' })
  definitionEn?: string;

  @ApiProperty({ example: 'mạch lạc, chặt chẽ' })
  @Transform(trim)
  @IsString({ message: 'Nghĩa tiếng Việt phải là chuỗi' })
  @Length(1, 500, { message: 'Nghĩa tiếng Việt phải từ 1 đến 500 ký tự' })
  definitionVi!: string;

  @ApiPropertyOptional({ example: 'He proposed a coherent plan for reform.' })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(1000, { message: 'Câu ví dụ tối đa 1000 ký tự' })
  exampleSentence?: string;

  @ApiProperty({ enum: CefrLevel, example: 'B2' })
  @IsEnum(CefrLevel, { message: 'cefrLevel phải từ A1 đến C2' })
  cefrLevel!: CefrLevel;
}

export class UpdateVocabularyDto extends PartialType(CreateVocabularyDto) {}

/** Một từ do AI sinh (Màn 14); `ipa` của AI được lưu vào ipaUk. */
export class BatchWordDto extends CreateVocabularyDto {
  @ApiPropertyOptional({ example: '/ˈsəʊlə/' })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100, { message: 'Phiên âm tối đa 100 ký tự' })
  ipa?: string;
}

export class BatchSaveDto {
  @ApiProperty()
  @IsUUID('all', { message: 'collectionId không hợp lệ' })
  collectionId!: string;

  @ApiProperty({ type: [BatchWordDto] })
  @IsArray({ message: 'words phải là danh sách' })
  @ArrayMinSize(1, { message: 'Cần chọn ít nhất 1 từ' })
  @ArrayMaxSize(50, { message: 'Tối đa 50 từ mỗi lần lưu' })
  @ValidateNested({ each: true })
  @Type(() => BatchWordDto)
  words!: BatchWordDto[];
}

export interface BatchSaveResultDto {
  savedCount: number;
  skippedTerms: string[];
  vocabularies: VocabularyDto[];
}

export type CreateVocabularyInput = Pick<
  CreateVocabularyDto,
  | 'term'
  | 'partOfSpeech'
  | 'ipaUk'
  | 'ipaUs'
  | 'definitionEn'
  | 'definitionVi'
  | 'exampleSentence'
  | 'cefrLevel'
>;

export interface VocabularyProgressDto {
  status: ProgressStatus;
  repetitionLevel: number;
  nextReviewAt: Date | null;
}

export interface VocabularyDto {
  id: string;
  collectionId: string;
  term: string;
  partOfSpeech: PartOfSpeech;
  ipaUk: string | null;
  ipaUs: string | null;
  audioUkUrl: string | null;
  audioUsUrl: string | null;
  definitionEn: string | null;
  definitionVi: string;
  exampleSentence: string | null;
  cefrLevel: CefrLevel;
  source: VocabSource;
  progress: VocabularyProgressDto | null;
}
