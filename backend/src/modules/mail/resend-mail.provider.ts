import { MailMessage, MailProvider } from './mail.provider';

/** Gửi email qua Resend (https://resend.com). */
export class ResendMailProvider extends MailProvider {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
  ) {
    super();
  }

  async send(message: MailMessage): Promise<void> {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: this.from,
        to: message.to,
        subject: message.subject,
        html: message.html,
      }),
    });
    if (!res.ok) {
      throw new Error(`Resend trả lỗi ${res.status}: ${await res.text()}`);
    }
  }
}
