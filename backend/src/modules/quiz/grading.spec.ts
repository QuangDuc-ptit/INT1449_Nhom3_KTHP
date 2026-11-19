import {
  expectedAnswer,
  gradeAnswer,
  levenshtein,
  normalizeAnswer,
} from './grading';

describe('normalizeAnswer', () => {
  it('trim, viết thường, gộp khoảng trắng', () => {
    expect(normalizeAnswer('  Break   THE  ice ')).toBe('break the ice');
  });

  it('chuẩn hoá Unicode NFC (tiếng Việt gõ kiểu tổ hợp)', () => {
    const decomposed = 'Mạch lạc'.normalize('NFD');
    expect(normalizeAnswer(decomposed)).toBe('mạch lạc'.normalize('NFC'));
  });
});

describe('levenshtein', () => {
  it.each([
    ['', 'abc', 3],
    ['abc', 'abc', 0],
    ['coherant', 'coherent', 1],
    ['cohernat', 'coherent', 2],
    ['kitten', 'sitting', 3],
  ])('levenshtein(%s, %s) = %i', (a, b, d) => {
    expect(levenshtein(a, b)).toBe(d);
  });
});

describe('gradeAnswer', () => {
  it('chế độ gõ chấp nhận khoảng trắng và hoa thường', () => {
    expect(gradeAnswer('listen_type', '  Coherent ', 'coherent')).toBe(true);
  });

  it('chế độ gõ chấp nhận sai 1 ký tự', () => {
    expect(gradeAnswer('type_meaning', 'coherant', 'coherent')).toBe(true);
  });

  it('chế độ gõ không chấp nhận sai 2 ký tự', () => {
    expect(gradeAnswer('type_meaning', 'cohernat', 'coherent')).toBe(false);
  });

  it('từ rất ngắn: không chấp nhận gõ sai khi đáp án chỉ 1-2 ký tự', () => {
    expect(gradeAnswer('listen_type', 'b', 'a')).toBe(false);
  });

  it('chế độ chọn phải khớp tuyệt đối sau chuẩn hoá', () => {
    expect(gradeAnswer('listen_choose', 'coherant', 'coherent')).toBe(false);
    expect(gradeAnswer('listen_choose', 'Coherent', 'coherent')).toBe(true);
  });

  it('chọn nghĩa tiếng Việt không phân biệt hoa thường', () => {
    expect(
      gradeAnswer('choose_meaning', 'Mạch lạc, chặt chẽ', 'mạch lạc, chặt chẽ'),
    ).toBe(true);
  });

  it('câu trả lời rỗng luôn sai', () => {
    expect(gradeAnswer('listen_type', '   ', 'a')).toBe(false);
  });
});

describe('expectedAnswer', () => {
  const v = { term: 'coherent', definitionVi: 'mạch lạc' };
  it('choose_meaning lấy nghĩa tiếng Việt, các chế độ khác lấy term', () => {
    expect(expectedAnswer('choose_meaning', v)).toBe('mạch lạc');
    expect(expectedAnswer('listen_choose', v)).toBe('coherent');
    expect(expectedAnswer('listen_type', v)).toBe('coherent');
    expect(expectedAnswer('type_meaning', v)).toBe('coherent');
  });
});
