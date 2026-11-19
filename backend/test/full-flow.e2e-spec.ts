import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { PrismaService } from '../src/infra/prisma/prisma.service';
import { TestClock, createTestApp } from './utils/app';
import { bearer } from './utils/auth';
import { resetDb, resetRedis } from './utils/db';

describe('Toàn luồng: Auth → AI → Quiz → SM-2 → Streak → Sync (e2e)', () => {
  let app: INestApplication;
  const clock = new TestClock(new Date('2026-11-19T10:00:00.000Z'));

  beforeAll(async () => {
    app = await createTestApp({ clock });
    await resetDb(app.get(PrismaService));
    await resetRedis(app);
  });

  afterAll(async () => {
    await app.close();
  });

  it('người học mới đi hết một vòng học tập', async () => {
    const http = () => request(app.getHttpServer());

    // 1. Đăng ký
    const reg = await http()
      .post('/api/v1/auth/register')
      .send({
        email: 'flow@example.com',
        password: 'Password123',
        fullName: 'Người Học',
      })
      .expect(201);
    const auth = bearer(reg.body.data.accessToken);

    // 2. Tạo học phần
    const col = await http()
      .post('/api/v1/collections')
      .set(auth)
      .send({ title: 'Năng lượng xanh', category: 'academic' })
      .expect(201);
    const collectionId: string = col.body.data.id;

    // 3. AI sinh 5 từ
    const gen = await http()
      .post('/api/v1/ai/generate-vocab')
      .set(auth)
      .send({
        topic: 'Green energy',
        cefrLevel: 'B2',
        wordCount: 5,
        collectionId,
      })
      .expect(200);
    expect(gen.body.data.words).toHaveLength(5);

    // 4. Lưu cả 5 từ
    const saved = await http()
      .post('/api/v1/vocabularies/batch-save')
      .set(auth)
      .send({
        collectionId,
        words: gen.body.data.words.map((w: Record<string, unknown>) => {
          const word = { ...w };
          delete word.existsInCollection;
          return word;
        }),
      })
      .expect(201);
    expect(saved.body.data.savedCount).toBe(5);

    // 5. Lấy câu hỏi chọn nghĩa
    const qs = await http()
      .get('/api/v1/practice/questions')
      .query({ collectionId, mode: 'choose_meaning', limit: 10 })
      .set(auth)
      .expect(200);
    const questions = qs.body.data.questions as {
      vocabularyId: string;
      answer: string;
      options: unknown[];
    }[];
    expect(questions).toHaveLength(5);
    expect(questions.every((q) => q.options.length === 4)).toBe(true);

    // 6. Nộp bài, trả lời đúng hết
    const submit = await http()
      .post('/api/v1/practice/submit-session')
      .set(auth)
      .send({
        clientSessionId: randomUUID(),
        collectionId,
        mode: 'choose_meaning',
        durationSeconds: 90,
        answers: questions.map((q) => ({
          vocabularyId: q.vocabularyId,
          userAnswer: q.answer,
          responseTimeMs: 1500,
        })),
      })
      .expect(200);
    expect(submit.body.data).toMatchObject({
      correctCount: 5,
      scorePercentage: 100,
      streak: { currentStreak: 1, isStreakActiveToday: true },
    });

    // 7. Dashboard
    const dash = await http()
      .get('/api/v1/home/dashboard')
      .set(auth)
      .expect(200);
    expect(dash.body.data.dailyGoal.wordsLearnedToday).toBe(5);
    expect(dash.body.data.streak.currentStreak).toBe(1);
    expect(dash.body.data.reviewReminder.dueWordsCount).toBe(0);

    // 8. Hồ sơ
    const profile = await http()
      .get('/api/v1/users/profile')
      .set(auth)
      .expect(200);
    expect(profile.body.data.stats.learnedWords).toBe(5);

    // 9. Đồng bộ offline: 5 progress ở trạng thái review
    const sync = await http().get('/api/v1/sync/delta').set(auth).expect(200);
    expect(sync.body.data.progress).toHaveLength(5);
    expect(
      sync.body.data.progress.every(
        (p: { status: string }) => p.status === 'review',
      ),
    ).toBe(true);

    // Ngày hôm sau: các từ đến hạn ôn
    clock.set('2026-11-20T11:00:00.000Z');
    const due = await http().get('/api/v1/practice/due').set(auth).expect(200);
    expect(due.body.data.dueCount).toBe(5);

    // 10. Đăng xuất: access token cũ hết hiệu lực
    await http()
      .post('/api/v1/auth/logout')
      .set(auth)
      .send({ refreshToken: reg.body.data.refreshToken })
      .expect(200);
    await http().get('/api/v1/auth/me').set(auth).expect(401);
  });
});
