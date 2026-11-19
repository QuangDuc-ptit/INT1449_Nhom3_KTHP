import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe('Đồng bộ offline GET /sync/delta (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let a: RegisteredUser;
  let b: RegisteredUser;
  let keepCol: string;
  let dropCol: string;
  let wordKeep: string;
  let wordOther: string;
  let wordDropped: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
    a = await registerUser(app);
    b = await registerUser(app);
    const mkCol = async (u: RegisteredUser, title: string) =>
      (
        await http()
          .post('/api/v1/collections')
          .set(bearer(u.accessToken))
          .send({ title })
          .expect(201)
      ).body.data.id as string;
    const mkWord = async (u: RegisteredUser, colId: string, term: string) =>
      (
        await http()
          .post(`/api/v1/collections/${colId}/words`)
          .set(bearer(u.accessToken))
          .send({
            term,
            partOfSpeech: 'noun',
            definitionVi: term,
            cefrLevel: 'A2',
          })
          .expect(201)
      ).body.data.id as string;
    keepCol = await mkCol(a, 'Giữ lại');
    dropCol = await mkCol(a, 'Sẽ xoá');
    wordKeep = await mkWord(a, keepCol, 'souvenir');
    wordOther = await mkWord(a, keepCol, 'explore');
    wordDropped = await mkWord(a, dropCol, 'destination');
    const bCol = await mkCol(b, 'Của B');
    await mkWord(b, bCol, 'ambitious');
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());
  const delta = (u: RegisteredUser, since?: string) =>
    http()
      .get('/api/v1/sync/delta')
      .query(since ? { since } : {})
      .set(bearer(u.accessToken));

  it('không có since: trả toàn bộ dữ liệu của user, deleted rỗng', async () => {
    const res = await delta(a).expect(200);
    const d = res.body.data;
    expect(d.serverTime).toEqual(expect.any(String));
    expect(d.collections).toHaveLength(2);
    expect(d.vocabularies).toHaveLength(3);
    expect(d.progress).toHaveLength(3);
    expect(d.progress[0]).toEqual(
      expect.objectContaining({
        vocabularyId: expect.any(String),
        status: 'new',
        repetitionLevel: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        nextReviewAt: null,
        lastReviewedAt: null,
      }),
    );
    expect(d.deleted).toEqual([]);
  });

  it('có since: chỉ trả phần thay đổi sau mốc đó, kèm tombstone', async () => {
    const t0: string = (await delta(a).expect(200)).body.data.serverTime;
    await sleep(20);

    await http()
      .put(`/api/v1/vocabularies/${wordKeep}`)
      .set(bearer(a.accessToken))
      .send({ definitionVi: 'quà kỷ niệm' })
      .expect(200);
    await http()
      .delete(`/api/v1/collections/${dropCol}`)
      .set(bearer(a.accessToken))
      .expect(200);
    await prisma.userVocabProgress.update({
      where: {
        userId_vocabularyId: { userId: a.user.id, vocabularyId: wordOther },
      },
      data: { status: 'review', repetitionLevel: 1 },
    });

    const d = (await delta(a, t0).expect(200)).body.data;
    expect(d.vocabularies.map((v: { id: string }) => v.id)).toEqual([wordKeep]);
    expect(d.vocabularies[0].definitionVi).toBe('quà kỷ niệm');
    expect(d.collections).toEqual([]);
    expect(
      d.progress.map((p: { vocabularyId: string }) => p.vocabularyId),
    ).toEqual([wordOther]);
    expect(
      d.deleted
        .map((x: { entityType: string; entityId: string }) => [
          x.entityType,
          x.entityId,
        ])
        .sort(),
    ).toEqual(
      [
        ['collection', dropCol],
        ['vocabulary', wordDropped],
      ].sort(),
    );
    expect(new Date(d.serverTime).getTime()).toBeGreaterThan(
      new Date(t0).getTime(),
    );
  });

  it('không lẫn dữ liệu của user khác', async () => {
    const d = (await delta(b).expect(200)).body.data;
    expect(d.collections).toHaveLength(1);
    expect(d.collections[0].title).toBe('Của B');
    expect(d.vocabularies.map((v: { term: string }) => v.term)).toEqual([
      'ambitious',
    ]);
    await http()
      .delete(`/api/v1/collections/${dropCol}`)
      .set(bearer(a.accessToken))
      .expect(200);
    const after = (await delta(b, '2000-01-01T00:00:00.000Z').expect(200)).body
      .data;
    expect(after.deleted).toEqual([]);
  });

  it('since không hợp lệ trả 400', async () => {
    await delta(a, 'hôm qua').expect(400);
  });
});
