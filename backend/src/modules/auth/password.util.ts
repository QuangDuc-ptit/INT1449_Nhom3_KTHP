import { compare, hash } from 'bcryptjs';

export const BCRYPT_SALT_ROUNDS = 10;

/** Tối thiểu 8 ký tự, có ít nhất 1 chữ hoa và 1 chữ số. */
export const STRONG_PASSWORD_REGEX = /^(?=.*[A-Z])(?=.*\d).{8,}$/;

export const STRONG_PASSWORD_MESSAGE =
  'Mật khẩu phải có tối thiểu 8 ký tự, gồm ít nhất 1 chữ hoa và 1 chữ số';

export function isStrongPassword(password: string): boolean {
  return STRONG_PASSWORD_REGEX.test(password);
}

export function hashPassword(password: string): Promise<string> {
  return hash(password, BCRYPT_SALT_ROUNDS);
}

export function verifyPassword(
  password: string,
  passwordHash: string,
): Promise<boolean> {
  return compare(password, passwordHash);
}
