/** Lưu file (audio, avatar) và trả về URL công khai. */
export abstract class StorageService {
  abstract putObject(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<string>;
}

const SAFE_KEY = /^[A-Za-z0-9._-]+(\/[A-Za-z0-9._-]+)*$/;

/** Chặn key rỗng, tuyệt đối, có `..` hoặc ký tự lạ (chống ghi ra ngoài thư mục). */
export function assertSafeKey(key: string): void {
  if (
    !SAFE_KEY.test(key) ||
    key.split('/').some((p) => p === '..' || p === '.')
  ) {
    throw new Error(`Storage key không hợp lệ: "${key}"`);
  }
}
