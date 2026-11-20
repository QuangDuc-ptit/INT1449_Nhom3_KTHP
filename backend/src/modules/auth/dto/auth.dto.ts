import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsString,
  Length,
  Matches,
  MaxLength,
} from 'class-validator';
import { SOCIAL_PROVIDERS } from '../social/social-verifier';
import type { SocialProvider } from '../social/social-verifier';
import {
  STRONG_PASSWORD_MESSAGE,
  STRONG_PASSWORD_REGEX,
} from '../password.util';

export const normalizeEmail = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().toLowerCase() : value;

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class RegisterDto {
  @ApiProperty({ example: 'user@example.com' })
  @Transform(normalizeEmail)
  @IsEmail({}, { message: 'Email không đúng định dạng' })
  @MaxLength(254, { message: 'Email quá dài' })
  email!: string;

  @ApiProperty({ example: 'Password123' })
  @IsString({ message: 'Mật khẩu phải là chuỗi' })
  @MaxLength(72, { message: 'Mật khẩu tối đa 72 ký tự' })
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  password!: string;

  @ApiProperty({ example: 'Nguyen Van A' })
  @Transform(trim)
  @IsString({ message: 'Họ tên phải là chuỗi' })
  @Length(1, 100, { message: 'Họ tên phải từ 1 đến 100 ký tự' })
  fullName!: string;
}

export class SocialLoginDto {
  @ApiProperty({ enum: SOCIAL_PROVIDERS })
  @IsIn(SOCIAL_PROVIDERS, { message: 'provider phải là google hoặc facebook' })
  provider!: SocialProvider;

  @ApiProperty({ description: 'Google ID token hoặc Facebook access token' })
  @IsString({ message: 'idToken phải là chuỗi' })
  @Length(1, 4096, { message: 'idToken không hợp lệ' })
  idToken!: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: 'user@example.com' })
  @Transform(normalizeEmail)
  @IsEmail({}, { message: 'Email không đúng định dạng' })
  email!: string;
}

export class ResetPasswordDto {
  @ApiProperty({ example: 'user@example.com' })
  @Transform(normalizeEmail)
  @IsEmail({}, { message: 'Email không đúng định dạng' })
  email!: string;

  @ApiProperty({ example: '123456' })
  @Matches(/^\d{6}$/, { message: 'Mã xác nhận gồm 6 chữ số' })
  otp!: string;

  @ApiProperty({ example: 'NewPassword123' })
  @IsString({ message: 'Mật khẩu phải là chuỗi' })
  @MaxLength(72, { message: 'Mật khẩu tối đa 72 ký tự' })
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  newPassword!: string;
}

export class RefreshTokenDto {
  @ApiProperty()
  @IsString({ message: 'refreshToken phải là chuỗi' })
  @Length(1, 256, { message: 'refreshToken không hợp lệ' })
  refreshToken!: string;
}

export class LoginDto {
  @ApiProperty({ example: 'user@example.com' })
  @Transform(normalizeEmail)
  @IsEmail({}, { message: 'Email không đúng định dạng' })
  email!: string;

  @ApiProperty({ example: 'Password123' })
  @IsString({ message: 'Mật khẩu phải là chuỗi' })
  @Length(1, 72, { message: 'Vui lòng nhập mật khẩu' })
  password!: string;
}
