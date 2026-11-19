import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { LoginDto, RegisterDto } from './dto/auth.dto';
import { hashPassword, verifyPassword } from './password.util';
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

  async me(userId: string): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new AppException(401, 'UNAUTHORIZED', 'Tài khoản không tồn tại');
    }
    return toUserDto(user);
  }
}
