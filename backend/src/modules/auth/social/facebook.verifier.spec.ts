import { FacebookVerifier } from './facebook.verifier';

const json = (body: unknown) => ({
  ok: true,
  status: 200,
  json: () => Promise.resolve(body),
});

describe('FacebookVerifier', () => {
  const fetchMock = jest.fn();

  beforeEach(() => {
    fetchMock.mockReset();
    global.fetch = fetchMock;
  });

  it('trả hồ sơ khi token hợp lệ và đúng app', async () => {
    fetchMock
      .mockResolvedValueOnce(
        json({ data: { is_valid: true, app_id: 'app1', user_id: 'fb1' } }),
      )
      .mockResolvedValueOnce(
        json({
          id: 'fb1',
          name: 'Minh',
          email: 'M@x.com',
          picture: { data: { url: 'https://img/1.png' } },
        }),
      );
    const profile = await new FacebookVerifier('app1', 'secret').verify('tok');
    expect(profile).toEqual({
      providerId: 'fb1',
      email: 'm@x.com',
      fullName: 'Minh',
      avatarUrl: 'https://img/1.png',
    });
    expect(String(fetchMock.mock.calls[0][0])).toContain(
      'access_token=app1%7Csecret',
    );
  });

  it('ném lỗi khi is_valid = false', async () => {
    fetchMock.mockResolvedValueOnce(json({ data: { is_valid: false } }));
    await expect(
      new FacebookVerifier('app1', 'secret').verify('tok'),
    ).rejects.toMatchObject({ errorCode: 'SOCIAL_TOKEN_INVALID' });
  });

  it('ném lỗi khi token thuộc app khác', async () => {
    fetchMock.mockResolvedValueOnce(
      json({ data: { is_valid: true, app_id: 'other' } }),
    );
    await expect(
      new FacebookVerifier('app1', 'secret').verify('tok'),
    ).rejects.toMatchObject({ errorCode: 'SOCIAL_TOKEN_INVALID' });
  });

  it('ném lỗi khi tài khoản Facebook không cung cấp email', async () => {
    fetchMock
      .mockResolvedValueOnce(json({ data: { is_valid: true, app_id: 'app1' } }))
      .mockResolvedValueOnce(json({ id: 'fb1', name: 'No Mail' }));
    await expect(
      new FacebookVerifier('app1', 'secret').verify('tok'),
    ).rejects.toMatchObject({ errorCode: 'SOCIAL_EMAIL_REQUIRED' });
  });
});
