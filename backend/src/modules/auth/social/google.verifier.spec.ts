import type { OAuth2Client } from 'google-auth-library';
import { GoogleVerifier } from './google.verifier';

function verifierWith(payload: Record<string, unknown> | null) {
  const verifyIdToken = jest.fn().mockResolvedValue({
    getPayload: () => payload,
  });
  const client = { verifyIdToken } as unknown as OAuth2Client;
  return { verifier: new GoogleVerifier('client-id', client), verifyIdToken };
}

describe('GoogleVerifier', () => {
  it('trả hồ sơ khi token hợp lệ và email đã xác minh', async () => {
    const { verifier, verifyIdToken } = verifierWith({
      sub: 'g-1',
      email: 'A@Gmail.com',
      email_verified: true,
      name: 'An',
      picture: 'https://img/a.png',
    });
    await expect(verifier.verify('tok')).resolves.toEqual({
      providerId: 'g-1',
      email: 'a@gmail.com',
      fullName: 'An',
      avatarUrl: 'https://img/a.png',
    });
    expect(verifyIdToken).toHaveBeenCalledWith({
      idToken: 'tok',
      audience: 'client-id',
    });
  });

  it('thiếu email_verified thì không tin email (không cho liên kết tài khoản)', async () => {
    const { verifier } = verifierWith({ sub: 'g-1', email: 'a@gmail.com' });
    await expect(verifier.verify('tok')).rejects.toMatchObject({
      errorCode: 'SOCIAL_EMAIL_REQUIRED',
    });
  });

  it('email_verified = false thì từ chối', async () => {
    const { verifier } = verifierWith({
      sub: 'g-1',
      email: 'a@gmail.com',
      email_verified: false,
    });
    await expect(verifier.verify('tok')).rejects.toMatchObject({
      errorCode: 'SOCIAL_EMAIL_REQUIRED',
    });
  });

  it('chữ ký hoặc audience sai thì 401 SOCIAL_TOKEN_INVALID', async () => {
    const client = {
      verifyIdToken: jest.fn().mockRejectedValue(new Error('Wrong audience')),
    } as unknown as OAuth2Client;
    await expect(
      new GoogleVerifier('client-id', client).verify('tok'),
    ).rejects.toMatchObject({ errorCode: 'SOCIAL_TOKEN_INVALID' });
  });
});
