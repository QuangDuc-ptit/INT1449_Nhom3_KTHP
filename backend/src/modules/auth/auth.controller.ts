import { Body, Controller, Get, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { AuthUser } from '../../common/auth/auth-user';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import { Public } from '../../common/auth/public.decorator';
import { ResponseMessage } from '../../common/http/response-message.decorator';
import { RateLimit } from '../../common/rate-limit/rate-limit.decorator';
import { AuthResult, AuthService } from './auth.service';
import {
  ForgotPasswordDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  ResetPasswordDto,
} from './dto/auth.dto';
import { PasswordResetService } from './password-reset.service';
import { UserDto } from './user.mapper';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly passwordReset: PasswordResetService,
  ) {}

  @Public()
  @Post('register')
  @ApiOperation({ summary: 'Đăng ký tài khoản bằng email (Màn 03)' })
  @ResponseMessage('Đăng ký thành công')
  register(@Body() dto: RegisterDto): Promise<AuthResult> {
    return this.auth.register(dto);
  }

  @Public()
  @Post('login')
  @HttpCode(200)
  @RateLimit({ key: 'login', limit: 5, windowSec: 60, by: 'ip+email' })
  @ApiOperation({ summary: 'Đăng nhập bằng email và mật khẩu (Màn 02)' })
  @ResponseMessage('Đăng nhập thành công')
  login(@Body() dto: LoginDto): Promise<AuthResult> {
    return this.auth.login(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({ summary: 'Cấp lại cặp token (xoay vòng refresh token)' })
  refresh(@Body() dto: RefreshTokenDto): Promise<AuthResult> {
    return this.auth.refresh(dto.refreshToken);
  }

  @Post('logout')
  @HttpCode(200)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Đăng xuất: thu hồi refresh token và access token' })
  @ResponseMessage('Đăng xuất thành công')
  async logout(
    @CurrentUser() user: AuthUser,
    @Body() dto: RefreshTokenDto,
  ): Promise<null> {
    await this.auth.logout(user, dto.refreshToken);
    return null;
  }

  @Public()
  @Post('forgot-password')
  @HttpCode(200)
  @RateLimit({ key: 'forgot', limit: 3, windowSec: 900, by: 'email' })
  @ApiOperation({ summary: 'Gửi mã OTP đặt lại mật khẩu qua email (Màn 21)' })
  @ResponseMessage('Nếu email tồn tại, mã xác nhận đã được gửi')
  async forgotPassword(@Body() dto: ForgotPasswordDto): Promise<null> {
    await this.passwordReset.requestOtp(dto.email);
    return null;
  }

  @Public()
  @Post('reset-password')
  @HttpCode(200)
  @ApiOperation({ summary: 'Đặt lại mật khẩu bằng OTP' })
  @ResponseMessage('Đặt lại mật khẩu thành công')
  async resetPassword(@Body() dto: ResetPasswordDto): Promise<null> {
    await this.passwordReset.resetPassword(dto.email, dto.otp, dto.newPassword);
    return null;
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Thông tin người dùng hiện tại' })
  me(@CurrentUser() user: AuthUser): Promise<UserDto> {
    return this.auth.me(user.id);
  }
}
