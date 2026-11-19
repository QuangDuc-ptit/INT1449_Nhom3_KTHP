import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AuthProvider, Language, Platform } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  Validate,
} from 'class-validator';
import {
  STRONG_PASSWORD_MESSAGE,
  STRONG_PASSWORD_REGEX,
} from '../../auth/password.util';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export function isValidTimezone(tz: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

@ValidatorConstraint({ name: 'isTimezone' })
class IsTimezoneConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    return typeof value === 'string' && isValidTimezone(value);
  }
  defaultMessage(args: ValidationArguments): string {
    return `${args.property} phải là múi giờ IANA hợp lệ, ví dụ Asia/Ho_Chi_Minh`;
  }
}

export class UpdateSettingsDto {
  @ApiPropertyOptional({ minimum: 5, maximum: 30, example: 15 })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Mục tiêu mỗi ngày phải là số nguyên' })
  @Min(5, { message: 'Mục tiêu mỗi ngày từ 5 đến 30 từ' })
  @Max(30, { message: 'Mục tiêu mỗi ngày từ 5 đến 30 từ' })
  dailyGoalWords?: number;

  @ApiPropertyOptional({ example: '20:00' })
  @IsOptional()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'Giờ nhắc học có dạng HH:mm, ví dụ 20:00',
  })
  reminderTime?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean({ message: 'isNotificationEnabled phải là true hoặc false' })
  isNotificationEnabled?: boolean;

  @ApiPropertyOptional({ example: 'Asia/Ho_Chi_Minh' })
  @IsOptional()
  @Validate(IsTimezoneConstraint)
  timezone?: string;

  @ApiPropertyOptional({ enum: Language })
  @IsOptional()
  @IsEnum(Language, { message: 'Ngôn ngữ phải là vi hoặc en' })
  language?: Language;
}

export class UpdateProfileDto {
  @ApiProperty({ example: 'Lê Anh Tuấn' })
  @Transform(trim)
  @IsString({ message: 'Họ tên phải là chuỗi' })
  @Length(1, 100, { message: 'Họ tên phải từ 1 đến 100 ký tự' })
  fullName!: string;
}

export class ChangePasswordDto {
  @ApiPropertyOptional({
    description: 'Bắt buộc nếu tài khoản đã có mật khẩu',
  })
  @IsOptional()
  @IsString()
  @MaxLength(72)
  currentPassword?: string;

  @ApiProperty({ example: 'NewPassword123' })
  @IsString({ message: 'Mật khẩu phải là chuỗi' })
  @MaxLength(72, { message: 'Mật khẩu tối đa 72 ký tự' })
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  newPassword!: string;
}

export class RegisterDeviceDto {
  @ApiProperty()
  @IsString({ message: 'fcmToken phải là chuỗi' })
  @Length(1, 4096, { message: 'fcmToken không hợp lệ' })
  fcmToken!: string;

  @ApiProperty({ enum: Platform })
  @IsEnum(Platform, { message: 'platform phải là ios hoặc android' })
  platform!: Platform;
}

export class RemoveDeviceDto {
  @ApiProperty()
  @IsString({ message: 'fcmToken phải là chuỗi' })
  @Length(1, 4096, { message: 'fcmToken không hợp lệ' })
  fcmToken!: string;
}

export interface SettingsDto {
  dailyGoalWords: number;
  reminderTime: string;
  isNotificationEnabled: boolean;
  timezone: string;
  language: Language;
}

export interface ProfileBadgeDto {
  code: string;
  title: string;
  description: string;
  iconUrl: string | null;
  requiredPoints: number;
  unlocked: boolean;
  unlockedAt: Date | null;
  progress: number;
}

export interface ProfileDto {
  user: {
    id: string;
    email: string;
    fullName: string;
    avatarUrl: string | null;
    authProvider: AuthProvider;
  };
  stats: {
    learnedWords: number;
    masteredWords: number;
    collectionsCount: number;
    currentStreak: number;
    highestStreak: number;
  };
  settings: SettingsDto;
  badges: ProfileBadgeDto[];
}
