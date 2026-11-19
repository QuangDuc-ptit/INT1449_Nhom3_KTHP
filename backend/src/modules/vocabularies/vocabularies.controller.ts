import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { ResponseMessage } from '../../common/http/response-message.decorator';
import { UuidParam } from '../collections/collections.controller';
import {
  CreateVocabularyDto,
  UpdateVocabularyDto,
  VocabularyDto,
} from './dto/vocabulary.dto';
import { VocabulariesService } from './vocabularies.service';

@ApiTags('Vocabularies')
@ApiBearerAuth()
@Controller()
export class VocabulariesController {
  constructor(private readonly vocabularies: VocabulariesService) {}

  @Get('collections/:id/words')
  @ApiOperation({ summary: 'Danh sách từ trong học phần (Màn 06)' })
  list(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) collectionId: string,
  ): Promise<VocabularyDto[]> {
    return this.vocabularies.listWords(user.id, collectionId);
  }

  @Post('collections/:id/words')
  @ApiOperation({ summary: 'Thêm từ vào học phần (Màn 24)' })
  @ResponseMessage('Thêm từ vựng thành công')
  create(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) collectionId: string,
    @Body() dto: CreateVocabularyDto,
  ): Promise<VocabularyDto> {
    return this.vocabularies.create(user.id, collectionId, dto);
  }

  @Put('vocabularies/:id')
  @ApiOperation({ summary: 'Sửa từ vựng (Màn 09)' })
  @ResponseMessage('Cập nhật từ vựng thành công')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) id: string,
    @Body() dto: UpdateVocabularyDto,
  ): Promise<VocabularyDto> {
    return this.vocabularies.update(user.id, id, dto);
  }

  @Delete('vocabularies/:id')
  @ApiOperation({ summary: 'Xoá từ vựng (Màn 28)' })
  @ResponseMessage('Đã xoá từ vựng')
  async remove(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) id: string,
  ): Promise<null> {
    await this.vocabularies.remove(user.id, id);
    return null;
  }
}
