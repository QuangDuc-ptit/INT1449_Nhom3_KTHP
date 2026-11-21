import { OAuth2Client } from 'google-auth-library';
import {
  SocialProfile,
  socialEmailRequired,
  socialTokenInvalid,
} from './social-verifier';

/** Xác thực Google ID token (chữ ký, audience, hạn dùng) bằng google-auth-library. */
export class GoogleVerifier {
  constructor(
    private readonly clientId: string,
    private readonly client: OAuth2Client = new OAuth2Client(),
  ) {}

  async verify(idToken: string): Promise<SocialProfile> {
    let payload;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.clientId,
      });
      payload = ticket.getPayload();
    } catch {
      throw socialTokenInvalid();
    }
    if (!payload?.sub) throw socialTokenInvalid();
    // Chỉ tin email Google đã xác minh rõ ràng (email_verified === true)
    if (!payload.email || payload.email_verified !== true) {
      throw socialEmailRequired();
    }
    return {
      providerId: payload.sub,
      email: payload.email.toLowerCase(),
      fullName: payload.name?.trim() || payload.email,
      avatarUrl: payload.picture,
    };
  }
}
