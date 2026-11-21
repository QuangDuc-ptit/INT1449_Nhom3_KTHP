import { TextToSpeechClient } from '@google-cloud/text-to-speech';
import { Accent, TtsProvider } from './tts.provider';

const VOICES: Record<Accent, { languageCode: string; name: string }> = {
  uk: { languageCode: 'en-GB', name: 'en-GB-Neural2-B' },
  us: { languageCode: 'en-US', name: 'en-US-Neural2-D' },
};

/** Google Cloud Text-to-Speech; xác thực qua GOOGLE_APPLICATION_CREDENTIALS. */
export class GoogleTtsProvider extends TtsProvider {
  constructor(private readonly client = new TextToSpeechClient()) {
    super();
  }

  async synthesize(text: string, accent: Accent): Promise<Buffer> {
    const [res] = await this.client.synthesizeSpeech({
      input: { text },
      voice: VOICES[accent],
      audioConfig: { audioEncoding: 'MP3' },
    });
    if (!res.audioContent) {
      throw new Error(`Google TTS không trả audio cho "${text}"`);
    }
    return Buffer.from(res.audioContent as Uint8Array);
  }
}
