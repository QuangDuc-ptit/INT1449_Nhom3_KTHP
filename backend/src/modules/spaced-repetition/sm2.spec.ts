import { INTERVALS, SrsState, applyAnswer } from './sm2';

const NOW = new Date('2026-11-19T10:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const fresh = (): SrsState => ({
  repetitionLevel: 0,
  easeFactor: 2.5,
  intervalDays: 0,
  status: 'new',
  nextReviewAt: null,
});

describe('SM-2 (biến thể theo đặc tả 4.1)', () => {
  it('từ mới trả lời đúng lên level 1, ôn lại sau 1 ngày, ease không vượt 2.5', () => {
    expect(applyAnswer(fresh(), true, NOW)).toEqual({
      repetitionLevel: 1,
      easeFactor: 2.5,
      intervalDays: 1,
      status: 'review',
      nextReviewAt: new Date('2026-11-20T10:00:00.000Z'),
    });
  });

  it('đúng liên tiếp: khoảng cách 1, 3, 7, 16, 35 ngày và level 5 là mastered', () => {
    let s = fresh();
    const intervals: number[] = [];
    for (let i = 0; i < 5; i++) {
      s = applyAnswer(s, true, NOW);
      intervals.push(s.intervalDays);
    }
    expect(intervals).toEqual([1, 3, 7, 16, 35]);
    expect(s.repetitionLevel).toBe(5);
    expect(s.status).toBe('mastered');
    expect(s.nextReviewAt).toEqual(new Date(NOW.getTime() + 35 * DAY));
    expect(INTERVALS).toEqual({ 1: 1, 2: 3, 3: 7, 4: 16, 5: 35 });
  });

  it('level 5 trả lời đúng vẫn giữ level 5, 35 ngày, mastered', () => {
    const s = applyAnswer(
      { ...fresh(), repetitionLevel: 5, intervalDays: 35, status: 'mastered' },
      true,
      NOW,
    );
    expect(s).toMatchObject({
      repetitionLevel: 5,
      intervalDays: 35,
      status: 'mastered',
    });
  });

  it('trả lời sai: về level 0, ôn lại ngày mai, ease giảm 0.2, trạng thái learning', () => {
    const s = applyAnswer(
      {
        repetitionLevel: 3,
        easeFactor: 2.0,
        intervalDays: 7,
        status: 'review',
        nextReviewAt: NOW,
      },
      false,
      NOW,
    );
    expect(s.repetitionLevel).toBe(0);
    expect(s.intervalDays).toBe(1);
    expect(s.easeFactor).toBeCloseTo(1.8, 9);
    expect(s.status).toBe('learning');
    expect(s.nextReviewAt).toEqual(new Date(NOW.getTime() + DAY));
  });

  it('ease không giảm dưới 1.3', () => {
    expect(
      applyAnswer({ ...fresh(), easeFactor: 1.4 }, false, NOW).easeFactor,
    ).toBeCloseTo(1.3, 9);
    expect(
      applyAnswer({ ...fresh(), easeFactor: 1.3 }, false, NOW).easeFactor,
    ).toBeCloseTo(1.3, 9);
  });

  it('trả lời đúng tăng ease 0.1', () => {
    expect(
      applyAnswer({ ...fresh(), easeFactor: 2.0 }, true, NOW).easeFactor,
    ).toBeCloseTo(2.1, 9);
  });

  it('không làm thay đổi state đầu vào', () => {
    const s = fresh();
    applyAnswer(s, true, NOW);
    expect(s).toEqual(fresh());
  });
});
