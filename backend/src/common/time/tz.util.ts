/** Tiện ích thời gian theo múi giờ IANA của user, chỉ dùng Intl (không thêm thư viện). */

interface LocalParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatter(tz: string): Intl.DateTimeFormat {
  let f = formatters.get(tz);
  if (!f) {
    f = new Intl.DateTimeFormat('en-US', {
      timeZone: tz,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
    formatters.set(tz, f);
  }
  return f;
}

function localParts(instant: Date, tz: string): LocalParts {
  const parts = Object.fromEntries(
    formatter(tz)
      .formatToParts(instant)
      .filter((p) => p.type !== 'literal')
      .map((p) => [p.type, Number(p.value)]),
  ) as Record<string, number>;
  return {
    year: parts.year,
    month: parts.month,
    day: parts.day,
    hour: parts.hour,
    minute: parts.minute,
    second: parts.second,
  };
}

const pad = (n: number) => String(n).padStart(2, '0');

/** Ngày địa phương dạng YYYY-MM-DD. */
export function localDateString(instant: Date, tz: string): string {
  const p = localParts(instant, tz);
  return `${p.year}-${pad(p.month)}-${pad(p.day)}`;
}

/** Giờ địa phương dạng HH:mm. */
export function localTimeHHmm(instant: Date, tz: string): string {
  const p = localParts(instant, tz);
  return `${pad(p.hour)}:${pad(p.minute)}`;
}

/** Độ lệch (ms) giữa giờ địa phương và UTC tại một thời điểm. */
function offsetMs(instant: Date, tz: string): number {
  const p = localParts(instant, tz);
  const asUtc = Date.UTC(
    p.year,
    p.month - 1,
    p.day,
    p.hour,
    p.minute,
    p.second,
  );
  return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

/** Thời điểm (UTC) của 00:00 giờ địa phương trong ngày chứa `instant`. */
export function startOfLocalDayUtc(instant: Date, tz: string): Date {
  const p = localParts(instant, tz);
  const midnightAsUtc = Date.UTC(p.year, p.month - 1, p.day);
  // Lặp hai lần để xử lý đúng ngày chuyển giờ mùa hè
  let guess = midnightAsUtc - offsetMs(instant, tz);
  guess = midnightAsUtc - offsetMs(new Date(guess), tz);
  return new Date(guess);
}

/** Cộng/trừ ngày trên chuỗi YYYY-MM-DD. */
export function addDays(date: string, days: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Chuyển cột DATE của Postgres (Prisma trả Date lúc 00:00 UTC) về YYYY-MM-DD. */
export function dateOnlyToString(d: Date | null): string | null {
  return d ? d.toISOString().slice(0, 10) : null;
}

/** Ngược lại: YYYY-MM-DD thành Date để lưu vào cột DATE. */
export function dateStringToDateOnly(s: string): Date {
  return new Date(`${s}T00:00:00Z`);
}
