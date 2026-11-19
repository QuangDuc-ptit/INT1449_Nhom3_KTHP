import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Patch,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { ResponseMessage } from '../../common/http/response-message.decorator';
import { TokenPair } from '../auth/token.service';
import { UserDto } from '../auth/user.mapper';
import {
  ChangePasswordDto,
  ProfileDto,
  RegisterDeviceDto,
  RemoveDeviceDto,
  SettingsDto,
  UpdateProfileDto,
  UpdateSettingsDto,
} from './dto/users.dto';
import { UsersService } from './users.service';

export const AVATAR_MAX_BYTES = 2 * 1024 * 1024;

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Hồ sơ cá nhân, thống kê và huy hiệu (Màn 15)' })
  getProfile(@CurrentUser() user: AuthUser): Promise<ProfileDto> {
    return this.users.getProfile(user.id);
  }

  @Patch('settings')
  @ApiOperation({ summary: 'Cập nhật cài đặt học tập (Màn 23)' })
  @ResponseMessage('Đã lưu cài đặt')
  updateSettings(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateSettingsDto,
  ): Promise<SettingsDto> {
    return this.users.updateSettings(user.id, dto);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Đổi họ tên' })
  @ResponseMessage('Đã cập nhật hồ sơ')
  updateProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserDto> {
    return this.users.updateProfile(user.id, dto.fullName);
  }

  @Patch('password')
  @ApiOperation({ summary: 'Đổi mật khẩu (Màn 23), trả cặp token mới' })
  @ResponseMessage('Đổi mật khẩu thành công')
  changePassword(
    @CurrentUser() user: AuthUser,
    @Body() dto: ChangePasswordDto,
  ): Promise<TokenPair> {
    return this.users.changePassword(user, dto);
  }

  @Post('avatar')
  @ApiOperation({ summary: 'Tải ảnh đại diện (PNG/JPEG/WebP, tối đa 2 MB)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: AVATAR_MAX_BYTES, files: 1 },
    }),
  )
  @ResponseMessage('Đã cập nhật ảnh đại diện')
  uploadAvatar(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
  ): Promise<{ avatarUrl: string }> {
    return this.users.uploadAvatar(user.id, file);
  }

  @Post('devices')
  @ApiOperation({ summary: 'Đăng ký thiết bị nhận thông báo đẩy (FCM)' })
  @ResponseMessage('Đã đăng ký thiết bị')
  async registerDevice(
    @CurrentUser() user: AuthUser,
    @Body() dto: RegisterDeviceDto,
  ): Promise<null> {
    await this.users.registerDevice(user.id, dto);
    return null;
  }

  @Delete('devices')
  @HttpCode(200)
  @ApiOperation({ summary: 'Huỷ đăng ký thiết bị (khi đăng xuất)' })
  @ResponseMessage('Đã huỷ đăng ký thiết bị')
  async removeDevice(
    @CurrentUser() user: AuthUser,
    @Body() dto: RemoveDeviceDto,
  ): Promise<null> {
    await this.users.removeDevice(user.id, dto.fcmToken);
    return null;
  }
}
