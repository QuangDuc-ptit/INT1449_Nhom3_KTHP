import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { StorageService, assertSafeKey } from './storage.service';

/** Lưu file lên S3 hoặc dịch vụ tương thích (Cloudflare R2, MinIO). */
export class S3StorageService extends StorageService {
  constructor(
    private readonly client: S3Client,
    private readonly bucket: string,
    private readonly publicUrl: string,
  ) {
    super();
  }

  async putObject(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<string> {
    assertSafeKey(key);
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
        CacheControl: 'public, max-age=31536000',
      }),
    );
    return `${this.publicUrl.replace(/\/+$/, '')}/${key}`;
  }
}
