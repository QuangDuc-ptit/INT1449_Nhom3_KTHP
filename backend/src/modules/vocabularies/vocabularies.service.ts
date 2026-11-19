import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Collection, Prisma, VocabSource, Vocabulary } from '@prisma/client';
import { AppException } from '../../common/http/app.exception';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CollectionsService } from '../collections/collections.service';
import {
  BatchSaveDto,
  BatchSaveResultDto,
  CreateVocabularyDto,
  CreateVocabularyInput,
  UpdateVocabularyDto,
  VocabularyDto,
} from './dto/vocabulary.dto';
import { termKey, toVocabularyDto } from './vocabulary.mapper';

/** Sự kiện phát sau khi từ mới được lưu (worker audio lắng nghe). */
export const VOCABULARY_CREATED = 'vocabulary.created';
/** Phát khi term đổi: audio cũ đọc sai từ, cần sinh lại. */
export const VOCABULARY_TERM_CHANGED = 'vocabulary.term-changed';
export interface VocabularyCreatedEvent {
  ids: string[];
}

export const vocabularyNotFound = () =>
  new AppException(404, 'VOCABULARY_NOT_FOUND', 'Không tìm thấy từ vựng');

const vocabularyExists = (term: string) =>
  new AppException(
    409,
    'VOCABULARY_EXISTS',
    `Từ "${term}" đã có trong học phần`,
  );

@Injectable()
export class VocabulariesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly collections: CollectionsService,
    private readonly events: EventEmitter2,
  ) {}

  /** Trả từ (kèm học phần) nếu thuộc học phần của user; ngược lại 404. */
  async assertOwned(
    userId: string,
    vocabularyId: string,
    tx: Prisma.TransactionClient = this.prisma,
  ): Promise<Vocabulary & { collection: Collection }> {
    const v = await tx.vocabulary.findFirst({
      where: { id: vocabularyId, collection: { userId } },
      include: { collection: true },
    });
    if (!v) throw vocabularyNotFound();
    return v;
  }

  async listWords(
    userId: string,
    collectionId: string,
  ): Promise<VocabularyDto[]> {
    await this.collections.assertOwned(userId, collectionId);
    const words = await this.prisma.vocabulary.findMany({
      where: { collectionId },
      include: { progress: { where: { userId } } },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return words.map((w) => toVocabularyDto(w, w.progress[0]));
  }

  async create(
    userId: string,
    collectionId: string,
    dto: CreateVocabularyDto,
  ): Promise<VocabularyDto> {
    const { saved, skippedTerms } = await this.createBatch(
      userId,
      collectionId,
      [dto],
      'manual',
    );
    if (skippedTerms.length) throw vocabularyExists(dto.term);
    this.emitCreated(saved);
    return this.toDtoWithProgress(userId, saved[0]);
  }

  /**
   * Lưu nhiều từ vào học phần: bỏ qua từ trùng (không phân biệt hoa thường,
   * kể cả trùng trong cùng batch), tạo progress `new` cho từng từ và cộng totalWords.
   * Không tự phát sự kiện; người gọi phát sau khi transaction commit.
   */
  async createBatch(
    userId: string,
    collectionId: string,
    words: CreateVocabularyInput[],
    source: VocabSource,
    tx?: Prisma.TransactionClient,
  ): Promise<{ saved: Vocabulary[]; skippedTerms: string[] }> {
    if (!tx) {
      return this.prisma.$transaction((t) =>
        this.createBatch(userId, collectionId, words, source, t),
      );
    }
    await this.collections.assertOwned(userId, collectionId, tx);
    const existing = await tx.vocabulary.findMany({
      where: { collectionId },
      select: { term: true },
    });
    const seen = new Set(existing.map((e) => termKey(e.term)));
    const saved: Vocabulary[] = [];
    const skippedTerms: string[] = [];
    for (const w of words) {
      const key = termKey(w.term);
      if (seen.has(key)) {
        skippedTerms.push(w.term);
        continue;
      }
      seen.add(key);
      saved.push(
        await tx.vocabulary.create({
          data: { ...w, term: w.term.trim(), collectionId, source },
        }),
      );
    }
    if (saved.length) {
      await tx.userVocabProgress.createMany({
        data: saved.map((v) => ({ userId, vocabularyId: v.id })),
      });
      await tx.collection.update({
        where: { id: collectionId },
        data: { totalWords: { increment: saved.length } },
      });
    }
    return { saved, skippedTerms };
  }

  /** Lưu các từ AI đã chọn (Màn 14) trong một transaction, rồi đẩy job sinh audio. */
  async batchSave(
    userId: string,
    dto: BatchSaveDto,
  ): Promise<BatchSaveResultDto> {
    const words: CreateVocabularyInput[] = dto.words.map(({ ipa, ...w }) => ({
      ...w,
      ipaUk: w.ipaUk ?? ipa,
    }));
    const { saved, skippedTerms } = await this.createBatch(
      userId,
      dto.collectionId,
      words,
      'ai_generated',
    );
    this.emitCreated(saved);
    return {
      savedCount: saved.length,
      skippedTerms,
      vocabularies: saved.map((v) =>
        toVocabularyDto(v, {
          status: 'new',
          repetitionLevel: 0,
          nextReviewAt: null,
        }),
      ),
    };
  }

  emitCreated(vocabularies: Pick<Vocabulary, 'id'>[]): void {
    if (vocabularies.length) {
      const event: VocabularyCreatedEvent = {
        ids: vocabularies.map((v) => v.id),
      };
      this.events.emit(VOCABULARY_CREATED, event);
    }
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateVocabularyDto,
  ): Promise<VocabularyDto> {
    const current = await this.assertOwned(userId, id);
    const newTerm = typeof dto.term === 'string' ? dto.term : null;
    const termChanged =
      newTerm !== null && termKey(newTerm) !== termKey(current.term);
    if (newTerm !== null && termChanged) {
      const others = await this.prisma.vocabulary.findMany({
        where: { collectionId: current.collectionId, NOT: { id } },
        select: { term: true },
      });
      if (others.some((o) => termKey(o.term) === termKey(newTerm))) {
        throw vocabularyExists(newTerm);
      }
    }
    const updated = await this.prisma.vocabulary.update({
      where: { id },
      // Đổi term thì bỏ audio cũ ngay để app không phát sai từ trong lúc chờ sinh lại
      data: termChanged ? { ...dto, audioUkUrl: null, audioUsUrl: null } : dto,
    });
    if (termChanged) {
      const event: VocabularyCreatedEvent = { ids: [id] };
      this.events.emit(VOCABULARY_TERM_CHANGED, event);
    }
    return this.toDtoWithProgress(userId, updated);
  }

  /** Xoá từ (progress xoá theo), giảm totalWords và ghi tombstone. */
  async remove(userId: string, id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const v = await this.assertOwned(userId, id, tx);
      await tx.vocabulary.delete({ where: { id } });
      await tx.collection.update({
        where: { id: v.collectionId },
        data: { totalWords: { decrement: 1 } },
      });
      await tx.deletedRecord.create({
        data: { userId, entityType: 'vocabulary', entityId: id },
      });
    });
  }

  private async toDtoWithProgress(
    userId: string,
    v: Vocabulary,
  ): Promise<VocabularyDto> {
    const progress = await this.prisma.userVocabProgress.findUnique({
      where: { userId_vocabularyId: { userId, vocabularyId: v.id } },
    });
    return toVocabularyDto(v, progress);
  }
}
