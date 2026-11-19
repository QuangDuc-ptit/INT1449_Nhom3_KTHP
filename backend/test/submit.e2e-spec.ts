import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { TestClock, createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { seedCollection } from './utils/fixtures';

const NOW = new Date('2026-11-19T10:00:00.000Z');

describe('Nộp bài luyện tập (e2e)', () => {
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
      { term: 'coherent', definitionVi: 'mạch lạc' },
      { term: 'mitigate', definitionVi: 'giảm nhẹ' },
      { term: 'souvenir', definitionVi: 'quà lưu niệm' },
    ]));
  });

  afterAll(async () => {
    await app.close();
  });

  const submit = (body: Record<string, unknown>, token = u.accessToken) =>
    request(app.getHttpServer())
      .post('/api/v1/practice/submit-session')
      .set(bearer(token))
      .send(body);

  const progressOf = (term: string) =>
    prisma.userVocabProgress.findUniqueOrThrow({
      where: {
        userId_vocabularyId: { userId: u.user.id, vocabularyId: ids[term] },
      },
    });

  const baseBody = (answers: Record<string, unknown>[]) => ({
    collectionId,
    mode: 'listen_type',
    durationSeconds: 45,
    answers,
  });

  it('server tự chấm (bỏ qua isCorrect của client), lưu phiên, cập nhật SM-2 và streak', async () => {
    const res = await submit(
      baseBody([
        {
          vocabularyId: ids.coherent,
          userAnswer: ' Coherant ',
          isCorrect: false,
          responseTimeMs: 2300,
        },
        {
          vocabularyId: ids.mitigate,
          userAnswer: 'wrong',
          isCorrect: true,
          responseTimeMs: 4100,
        },
      ]),
    ).expect(200);

    expect(res.body.data).toMatchObject({
      totalQuestions: 2,
      correctCount: 1,
      incorrectCount: 1,
      scorePercentage: 50,
      durationSeconds: 45,
      streak: { currentStreak: 1, highestStreak: 1, isStreakActiveToday: true },
      newBadges: [],
      answers: [
        {
          vocabularyId: ids.coherent,
          isCorrect: true,
          correctAnswer: 'coherent',
        },
        {
          vocabularyId: ids.mitigate,
          isCorrect: false,
          correctAnswer: 'mitigate',
        },
      ],
    });
    expect(res.body.data.sessionId).toEqual(expect.any(String));
    expect(await prisma.quizSession.count()).toBe(1);
    expect(await prisma.quizAnswer.count()).toBe(2);

    const ok = await progressOf('coherent');
    expect(ok).toMatchObject({
      repetitionLevel: 1,
      status: 'review',
      intervalDays: 1,
      reviewCount: 1,
      correctCount: 1,
      incorrectCount: 0,
    });
    expect(ok.nextReviewAt).toEqual(new Date('2026-11-20T10:00:00.000Z'));
    expect(ok.lastReviewedAt).toEqual(NOW);
    const bad = await progressOf('mitigate');
    expect(bad).toMatchObject({
      status: 'learning',
      repetitionLevel: 0,
      incorrectCount: 1,
    });
    expect(bad.easeFactor).toBeCloseTo(2.3, 9);
  });

  it('gửi lại cùng clientSessionId trả kết quả cũ, không chấm hay cập nhật lần hai', async () => {
    const clientSessionId = randomUUID();
    const body = {
      ...baseBody([
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1000,
        },
      ]),
      clientSessionId,
    };
    const first = await submit(body).expect(200);
    const second = await submit(body).expect(200);
    expect(second.body.data.sessionId).toBe(first.body.data.sessionId);
    expect(second.body.data).toMatchObject({
      correctCount: 1,
      scorePercentage: 100,
      answers: [{ vocabularyId: ids.coherent, isCorrect: true }],
    });
    expect(await prisma.quizSession.count()).toBe(1);
    expect((await progressOf('coherent')).reviewCount).toBe(1);
  });

  it('từ của user khác trả 404, không ghi gì vào DB', async () => {
    const other = await registerUser(app);
    const foreign = await seedCollection(prisma, other.user.id, 'B', [
      { term: 'secret' },
    ]);
    const res = await submit({
      mode: 'listen_type',
      durationSeconds: 10,
      answers: [
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1,
        },
        {
          vocabularyId: foreign.ids.secret,
          userAnswer: 'secret',
          responseTimeMs: 1,
        },
      ],
    }).expect(404);
    expect(res.body.errorCode).toBe('VOCABULARY_NOT_FOUND');
    expect(await prisma.quizSession.count()).toBe(0);
    expect((await progressOf('coherent')).reviewCount).toBe(0);
    const user = await prisma.user.findUniqueOrThrow({
      where: { id: u.user.id },
    });
    expect(user.currentStreak).toBe(0);
  });

  it('cùng một từ trả lời sai rồi đúng: SM-2 chạy theo thứ tự, kết quả level 1', async () => {
    await submit(
      baseBody([
        { vocabularyId: ids.coherent, userAnswer: 'xyz', responseTimeMs: 1 },
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1,
        },
      ]),
    ).expect(200);
    const p = await progressOf('coherent');
    expect(p).toMatchObject({
      repetitionLevel: 1,
      status: 'review',
      reviewCount: 2,
      correctCount: 1,
      incorrectCount: 1,
    });
  });

  it('streak theo múi giờ VN: 23:30 rồi 00:30 hôm sau thì streak 1 rồi 2', async () => {
    const body = baseBody([
      { vocabularyId: ids.souvenir, userAnswer: 'souvenir', responseTimeMs: 1 },
    ]);
    clock.set('2026-11-19T16:30:00.000Z'); // 23:30 ngày 19 giờ VN
    const first = await submit(body).expect(200);
    expect(first.body.data.streak.currentStreak).toBe(1);
    clock.set('2026-11-19T17:30:00.000Z'); // 00:30 ngày 20 giờ VN
    const second = await submit(body).expect(200);
    expect(second.body.data.streak).toEqual({
      currentStreak: 2,
      highestStreak: 2,
      isStreakActiveToday: true,
    });
    clock.set('2026-11-20T03:00:00.000Z'); // vẫn ngày 20 giờ VN
    const third = await submit(body).expect(200);
    expect(third.body.data.streak.currentStreak).toBe(2);
  });

  it.each([
    [{ answers: [] }],
    [{ mode: 'foo' }],
    [{ durationSeconds: -1 }],
    [{ clientSessionId: 'abc' }],
  ])('dữ liệu không hợp lệ %j trả 400', async (patch) => {
    await submit({
      ...baseBody([
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1,
        },
      ]),
      ...patch,
    }).expect(400);
  });

  it('collectionId của người khác trả 404', async () => {
    const other = await registerUser(app);
    const foreign = await seedCollection(prisma, other.user.id, 'B', []);
    await submit({
      ...baseBody([
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1,
        },
      ]),
      collectionId: foreign.collectionId,
    }).expect(404);
  });
});
