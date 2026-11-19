import { Logger } from '@nestjs/common';
import { MailMessage, MailProvider } from './mail.provider';

/** Không gửi thư thật: ghi log và giữ lại thư để test đọc. */
export class ConsoleMailProvider extends MailProvider {
  private readonly logger = new Logger('Mail');
  readonly lastMessages: MailMessage[] = [];

  send(message: MailMessage): Promise<void> {
    this.lastMessages.push(message);
    if (this.lastMessages.length > 50) this.lastMessages.shift();
    this.logger.log(`[console] gửi tới ${message.to}: ${message.subject}`);
    return Promise.resolve();
  }
}
