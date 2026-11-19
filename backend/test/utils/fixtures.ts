import { CefrLevel, PartOfSpeech, ProgressStatus } from '@prisma/client';
import { PrismaService } from '../../src/infra/prisma/prisma.service';

export interface WordSeed {
  term: string;
  partOfSpeech?: PartOfSpeech;
  definitionVi?: string;
  cefrLevel?: CefrLevel;
  progress?: {
    status: ProgressStatus;
    nextReviewAt: Date | null;
    repetitionLevel?: number;
  };
}

/** Tạo nhanh học phần kèm từ và tiến độ trực tiếp trong DB. */
export async function seedCollection(
  prisma: PrismaService,
  userId: string,
  title: string,
  words: WordSeed[],
): Promise<{ collectionId: string; ids: Record<string, string> }> {
  const col = await prisma.collection.create({
    data: { userId, title, totalWords: words.length },
  });
  const ids: Record<string, string> = {};
  for (const w of words) {
    const v = await prisma.vocabulary.create({
      data: {
        collectionId: col.id,
        term: w.term,
        partOfSpeech: w.partOfSpeech ?? 'noun',
        definitionVi: w.definitionVi ?? `nghĩa của ${w.term}`,
        cefrLevel: w.cefrLevel ?? 'B1',
        audioUkUrl: `https://cdn.test/${w.term}-uk.mp3`,
        ipaUk: `/${w.term}/`,
      },
    });
    ids[w.term] = v.id;
    await prisma.userVocabProgress.create({
      data: {
        userId,
        vocabularyId: v.id,
        status: w.progress?.status ?? 'new',
        nextReviewAt: w.progress?.nextReviewAt ?? null,
        repetitionLevel: w.progress?.repetitionLevel ?? 0,
      },
    });
  }
  return { collectionId: col.id, ids };
}
