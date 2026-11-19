import { OAuth2Client } from 'google-auth-library';
import {
  SocialProfile,
  socialEmailRequired,
  socialTokenInvalid,
} from './social-verifier';

/** Xác thực Google ID token (chữ ký, audience, hạn dùng) bằng google-auth-library. */
export class GoogleVerifier {
  private readonly client = new OAuth2Client();

  constructor(private readonly clientId: string) {}

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
    if (!payload.email || payload.email_verified === false) {
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
