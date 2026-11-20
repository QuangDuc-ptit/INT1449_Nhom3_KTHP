export interface UserMetrics {
  currentStreak: number;
  /** Số từ có trạng thái khác `new` (đã ôn ít nhất một lần). */
  learnedWords: number;
  collectionsCount: number;
}

/** Giá trị chỉ số mà mỗi huy hiệu so với requiredPoints (xem seed huy hiệu). */
export const BADGE_RULES: Record<string, (m: UserMetrics) => number> = {
  streak_7: (m) => m.currentStreak,
  first_100: (m) => m.learnedWords,
  explorer_5: (m) => m.collectionsCount,
};

/** Tiến độ hiển thị (0..requiredPoints); huy hiệu không có luật thì 0. */
export function badgeProgress(
  code: string,
  requiredPoints: number,
  metrics: UserMetrics,
): number {
  const rule = BADGE_RULES[code];
  return rule ? Math.min(rule(metrics), requiredPoints) : 0;
}
