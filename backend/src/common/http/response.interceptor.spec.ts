import { CallHandler, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { lastValueFrom, of } from 'rxjs';
import { ResponseInterceptor } from './response.interceptor';
import { RESPONSE_MESSAGE_KEY } from './response-message.decorator';

const fixedNow = new Date('2026-11-19T10:00:00.000Z');
const clock = { now: () => fixedNow };

function ctx(): ExecutionContext {
  return {
    getHandler: () => () => undefined,
    getClass: () => class {},
  } as unknown as ExecutionContext;
}

describe('ResponseInterceptor', () => {
  it('bọc dữ liệu trả về theo chuẩn { success, data, message, timestamp }', async () => {
    const interceptor = new ResponseInterceptor(new Reflector(), clock);
    const next: CallHandler = { handle: () => of({ a: 1 }) };
    const result = await lastValueFrom(interceptor.intercept(ctx(), next));
    expect(result).toEqual({
      success: true,
      data: { a: 1 },
      message: 'Thành công',
      timestamp: '2026-11-19T10:00:00.000Z',
    });
  });

  it('dùng message từ @ResponseMessage nếu có', async () => {
    const reflector = new Reflector();
    jest
      .spyOn(reflector, 'getAllAndOverride')
      .mockImplementation((key) =>
        key === RESPONSE_MESSAGE_KEY ? 'Đăng ký thành công' : undefined,
      );
    const interceptor = new ResponseInterceptor(reflector, clock);
    const next: CallHandler = { handle: () => of(null) };
    const result = await lastValueFrom(interceptor.intercept(ctx(), next));
    expect(result).toMatchObject({
      success: true,
      data: null,
      message: 'Đăng ký thành công',
    });
  });
});
