import { PrismaService } from '../src/infra/prisma/prisma.service';
import { resetDb } from './utils/db';

describe('Schema (e2e)', () => {
  const prisma = new PrismaService();

  beforeAll(async () => {
    await prisma.$connect();
  });

  beforeEach(async () => {
    await resetDb(prisma);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('seed tạo đúng 3 huy hiệu', async () => {
    const badges = await prisma.badge.findMany({ orderBy: { code: 'asc' } });
    expect(badges.map((b) => b.code)).toEqual([
      'explorer_5',
      'first_100',
      'streak_7',
    ]);
  });

  it('xoá user thì học phần bị xoá theo (cascade)', async () => {
    const user = await prisma.user.create({
      data: { email: 'a@example.com', fullName: 'A' },
    });
    await prisma.collection.create({
      data: { userId: user.id, title: 'IELTS' },
    });
    await prisma.user.delete({ where: { id: user.id } });
    expect(await prisma.collection.count()).toBe(0);
  });

  it('không cho tạo 2 progress cùng (user, vocab)', async () => {
    const user = await prisma.user.create({
      data: { email: 'b@example.com', fullName: 'B' },
    });
    const col = await prisma.collection.create({
      data: { userId: user.id, title: 'Travel' },
    });
    const vocab = await prisma.vocabulary.create({
      data: {
        collectionId: col.id,
        term: 'itinerary',
        termKey: 'itinerary',
        partOfSpeech: 'noun',
        definitionVi: 'lịch trình',
        cefrLevel: 'B1',
      },
    });
    await prisma.userVocabProgress.create({
      data: { userId: user.id, vocabularyId: vocab.id },
    });
    await expect(
      prisma.userVocabProgress.create({
        data: { userId: user.id, vocabularyId: vocab.id },
      }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });

  it('có đủ index bắt buộc theo đặc tả và index trigram cho tìm kiếm', async () => {
    const rows = await prisma.$queryRaw<{ indexname: string }[]>`
      SELECT indexname FROM pg_indexes WHERE schemaname = 'public'`;
    const names = rows.map((r) => r.indexname);
    expect(names).toEqual(
      expect.arrayContaining([
        'users_email_key',
        'collections_user_id_category_idx',
        'vocabularies_collection_id_term_idx',
        'user_vocab_progress_user_id_next_review_at_status_idx',
        'collections_title_trgm_idx',
        'collections_description_trgm_idx',
      ]),
    );
  });
});
