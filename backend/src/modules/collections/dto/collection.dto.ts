import { ApiPropertyOptional, ApiProperty, PartialType } from '@nestjs/swagger';
import { Category } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

const CATEGORY_MESSAGE =
  'category phải là một trong: academic, career, life, travel, other';

export class CreateCollectionDto {
  @ApiProperty({ example: 'IELTS Academic Core' })
  @Transform(trim)
  @IsString({ message: 'Tên học phần phải là chuỗi' })
  @Length(1, 100, { message: 'Tên học phần phải từ 1 đến 100 ký tự' })
  title!: string;

  @ApiPropertyOptional({ example: 'Bộ từ vựng band 7+' })
  @IsOptional()
  @Transform(trim)
  @IsString({ message: 'Mô tả phải là chuỗi' })
  @MaxLength(500, { message: 'Mô tả tối đa 500 ký tự' })
  description?: string;

  @ApiPropertyOptional({ enum: Category, default: Category.other })
  @IsOptional()
  @IsEnum(Category, { message: CATEGORY_MESSAGE })
  category?: Category;

  @ApiPropertyOptional({ example: 'book' })
  @IsOptional()
  @IsString({ message: 'iconName phải là chuỗi' })
  @Length(1, 50, { message: 'iconName phải từ 1 đến 50 ký tự' })
  iconName?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean({ message: 'isPublic phải là true hoặc false' })
  isPublic?: boolean;
}

export class UpdateCollectionDto extends PartialType(CreateCollectionDto) {}

export class ListCollectionsQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: Category })
  @IsOptional()
  @IsEnum(Category, { message: CATEGORY_MESSAGE })
  category?: Category;

  @ApiPropertyOptional({ example: 'ielts' })
  @IsOptional()
  @Transform(trim)
  @Type(() => String)
  @IsString()
  @MaxLength(100, { message: 'Từ khoá tìm kiếm tối đa 100 ký tự' })
  search?: string;
}

export interface CollectionDto {
  id: string;
  title: string;
  description: string | null;
  category: Category;
  iconName: string;
  isPublic: boolean;
  totalWords: number;
  createdAt: Date;
  updatedAt: Date;
}
