import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { TestClock, createTestApp } from './utils/app';
import { RegisteredUser, bearer, registerUser } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';
import { seedCollection } from './utils/fixtures';

const NOW = new Date('2026-11-19T10:00:00.000Z'); // 17:00 giờ VN

describe('Dashboard trang chủ (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const clock = new TestClock(NOW);
  let u: RegisteredUser;

  beforeAll(async () => {
    app = await createTestApp({ clock });
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    clock.set(NOW);
    await resetDb(prisma);
    await resetRedis(app);
    u = await registerUser(app);
  });

  afterAll(async () => {
    await app.close();
  });

  const dashboard = () =>
    request(app.getHttpServer())
      .get('/api/v1/home/dashboard')
      .set(bearer(u.accessToken))
      .expect(200);

  const submitCorrect = async (
    collectionId: string,
    terms: string[],
    ids: Record<string, string>,
  ) =>
    request(app.getHttpServer())
      .post('/api/v1/practice/submit-session')
      .set(bearer(u.accessToken))
      .send({
        collectionId,
        mode: 'listen_type',
        durationSeconds: 60,
        answers: terms.map((t) => ({
          vocabularyId: ids[t],
          userAnswer: t,
          responseTimeMs: 1000,
        })),
      })
      .expect(200);

  it('user mới: mọi chỉ số bằng 0', async () => {
    const res = await dashboard();
    expect(res.body.data).toEqual({
      streak: {
        currentStreak: 0,
        highestStreak: 0,
        isStreakActiveToday: false,
      },
      dailyGoal: {
        targetWords: 10,
        wordsLearnedToday: 0,
        progressPercentage: 0,
      },
      reviewReminder: { hasPendingReview: false, dueWordsCount: 0 },
      quickCollections: [],
    });
  });

  it('học 7 từ đúng hôm nay: 70% mục tiêu, streak đang hoạt động', async () => {
    const terms = Array.from({ length: 8 }, (_, i) => `word${i}`);
    const { collectionId, ids } = await seedCollection(
      prisma,
      u.user.id,
      'IELTS',
      terms.map((term) => ({ term })),
    );
    // 7 từ đúng, cộng thêm 1 câu sai và 1 câu lặp lại cùng từ
    await submitCorrect(collectionId, terms.slice(0, 7), ids);
    await request(app.getHttpServer())
      .post('/api/v1/practice/submit-session')
      .set(bearer(u.accessToken))
      .send({
        mode: 'listen_type',
        durationSeconds: 5,
        answers: [
          { vocabularyId: ids.word7, userAnswer: 'xxx', responseTimeMs: 1 },
          { vocabularyId: ids.word0, userAnswer: 'word0', responseTimeMs: 1 },
        ],
      })
      .expect(200);

    const res = await dashboard();
    expect(res.body.data.dailyGoal).toEqual({
      targetWords: 10,
      wordsLearnedToday: 7,
      progressPercentage: 70,
    });
    expect(res.body.data.streak).toEqual({
      currentStreak: 1,
      highestStreak: 1,
      isStreakActiveToday: true,
    });
  });

  it('câu đúng lúc 23:30 hôm qua (giờ VN) không tính vào hôm nay', async () => {
    const { collectionId, ids } = await seedCollection(prisma, u.user.id, 'A', [
      { term: 'alpha' },
      { term: 'beta' },
    ]);
    clock.set('2026-11-18T16:30:00.000Z'); // 23:30 ngày 18 giờ VN
    await submitCorrect(collectionId, ['alpha'], ids);
    clock.set('2026-11-18T17:30:00.000Z'); // 00:30 ngày 19 giờ VN
    await submitCorrect(collectionId, ['beta'], ids);
    clock.set(NOW);
    const res = await dashboard();
    expect(res.body.data.dailyGoal.wordsLearnedToday).toBe(1);
  });

  it('vượt mục tiêu thì tiến độ dừng ở 100%', async () => {
    const terms = Array.from({ length: 12 }, (_, i) => `w${i}`);
    const { collectionId, ids } = await seedCollection(
      prisma,
      u.user.id,
      'Big',
      terms.map((term) => ({ term })),
    );
    await submitCorrect(collectionId, terms, ids);
    const res = await dashboard();
    expect(res.body.data.dailyGoal).toMatchObject({
      wordsLearnedToday: 12,
      progressPercentage: 100,
    });
  });

  it('nhắc ôn tập đếm từ đến hạn; quickCollections là 3 học phần mới cập nhật nhất', async () => {
    await seedCollection(prisma, u.user.id, 'Cũ', [
      {
        term: 'due',
        progress: {
          status: 'review',
          nextReviewAt: new Date('2026-11-19T09:00:00.000Z'),
        },
      },
      {
        term: 'notyet',
        progress: {
          status: 'review',
          nextReviewAt: new Date('2026-11-20T09:00:00.000Z'),
        },
      },
    ]);
    for (const t of ['B', 'C', 'D']) {
      await new Promise((r) => setTimeout(r, 5));
      await seedCollection(prisma, u.user.id, t, []);
    }
    const res = await dashboard();
    expect(res.body.data.reviewReminder).toEqual({
      hasPendingReview: true,
      dueWordsCount: 1,
    });
    expect(
      res.body.data.quickCollections.map((c: { title: string }) => c.title),
    ).toEqual(['D', 'C', 'B']);
  });
});
