import { AppException } from '../../../common/http/app.exception';

export type SocialProvider = 'google' | 'facebook';
export const SOCIAL_PROVIDERS: SocialProvider[] = ['google', 'facebook'];

export interface SocialProfile {
  providerId: string;
  email: string;
  fullName: string;
  avatarUrl?: string;
}

/** Xác thực token do SDK Google/Facebook trên app cấp, trả về hồ sơ người dùng. */
export abstract class SocialVerifier {
  abstract verify(
    provider: SocialProvider,
    token: string,
  ): Promise<SocialProfile>;
}

export const socialTokenInvalid = () =>
  new AppException(
    401,
    'SOCIAL_TOKEN_INVALID',
    'Không xác thực được tài khoản mạng xã hội, vui lòng thử lại',
  );

export const socialEmailRequired = () =>
  new AppException(
    401,
    'SOCIAL_EMAIL_REQUIRED',
    'Tài khoản mạng xã hội chưa cung cấp email, vui lòng cấp quyền email',
  );
