import { ResendMailProvider } from './resend-mail.provider';

describe('ResendMailProvider', () => {
  const fetchMock = jest.fn();

  beforeEach(() => {
    fetchMock.mockReset();
    global.fetch = fetchMock;
  });

  it('gọi API Resend với Bearer key và body đúng', async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      text: () => Promise.resolve(''),
    });
    const provider = new ResendMailProvider('re_key', 'KarVocab <a@b.c>');
    await provider.send({
      to: 'u@x.com',
      subject: 'Chủ đề',
      html: '<p>Hi</p>',
    });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://api.resend.com/emails');
    expect(init.method).toBe('POST');
    expect(init.headers.Authorization).toBe('Bearer re_key');
    expect(JSON.parse(init.body)).toEqual({
      from: 'KarVocab <a@b.c>',
      to: 'u@x.com',
      subject: 'Chủ đề',
      html: '<p>Hi</p>',
    });
  });

  it('ném lỗi khi Resend trả status lỗi', async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 422,
      text: () => Promise.resolve('bad'),
    });
    const provider = new ResendMailProvider('re_key', 'a@b.c');
    await expect(
      provider.send({ to: 'u@x.com', subject: 's', html: 'h' }),
    ).rejects.toThrow(/422/);
  });
});
