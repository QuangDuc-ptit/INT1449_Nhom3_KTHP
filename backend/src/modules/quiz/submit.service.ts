import { Injectable } from '@nestjs/common';
import { Prisma, UserVocabProgress } from '@prisma/client';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsService } from '../collections/collections.service';
import { SrsState, applySession } from '../spaced-repetition/sm2';
import { StreakService, StreakSummary } from '../streak/streak.service';
import { vocabularyNotFound } from '../vocabularies/vocabularies.service';
import { BadgeDto, SessionResultDto, SubmitSessionDto } from './dto/submit.dto';
import { expectedAnswer, gradeAnswer } from './grading';

/** Móc mở rộng chạy cuối transaction nộp bài (huy hiệu gắn vào ở Task 19). */
export abstract class SessionCompletionHook {
  abstract onSessionCompleted(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<BadgeDto[]>;
}

const INITIAL: SrsState = {
  repetitionLevel: 0,
  easeFactor: 2.5,
  intervalDays: 0,
  status: 'new',
  nextReviewAt: null,
};

interface ProgressAcc {
  state: SrsState;
  reviewCount: number;
  correctCount: number;
  incorrectCount: number;
}

@Injectable()
export class SubmitService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly collections: CollectionsService,
    private readonly streak: StreakService,
    private readonly clock: Clock,
    private readonly hook: SessionCompletionHook,
  ) {}

  async submit(
    userId: string,
    dto: SubmitSessionDto,
  ): Promise<SessionResultDto> {
    if (dto.clientSessionId) {
      const existing = await this.findByClientId(userId, dto.clientSessionId);
      if (existing) return existing;
    }
    try {
      return await this.prisma.$transaction((tx) =>
        this.submitInTx(tx, userId, dto),
      );
    } catch (err) {
      // Hai request trùng clientSessionId chạy song song: request thua trả kết quả của request thắng
      if (
        dto.clientSessionId &&
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        const existing = await this.findByClientId(userId, dto.clientSessionId);
        if (existing) return existing;
      }
      throw err;
    }
  }

  private async submitInTx(
    tx: Prisma.TransactionClient,
    userId: string,
    dto: SubmitSessionDto,
  ): Promise<SessionResultDto> {
    const now = this.clock.now();
    if (dto.collectionId) {
      await this.collections.assertOwned(userId, dto.collectionId, tx);
    }

    const ids = [...new Set(dto.answers.map((a) => a.vocabularyId))];
    const vocabs = await tx.vocabulary.findMany({
      where: { id: { in: ids }, collection: { userId } },
      select: { id: true, term: true, definitionVi: true },
    });
    if (vocabs.length !== ids.length) throw vocabularyNotFound();
    const byId = new Map(vocabs.map((v) => [v.id, v]));

    const graded = dto.answers.map((a) => {
      const correctAnswer = expectedAnswer(dto.mode, byId.get(a.vocabularyId)!);
      return {
        ...a,
        correctAnswer,
        isCorrect: gradeAnswer(dto.mode, a.userAnswer, correctAnswer),
      };
    });
    const correctCount = graded.filter((g) => g.isCorrect).length;
    const total = graded.length;

    const session = await tx.quizSession.create({
      data: {
        userId,
        collectionId: dto.collectionId,
        clientSessionId: dto.clientSessionId,
        mode: dto.mode,
        totalQuestions: total,
        correctCount,
        incorrectCount: total - correctCount,
        scorePercentage: Math.round((correctCount / total) * 100),
        durationSeconds: dto.durationSeconds,
        completedAt: now,
      },
    });
    await tx.quizAnswer.createMany({
      // createdAt tăng dần theo thứ tự câu để dựng lại kết quả đúng thứ tự
      data: graded.map((g, i) => ({
        sessionId: session.id,
        vocabularyId: g.vocabularyId,
        userAnswer: g.userAnswer,
        isCorrect: g.isCorrect,
        responseTimeMs: g.responseTimeMs,
        createdAt: new Date(now.getTime() + i),
      })),
    });

    await this.updateProgress(tx, userId, graded, now);
    const streak = await this.streak.recordActivity(tx, userId, now);
    const newBadges = await this.hook.onSessionCompleted(tx, userId);

    return {
      sessionId: session.id,
      totalQuestions: session.totalQuestions,
      correctCount: session.correctCount,
      incorrectCount: session.incorrectCount,
      scorePercentage: session.scorePercentage,
      durationSeconds: session.durationSeconds,
      streak,
      newBadges,
      answers: graded.map((g) => ({
        vocabularyId: g.vocabularyId,
        isCorrect: g.isCorrect,
        correctAnswer: g.correctAnswer,
      })),
    };
  }

  /** Áp SM-2 một lần cho mỗi từ trong phiên (xem applySession), rồi ghi vào DB. */
  private async updateProgress(
    tx: Prisma.TransactionClient,
    userId: string,
    graded: { vocabularyId: string; isCorrect: boolean }[],
    now: Date,
  ): Promise<void> {
    const ids = [...new Set(graded.map((g) => g.vocabularyId))];
    const existing = await tx.userVocabProgress.findMany({
      where: { userId, vocabularyId: { in: ids } },
    });
    const acc = new Map<string, ProgressAcc>(
      existing.map((p: UserVocabProgress) => [
        p.vocabularyId,
        {
          state: {
            repetitionLevel: p.repetitionLevel,
            easeFactor: p.easeFactor,
            intervalDays: p.intervalDays,
            status: p.status,
            nextReviewAt: p.nextReviewAt,
          },
          reviewCount: p.reviewCount,
          correctCount: p.correctCount,
          incorrectCount: p.incorrectCount,
        },
      ]),
    );
    // Gom kết quả theo từ (giữ thứ tự), đếm mọi câu nhưng SM-2 chỉ chạy một lần mỗi từ
    const answersByWord = new Map<string, boolean[]>();
    for (const g of graded) {
      const cur = acc.get(g.vocabularyId) ?? {
        state: INITIAL,
        reviewCount: 0,
        correctCount: 0,
        incorrectCount: 0,
      };
      acc.set(g.vocabularyId, {
        state: cur.state,
        reviewCount: cur.reviewCount + 1,
        correctCount: cur.correctCount + (g.isCorrect ? 1 : 0),
        incorrectCount: cur.incorrectCount + (g.isCorrect ? 0 : 1),
      });
      answersByWord.set(g.vocabularyId, [
        ...(answersByWord.get(g.vocabularyId) ?? []),
        g.isCorrect,
      ]);
    }
    for (const [vocabularyId, answers] of answersByWord) {
      const a = acc.get(vocabularyId)!;
      a.state = applySession(a.state, answers, now);
    }
    for (const [vocabularyId, a] of acc) {
      const data = {
        ...a.state,
        reviewCount: a.reviewCount,
        correctCount: a.correctCount,
        incorrectCount: a.incorrectCount,
        lastReviewedAt: now,
      };
      await tx.userVocabProgress.upsert({
        where: { userId_vocabularyId: { userId, vocabularyId } },
        create: { userId, vocabularyId, ...data },
        update: data,
      });
    }
  }

  /** Dựng lại kết quả của phiên đã nộp (khi FE gửi lại cùng clientSessionId). */
  private async findByClientId(
    userId: string,
    clientSessionId: string,
  ): Promise<SessionResultDto | null> {
    const session = await this.prisma.quizSession.findUnique({
      where: { userId_clientSessionId: { userId, clientSessionId } },
      include: {
        answers: {
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
          include: {
            vocabulary: { select: { term: true, definitionVi: true } },
          },
        },
        user: true,
      },
    });
    if (!session) return null;
    const streak: StreakSummary = this.streak.summarize(
      session.user,
      this.clock.now(),
    );
    return {
      sessionId: session.id,
      totalQuestions: session.totalQuestions,
      correctCount: session.correctCount,
      incorrectCount: session.incorrectCount,
      scorePercentage: session.scorePercentage,
      durationSeconds: session.durationSeconds,
      streak,
      newBadges: [],
      answers: session.answers.map((a) => ({
        vocabularyId: a.vocabularyId,
        isCorrect: a.isCorrect,
        correctAnswer: expectedAnswer(session.mode, a.vocabulary),
      })),
    };
  }
}
