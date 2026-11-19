import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../../config/env.schema';
import { ConsoleMailProvider } from './console-mail.provider';
import { MailProvider } from './mail.provider';
import { ResendMailProvider } from './resend-mail.provider';

@Global()
@Module({
  providers: [
    {
      provide: MailProvider,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): MailProvider =>
        config.get('MAIL_PROVIDER', { infer: true }) === 'resend'
          ? new ResendMailProvider(
              config.get('RESEND_API_KEY', { infer: true }),
              config.get('MAIL_FROM', { infer: true }),
            )
          : new ConsoleMailProvider(),
    },
  ],
  exports: [MailProvider],
})
export class MailModule {}
