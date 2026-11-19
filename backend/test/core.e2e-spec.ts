import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp } from './utils/app';

describe('Core (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('Swagger JSON có tiêu đề KarVocab API', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/docs-json')
      .expect(200);
    expect(res.body.info.title).toBe('KarVocab API');
  });

  it('route không tồn tại trả 404 với body lỗi chuẩn', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/khong-ton-tai')
      .expect(404);
    expect(res.body).toMatchObject({
      success: false,
      data: null,
      errorCode: 'NOT_FOUND',
    });
  });
});
