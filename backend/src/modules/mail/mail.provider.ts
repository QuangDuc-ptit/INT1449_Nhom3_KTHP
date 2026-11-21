export interface MailMessage {
  to: string;
  subject: string;
  html: string;
}

/** Cổng gửi email; bản console dùng cho dev/test, bản Resend dùng thật. */
export abstract class MailProvider {
  abstract send(message: MailMessage): Promise<void>;
}
