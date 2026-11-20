import { TtsProvider } from './tts.provider';

/**
 * Một frame MPEG-1 Layer III im lặng (128 kbps, 44.1 kHz) để có file MP3
 * hợp lệ khi chạy dev/test/Demo mà không cần gọi dịch vụ TTS.
 */
const SILENT_FRAME = Buffer.concat([
  Buffer.from([0xff, 0xfb, 0x90, 0x64]),
  Buffer.alloc(413),
]);

export class MockTtsProvider extends TtsProvider {
  synthesize(): Promise<Buffer> {
    return Promise.resolve(Buffer.from(SILENT_FRAME));
  }
}
