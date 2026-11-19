import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { StorageService } from '../src/modules/storage/storage.service';
import { createTestApp } from './utils/app';

describe('Lưu file cục bộ (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('file đã lưu được phục vụ tĩnh qua /uploads', async () => {
    const url = await app
      .get(StorageService)
      .putObject('audio/e2e-check.mp3', Buffer.from('ID3'), 'audio/mpeg');
    const path = new URL(url).pathname;
    expect(path).toBe('/uploads/audio/e2e-check.mp3');
    const res = await request(app.getHttpServer()).get(path).expect(200);
    expect(res.headers['content-type']).toContain('audio/mpeg');
  });

  it('file không tồn tại trả 404', async () => {
    await request(app.getHttpServer())
      .get('/uploads/audio/khong-co.mp3')
      .expect(404);
  });
});
