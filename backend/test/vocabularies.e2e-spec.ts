import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { VocabulariesService } from '../src/modules/vocabularies/vocabularies.service';
import { createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { waitFor } from './utils/wait';

const COHERENT = {
  term: 'coherent',
  partOfSpeech: 'adj',
  definitionVi: 'mạch lạc, chặt chẽ',
  definitionEn: 'logical and consistent',
  exampleSentence: 'He proposed a coherent plan for reform.',
  cefrLevel: 'B2',
};

describe('Từ vựng (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let a: RegisteredUser;
  let b: RegisteredUser;
  let collectionId: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    await resetRedis(app);
    a = await registerUser(app);
    b = await registerUser(app);
    collectionId = (
      await request(app.getHttpServer())
        .post('/api/v1/collections')
        .set(bearer(a.accessToken))
        .send({ title: 'IELTS Core', category: 'academic' })
        .expect(201)
    ).body.data.id;
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());
  const addWord = (
    user: RegisteredUser,
    body: Record<string, unknown>,
    colId = collectionId,
  ) =>
    http()
      .post(`/api/v1/collections/${colId}/words`)
      .set(bearer(user.accessToken))
      .send(body);
  const totalWords = async () =>
    (await prisma.collection.findUniqueOrThrow({ where: { id: collectionId } }))
      .totalWords;

  describe('POST /collections/:id/words', () => {
    it('thêm từ, tăng totalWords và tạo progress trạng thái new', async () => {
      const res = await addWord(a, COHERENT).expect(201);
      expect(res.body.data).toMatchObject({
        term: 'coherent',
        partOfSpeech: 'adj',
        cefrLevel: 'B2',
        source: 'manual',
        progress: { status: 'new', repetitionLevel: 0, nextReviewAt: null },
      });
      expect(await totalWords()).toBe(1);
      const progress = await prisma.userVocabProgress.findMany({
        where: { userId: a.user.id },
      });
      expect(progress).toHaveLength(1);
      expect(progress[0].status).toBe('new');
    });

    it('trùng term trong học phần (không phân biệt hoa thường, khoảng trắng) trả 409', async () => {
      await addWord(a, COHERENT).expect(201);
      const res = await addWord(a, { ...COHERENT, term: '  Coherent ' }).expect(
        409,
      );
      expect(res.body.errorCode).toBe('VOCABULARY_EXISTS');
      expect(await totalWords()).toBe(1);
    });

    it('hai request thêm cùng một từ chạy song song: chỉ một từ được lưu', async () => {
      const results = await Promise.all(
        Array.from({ length: 5 }, (_, i) =>
          addWord(a, { ...COHERENT, term: i % 2 ? 'Coherent' : 'coherent' }),
        ),
      );
      const statuses = results.map((r) => r.status).sort();
      expect(statuses.filter((s) => s === 201)).toHaveLength(1);
      expect(statuses.filter((s) => s === 409)).toHaveLength(4);
      for (const r of results.filter((x) => x.status === 409)) {
        expect(r.body.errorCode).toBe('VOCABULARY_EXISTS');
      }
      expect(await prisma.vocabulary.count({ where: { collectionId } })).toBe(
        1,
      );
      expect(await totalWords()).toBe(1);
    });

    it('thiếu definitionVi hoặc cefrLevel sai trả 400', async () => {
      const noVi: Record<string, unknown> = { ...COHERENT };
      delete noVi.definitionVi;
      await addWord(a, noVi).expect(400);
      await addWord(a, { ...COHERENT, cefrLevel: 'D1' }).expect(400);
      await addWord(a, { ...COHERENT, partOfSpeech: 'pronoun' }).expect(400);
    });

    it('thêm vào học phần của người khác trả 404', async () => {
      const res = await addWord(b, COHERENT).expect(404);
      expect(res.body.errorCode).toBe('COLLECTION_NOT_FOUND');
    });
  });

  it('GET /collections/:id/words trả danh sách theo thứ tự thêm, kèm progress', async () => {
    await addWord(a, COHERENT).expect(201);
    await addWord(a, {
      term: 'mitigate',
      partOfSpeech: 'verb',
      definitionVi: 'giảm nhẹ',
      cefrLevel: 'C1',
    }).expect(201);
    const res = await http()
      .get(`/api/v1/collections/${collectionId}/words`)
      .set(bearer(a.accessToken))
      .expect(200);
    expect(res.body.data.map((w: { term: string }) => w.term)).toEqual([
      'coherent',
      'mitigate',
    ]);
    expect(res.body.data[0].progress.status).toBe('new');
    await http()
      .get(`/api/v1/collections/${collectionId}/words`)
      .set(bearer(b.accessToken))
      .expect(404);
  });

  describe('PUT/DELETE /vocabularies/:id', () => {
    let wordId: string;

    beforeEach(async () => {
      wordId = (await addWord(a, COHERENT).expect(201)).body.data.id;
    });

    it('sửa được definitionVi', async () => {
      const res = await http()
        .put(`/api/v1/vocabularies/${wordId}`)
        .set(bearer(a.accessToken))
        .send({ definitionVi: 'logic, nhất quán' })
        .expect(200);
      expect(res.body.data.definitionVi).toBe('logic, nhất quán');
      expect(res.body.data.term).toBe('coherent');
    });

    it('đổi term trùng với từ khác trong học phần trả 409', async () => {
      await addWord(a, {
        term: 'mitigate',
        partOfSpeech: 'verb',
        definitionVi: 'giảm nhẹ',
        cefrLevel: 'C1',
      }).expect(201);
      await http()
        .put(`/api/v1/vocabularies/${wordId}`)
        .set(bearer(a.accessToken))
        .send({ term: 'MITIGATE' })
        .expect(409);
    });

    it('xoá từ: xoá progress, giảm totalWords và ghi tombstone', async () => {
      await http()
        .delete(`/api/v1/vocabularies/${wordId}`)
        .set(bearer(a.accessToken))
        .expect(200);
      expect(await prisma.vocabulary.count()).toBe(0);
      expect(await prisma.userVocabProgress.count()).toBe(0);
      expect(await totalWords()).toBe(0);
      const t = await prisma.deletedRecord.findMany();
      expect(t).toHaveLength(1);
      expect(t[0]).toMatchObject({
        entityType: 'vocabulary',
        entityId: wordId,
      });
    });

    it('user khác không sửa, xoá được (404) và từ không đổi', async () => {
      await http()
        .put(`/api/v1/vocabularies/${wordId}`)
        .set(bearer(b.accessToken))
        .send({ definitionVi: 'hack' })
        .expect(404);
      await http()
        .delete(`/api/v1/vocabularies/${wordId}`)
        .set(bearer(b.accessToken))
        .expect(404);
      const w = await prisma.vocabulary.findUniqueOrThrow({
        where: { id: wordId },
      });
      expect(w.definitionVi).toBe(COHERENT.definitionVi);
    });
  });

  it('createBatch bỏ qua từ trùng (kể cả trùng trong cùng batch)', async () => {
    await addWord(a, {
      term: 'mitigate',
      partOfSpeech: 'verb',
      definitionVi: 'giảm nhẹ',
      cefrLevel: 'C1',
    }).expect(201);
    const service = app.get(VocabulariesService);
    const base = {
      partOfSpeech: 'adj' as const,
      definitionVi: 'x',
      cefrLevel: 'B2' as const,
    };
    const result = await service.createBatch(
      a.user.id,
      collectionId,
      [
        { ...base, term: 'coherent' },
        { ...base, term: 'COHERENT' },
        { ...base, term: 'mitigate' },
      ],
      'ai_generated',
    );
    expect(result.saved.map((v) => v.term)).toEqual(['coherent']);
    expect(result.saved[0].source).toBe('ai_generated');
    expect(result.skippedTerms).toEqual(['COHERENT', 'mitigate']);
    expect(await totalWords()).toBe(2);
    expect(await prisma.userVocabProgress.count()).toBe(2);
  });

  describe('POST /vocabularies/batch-save', () => {
    const aiWord = (term: string) => ({
      term,
      partOfSpeech: 'noun',
      ipa: `/${term}/`,
      definitionEn: `meaning of ${term}`,
      definitionVi: `nghĩa của ${term}`,
      exampleSentence: `I like ${term}.`,
      cefrLevel: 'B1',
    });
    const batchSave = (user: RegisteredUser, body: Record<string, unknown>) =>
      http()
        .post('/api/v1/vocabularies/batch-save')
        .set(bearer(user.accessToken))
        .send(body);

    it('lưu 3 từ AI trong một transaction, tạo progress và sinh audio', async () => {
      const res = await batchSave(a, {
        collectionId,
        words: ['solar', 'wind', 'turbine'].map(aiWord),
      }).expect(201);
      expect(res.body.data.savedCount).toBe(3);
      expect(res.body.data.skippedTerms).toEqual([]);
      expect(res.body.data.vocabularies).toHaveLength(3);
      expect(res.body.data.vocabularies[0]).toMatchObject({
        term: 'solar',
        source: 'ai_generated',
        ipaUk: '/solar/',
        progress: { status: 'new' },
      });
      expect(await totalWords()).toBe(3);
      expect(await prisma.userVocabProgress.count()).toBe(3);

      await waitFor(async () => {
        const n = await prisma.vocabulary.count({
          where: { collectionId, audioUkUrl: { not: null } },
        });
        return n === 3;
      });
    });

    it('bỏ qua từ đã có trong học phần và báo lại', async () => {
      await addWord(a, COHERENT).expect(201);
      const res = await batchSave(a, {
        collectionId,
        words: [aiWord('Coherent'), aiWord('solar')],
      }).expect(201);
      expect(res.body.data.savedCount).toBe(1);
      expect(res.body.data.skippedTerms).toEqual(['Coherent']);
    });

    it('một từ không hợp lệ thì trả 400 và không lưu từ nào', async () => {
      const { term: _t, ...noTerm } = aiWord('broken');
      void _t;
      await batchSave(a, {
        collectionId,
        words: [aiWord('solar'), noTerm],
      }).expect(400);
      expect(await prisma.vocabulary.count()).toBe(0);
      expect(await totalWords()).toBe(0);
    });

    it('danh sách rỗng hoặc quá 50 từ trả 400', async () => {
      await batchSave(a, { collectionId, words: [] }).expect(400);
      const many = Array.from({ length: 51 }, (_, i) => aiWord(`w${i}`));
      await batchSave(a, { collectionId, words: many }).expect(400);
    });

    it('học phần của người khác trả 404, không lưu gì', async () => {
      await batchSave(b, {
        collectionId,
        words: [aiWord('solar')],
      }).expect(404);
      expect(await prisma.vocabulary.count()).toBe(0);
    });
  });
});
