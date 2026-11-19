import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { LocalStorageService } from './local-storage.service';

describe('LocalStorageService', () => {
  let dir: string;
  let storage: LocalStorageService;

  beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'karvocab-storage-'));
    storage = new LocalStorageService(dir, 'http://localhost:3100');
  });

  afterEach(() => {
    rmSync(dir, { recursive: true, force: true });
  });

  it('ghi file vào thư mục uploads và trả URL công khai', async () => {
    const url = await storage.putObject(
      'audio/x-uk.mp3',
      Buffer.from('abc'),
      'audio/mpeg',
    );
    expect(url).toBe('http://localhost:3100/uploads/audio/x-uk.mp3');
    expect(readFileSync(join(dir, 'audio', 'x-uk.mp3'), 'utf8')).toBe('abc');
  });

  it('ghi đè được file đã có', async () => {
    await storage.putObject('a.txt', Buffer.from('1'), 'text/plain');
    await storage.putObject('a.txt', Buffer.from('2'), 'text/plain');
    expect(readFileSync(join(dir, 'a.txt'), 'utf8')).toBe('2');
  });

  it.each(['../evil.mp3', 'audio/../../evil.mp3', '/abs.mp3', 'a\\b.mp3', ''])(
    'từ chối key không an toàn: %s',
    async (key) => {
      await expect(
        storage.putObject(key, Buffer.from('x'), 'audio/mpeg'),
      ).rejects.toThrow(/key/i);
    },
  );
});
