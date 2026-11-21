import { addDays } from '../../common/time/tz.util';

export interface StreakState {
  currentStreak: number;
  highestStreak: number;
  /** Ngày địa phương gần nhất có học (YYYY-MM-DD). */
  lastStreakDate: string | null;
}

/** Cập nhật streak khi user hoàn thành một phiên học vào ngày `todayLocal`. */
export function computeStreak(s: StreakState, todayLocal: string): StreakState {
  if (s.lastStreakDate === todayLocal) return { ...s };
  const continues =
    s.lastStreakDate === addDays(todayLocal, -1) && s.currentStreak > 0;
  const currentStreak = continues ? s.currentStreak + 1 : 1;
  return {
    currentStreak,
    highestStreak: Math.max(s.highestStreak, currentStreak),
    lastStreakDate: todayLocal,
  };
}
