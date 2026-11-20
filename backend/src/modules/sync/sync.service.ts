import { Injectable } from '@nestjs/common';
import { ProgressStatus, SyncEntity } from '@prisma/client';
import { Clock } from '../../common/time/clock';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { toCollectionDto } from '../collections/collections.service';
import { CollectionDto } from '../collections/dto/collection.dto';
import { VocabularyDto } from '../vocabularies/dto/vocabulary.dto';
import { toVocabularyDto } from '../vocabularies/vocabulary.mapper';

export interface SyncProgressDto {
  vocabularyId: string;
  status: ProgressStatus;
  repetitionLevel: number;
  easeFactor: number;
  intervalDays: number;
  nextReviewAt: Date | null;
  lastReviewedAt: Date | null;
  reviewCount: number;
  correctCount: number;
  incorrectCount: number;
  updatedAt: Date;
}

export interface SyncDeltaDto {
  /** Mốc thời gian server; FE lưu lại để làm `since` cho lần đồng bộ sau. */
  serverTime: Date;
  collections: CollectionDto[];
  vocabularies: VocabularyDto[];
  progress: SyncProgressDto[];
  deleted: { entityType: SyncEntity; entityId: string; deletedAt: Date }[];
}

/** Khoảng lùi (ms) khi so với since, xem SyncService.delta. */
export const SYNC_OVERLAP_MS = 2000;

@Injectable()
export class SyncService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  /** Trả mọi thay đổi sau `since` (không có `since` = đồng bộ toàn bộ). */
  async delta(userId: string, since?: Date): Promise<SyncDeltaDto> {
    // Lấy mốc trước khi truy vấn để không bỏ sót thay đổi xảy ra trong lúc đọc
    const serverTime = this.clock.now();
    // Lùi mốc một chút: transaction đóng dấu updatedAt trước serverTime lần trước nhưng
    // commit sau đó vẫn được gửi lại. FE upsert theo id nên nhận trùng không sao.
    const from = since
      ? new Date(since.getTime() - SYNC_OVERLAP_MS)
      : undefined;
    const changed = from ? { updatedAt: { gt: from } } : {};

    const [collections, vocabularies, progress, deleted] = await Promise.all([
      this.prisma.collection.findMany({
        where: { userId, ...changed },
        orderBy: [{ updatedAt: 'asc' }, { id: 'asc' }],
      }),
      this.prisma.vocabulary.findMany({
        where: { collection: { userId }, ...changed },
        include: { progress: { where: { userId } } },
        orderBy: [{ updatedAt: 'asc' }, { id: 'asc' }],
      }),
      this.prisma.userVocabProgress.findMany({
        where: { userId, ...changed },
        orderBy: [{ updatedAt: 'asc' }, { id: 'asc' }],
      }),
      since
        ? this.prisma.deletedRecord.findMany({
            where: { userId, deletedAt: { gt: from } },
            orderBy: { deletedAt: 'asc' },
          })
        : Promise.resolve([]),
    ]);

    return {
      serverTime,
      collections: collections.map(toCollectionDto),
      vocabularies: vocabularies.map((v) => toVocabularyDto(v, v.progress[0])),
      progress: progress.map((p) => ({
        vocabularyId: p.vocabularyId,
        status: p.status,
        repetitionLevel: p.repetitionLevel,
        easeFactor: p.easeFactor,
        intervalDays: p.intervalDays,
        nextReviewAt: p.nextReviewAt,
        lastReviewedAt: p.lastReviewedAt,
        reviewCount: p.reviewCount,
        correctCount: p.correctCount,
        incorrectCount: p.incorrectCount,
        updatedAt: p.updatedAt,
      })),
      deleted: deleted.map((d) => ({
        entityType: d.entityType,
        entityId: d.entityId,
        deletedAt: d.deletedAt,
      })),
    };
  }
}
