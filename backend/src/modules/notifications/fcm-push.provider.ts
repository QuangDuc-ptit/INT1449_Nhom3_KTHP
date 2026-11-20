import type { Messaging } from 'firebase-admin/messaging';
import { MulticastResult, PushMessage, PushProvider } from './push.provider';

/** FCM giới hạn 500 token mỗi lần gửi multicast. */
const BATCH_SIZE = 500;

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** Gửi thông báo qua Firebase Cloud Messaging (firebase-admin). */
export class FcmPushProvider extends PushProvider {
  constructor(private readonly messaging: Messaging) {
    super();
  }

  async sendMulticast(
    tokens: string[],
    message: PushMessage,
  ): Promise<MulticastResult> {
    const result: MulticastResult = { successCount: 0, invalidTokens: [] };
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const res = await this.messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title: message.title, body: message.body },
        ...(message.data ? { data: message.data } : {}),
      });
      result.successCount += res.successCount;
      res.responses.forEach((r, idx) => {
        if (!r.success && r.error && DEAD_TOKEN_CODES.has(r.error.code)) {
          result.invalidTokens.push(batch[idx]);
        }
      });
    }
    return result;
  }
}
