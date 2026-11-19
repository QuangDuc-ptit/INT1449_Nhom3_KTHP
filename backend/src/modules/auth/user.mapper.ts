import { User } from '@prisma/client';

export interface UserDto {
  id: string;
  email: string;
  fullName: string;
  avatarUrl: string | null;
}

export function toUserDto(user: User): UserDto {
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    avatarUrl: user.avatarUrl,
  };
}
