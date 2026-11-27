import { SAMPLE_WORDS } from '../../common/data/sample-words';
import { AiVocabProvider, GenerateVocabInput } from './ai-vocab.provider';

/**
 * Provider giả lập cho dev/test và chế độ Demo: trả từ mẫu theo đúng số
 * lượng và cấp độ yêu cầu, không gọi mạng. Chủ đề dùng để xoay vòng thứ tự.
 */
export class MockAiVocabProvider extends AiVocabProvider {
  readonly models = ['mock'] as const;

  generate(input: GenerateVocabInput): Promise<unknown> {
    const offset =
      [...input.topic].reduce((s, ch) => s + ch.charCodeAt(0), 0) %
      SAMPLE_WORDS.length;
    const words = Array.from({ length: input.wordCount }, (_, i) => {
      const [term, partOfSpeech, ipa, definitionEn, definitionVi, example] =
        SAMPLE_WORDS[(offset + i) % SAMPLE_WORDS.length];
      return {
        term,
        partOfSpeech,
        ipa,
        definitionEn,
        definitionVi,
        exampleSentence: example,
        cefrLevel: input.cefrLevel,
      };
    });
    return Promise.resolve({ words });
  }
}
