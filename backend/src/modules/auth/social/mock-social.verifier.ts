import {
  SocialProfile,
  SocialVerifier,
  socialTokenInvalid,
} from './social-verifier';

/**
 * Verifier giả lập cho dev/test và chế độ Demo.
 * Token có dạng `mock:<providerId>:<email>:<fullName>`.
 */
export class MockSocialVerifier extends SocialVerifier {
  /** Token mock tự khai email, không ai xác minh. */
  readonly emailVerifiedByProvider = false;

  verify(_provider: string, token: string): Promise<SocialProfile> {
    const [prefix, providerId, email, ...nameParts] = token.split(':');
    const fullName = nameParts.join(':').trim();
    if (
      prefix !== 'mock' ||
      !providerId ||
      !email?.includes('@') ||
      !fullName
    ) {
      return Promise.reject(socialTokenInvalid());
    }
    return Promise.resolve({
      providerId,
      email: email.trim().toLowerCase(),
      fullName,
    });
  }
}
