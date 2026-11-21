import { Logger } from '@nestjs/common';
import { MulticastResult, PushMessage, PushProvider } from './push.provider';

/**
 * Không gửi thật: ghi log và lưu lại để test đọc.
 * Token bắt đầu bằng `invalid` được coi là đã chết (để thử luồng dọn token).
 */
export class MockPushProvider extends PushProvider {
  private readonly logger = new Logger('Push');
  readonly sent: { tokens: string[]; message: PushMessage }[] = [];

  sendMulticast(
    tokens: string[],
    message: PushMessage,
  ): Promise<MulticastResult> {
    this.sent.push({ tokens, message });
    if (this.sent.length > 100) this.sent.shift();
    const invalidTokens = tokens.filter((t) => t.startsWith('invalid'));
    this.logger.log(`[mock] ${message.title}: ${message.body}`);
    return Promise.resolve({
      invalidTokens,
      successCount: tokens.length - invalidTokens.length,
    });
  }
}
