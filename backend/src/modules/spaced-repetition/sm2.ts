import { ProgressStatus } from '@prisma/client';

export interface SrsState {
  repetitionLevel: number;
  easeFactor: number;
  intervalDays: number;
  status: ProgressStatus;
  nextReviewAt: Date | null;
}

/** Khoảng cách ôn tập (ngày) theo level, đặc tả BE mục 4.1. */
export const INTERVALS: Record<number, number> = {
  1: 1,
  2: 3,
  3: 7,
  4: 16,
  5: 35,
};

export const MAX_LEVEL = 5;
export const MAX_EASE = 2.5;
export const MIN_EASE = 1.3;
const DAY_MS = 24 * 60 * 60 * 1000;

const round = (n: number) => Math.round(n * 100) / 100;

/** Tính trạng thái ôn tập mới sau một câu trả lời (hàm thuần, không đổi đầu vào). */
export function applyAnswer(
  state: SrsState,
  isCorrect: boolean,
  now: Date,
): SrsState {
  if (isCorrect) {
    const level = Math.min(MAX_LEVEL, state.repetitionLevel + 1);
    const intervalDays = INTERVALS[level];
    return {
      repetitionLevel: level,
      easeFactor: Math.min(MAX_EASE, round(state.easeFactor + 0.1)),
      intervalDays,
      status: level === MAX_LEVEL ? 'mastered' : 'review',
      nextReviewAt: new Date(now.getTime() + intervalDays * DAY_MS),
    };
  }
  return {
    repetitionLevel: 0,
    easeFactor: Math.max(MIN_EASE, round(state.easeFactor - 0.2)),
    intervalDays: 1,
    status: 'learning',
    nextReviewAt: new Date(now.getTime() + DAY_MS),
  };
}
