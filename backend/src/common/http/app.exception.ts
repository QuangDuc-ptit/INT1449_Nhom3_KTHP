import { HttpException } from '@nestjs/common';

export interface FieldError {
  field: string;
  message: string;
}

/** Lỗi nghiệp vụ có mã lỗi và thông báo tiếng Việt. */
export class AppException extends HttpException {
  constructor(
    status: number,
    readonly errorCode: string,
    message: string,
    readonly errors?: FieldError[],
  ) {
    super(message, status);
  }
}
