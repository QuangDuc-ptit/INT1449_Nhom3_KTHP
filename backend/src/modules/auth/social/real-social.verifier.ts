import { FacebookVerifier } from './facebook.verifier';
import { GoogleVerifier } from './google.verifier';
import {
  SocialProfile,
  SocialProvider,
  SocialVerifier,
} from './social-verifier';

/** Gọi đúng verifier thật theo provider. */
export class RealSocialVerifier extends SocialVerifier {
  constructor(
    private readonly google: GoogleVerifier,
    private readonly facebook: FacebookVerifier,
  ) {
    super();
  }

  verify(provider: SocialProvider, token: string): Promise<SocialProfile> {
    return provider === 'google'
      ? this.google.verify(token)
      : this.facebook.verify(token);
  }
}
