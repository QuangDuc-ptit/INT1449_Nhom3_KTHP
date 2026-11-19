export type Accent = 'uk' | 'us';
export const ACCENTS: Accent[] = ['uk', 'us'];

/** Chuyển văn bản thành MP3 phát âm theo giọng Anh-Anh hoặc Anh-Mỹ. */
export abstract class TtsProvider {
  abstract synthesize(text: string, accent: Accent): Promise<Buffer>;
}
