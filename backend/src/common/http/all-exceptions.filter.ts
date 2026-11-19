import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Clock } from '../time/clock';
import { AppException, FieldError } from './app.exception';

const DEFAULTS: Record<number, { code: string; message: string }> = {
  400: { code: 'BAD_REQUEST', message: 'Yêu cầu không hợp lệ' },
  401: { code: 'UNAUTHORIZED', message: 'Bạn cần đăng nhập để tiếp tục' },
  403: {
    code: 'FORBIDDEN',
    message: 'Bạn không có quyền thực hiện thao tác này',
  },
  404: { code: 'NOT_FOUND', message: 'Không tìm thấy tài nguyên' },
  409: { code: 'CONFLICT', message: 'Dữ liệu bị trùng lặp' },
  413: { code: 'PAYLOAD_TOO_LARGE', message: 'Dữ liệu gửi lên quá lớn' },
  429: {
    code: 'RATE_LIMITED',
    message: 'Bạn thao tác quá nhanh, vui lòng thử lại sau',
  },
  500: {
    code: 'INTERNAL_ERROR',
    message: 'Đã có lỗi xảy ra, vui lòng thử lại sau',
  },
};

interface Resolved {
  status: number;
  errorCode: string;
  message: string;
  errors?: FieldError[];
}

function fromStatus(status: number): Resolved {
  const d = DEFAULTS[status] ?? (status >= 500 ? DEFAULTS[500] : DEFAULTS[400]);
  return { status, errorCode: d.code, message: d.message };
}

interface HttpResponseLike {
  status(code: number): { json(body: unknown): unknown };
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');

  constructor(private readonly clock: Pick<Clock, 'now'>) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const res = http.getResponse<HttpResponseLike>();
    const r = this.resolve(exception);
    if (r.status >= 500) {
      const req = http.getRequest<{ method: string; url: string }>();
      this.logger.error(
        `${req.method} ${req.url}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }
    res.status(r.status).json({
      success: false,
      data: null,
      message: r.message,
      errorCode: r.errorCode,
      ...(r.errors ? { errors: r.errors } : {}),
      timestamp: this.clock.now().toISOString(),
    });
  }

  private resolve(exception: unknown): Resolved {
    if (exception instanceof AppException) {
      return {
        status: exception.getStatus(),
        errorCode: exception.errorCode,
        message: exception.message,
        errors: exception.errors,
      };
    }
    if (exception instanceof HttpException) {
      return fromStatus(exception.getStatus());
    }
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') return fromStatus(409);
      if (exception.code === 'P2025') return fromStatus(404);
      return fromStatus(500);
    }
    // Dữ liệu sai kiểu lọt qua DTO (vd null cho cột NOT NULL): lỗi của client, không phải 500
    if (exception instanceof Prisma.PrismaClientValidationError) {
      return {
        status: 400,
        errorCode: 'VALIDATION_ERROR',
        message: 'Dữ liệu không hợp lệ',
      };
    }
    // Lỗi từ body-parser của Express (JSON hỏng, body quá lớn...) mang sẵn status 4xx
    const status = (exception as { status?: unknown } | null)?.status;
    if (typeof status === 'number' && status >= 400 && status < 500) {
      return fromStatus(status);
    }
    return fromStatus(500);
  }
}
