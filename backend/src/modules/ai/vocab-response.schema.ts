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
          partOfSpeech: { type: 'string' },
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
