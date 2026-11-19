import { Injectable } from '@nestjs/common';
import { Collection, Prisma } from '@prisma/client';
import { AppException } from '../../common/http/app.exception';
import { Paginated, paginated } from '../../common/pagination/pagination.dto';
import { PrismaService } from '../../infra/prisma/prisma.service';
import {
  CollectionDto,
  CreateCollectionDto,
  ListCollectionsQueryDto,
  UpdateCollectionDto,
} from './dto/collection.dto';

export const collectionNotFound = () =>
  new AppException(404, 'COLLECTION_NOT_FOUND', 'Không tìm thấy học phần');

export function toCollectionDto(c: Collection): CollectionDto {
  return {
    id: c.id,
    title: c.title,
    description: c.description,
    category: c.category,
    iconName: c.iconName,
    isPublic: c.isPublic,
    totalWords: c.totalWords,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

@Injectable()
export class CollectionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Trả học phần nếu thuộc user; ngược lại 404 (không tiết lộ sự tồn tại). */
  async assertOwned(
    userId: string,
    collectionId: string,
    tx: Prisma.TransactionClient = this.prisma,
  ): Promise<Collection> {
    const c = await tx.collection.findFirst({
      where: { id: collectionId, userId },
    });
    if (!c) throw collectionNotFound();
    return c;
  }

  async create(
    userId: string,
    dto: CreateCollectionDto,
  ): Promise<CollectionDto> {
    const c = await this.prisma.collection.create({
      data: { ...dto, userId },
    });
    return toCollectionDto(c);
  }

  async list(
    userId: string,
    q: ListCollectionsQueryDto,
  ): Promise<Paginated<CollectionDto>> {
    const where: Prisma.CollectionWhereInput = {
      userId,
      ...(q.category ? { category: q.category } : {}),
      ...(q.search
        ? {
            OR: [
              { title: { contains: q.search, mode: 'insensitive' } },
              { description: { contains: q.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.collection.findMany({
        where,
        orderBy: [{ updatedAt: 'desc' }, { id: 'asc' }],
        skip: (q.page - 1) * q.limit,
        take: q.limit,
      }),
      this.prisma.collection.count({ where }),
    ]);
    return paginated(items.map(toCollectionDto), total, q);
  }

  async get(userId: string, id: string): Promise<CollectionDto> {
    return toCollectionDto(await this.assertOwned(userId, id));
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateCollectionDto,
  ): Promise<CollectionDto> {
    await this.assertOwned(userId, id);
    const c = await this.prisma.collection.update({ where: { id }, data: dto });
    return toCollectionDto(c);
  }

  /** Xoá học phần (từ vựng và tiến độ bị xoá theo) và ghi tombstone cho đồng bộ offline. */
  async remove(userId: string, id: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await this.assertOwned(userId, id, tx);
      const vocabs = await tx.vocabulary.findMany({
        where: { collectionId: id },
        select: { id: true },
      });
      await tx.deletedRecord.createMany({
        data: [
          { userId, entityType: 'collection', entityId: id },
          ...vocabs.map((v) => ({
            userId,
            entityType: 'vocabulary' as const,
            entityId: v.id,
          })),
        ],
      });
      await tx.collection.delete({ where: { id } });
    });
  }
}
