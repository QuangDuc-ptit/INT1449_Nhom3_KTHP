import { ArgumentsHost, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AllExceptionsFilter } from './all-exceptions.filter';
import { AppException } from './app.exception';

const clock = { now: () => new Date('2026-11-19T10:00:00.000Z') };

function run(exception: unknown) {
  const res = { statusCode: 0, body: undefined as unknown };
  const httpRes = {
    status: (code: number) => {
      res.statusCode = code;
      return httpRes;
    },
    json: (b: unknown) => {
      res.body = b;
      return httpRes;
    },
  };
  const host = {
    switchToHttp: () => ({
      getResponse: () => httpRes,
      getRequest: () => ({ url: '/x', method: 'GET' }),
    }),
  } as unknown as ArgumentsHost;
  new AllExceptionsFilter(clock).catch(exception, host);
  return res;
}

describe('AllExceptionsFilter', () => {
  it('chuyển AppException thành body lỗi chuẩn', () => {
    const res = run(
      new AppException(404, 'COLLECTION_NOT_FOUND', 'Không tìm thấy học phần'),
    );
    expect(res.statusCode).toBe(404);
    expect(res.body).toEqual({
      success: false,
      data: null,
      message: 'Không tìm thấy học phần',
      errorCode: 'COLLECTION_NOT_FOUND',
      timestamp: '2026-11-19T10:00:00.000Z',
    });
  });

  it('lỗi không xác định trả 500 và không lộ chi tiết', () => {
    const res = run(new Error('db password is hunter2'));
    expect(res.statusCode).toBe(500);
    expect(res.body).toMatchObject({
      success: false,
      errorCode: 'INTERNAL_ERROR',
      message: 'Đã có lỗi xảy ra, vui lòng thử lại sau',
    });
    expect(JSON.stringify(res.body)).not.toContain('hunter2');
  });

  it('HttpException của Nest được gán errorCode theo status', () => {
    const res = run(new NotFoundException());
    expect(res.statusCode).toBe(404);
    expect(res.body).toMatchObject({ errorCode: 'NOT_FOUND' });
  });

  it('Prisma P2002 thành 409 CONFLICT', () => {
    const err = new Prisma.PrismaClientKnownRequestError('dup', {
      code: 'P2002',
      clientVersion: 'x',
    });
    const res = run(err);
    expect(res.statusCode).toBe(409);
    expect(res.body).toMatchObject({ errorCode: 'CONFLICT' });
  });

  it('Prisma P2025 thành 404 NOT_FOUND', () => {
    const err = new Prisma.PrismaClientKnownRequestError('missing', {
      code: 'P2025',
      clientVersion: 'x',
    });
    expect(run(err).statusCode).toBe(404);
  });

  it('body quá lớn (413 từ body-parser) giữ nguyên status', () => {
    const err = Object.assign(new Error('request entity too large'), {
      status: 413,
      type: 'entity.too.large',
    });
    const res = run(err);
    expect(res.statusCode).toBe(413);
    expect(res.body).toMatchObject({ errorCode: 'PAYLOAD_TOO_LARGE' });
  });
});
