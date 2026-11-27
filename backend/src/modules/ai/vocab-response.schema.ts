import { CefrLevel } from '@prisma/client';

export const PART_OF_SPEECH_VALUES = [
  'noun',
  'verb',
  'adj',
  'adv',
  'idiom',
] as const;

/** JSON Schema bắt buộc Gemini trả về (đặc tả BE mục 3.4). */
export const VOCAB_RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    words: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          term: { type: 'string' },
          partOfSpeech: { type: 'string', enum: [...PART_OF_SPEECH_VALUES] },
          ipa: { type: 'string' },
          definitionEn: { type: 'string' },
          definitionVi: { type: 'string' },
          exampleSentence: { type: 'string' },
          cefrLevel: { type: 'string' },
        },
        required: [
          'term',
          'partOfSpeech',
          'definitionEn',
          'definitionVi',
          'exampleSentence',
          'cefrLevel',
        ],
      },
    },
  },
  required: ['words'],
} as const;

/**
 * Schema cho một request cụ thể: khoá cấp độ CEFR đúng mức người dùng chọn và
 * số phần tử của mảng, để model không thể trả sai cấp độ hay thiếu/thừa từ.
 */
export function vocabSchemaFor(cefrLevel: CefrLevel, wordCount: number) {
  const base = VOCAB_RESPONSE_SCHEMA.properties.words;
  return {
    ...VOCAB_RESPONSE_SCHEMA,
    properties: {
      words: {
        ...base,
        minItems: wordCount,
        maxItems: wordCount,
        items: {
          ...base.items,
          properties: {
            ...base.items.properties,
            cefrLevel: { type: 'string', enum: [cefrLevel] },
          },
        },
      },
    },
  };
}
