import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Học phần (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let a: RegisteredUser;
  let b: RegisteredUser;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
    a = await registerUser(app);
    b = await registerUser(app);
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  const create = (user: RegisteredUser, body: Record<string, unknown>) =>
    http().post('/api/v1/collections').set(bearer(user.accessToken)).send(body);

  it('tạo học phần mới với totalWords = 0', async () => {
    const res = await create(a, {
      title: '  IELTS Core ',
      category: 'academic',
      iconName: 'book',
    }).expect(201);
    expect(res.body.data).toMatchObject({
      title: 'IELTS Core',
      category: 'academic',
      iconName: 'book',
      isPublic: false,
      totalWords: 0,
    });
    expect(res.body.data.id).toEqual(expect.any(String));
  });

  it('title rỗng, quá 100 ký tự hoặc category sai trả 400', async () => {
    await create(a, { title: '   ' }).expect(400);
    await create(a, { title: 'x'.repeat(101) }).expect(400);
    await create(a, { title: 'OK', category: 'sports' }).expect(400);
  });

  it('không có token trả 401', async () => {
    await http().get('/api/v1/collections').expect(401);
  });

  describe('GET /collections', () => {
    beforeEach(async () => {
      await create(a, {
        title: 'IELTS Core',
        description: 'Từ vựng học thuật',
        category: 'academic',
      });
      await create(a, {
        title: 'Du lịch',
        description: 'Sân bay, khách sạn và IELTS speaking',
        category: 'travel',
      });
      await create(b, { title: 'IELTS của B', category: 'academic' });
    });

    it('chỉ trả học phần của chính user, kèm meta phân trang', async () => {
      const res = await http()
        .get('/api/v1/collections')
        .set(bearer(a.accessToken))
        .expect(200);
      expect(res.body.data.items).toHaveLength(2);
      expect(res.body.data.meta).toEqual({
        page: 1,
        limit: 20,
        total: 2,
        totalPages: 1,
      });
    });

    it('search không phân biệt hoa thường, tìm cả title và description', async () => {
      const res = await http()
        .get('/api/v1/collections?search=ielts')
        .set(bearer(a.accessToken))
        .expect(200);
      expect(
        res.body.data.items.map((c: { title: string }) => c.title).sort(),
      ).toEqual(['Du lịch', 'IELTS Core']);
    });

    it('lọc theo category', async () => {
      const res = await http()
        .get('/api/v1/collections?category=travel')
        .set(bearer(a.accessToken))
        .expect(200);
      expect(res.body.data.items).toHaveLength(1);
      expect(res.body.data.items[0].category).toBe('travel');
    });

    it('phân trang page=2&limit=1', async () => {
      const res = await http()
        .get('/api/v1/collections?page=2&limit=1')
        .set(bearer(a.accessToken))
        .expect(200);
      expect(res.body.data.items).toHaveLength(1);
      expect(res.body.data.meta).toEqual({
        page: 2,
        limit: 1,
        total: 2,
        totalPages: 2,
      });
    });

    it('limit=51 trả 400', async () => {
      await http()
        .get('/api/v1/collections?limit=51')
        .set(bearer(a.accessToken))
        .expect(400);
    });
  });

  describe('Một học phần', () => {
    let id: string;

    beforeEach(async () => {
      id = (await create(a, { title: 'Của A' })).body.data.id;
    });

    it('xem, sửa được học phần của mình', async () => {
      await http()
        .get(`/api/v1/collections/${id}`)
        .set(bearer(a.accessToken))
        .expect(200);
      const res = await http()
        .patch(`/api/v1/collections/${id}`)
        .set(bearer(a.accessToken))
        .send({ title: 'Đã đổi', category: 'life' })
        .expect(200);
      expect(res.body.data).toMatchObject({
        title: 'Đã đổi',
        category: 'life',
      });
    });

    it('user khác không xem, sửa, xoá được (404) và dữ liệu không đổi', async () => {
      for (const req of [
        http().get(`/api/v1/collections/${id}`),
        http().patch(`/api/v1/collections/${id}`).send({ title: 'Hack' }),
        http().delete(`/api/v1/collections/${id}`),
      ]) {
        const res = await req.set(bearer(b.accessToken)).expect(404);
        expect(res.body.errorCode).toBe('COLLECTION_NOT_FOUND');
      }
      const still = await prisma.collection.findUniqueOrThrow({
        where: { id },
      });
      expect(still.title).toBe('Của A');
    });

    it('id không phải uuid trả 400', async () => {
      await http()
        .get('/api/v1/collections/abc')
        .set(bearer(a.accessToken))
        .expect(400);
    });

    it('xoá học phần ghi tombstone cho học phần và từng từ của nó', async () => {
      const vocab = await prisma.vocabulary.create({
        data: {
          collectionId: id,
          term: 'souvenir',
          partOfSpeech: 'noun',
          definitionVi: 'quà lưu niệm',
          cefrLevel: 'A2',
        },
      });
      await http()
        .delete(`/api/v1/collections/${id}`)
        .set(bearer(a.accessToken))
        .expect(200);
      expect(await prisma.collection.count({ where: { id } })).toBe(0);
      const tombstones = await prisma.deletedRecord.findMany({
        where: { userId: a.user.id },
      });
      expect(tombstones.map((t) => [t.entityType, t.entityId]).sort()).toEqual(
        [
          ['collection', id],
          ['vocabulary', vocab.id],
        ].sort(),
      );
    });
  });
});
