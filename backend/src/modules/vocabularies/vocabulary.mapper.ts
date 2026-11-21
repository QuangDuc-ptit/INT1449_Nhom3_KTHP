import { UserVocabProgress, Vocabulary } from '@prisma/client';
import { VocabularyDto } from './dto/vocabulary.dto';

export function toVocabularyDto(
  v: Vocabulary,
  progress?: Pick<
    UserVocabProgress,
    'status' | 'repetitionLevel' | 'nextReviewAt'
  > | null,
): VocabularyDto {
  return {
    id: v.id,
    collectionId: v.collectionId,
    term: v.term,
    partOfSpeech: v.partOfSpeech,
    ipaUk: v.ipaUk,
    ipaUs: v.ipaUs,
    audioUkUrl: v.audioUkUrl,
    audioUsUrl: v.audioUsUrl,
    definitionEn: v.definitionEn,
    definitionVi: v.definitionVi,
    exampleSentence: v.exampleSentence,
    cefrLevel: v.cefrLevel,
    source: v.source,
    progress: progress
      ? {
          status: progress.status,
          repetitionLevel: progress.repetitionLevel,
          nextReviewAt: progress.nextReviewAt,
        }
      : null,
  };
}

/** Khoá so sánh trùng từ: bỏ khoảng trắng thừa, không phân biệt hoa thường. */
export const termKey = (term: string) =>
  term.trim().replace(/\s+/g, ' ').toLowerCase();
