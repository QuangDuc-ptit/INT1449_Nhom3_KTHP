import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { cert, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { readFileSync } from 'node:fs';
import { Env } from '../../config/env.schema';
import { FcmPushProvider } from './fcm-push.provider';
import { MockPushProvider } from './mock-push.provider';
import { PushProvider } from './push.provider';
import { PushService } from './push.service';

@Global()
@Module({
  providers: [
    PushService,
    {
      provide: PushProvider,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): PushProvider => {
        if (config.get('PUSH_PROVIDER', { infer: true }) !== 'fcm') {
          return new MockPushProvider();
        }
        const path = config.get('FIREBASE_SERVICE_ACCOUNT_PATH', {
          infer: true,
        });
        const serviceAccount = JSON.parse(readFileSync(path, 'utf8')) as {
          project_id: string;
          client_email: string;
          private_key: string;
        };
        const app = initializeApp(
          {
            credential: cert({
              projectId: serviceAccount.project_id,
              clientEmail: serviceAccount.client_email,
              privateKey: serviceAccount.private_key,
            }),
          },
          'karvocab',
        );
        return new FcmPushProvider(getMessaging(app));
      },
    },
  ],
  exports: [PushService, PushProvider],
})
export class NotificationsModule {}
