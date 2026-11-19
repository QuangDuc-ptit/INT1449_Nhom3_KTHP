import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { waitFor } from './utils/wait';

describe('Sinh audio TTS qua hàng đợi (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
  });

  afterAll(async () => {
    await app.close();
  });

  it('thêm từ mới thì worker tự sinh audio UK và US', async () => {
    const u = await registerUser(app);
    const col = await request(app.getHttpServer())
      .post('/api/v1/collections')
      .set(bearer(u.accessToken))
      .send({ title: 'Travel' })
      .expect(201);
    const word = await request(app.getHttpServer())
      .post(`/api/v1/collections/${col.body.data.id}/words`)
      .set(bearer(u.accessToken))
      .send({
        term: 'itinerary',
        partOfSpeech: 'noun',
        definitionVi: 'lịch trình',
        cefrLevel: 'B1',
      })
      .expect(201);
    const id: string = word.body.data.id;

    const done = await waitFor(async () => {
      const v = await prisma.vocabulary.findUnique({ where: { id } });
      return v?.audioUkUrl && v.audioUsUrl ? v : null;
    });
    expect(done.audioUkUrl).toMatch(
      new RegExp(`/uploads/audio/${id}-uk\\.mp3$`),
    );
    expect(done.audioUsUrl).toMatch(
      new RegExp(`/uploads/audio/${id}-us\\.mp3$`),
    );
    const file = await request(app.getHttpServer())
      .get(new URL(done.audioUkUrl!).pathname)
      .expect(200);
    expect(file.headers['content-type']).toContain('audio/mpeg');
  });
});
