import { Injectable } from '@nestjs/common';
import { QuizMode, UserVocabProgress, Vocabulary } from '@prisma/client';
import { AppException } from '../../common/http/app.exception';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsService } from '../collections/collections.service';
import { toVocabularyDto } from '../vocabularies/vocabulary.mapper';
import { DistractorCandidate, pickDistractors, shuffle } from './distractors';
import {
  DueDto,
  QuestionDto,
  QuestionsDto,
  QuestionsQueryDto,
} from './dto/practice.dto';
import { CHOICE_MODES, expectedAnswer } from './grading';

type WordWithProgress = Vocabulary & { progress: UserVocabProgress[] };

const OPTIONS_PER_QUESTION = 4;

export const sessionNotFound = () =>
  new AppException(404, 'SESSION_NOT_FOUND', 'Không tìm thấy phiên luyện tập');

@Injectable()
export class QuestionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly collections: CollectionsService,
    private readonly clock: Clock,
    private readonly rng: () => number = Math.random,
  ) {}

  /**
   * Chọn từ để luyện: từ đến hạn (sớm nhất trước) → từ mới → còn lại theo hạn ôn.
   * Không có collectionId thì chỉ lấy từ đến hạn trên mọi học phần.
   */
  async getQuestions(
    userId: string,
    q: QuestionsQueryDto,
  ): Promise<QuestionsDto> {
    const now = this.clock.now();
    let words: WordWithProgress[];
    if (q.collectionId) {
      await this.collections.assertOwned(userId, q.collectionId);
      const all = await this.prisma.vocabulary.findMany({
        where: { collectionId: q.collectionId },
        include: { progress: { where: { userId } } },
      });
      words = rankForPractice(all, now).slice(0, q.limit);
    } else {
      words = await this.prisma.vocabulary.findMany({
        where: {
          collection: { userId },
          progress: { some: { userId, nextReviewAt: { lte: now } } },
        },
        include: { progress: { where: { userId } } },
      });
      words = rankForPractice(words, now).slice(0, q.limit);
    }
    return {
      mode: q.mode,
      questions: await this.buildQuestions(userId, q.mode, words),
    };
  }

  async getDue(userId: string, limit: number): Promise<DueDto> {
    const where = {
      userId,
      nextReviewAt: { lte: this.clock.now() },
      vocabulary: { collection: { userId } },
    };
    const [dueCount, rows] = await Promise.all([
      this.prisma.userVocabProgress.count({ where }),
      this.prisma.userVocabProgress.findMany({
        where,
        include: { vocabulary: true },
        orderBy: [{ nextReviewAt: 'asc' }, { id: 'asc' }],
        take: limit,
      }),
    ]);
    return {
      dueCount,
      words: rows.map((p) => toVocabularyDto(p.vocabulary, p)),
    };
  }

  /** Câu hỏi luyện lại cho những từ trả lời sai trong một phiên (cùng chế độ). */
  async retryMissed(userId: string, sessionId: string): Promise<QuestionsDto> {
    const session = await this.prisma.quizSession.findFirst({
      where: { id: sessionId, userId },
      include: { answers: { where: { isCorrect: false } } },
    });
    if (!session) throw sessionNotFound();
    const missedIds = [...new Set(session.answers.map((a) => a.vocabularyId))];
    const words = await this.prisma.vocabulary.findMany({
      where: { id: { in: missedIds }, collection: { userId } },
      include: { progress: { where: { userId } } },
    });
    return {
      mode: session.mode,
      questions: await this.buildQuestions(
        userId,
        session.mode,
        shuffle(words, this.rng),
      ),
    };
  }

  private async buildQuestions(
    userId: string,
    mode: QuizMode,
    words: Vocabulary[],
  ): Promise<QuestionDto[]> {
    if (!words.length) return [];
    const choice = CHOICE_MODES.has(mode);
    const pool = choice ? await this.distractorPool(userId) : null;

    return shuffle(words, this.rng).map((v) => {
      const question: QuestionDto = {
        vocabularyId: v.id,
        prompt: promptFor(mode, v),
        answer: expectedAnswer(mode, v),
      };
      if (pool) {
        const picked = pickDistractors(
          v,
          pool,
          OPTIONS_PER_QUESTION - 1,
          this.rng,
        );
        question.options = shuffle([v, ...picked], this.rng).map((o) => ({
          vocabularyId: o.id,
          text: expectedAnswer(mode, o),
        }));
      }
      return question;
    });
  }

  /** Ứng viên gây nhiễu: mọi từ trong các học phần của user. */
  private distractorPool(userId: string): Promise<DistractorCandidate[]> {
    return this.prisma.vocabulary.findMany({
      where: { collection: { userId } },
      select: { id: true, term: true, partOfSpeech: true, definitionVi: true },
    });
  }
}

/** Thứ tự ưu tiên luyện tập (hàm thuần). */
export function rankForPractice<T extends WordWithProgress>(
  words: T[],
  now: Date,
): T[] {
  const rank = (w: T): [number, number] => {
    const p = w.progress[0];
    const next = p?.nextReviewAt?.getTime();
    if (next !== undefined && next <= now.getTime()) return [0, next];
    if (!p || p.status === 'new') return [1, w.createdAt.getTime()];
    return [2, next ?? Number.MAX_SAFE_INTEGER];
  };
  return [...words].sort((a, b) => {
    const [ga, ka] = rank(a);
    const [gb, kb] = rank(b);
    return ga - gb || ka - kb || a.id.localeCompare(b.id);
  });
}

function promptFor(mode: QuizMode, v: Vocabulary): QuestionDto['prompt'] {
  const ipa = v.ipaUk ?? v.ipaUs ?? undefined;
  const audioUrl = v.audioUkUrl ?? v.audioUsUrl ?? undefined;
  switch (mode) {
    case 'listen_choose':
    case 'listen_type':
      return { ...(audioUrl ? { audioUrl } : {}), ...(ipa ? { ipa } : {}) };
    case 'choose_meaning':
      return { term: v.term, ...(ipa ? { ipa } : {}) };
    case 'type_meaning':
      return { definitionVi: v.definitionVi };
  }
}
