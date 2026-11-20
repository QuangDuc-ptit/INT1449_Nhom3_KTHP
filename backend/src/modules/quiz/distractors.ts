import { PartOfSpeech } from '@prisma/client';
import { normalizeAnswer } from './grading';

export interface DistractorCandidate {
  id: string;
  term: string;
  partOfSpeech: PartOfSpeech;
  definitionVi: string;
}

/**
 * Chọn tối đa `count` phương án gây nhiễu: ưu tiên cùng từ loại với target,
 * thiếu thì bù từ loại khác. Bỏ target, bỏ từ trùng term hoặc trùng nghĩa
 * tiếng Việt (để không có hai đáp án đúng). Độ phức tạp O(n).
 */
export function pickDistractors<T extends DistractorCandidate>(
  target: DistractorCandidate,
  pool: T[],
  count: number,
  rng: () => number = Math.random,
): T[] {
  const usedTerms = new Set([normalizeAnswer(target.term)]);
  const usedMeanings = new Set([normalizeAnswer(target.definitionVi)]);
  const same: T[] = [];
  const other: T[] = [];
  for (const c of pool) {
    if (c.id === target.id) continue;
    (c.partOfSpeech === target.partOfSpeech ? same : other).push(c);
  }

  const picked: T[] = [];
  for (const group of [shuffle(same, rng), shuffle(other, rng)]) {
    for (const c of group) {
      if (picked.length === count) return picked;
      const term = normalizeAnswer(c.term);
      const meaning = normalizeAnswer(c.definitionVi);
      if (usedTerms.has(term) || usedMeanings.has(meaning)) continue;
      usedTerms.add(term);
      usedMeanings.add(meaning);
      picked.push(c);
    }
  }
  return picked;
}

/** Fisher–Yates, trả mảng mới. */
export function shuffle<T>(items: T[], rng: () => number = Math.random): T[] {
  const a = [...items];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
