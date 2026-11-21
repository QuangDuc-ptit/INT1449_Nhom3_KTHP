import { computeStreak } from './streak';

const s = (
  currentStreak: number,
  highestStreak: number,
  lastStreakDate: string | null,
) => ({ currentStreak, highestStreak, lastStreakDate });

describe('computeStreak', () => {
  it('học tiếp ngày hôm sau thì +1', () => {
    expect(computeStreak(s(3, 5, '2026-11-19'), '2026-11-20')).toEqual(
      s(4, 5, '2026-11-20'),
    );
  });

  it('học thêm trong cùng ngày thì giữ nguyên', () => {
    expect(computeStreak(s(3, 5, '2026-11-20'), '2026-11-20')).toEqual(
      s(3, 5, '2026-11-20'),
    );
  });

  it('bỏ lỡ ngày thì bắt đầu lại từ 1', () => {
    expect(computeStreak(s(3, 5, '2026-11-17'), '2026-11-20')).toEqual(
      s(1, 5, '2026-11-20'),
    );
  });

  it('vượt kỷ lục thì cập nhật highestStreak', () => {
    expect(computeStreak(s(5, 5, '2026-11-19'), '2026-11-20')).toEqual(
      s(6, 6, '2026-11-20'),
    );
  });

  it('lần học đầu tiên', () => {
    expect(computeStreak(s(0, 0, null), '2026-11-20')).toEqual(
      s(1, 1, '2026-11-20'),
    );
  });

  it('streak đã bị cron reset về 0 nhưng học tiếp ngay hôm sau thì bắt đầu từ 1', () => {
    expect(computeStreak(s(0, 9, '2026-11-19'), '2026-11-20')).toEqual(
      s(1, 9, '2026-11-20'),
    );
  });
});
