import { Injectable } from '@nestjs/common';
import { AuthUser } from '../../common/auth/auth-user';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { LoginDto, RegisterDto } from './dto/auth.dto';
import { hashPassword, verifyPassword } from './password.util';
import { SocialProvider, SocialVerifier } from './social/social-verifier';
import { TokenPair, TokenService } from './token.service';
import { UserDto, toUserDto } from './user.mapper';

export interface AuthResult extends TokenPair {
  user: UserDto;
}

export const invalidCredentials = () =>
  new AppException(
    401,
    'INVALID_CREDENTIALS',
    'Email hoặc mật khẩu không đúng',
  );

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly social: SocialVerifier,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const exists = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true },
    });
    if (exists) {
      throw new AppException(409, 'EMAIL_EXISTS', 'Email đã được sử dụng');
    }
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        fullName: dto.fullName,
        passwordHash: await hashPassword(dto.password),
      },
    });
    return { ...(await this.tokens.issuePair(user)), user: toUserDto(user) };
  }

  async login(dto: LoginDto): Promise<AuthResult> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    const ok =
      !!user?.passwordHash &&
      (await verifyPassword(dto.password, user.passwordHash));
    if (!user || !ok) throw invalidCredentials();
    return { ...(await this.tokens.issuePair(user)), user: toUserDto(user) };
  }

  /**
   * Đăng nhập Google/Facebook: tìm theo (provider, providerId); nếu chưa có thì
   * liên kết với tài khoản cùng email (email đã được nhà cung cấp xác minh),
   * cuối cùng mới tạo tài khoản mới không có mật khẩu.
   */
  async socialLogin(
    provider: SocialProvider,
    token: string,
  ): Promise<AuthResult> {
    const profile = await this.social.verify(provider, token);
    const user =
      (await this.prisma.user.findUnique({
        where: {
          authProvider_providerId: {
            authProvider: provider,
            providerId: profile.providerId,
          },
        },
      })) ??
      (await this.prisma.user.findUnique({
        where: { email: profile.email },
      })) ??
      (await this.prisma.user.create({
        data: {
          email: profile.email,
          fullName: profile.fullName.slice(0, 100),
          avatarUrl: profile.avatarUrl,
          authProvider: provider,
          providerId: profile.providerId,
        },
      }));
    return { ...(await this.tokens.issuePair(user)), user: toUserDto(user) };
  }

  async refresh(refreshToken: string): Promise<AuthResult> {
    const { pair, user } = await this.tokens.rotate(refreshToken);
    return { ...pair, user: toUserDto(user) };
  }

  async logout(user: AuthUser, refreshToken: string): Promise<void> {
    await this.tokens.revokeRefreshToken(user.id, refreshToken);
    await this.tokens.blacklistAccess(user.jti, user.exp);
  }

  async me(userId: string): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new AppException(401, 'UNAUTHORIZED', 'Tài khoản không tồn tại');
    }
    return toUserDto(user);
  }
}
