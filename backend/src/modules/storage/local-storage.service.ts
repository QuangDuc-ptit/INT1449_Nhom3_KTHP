import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { StorageService, assertSafeKey } from './storage.service';

export const UPLOADS_ROUTE = '/uploads';

/** Lưu file trên đĩa và phục vụ tĩnh qua /uploads (dùng cho dev và Demo). */
export class LocalStorageService extends StorageService {
  constructor(
    private readonly rootDir: string,
    private readonly publicBaseUrl: string,
  ) {
    super();
  }

  /** contentType không cần cho file cục bộ (Express suy ra từ phần mở rộng). */
  async putObject(
    key: string,
    body: Buffer,
    _contentType?: string,
  ): Promise<string> {
    assertSafeKey(key);
    const path = join(this.rootDir, ...key.split('/'));
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, body);
    return `${this.publicBaseUrl.replace(/\/+$/, '')}${UPLOADS_ROUTE}/${key}`;
  }
}
