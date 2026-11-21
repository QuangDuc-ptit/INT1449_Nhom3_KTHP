import { QuizMode } from '@prisma/client';

/** Chế độ trắc nghiệm 4 lựa chọn (các chế độ còn lại là gõ đáp án). */
export const CHOICE_MODES: ReadonlySet<QuizMode> = new Set<QuizMode>([
  'listen_choose',
  'choose_meaning',
]);

export function normalizeAnswer(s: string): string {
  return s.normalize('NFC').trim().replace(/\s+/g, ' ').toLowerCase();
}

export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  let prev = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) {
      cur[j] = Math.min(
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1),
      );
    }
    prev = cur;
  }
  return prev[b.length];
}

/**
 * Chấm một câu trả lời. Chế độ chọn: khớp tuyệt đối sau chuẩn hoá.
 * Chế độ gõ: cho phép sai 1 ký tự (Levenshtein ≤ 1) với đáp án từ 3 ký tự trở lên.
 */
export function gradeAnswer(
  mode: QuizMode,
  userAnswer: string,
  expected: string,
): boolean {
  const given = normalizeAnswer(userAnswer);
  const want = normalizeAnswer(expected);
  if (!given) return false;
  if (given === want) return true;
  if (CHOICE_MODES.has(mode) || want.length < 3) return false;
  return levenshtein(given, want) <= 1;
}

/** Đáp án mong đợi: chọn nghĩa thì là nghĩa tiếng Việt, còn lại là từ tiếng Anh. */
export function expectedAnswer(
  mode: QuizMode,
  vocab: { term: string; definitionVi: string },
): string {
  return mode === 'choose_meaning' ? vocab.definitionVi : vocab.term;
}
