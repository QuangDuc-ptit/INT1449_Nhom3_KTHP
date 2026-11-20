import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { seedCollection } from './utils/fixtures';

/** Client di động hay gửi null cho trường "không đổi": phải là 400, không bao giờ 500. */
describe('Gửi null cho trường không được null (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let u: RegisteredUser;
  let collectionId: string;
  let wordId: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
    u = await registerUser(app);
    const seeded = await seedCollection(prisma, u.user.id, 'A', [
      { term: 'coherent' },
    ]);
    collectionId = seeded.collectionId;
    wordId = seeded.ids.coherent;
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  it.each([
    ['PATCH', '/collections/:col', { title: null }],
    ['PATCH', '/collections/:col', { category: null }],
    ['PUT', '/vocabularies/:word', { term: null }],
    ['PUT', '/vocabularies/:word', { definitionVi: null }],
    ['PATCH', '/users/settings', { timezone: null }],
    ['PATCH', '/users/settings', { dailyGoalWords: null }],
  ])('%s %s với %j trả 400 VALIDATION_ERROR', async (method, path, body) => {
    const url =
      '/api/v1' + path.replace(':col', collectionId).replace(':word', wordId);
    const req = method === 'PATCH' ? http().patch(url) : http().put(url);
    const res = await req.set(bearer(u.accessToken)).send(body).expect(400);
    expect(res.body).toMatchObject({
      success: false,
      errorCode: 'VALIDATION_ERROR',
    });
  });

  it('null cho trường được phép null (mô tả học phần) thì xoá giá trị', async () => {
    await prisma.collection.update({
      where: { id: collectionId },
      data: { description: 'cũ' },
    });
    const res = await http()
      .patch(`/api/v1/collections/${collectionId}`)
      .set(bearer(u.accessToken))
      .send({ description: null })
      .expect(200);
    expect(res.body.data.description).toBeNull();
  });
});
