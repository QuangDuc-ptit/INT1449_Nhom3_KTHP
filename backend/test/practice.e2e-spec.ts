import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { TestClock, createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { seedCollection } from './utils/fixtures';

const NOW = new Date('2026-11-19T10:00:00.000Z');
const hoursFromNow = (h: number) => new Date(NOW.getTime() + h * 3600_000);

interface Question {
  vocabularyId: string;
  prompt: {
    term?: string;
    ipa?: string;
    audioUrl?: string;
    definitionVi?: string;
  };
  options?: { vocabularyId: string; text: string }[];
  answer: string;
}

describe('Luyện tập: câu hỏi, hàng đợi ôn tập (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const clock = new TestClock(NOW);
  let u: RegisteredUser;
  let collectionId: string;
  let ids: Record<string, string>;

  beforeAll(async () => {
    app = await createTestApp({ clock });
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    clock.set(NOW);
    await resetDb(prisma);
    await resetRedis(app);
    u = await registerUser(app);
    ({ collectionId, ids } = await seedCollection(prisma, u.user.id, 'IELTS', [
      {
        term: 'due1',
        partOfSpeech: 'adj',
        progress: { status: 'review', nextReviewAt: hoursFromNow(-48) },
      },
      {
        term: 'due2',
        partOfSpeech: 'adj',
        progress: { status: 'learning', nextReviewAt: hoursFromNow(-1) },
      },
      { term: 'new1', partOfSpeech: 'adj' },
      { term: 'new2', partOfSpeech: 'verb' },
      {
        term: 'later1',
        partOfSpeech: 'noun',
        progress: { status: 'review', nextReviewAt: hoursFromNow(24) },
      },
      {
        term: 'later2',
        partOfSpeech: 'noun',
        progress: { status: 'review', nextReviewAt: hoursFromNow(72) },
      },
    ]));
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());
  const questions = (query: Record<string, unknown>, token = u.accessToken) =>
    http().get('/api/v1/practice/questions').query(query).set(bearer(token));

  it('choose_meaning: 4 câu, mỗi câu 4 phương án khác nhau, answer nằm trong phương án', async () => {
    const res = await questions({
      collectionId,
      mode: 'choose_meaning',
      limit: 4,
    }).expect(200);
    expect(res.body.data.mode).toBe('choose_meaning');
    const qs: Question[] = res.body.data.questions;
    expect(qs).toHaveLength(4);
    for (const q of qs) {
      expect(q.options).toHaveLength(4);
      const texts = q.options!.map((o) => o.text);
      expect(new Set(texts).size).toBe(4);
      expect(texts).toContain(q.answer);
      const correct = q.options!.find((o) => o.text === q.answer)!;
      expect(correct.vocabularyId).toBe(q.vocabularyId);
      expect(q.prompt.term).toEqual(expect.any(String));
      expect(q.prompt.definitionVi).toBeUndefined();
    }
  });

  it('ưu tiên từ đến hạn, rồi từ mới', async () => {
    const res = await questions({
      collectionId,
      mode: 'choose_meaning',
      limit: 4,
    }).expect(200);
    const got = res.body.data.questions.map((q: Question) => q.vocabularyId);
    expect(new Set(got)).toEqual(
      new Set([ids.due1, ids.due2, ids.new1, ids.new2]),
    );
  });

  it('listen_type: không có phương án, không lộ term, có audio và IPA', async () => {
    const res = await questions({
      collectionId,
      mode: 'listen_type',
      limit: 2,
    }).expect(200);
    for (const q of res.body.data.questions as Question[]) {
      expect(q.options).toBeUndefined();
      expect(q.prompt.term).toBeUndefined();
      expect(q.prompt.audioUrl).toMatch(/^https:\/\/cdn\.test\//);
      expect(q.prompt.ipa).toEqual(expect.any(String));
    }
  });

  it('type_meaning: đề là nghĩa tiếng Việt, đáp án là term', async () => {
    const res = await questions({
      collectionId,
      mode: 'type_meaning',
      limit: 1,
    }).expect(200);
    const q: Question = res.body.data.questions[0];
    expect(q.prompt).toEqual({ definitionVi: `nghĩa của ${q.answer}` });
  });

  it('không truyền collectionId: chỉ lấy từ đến hạn trên mọi học phần', async () => {
    const res = await questions({ mode: 'listen_choose' }).expect(200);
    const got = res.body.data.questions.map((q: Question) => q.vocabularyId);
    expect(new Set(got)).toEqual(new Set([ids.due1, ids.due2]));
  });

  it('học phần rỗng trả danh sách câu hỏi rỗng', async () => {
    const empty = await prisma.collection.create({
      data: { userId: u.user.id, title: 'Rỗng' },
    });
    const res = await questions({
      collectionId: empty.id,
      mode: 'listen_choose',
    }).expect(200);
    expect(res.body.data.questions).toEqual([]);
  });

  it('collectionId của người khác trả 404; mode sai hoặc limit sai trả 400', async () => {
    const other = await registerUser(app);
    await questions(
      { collectionId, mode: 'listen_choose' },
      other.accessToken,
    ).expect(404);
    await questions({ collectionId, mode: 'foo' }).expect(400);
    await questions({ collectionId, mode: 'listen_choose', limit: 0 }).expect(
      400,
    );
  });

  it('GET /practice/due trả đúng các từ đến hạn, sớm nhất trước', async () => {
    const res = await http()
      .get('/api/v1/practice/due')
      .set(bearer(u.accessToken))
      .expect(200);
    expect(res.body.data.dueCount).toBe(2);
    expect(res.body.data.words.map((w: { id: string }) => w.id)).toEqual([
      ids.due1,
      ids.due2,
    ]);
  });

  it('GET /practice/retry-missed với session của người khác trả 404', async () => {
    const other = await registerUser(app);
    const session = await prisma.quizSession.create({
      data: {
        userId: other.user.id,
        mode: 'listen_type',
        totalQuestions: 1,
        correctCount: 0,
        incorrectCount: 1,
        scorePercentage: 0,
        durationSeconds: 10,
      },
    });
    const res = await http()
      .get('/api/v1/practice/retry-missed')
      .query({ sessionId: session.id })
      .set(bearer(u.accessToken))
      .expect(404);
    expect(res.body.errorCode).toBe('SESSION_NOT_FOUND');
  });

  it('GET /practice/retry-missed trả câu hỏi cho các từ bị sai trong phiên', async () => {
    const session = await prisma.quizSession.create({
      data: {
        userId: u.user.id,
        collectionId,
        mode: 'listen_choose',
        totalQuestions: 3,
        correctCount: 1,
        incorrectCount: 2,
        scorePercentage: 33,
        durationSeconds: 30,
        answers: {
          create: [
            {
              vocabularyId: ids.new1,
              userAnswer: 'x',
              isCorrect: false,
              responseTimeMs: 1,
            },
            {
              vocabularyId: ids.new1,
              userAnswer: 'y',
              isCorrect: false,
              responseTimeMs: 1,
            },
            {
              vocabularyId: ids.later1,
              userAnswer: 'z',
              isCorrect: false,
              responseTimeMs: 1,
            },
            {
              vocabularyId: ids.due1,
              userAnswer: 'due1',
              isCorrect: true,
              responseTimeMs: 1,
            },
          ],
        },
      },
    });
    const res = await http()
      .get('/api/v1/practice/retry-missed')
      .query({ sessionId: session.id })
      .set(bearer(u.accessToken))
      .expect(200);
    expect(res.body.data.mode).toBe('listen_choose');
    const got = res.body.data.questions.map((q: Question) => q.vocabularyId);
    expect(got.sort()).toEqual([ids.new1, ids.later1].sort());
  });
});
