import { BADGE_RULES, UserMetrics, badgeProgress } from './badge-rules';

const m = (over: Partial<UserMetrics> = {}): UserMetrics => ({
  currentStreak: 0,
  learnedWords: 0,
  collectionsCount: 0,
  ...over,
});

describe('BADGE_RULES', () => {
  it('mỗi huy hiệu đọc đúng chỉ số', () => {
    expect(BADGE_RULES.streak_7(m({ currentStreak: 7 }))).toBe(7);
    expect(BADGE_RULES.first_100(m({ learnedWords: 42 }))).toBe(42);
    expect(BADGE_RULES.explorer_5(m({ collectionsCount: 3 }))).toBe(3);
  });

  it('badgeProgress chặn trên bằng requiredPoints, mã lạ trả 0', () => {
    expect(badgeProgress('streak_7', 7, m({ currentStreak: 12 }))).toBe(7);
    expect(badgeProgress('first_100', 100, m({ learnedWords: 42 }))).toBe(42);
    expect(badgeProgress('unknown', 5, m({ currentStreak: 9 }))).toBe(0);
  });
});
