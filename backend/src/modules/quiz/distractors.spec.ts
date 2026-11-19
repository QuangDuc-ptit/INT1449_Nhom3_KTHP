import { PartOfSpeech } from '@prisma/client';
import { DistractorCandidate, pickDistractors } from './distractors';

let seq = 0;
const v = (
  term: string,
  partOfSpeech: PartOfSpeech = 'noun',
  definitionVi = `nghĩa ${term}`,
): DistractorCandidate => ({
  id: `id-${seq++}`,
  term,
  partOfSpeech,
  definitionVi,
});

/** RNG cố định để test lặp lại được. */
const seeded =
  (seed = 42) =>
  () => {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  };

describe('pickDistractors', () => {
  const target = v('coherent', 'adj', 'mạch lạc');

  it('ưu tiên 3 từ cùng từ loại, không chứa target, không trùng term', () => {
    const pool = [
      target,
      v('ambitious', 'adj'),
      v('reliable', 'adj'),
      v('abundant', 'adj'),
      v('Ambitious', 'adj'),
      v('explore', 'verb'),
    ];
    const res = pickDistractors(target, pool, 3, seeded());
    expect(res).toHaveLength(3);
    expect(res.every((d) => d.partOfSpeech === 'adj')).toBe(true);
    expect(res.map((d) => d.term)).not.toContain('coherent');
    const terms = res.map((d) => d.term.toLowerCase());
    expect(new Set(terms).size).toBe(3);
  });

  it('thiếu từ cùng loại thì bù bằng từ khác loại (cùng loại đứng trước)', () => {
    const pool = [
      v('reliable', 'adj'),
      v('explore', 'verb'),
      v('souvenir', 'noun'),
      v('quickly', 'adv'),
      v('trip', 'noun'),
      v('run', 'verb'),
    ];
    const res = pickDistractors(target, pool, 3, seeded());
    expect(res).toHaveLength(3);
    expect(res[0].term).toBe('reliable');
    expect(res.slice(1).every((d) => d.partOfSpeech !== 'adj')).toBe(true);
  });

  it('pool chỉ có 1 phần tử thì trả 1', () => {
    expect(
      pickDistractors(target, [v('explore', 'verb')], 3, seeded()),
    ).toHaveLength(1);
  });

  it('loại từ trùng nghĩa tiếng Việt với target (tránh 2 đáp án đúng)', () => {
    const pool = [v('logical', 'adj', 'Mạch lạc'), v('reliable', 'adj')];
    const res = pickDistractors(target, pool, 3, seeded());
    expect(res.map((d) => d.term)).toEqual(['reliable']);
  });

  it('hiệu năng: pool 5000 từ chạy dưới 50 ms', () => {
    const pos: PartOfSpeech[] = ['noun', 'verb', 'adj', 'adv', 'idiom'];
    const pool = Array.from({ length: 5000 }, (_, i) => v(`w${i}`, pos[i % 5]));
    const rng = seeded();
    for (let i = 0; i < 10; i++) {
      const start = performance.now();
      pickDistractors(target, pool, 3, rng);
      expect(performance.now() - start).toBeLessThan(50);
    }
  });
});
