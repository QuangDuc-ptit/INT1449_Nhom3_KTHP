import {
  hashPassword,
  isStrongPassword,
  verifyPassword,
} from './password.util';

describe('password.util', () => {
  it('chấp nhận mật khẩu đủ 8 ký tự, có chữ hoa và số', () => {
    expect(isStrongPassword('Password123')).toBe(true);
  });

  it('từ chối mật khẩu thiếu chữ hoa', () => {
    expect(isStrongPassword('password123')).toBe(false);
  });

  it('từ chối mật khẩu thiếu chữ số', () => {
    expect(isStrongPassword('Passwordabc')).toBe(false);
  });

  it('từ chối mật khẩu ngắn hơn 8 ký tự', () => {
    expect(isStrongPassword('Pass1')).toBe(false);
  });

  it('hash bằng bcrypt salt 10 và kiểm tra được', async () => {
    const hash = await hashPassword('Password123');
    expect(hash).toMatch(/^\$2[aby]\$10\$/);
    await expect(verifyPassword('Password123', hash)).resolves.toBe(true);
    await expect(verifyPassword('Password124', hash)).resolves.toBe(false);
  });
});
