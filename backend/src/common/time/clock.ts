import { Injectable } from '@nestjs/common';

/** Nguồn thời gian duy nhất của ứng dụng; inject để test cố định được "bây giờ". */
export abstract class Clock {
  abstract now(): Date;
}

@Injectable()
export class SystemClock extends Clock {
  now(): Date {
    return new Date();
  }
}
