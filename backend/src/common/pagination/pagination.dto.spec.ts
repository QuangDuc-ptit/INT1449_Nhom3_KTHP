import { paginated } from './pagination.dto';

describe('paginated', () => {
  it('tính meta phân trang', () => {
    expect(paginated(['b'], 3, { page: 2, limit: 2 })).toEqual({
      items: ['b'],
      meta: { page: 2, limit: 2, total: 3, totalPages: 2 },
    });
  });

  it('total = 0 thì totalPages = 0', () => {
    expect(paginated([], 0, { page: 1, limit: 20 }).meta.totalPages).toBe(0);
  });
});
