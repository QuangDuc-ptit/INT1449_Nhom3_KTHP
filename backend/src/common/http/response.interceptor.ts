import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, map } from 'rxjs';
import { Clock } from '../time/clock';
import { RESPONSE_MESSAGE_KEY } from './response-message.decorator';

export interface ApiResponse<T> {
  success: true;
  data: T;
  message: string;
  timestamp: string;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<
  T,
  ApiResponse<T>
> {
  constructor(
    private readonly reflector: Reflector,
    private readonly clock: Pick<Clock, 'now'>,
  ) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<ApiResponse<T>> {
    const message =
      this.reflector.getAllAndOverride<string | undefined>(
        RESPONSE_MESSAGE_KEY,
        [context.getHandler(), context.getClass()],
      ) ?? 'Thành công';
    return next.handle().pipe(
      map((data) => ({
        success: true as const,
        data: data === undefined ? (null as T) : data,
        message,
        timestamp: this.clock.now().toISOString(),
      })),
    );
  }
}
