import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { AppException } from '../../common/http/app.exception';
import { ResponseMessage } from '../../common/http/response-message.decorator';
import { Paginated } from '../../common/pagination/pagination.dto';
import { CollectionsService } from './collections.service';
import {
  CollectionDto,
  CreateCollectionDto,
  ListCollectionsQueryDto,
  UpdateCollectionDto,
} from './dto/collection.dto';

/** ParseUUIDPipe trả lỗi tiếng Việt theo chuẩn chung. */
export const UuidParam = new ParseUUIDPipe({
  exceptionFactory: () =>
    new AppException(400, 'VALIDATION_ERROR', 'Mã định danh không hợp lệ'),
});

@ApiTags('Collections')
@ApiBearerAuth()
@Controller('collections')
export class CollectionsController {
  constructor(private readonly collections: CollectionsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sách học phần của tôi (Màn 05)' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() q: ListCollectionsQueryDto,
  ): Promise<Paginated<CollectionDto>> {
    return this.collections.list(user.id, q);
  }

  @Post()
  @ApiOperation({ summary: 'Tạo học phần mới (Màn 22)' })
  @ResponseMessage('Tạo học phần thành công')
  create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateCollectionDto,
  ): Promise<CollectionDto> {
    return this.collections.create(user.id, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiết học phần' })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) id: string,
  ): Promise<CollectionDto> {
    return this.collections.get(user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Sửa học phần' })
  @ResponseMessage('Cập nhật học phần thành công')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) id: string,
    @Body() dto: UpdateCollectionDto,
  ): Promise<CollectionDto> {
    return this.collections.update(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Xoá học phần cùng toàn bộ từ vựng' })
  @ResponseMessage('Đã xoá học phần')
  async remove(
    @CurrentUser() user: AuthUser,
    @Param('id', UuidParam) id: string,
  ): Promise<null> {
    await this.collections.remove(user.id, id);
    return null;
  }
}
