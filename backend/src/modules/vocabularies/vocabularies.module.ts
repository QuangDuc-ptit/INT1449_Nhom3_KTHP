import { Module } from '@nestjs/common';
import { CollectionsModule } from '../collections/collections.module';
import { VocabulariesController } from './vocabularies.controller';
import { VocabulariesService } from './vocabularies.service';

@Module({
  imports: [CollectionsModule],
  controllers: [VocabulariesController],
  providers: [VocabulariesService],
  exports: [VocabulariesService],
})
export class VocabulariesModule {}
