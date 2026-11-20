import {
  addDays,
  localDateString,
  localTimeHHmm,
  startOfLocalDayUtc,
} from './tz.util';

const VN = 'Asia/Ho_Chi_Minh';

describe('tz.util', () => {
  it('localDateString theo múi giờ của user', () => {
    expect(localDateString(new Date('2026-11-19T17:30:00Z'), VN)).toBe(
      '2026-11-20',
    );
    expect(localDateString(new Date('2026-11-19T16:30:00Z'), VN)).toBe(
      '2026-11-19',
    );
    expect(
      localDateString(new Date('2026-11-19T03:00:00Z'), 'America/New_York'),
    ).toBe('2026-11-18');
  });

  it('startOfLocalDayUtc trả thời điểm 00:00 giờ địa phương (theo UTC)', () => {
    expect(
      startOfLocalDayUtc(new Date('2026-11-19T17:30:00Z'), VN).toISOString(),
    ).toBe('2026-11-19T17:00:00.000Z');
    expect(
      startOfLocalDayUtc(
        new Date('2026-07-01T12:00:00Z'),
        'America/New_York',
      ).toISOString(),
    ).toBe('2026-07-01T04:00:00.000Z');
  });

  it('localTimeHHmm', () => {
    expect(localTimeHHmm(new Date('2026-11-19T13:05:00Z'), VN)).toBe('20:05');
    expect(localTimeHHmm(new Date('2026-11-19T17:00:00Z'), VN)).toBe('00:00');
  });

  it('addDays trên chuỗi ngày, qua tháng và năm', () => {
    expect(addDays('2026-11-30', 1)).toBe('2026-12-01');
    expect(addDays('2027-01-01', -1)).toBe('2026-12-31');
  });
});
