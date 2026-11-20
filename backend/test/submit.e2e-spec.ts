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

  it('học dồn: nộp 5 phiên liền trong một tối, từ chỉ lên level 1, không thành mastered', async () => {
    for (let i = 0; i < 5; i++) {
      clock.set(new Date(NOW.getTime() + i * 60_000));
      await submit(
        baseBody([
          {
            vocabularyId: ids.coherent,
            userAnswer: 'coherent',
            responseTimeMs: 1,
          },
        ]),
      ).expect(200);
    }
    const p = await progressOf('coherent');
    expect(p).toMatchObject({
      repetitionLevel: 1,
      status: 'review',
      intervalDays: 1,
      reviewCount: 5,
      correctCount: 5,
    });
    expect(p.nextReviewAt).toEqual(new Date('2026-11-20T10:00:00.000Z'));
  });

  it('nhiều phiên nộp song song (hai thiết bị) không ghi đè số lần ôn của nhau', async () => {
    const results = await Promise.all(
      Array.from({ length: 6 }, () =>
        submit(
          baseBody([
            {
              vocabularyId: ids.coherent,
              userAnswer: 'coherent',
              responseTimeMs: 1,
            },
          ]),
        ),
      ),
    );
    expect(results.map((r) => r.status)).toEqual(Array(6).fill(200));
    const p = await progressOf('coherent');
    expect(p.reviewCount).toBe(6);
    expect(p.correctCount).toBe(6);
    // Chống học dồn vẫn đúng khi song song: chỉ lên đúng 1 level
    expect(p.repetitionLevel).toBe(1);
  });

  it('ôn đúng hạn qua nhiều ngày thì vẫn lên level bình thường', async () => {
    const one = baseBody([
      { vocabularyId: ids.coherent, userAnswer: 'coherent', responseTimeMs: 1 },
    ]);
    await submit(one).expect(200); // level 1, hẹn sau 1 ngày
    clock.set('2026-11-20T10:00:00.000Z');
    await submit(one).expect(200); // đến hạn: level 2, hẹn sau 3 ngày
    const p = await progressOf('coherent');
    expect(p).toMatchObject({ repetitionLevel: 2, intervalDays: 3 });
  });

  it('cùng một từ trả lời sai rồi đúng trong một phiên: tính theo lần đầu (sai)', async () => {
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
      repetitionLevel: 0,
      status: 'learning',
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

  describe('Huy hiệu', () => {
    const one = () =>
      baseBody([
        {
          vocabularyId: ids.coherent,
          userAnswer: 'coherent',
          responseTimeMs: 1,
        },
      ]);

    it('đạt streak 7 ngày thì mở khoá streak_7 đúng một lần', async () => {
      await prisma.user.update({
        where: { id: u.user.id },
        data: {
          currentStreak: 6,
          highestStreak: 6,
          lastStreakDate: new Date('2026-11-18T00:00:00.000Z'),
        },
      });
      const first = await submit(one()).expect(200);
      expect(first.body.data.streak.currentStreak).toBe(7);
      expect(
        first.body.data.newBadges.map((b: { code: string }) => b.code),
      ).toEqual(['streak_7']);
      expect(first.body.data.newBadges[0]).toMatchObject({
        title: 'Chuỗi 7 Ngày',
        requiredPoints: 7,
      });

      const second = await submit(one()).expect(200);
      expect(second.body.data.newBadges).toEqual([]);
      expect(
        await prisma.userBadge.count({ where: { userId: u.user.id } }),
      ).toBe(1);
    });

    it('đủ 5 học phần thì mở khoá explorer_5 sau phiên học', async () => {
      for (let i = 0; i < 4; i++) {
        await prisma.collection.create({
          data: { userId: u.user.id, title: `C${i}` },
        });
      }
      const res = await submit(one()).expect(200);
      expect(
        res.body.data.newBadges.map((b: { code: string }) => b.code),
      ).toEqual(['explorer_5']);
    });

    it('hồ sơ hiển thị huy hiệu đã mở khoá', async () => {
      await prisma.user.update({
        where: { id: u.user.id },
        data: {
          currentStreak: 6,
          lastStreakDate: new Date('2026-11-18T00:00:00.000Z'),
        },
      });
      await submit(one()).expect(200);
      const profile = await request(app.getHttpServer())
        .get('/api/v1/users/profile')
        .set(bearer(u.accessToken))
        .expect(200);
      const streak7 = profile.body.data.badges.find(
        (b: { code: string }) => b.code === 'streak_7',
      );
      expect(streak7).toMatchObject({ unlocked: true, progress: 7 });
    });
  });
});
