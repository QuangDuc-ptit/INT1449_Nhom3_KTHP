export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface MulticastResult {
  successCount: number;
  /** Token không còn hợp lệ (gỡ app, hết hạn) cần xoá khỏi DB. */
  invalidTokens: string[];
}

/** Cổng gửi thông báo đẩy tới nhiều thiết bị. */
export abstract class PushProvider {
  abstract sendMulticast(
    tokens: string[],
    message: PushMessage,
  ): Promise<MulticastResult>;
}
