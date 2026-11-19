import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Sinh từ vựng bằng AI (e2e, provider mock)', () => {
  let app: INestApplication;
  let u: RegisteredUser;

  beforeAll(async () => {
    app = await createTestApp();
  });

  beforeEach(async () => {
    await resetDb(app.get(PrismaService));
    await resetRedis(app);
    u = await registerUser(app);
  });

  afterAll(async () => {
    await app.close();
  });

  const gen = (body: Record<string, unknown>, token = u.accessToken) =>
    request(app.getHttpServer())
      .post('/api/v1/ai/generate-vocab')
      .set(bearer(token))
      .send(body);

  it('trả đúng số từ yêu cầu, đúng cấp độ', async () => {
    const res = await gen({
      topic: 'Du lịch',
      cefrLevel: 'A2',
      wordCount: 5,
    }).expect(200);
    expect(res.body.data.words).toHaveLength(5);
    for (const w of res.body.data.words) {
      expect(w).toMatchObject({ cefrLevel: 'A2', existsInCollection: false });
      expect(w.term).toEqual(expect.any(String));
      expect(w.definitionVi).toEqual(expect.any(String));
    }
  });

  it('wordCount 20 vẫn đủ từ, không trùng', async () => {
    const res = await gen({
      topic: 'Học thuật',
      cefrLevel: 'C1',
      wordCount: 20,
    }).expect(200);
    const terms = res.body.data.words.map((w: { term: string }) => w.term);
    expect(terms).toHaveLength(20);
    expect(new Set(terms).size).toBe(20);
  });

  it.each([
    [{ topic: 'ab', cefrLevel: 'B1', wordCount: 5 }],
    [{ topic: 'Du lịch', cefrLevel: 'C2', wordCount: 5 }],
    [{ topic: 'Du lịch', cefrLevel: 'B1', wordCount: 2 }],
    [{ topic: 'Du lịch', cefrLevel: 'B1', wordCount: 25 }],
  ])('dữ liệu không hợp lệ %j trả 400', async (body) => {
    await gen(body).expect(400);
  });

  it('không có token trả 401', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/ai/generate-vocab')
      .send({ topic: 'Du lịch', cefrLevel: 'B1', wordCount: 5 })
      .expect(401);
  });

  it('lần gọi thứ 6 trong 1 phút bị 429', async () => {
    const body = { topic: 'Du lịch', cefrLevel: 'B1', wordCount: 3 };
    for (let i = 0; i < 5; i++) await gen(body).expect(200);
    const res = await gen(body).expect(429);
    expect(res.body.errorCode).toBe('RATE_LIMITED');
    // Giới hạn tính riêng theo từng user
    const other = await registerUser(app);
    await gen(body, other.accessToken).expect(200);
  });

  it('collectionId của người khác trả 404', async () => {
    const other = await registerUser(app);
    const col = await request(app.getHttpServer())
      .post('/api/v1/collections')
      .set(bearer(other.accessToken))
      .send({ title: 'Của người khác' })
      .expect(201);
    await gen({
      topic: 'Du lịch',
      cefrLevel: 'B1',
      wordCount: 3,
      collectionId: col.body.data.id,
    }).expect(404);
  });
});
