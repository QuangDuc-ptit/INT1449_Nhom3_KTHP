import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { configureApp } from '../../src/bootstrap';
import { Clock } from '../../src/common/time/clock';

/** Đồng hồ điều khiển được trong test. */
export class TestClock extends Clock {
  constructor(private current: Date = new Date()) {
    super();
  }
  now(): Date {
    return new Date(this.current);
  }
  set(value: Date | string): void {
    this.current = new Date(value);
  }
}

export async function createTestApp(
  opts: { clock?: TestClock } = {},
): Promise<INestApplication> {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (opts.clock) {
    builder = builder.overrideProvider(Clock).useValue(opts.clock);
  }
  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication();
  configureApp(app);
  await app.init();
  return app;
}
