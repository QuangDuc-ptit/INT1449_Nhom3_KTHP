import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { S3StorageService } from './s3-storage.service';

describe('S3StorageService', () => {
  it('gửi PutObjectCommand đúng bucket, key, content type và trả URL công khai', async () => {
    const send = jest.fn().mockResolvedValue({});
    const client = { send } as unknown as S3Client;
    const storage = new S3StorageService(
      client,
      'karvocab-media',
      'https://cdn.example.com/',
    );
    const url = await storage.putObject(
      'audio/v1-us.mp3',
      Buffer.from('mp3'),
      'audio/mpeg',
    );
    expect(url).toBe('https://cdn.example.com/audio/v1-us.mp3');
    expect(send).toHaveBeenCalledTimes(1);
    const cmd = send.mock.calls[0][0] as PutObjectCommand;
    expect(cmd).toBeInstanceOf(PutObjectCommand);
    expect(cmd.input).toMatchObject({
      Bucket: 'karvocab-media',
      Key: 'audio/v1-us.mp3',
      ContentType: 'audio/mpeg',
    });
  });

  it('từ chối key không an toàn', async () => {
    const storage = new S3StorageService(
      { send: jest.fn() } as unknown as S3Client,
      'b',
      'https://cdn',
    );
    await expect(
      storage.putObject('../x', Buffer.from('x'), 'text/plain'),
    ).rejects.toThrow(/key/i);
  });
});
