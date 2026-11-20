import { S3Client } from '@aws-sdk/client-s3';
import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../../config/env.schema';
import { LocalStorageService } from './local-storage.service';
import { S3StorageService } from './s3-storage.service';
import { StorageService } from './storage.service';

@Global()
@Module({
  providers: [
    {
      provide: StorageService,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): StorageService => {
        if (config.get('STORAGE_PROVIDER', { infer: true }) === 's3') {
          const endpoint = config.get('S3_ENDPOINT', { infer: true });
          const client = new S3Client({
            region: config.get('S3_REGION', { infer: true }),
            ...(endpoint ? { endpoint, forcePathStyle: true } : {}),
            credentials: {
              accessKeyId: config.get('S3_ACCESS_KEY_ID', { infer: true }),
              secretAccessKey: config.get('S3_SECRET_ACCESS_KEY', {
                infer: true,
              }),
            },
          });
          return new S3StorageService(
            client,
            config.get('S3_BUCKET', { infer: true }),
            config.get('S3_PUBLIC_URL', { infer: true }),
          );
        }
        return new LocalStorageService(
          config.get('UPLOAD_DIR', { infer: true }),
          config.get('PUBLIC_BASE_URL', { infer: true }),
        );
      },
    },
  ],
  exports: [StorageService],
})
export class StorageModule {}
