import { ValidationError, ValidationPipe } from '@nestjs/common';
import { AppException, FieldError } from '../http/app.exception';

function flatten(errors: ValidationError[], parent = ''): FieldError[] {
  return errors.flatMap((e) => {
    const field = parent ? `${parent}.${e.property}` : e.property;
    const own = Object.entries(e.constraints ?? {}).map(([key, msg]) => ({
      field,
      message:
        key === 'whitelistValidation' ? `Trường ${field} không được phép` : msg,
    }));
    return [...own, ...flatten(e.children ?? [], field)];
  });
}

export function createValidationPipe(): ValidationPipe {
  return new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    exceptionFactory: (errors) =>
      new AppException(
        400,
        'VALIDATION_ERROR',
        'Dữ liệu không hợp lệ',
        flatten(errors),
      ),
  });
}
