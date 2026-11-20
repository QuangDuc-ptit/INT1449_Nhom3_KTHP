import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { AuthUser } from '../../common/auth/auth-user';
import { AppException } from '../../common/http/app.exception';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { hashPassword, verifyPassword } from '../auth/password.util';
import { TokenPair, TokenService } from '../auth/token.service';
import { UserDto, toUserDto } from '../auth/user.mapper';
import { UserMetrics, badgeProgress } from '../gamification/badge-rules';
import { StorageService } from '../storage/storage.service';
import {
  ChangePasswordDto,
  ProfileBadgeDto,
  ProfileDto,
  RegisterDeviceDto,
  SettingsDto,
  UpdateSettingsDto,
} from './dto/users.dto';
import { IMAGE_CONTENT_TYPE, detectImage } from './image.util';

const toSettings = (u: User): SettingsDto => ({
  dailyGoalWords: u.dailyGoalWords,
  reminderTime: u.reminderTime,
  isNotificationEnabled: u.isNotificationEnabled,
  timezone: u.timezone,
  language: u.language,
});

const userNotFound = () =>
  new AppException(401, 'UNAUTHORIZED', 'Tài khoản không tồn tại');

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly storage: StorageService,
    private readonly clock: Clock,
  ) {}

  async getProfile(userId: string): Promise<ProfileDto> {
    const user = await this.findUser(userId);
    const [learnedWords, masteredWords, collectionsCount, badges, unlocked] =
      await Promise.all([
        this.prisma.userVocabProgress.count({
          where: { userId, status: { not: 'new' } },
        }),
        this.prisma.userVocabProgress.count({
          where: { userId, status: 'mastered' },
        }),
        this.prisma.collection.count({ where: { userId } }),
        this.prisma.badge.findMany({ orderBy: { requiredPoints: 'asc' } }),
        this.prisma.userBadge.findMany({ where: { userId } }),
      ]);
    const metrics: UserMetrics = {
      currentStreak: user.currentStreak,
      learnedWords,
      collectionsCount,
    };
    const unlockedAt = new Map(
      unlocked.map((ub) => [ub.badgeId, ub.unlockedAt]),
    );
    const badgeDtos: ProfileBadgeDto[] = badges.map((b) => {
      return {
        code: b.code,
        title: b.title,
        description: b.description,
        iconUrl: b.iconUrl,
        requiredPoints: b.requiredPoints,
        unlocked: unlockedAt.has(b.id),
        unlockedAt: unlockedAt.get(b.id) ?? null,
        progress: badgeProgress(b.code, b.requiredPoints, metrics),
      };
    });
    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        authProvider: user.authProvider,
      },
      stats: {
        learnedWords,
        masteredWords,
        collectionsCount,
        currentStreak: user.currentStreak,
        highestStreak: user.highestStreak,
      },
      settings: toSettings(user),
      badges: badgeDtos,
    };
  }

  async updateSettings(
    userId: string,
    dto: UpdateSettingsDto,
  ): Promise<SettingsDto> {
    await this.findUser(userId);
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
    return toSettings(user);
  }

  async updateProfile(userId: string, fullName: string): Promise<UserDto> {
    await this.findUser(userId);
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { fullName },
    });
    return toUserDto(user);
  }

  /**
   * Đổi mật khẩu (tài khoản social chưa có mật khẩu thì đặt mới). Thu hồi mọi
   * phiên cũ, vô hiệu hoá access token hiện tại và trả cặp token mới.
   */
  async changePassword(
    auth: AuthUser,
    dto: ChangePasswordDto,
  ): Promise<TokenPair> {
    const user = await this.findUser(auth.id);
    if (user.passwordHash) {
      const ok =
        !!dto.currentPassword &&
        (await verifyPassword(dto.currentPassword, user.passwordHash));
      if (!ok) {
        throw new AppException(
          400,
          'PASSWORD_INCORRECT',
          'Mật khẩu hiện tại không đúng',
        );
      }
    }
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: await hashPassword(dto.newPassword) },
    });
    await this.tokens.revokeAllForUser(user.id);
    await this.tokens.blacklistAccess(auth.jti, auth.exp);
    return this.tokens.issuePair(updated);
  }

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File | undefined,
  ): Promise<{ avatarUrl: string }> {
    if (!file) {
      throw new AppException(
        400,
        'FILE_REQUIRED',
        'Vui lòng chọn ảnh đại diện',
      );
    }
    const ext = detectImage(file.buffer);
    if (!ext) {
      throw new AppException(
        400,
        'FILE_TYPE_INVALID',
        'Ảnh đại diện phải là PNG, JPEG hoặc WebP',
      );
    }
    await this.findUser(userId);
    const avatarUrl = await this.storage.putObject(
      `avatars/${userId}-${this.clock.now().getTime()}.${ext}`,
      file.buffer,
      IMAGE_CONTENT_TYPE[ext],
    );
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });
    return { avatarUrl };
  }

  /** Lưu FCM token; token đã thuộc user khác (đổi tài khoản trên máy) thì chuyển chủ. */
  async registerDevice(userId: string, dto: RegisterDeviceDto): Promise<void> {
    await this.prisma.userDevice.upsert({
      where: { fcmToken: dto.fcmToken },
      create: { userId, fcmToken: dto.fcmToken, platform: dto.platform },
      update: { userId, platform: dto.platform },
    });
  }

  async removeDevice(userId: string, fcmToken: string): Promise<void> {
    await this.prisma.userDevice.deleteMany({ where: { userId, fcmToken } });
  }

  private async findUser(userId: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw userNotFound();
    return user;
  }
}
