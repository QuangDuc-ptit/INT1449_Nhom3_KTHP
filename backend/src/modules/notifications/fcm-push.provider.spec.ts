import type { Messaging } from 'firebase-admin/messaging';
import { FcmPushProvider } from './fcm-push.provider';

const fail = (code: string) => ({ success: false, error: { code } });
const ok = { success: true };

describe('FcmPushProvider', () => {
  it('đưa token chết (not-registered, invalid) vào invalidTokens', async () => {
    const sendEachForMulticast = jest.fn().mockResolvedValue({
      successCount: 1,
      responses: [
        ok,
        fail('messaging/registration-token-not-registered'),
        fail('messaging/invalid-registration-token'),
        fail('messaging/internal-error'),
      ],
    });
    const provider = new FcmPushProvider({
      sendEachForMulticast,
    } as unknown as Messaging);

    const res = await provider.sendMulticast(['a', 'b', 'c', 'd'], {
      title: 'T',
      body: 'B',
      data: { k: 'v' },
    });

    expect(res).toEqual({ successCount: 1, invalidTokens: ['b', 'c'] });
    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: ['a', 'b', 'c', 'd'],
      notification: { title: 'T', body: 'B' },
      data: { k: 'v' },
    });
  });

  it('chia lô tối đa 500 token mỗi lần gửi', async () => {
    const sendEachForMulticast = jest.fn(({ tokens }: { tokens: string[] }) =>
      Promise.resolve({
        successCount: tokens.length,
        responses: tokens.map(() => ok),
      }),
    );
    const provider = new FcmPushProvider({
      sendEachForMulticast,
    } as unknown as Messaging);
    const tokens = Array.from({ length: 1201 }, (_, i) => `t${i}`);
    const res = await provider.sendMulticast(tokens, { title: 'T', body: 'B' });
    expect(sendEachForMulticast).toHaveBeenCalledTimes(3);
    expect(res.successCount).toBe(1201);
  });
});
