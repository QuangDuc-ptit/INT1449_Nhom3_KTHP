# KarVocab Backend — Kế hoạch triển khai

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Mục tiêu:** Dựng toàn bộ backend KarVocab (Auth, Học phần, Từ vựng, Audio TTS, AI sinh từ, Quiz + SM-2, Streak, Huy hiệu, Dashboard, Hồ sơ, Push, Cron, Offline Sync) theo `BE-SPECIFICATION.md`, chạy được hoàn toàn offline bằng các provider mock.

**Kiến trúc:** Một service NestJS dạng module (mỗi domain một thư mục trong `backend/src/modules/`), PostgreSQL qua Prisma, Redis cho blacklist token / OTP / rate limit / hàng đợi BullMQ, `@nestjs/schedule` cho cron. Mọi dịch vụ bên ngoài (Gemini, TTS, S3, FCM, OAuth, email) nằm sau một interface và có 2 bản cài đặt: `mock` (mặc định, dùng cho dev/test) và bản thật, chọn bằng biến môi trường.

**Tech stack:** Node 24, NestJS 11, TypeScript, Prisma 6, PostgreSQL 15, Redis 7 (ioredis, BullMQ), class-validator, @nestjs/swagger, @nestjs/jwt, bcryptjs, date-fns-tz, @google/genai, @aws-sdk/client-s3, @google-cloud/text-to-speech, firebase-admin, google-auth-library, Jest + supertest, Docker Compose.

**Đặc tả:** `docs/karvocab/BE-SPECIFICATION.md` (nguồn chuẩn) + mục "Quyết định bổ sung" bên dưới. Khi FE và BE lệch nhau, **làm theo BE**; FE sửa theo sau (xem Task 27).

## Ràng buộc chung

- Mọi route có tiền tố `/api/v1`; Swagger tại `/api/docs`.
- Mọi response thành công: `{ "success": true, "data": ..., "message": "Thành công", "timestamp": "<ISO>" }`. Lỗi: `{ "success": false, "data": null, "message": "<tiếng Việt>", "errorCode": "<UPPER_SNAKE>", "errors"?: [...], "timestamp": "<ISO>" }`.
- Mật khẩu: tối thiểu 8 ký tự, có ít nhất 1 chữ hoa và 1 chữ số; hash bằng bcrypt (bcryptjs), salt rounds = 10.
- Access token sống 15 phút, refresh token sống 7 ngày, refresh token xoay vòng (rotation) mỗi lần dùng.
- OTP quên mật khẩu: 6 chữ số, lưu Redis TTL = 300 giây.
- Rate limit AI: tối đa 5 request / phút / user. Timeout gọi AI: 15 giây.
- SM-2: khoảng cách theo level 1→1, 2→3, 3→7, 4→16, 5→35 ngày; level 5 = `mastered`; đúng: `ease = min(2.5, ease + 0.1)`; sai: level 0, interval 1, `ease = max(1.3, ease − 0.2)`, `status = learning`.
- Fuzzy matching câu gõ: chuẩn hoá (trim, lowercase, gộp khoảng trắng), chấp nhận Levenshtein ≤ 1.
- Index bắt buộc: `users(email)`, `collections(user_id, category)`, `vocabularies(collection_id, term)`, `user_vocab_progress(user_id, next_review_at, status)`.
- Thông báo lỗi, message và mô tả Swagger viết bằng **tiếng Việt**; tên code (biến, hàm, file) bằng tiếng Anh.
- Không bao giờ commit `.env`, API key hay service account; chỉ commit `.env.example`.
- **Không bao giờ chạy `git push`** (chưa được cấp quyền).

## Quyết định bổ sung so với đặc tả

Những điểm đặc tả chưa nói hoặc nói chưa khớp. Đây là quyết định đã chốt; người triển khai không tự đổi.

1. **Vị trí:** toàn bộ backend nằm trong `backend/` ở gốc repo.
2. **Cột thêm vào `users`:** `auth_provider` (`local|google|facebook`), `provider_id`, `reminder_time` (`"HH:mm"`, mặc định `"20:00"`), `is_notification_enabled` (mặc định `true`), `timezone` (IANA, mặc định `Asia/Ho_Chi_Minh`), `language` (`vi|en`, mặc định `vi`). `password_hash` cho phép null (tài khoản social).
3. **Bảng thêm `deleted_records`** (tombstone) để `/sync/delta` báo được bản ghi đã xoá.
4. **`quiz_sessions.client_session_id`** (uuid, unique theo user) để nộp bài lặp lại do mạng không bị tính hai lần. `collection_id` cho phép null (phiên ôn tập tổng hợp).
5. **Server tự chấm bài.** `isCorrect` client gửi lên được chấp nhận nhưng bị bỏ qua; `GET /practice/questions` trả kèm đáp án đúng để FE phản hồi ngay (Màn 11).
6. **Chế độ luyện tập** (nội dung đề → đáp án mong đợi):
   - `listen_choose`: audio + IPA → chọn đúng `term` trong 4 phương án.
   - `listen_type`: audio + IPA → gõ `term`.
   - `choose_meaning`: `term` + IPA → chọn đúng `definitionVi` trong 4 phương án.
   - `type_meaning`: `definitionVi` → gõ `term`.
7. **Quyền sở hữu:** học phần là riêng tư theo user; truy cập tài nguyên của người khác trả **404** (không phải 403). `is_public` được lưu nhưng chưa có API duyệt học phần công khai.
8. **API thêm ngoài đặc tả:** `GET/PATCH/DELETE /collections/:id`, `POST /auth/logout`, `PATCH /users/profile`, `PATCH /users/password`, `POST /users/avatar`, `POST /users/devices`, `DELETE /users/devices`, `GET /practice/due`, `GET /practice/retry-missed`, `GET /sync/delta`, `GET /health`.
9. **Refresh token** là chuỗi ngẫu nhiên 64 byte (hex), DB chỉ lưu SHA-256. Dùng lại token đã thu hồi → thu hồi toàn bộ token của user đó.
10. **`forgot-password` luôn trả 200** dù email có tồn tại hay không (chống dò email). OTP lưu dạng hash; sai quá 5 lần → huỷ OTP.
11. **Từ AI** chỉ có một trường `ipa` → lưu vào `ipa_uk`.
12. **Tạo từ** (thủ công hay batch) đều tạo luôn bản ghi `user_vocab_progress` với `status = new`, `next_review_at = null`; trùng `term` trong cùng học phần (không phân biệt hoa thường) → 409 khi thêm thủ công, bỏ qua khi batch.
13. **Huy hiệu seed:**
    - `streak_7` "Chuỗi 7 Ngày": điều kiện `current_streak ≥ 7`, `required_points = 7`.
    - `first_100` "Bách Khoa 100 Từ": điều kiện số từ có `status ≠ new` ≥ 100, `required_points = 100`.
    - `explorer_5` "Nhà Thám Hiểm": điều kiện số học phần ≥ 5, `required_points = 5`.
14. **"Từ đã học hôm nay"** = số `vocabulary_id` khác nhau được trả lời **đúng** trong các phiên hoàn thành hôm nay, tính theo múi giờ của user.
16. **Chống học dồn (bổ sung sau review, người dùng đồng ý 20/11/2026):** mỗi từ chỉ chạy SM-2 **một lần mỗi phiên**, tính theo **câu trả lời đầu tiên**. Trả lời đúng chỉ lên level khi từ còn mới hoặc đã đến hạn (`nextReviewAt ≤ now`); chưa đến hạn thì giữ nguyên lịch, chỉ cộng số lần ôn. Trả lời sai vẫn reset như đặc tả. Mục đích: luyện dồn nhiều lần trong một tối không biến từ thành `mastered`.
17. **Ngoài phạm vi:** deploy production, domain/SSL, Sentry/Grafana (SHARED-BE-02); chạy k6 thật với 500 CCU (chỉ viết script); backup tự động lên S3 (chỉ viết script `pg_dump`).

## Quy trình Git và quy chuẩn commit

**Nhánh:**
- `main`: không đụng tới.
- `be/develop`: nhánh tích hợp backend, tạo từ `main` ở Task 0.
- Mỗi feature (F1…F9) có một nhánh riêng `feat/be-<số>-<tên>`, tạo từ `be/develop`.
- Khi feature xong và **toàn bộ kiểm tra cổng đều xanh**: `git switch be/develop && git merge --no-ff feat/be-<số>-<tên>`. Giữ lại nhánh feature, **không push**.

**Kiểm tra cổng trước khi merge một feature** (chạy trong `backend/`, tất cả phải xanh):
```bash
npm run lint && npm run build && npm test && npm run test:e2e
```

**Commit:** theo Conventional Commits, mô tả bằng tiếng Việt, mỗi task kết thúc bằng ít nhất một commit.
```
<type>(<scope>): <mô tả ngắn, ≤ 72 ký tự, không chấm cuối>

<Thân (tuỳ chọn): làm gì và vì sao.>

Refs: <Task ID trong đặc tả, vd BE1-S1-03>
```
- **Không** thêm dòng `Co-Authored-By`.
- Tác giả commit cấu hình cục bộ trong repo (`git config user.name/user.email`, không dùng `--global`): phần BE-1 đứng tên `TuanLe06 <leanhtuan180106@gmail.com>`; phần BE-2 đứng tên tài khoản người dùng cung cấp sau.

**Thứ tự thực hiện (theo tài khoản):**
- **Đợt BE-1** (tác giả TuanLe06): Task 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 20 → 22 → 24 → 25 → 27 (phần CI + backup).
  - Task 20 không phụ thuộc BE-2: hồ sơ tự đọc `badges`/`user_badges` và tự đếm chỉ số trong `UsersService`.
  - Nhánh feature của đợt này: `feat/be-01-foundation`, `feat/be-02-auth`, `feat/be-03-collections-vocab`, `feat/be-04-storage-audio`, `feat/be-07-users`, `feat/be-08-push`, `feat/be-09-sync-hardening`.
- **Đợt BE-2** (tác giả gửi sau): Task 13 → 14 → 15 → 16 → 17 → 18 → 19 → 21 → 23 → 26 → 27 (phần k6, tài liệu bàn giao).
  - Nhánh: `feat/be-05-ai`, `feat/be-06-srs-quiz`, `feat/be-10-gamification-dashboard`, `feat/be-11-jobs-handover`.
- `type`: `feat` | `fix` | `test` | `refactor` | `chore` | `build` | `ci` | `docs` | `perf`.
- `scope`: `infra` | `core` | `db` | `auth` | `users` | `collections` | `vocab` | `storage` | `audio` | `ai` | `quiz` | `srs` | `streak` | `gamification` | `dashboard` | `notifications` | `jobs` | `sync` | `security`.
- Commit merge: `merge(be): tích hợp feat/be-<số>-<tên> vào be/develop`.

## Trọng tâm review

Năm tình huống đặc tả ngầm yêu cầu, dễ gây lỗi nhất cho người dùng; mỗi dòng đã có test ở task tương ứng:
1. **Truy cập chéo (IDOR):** user B đọc/sửa/xoá học phần hoặc từ của A, hay nộp bài với `vocabularyId` của A → 404, dữ liệu A không đổi. *(Task 9, 10, 18)*
2. **Nộp bài trùng do mạng chập chờn:** gửi lại cùng `clientSessionId` → trả lại đúng kết quả cũ, không tạo session mới, không chạy SM-2/streak lần hai. *(Task 18)*
3. **Ranh giới ngày theo múi giờ:** học lúc 23:30 rồi 00:30 giờ VN (UTC+7) → streak tăng 1; cron chạy 00:30 giờ VN không reset người đã học hôm qua. *(Task 18, 23)*
4. **AI trả dữ liệu xấu:** JSON hỏng, thiếu trường, `cefrLevel` sai, từ trùng, quá 15 giây → lọc bỏ từ hỏng, hoặc lỗi thân thiện 502/504, không lỗi 500. *(Task 13)*
5. **Khoảng trắng và hoa thường khi gõ đáp án hoặc tìm kiếm:** `"  Coherent "` và `"coherant"` đều đúng với `coherent`; tìm `"ielts"` ra học phần "IELTS Core". *(Task 9, 16)*

---

## Cấu trúc file

```
backend/
  docker-compose.yml, Dockerfile, .env.example, .env.test, package.json, tsconfig*.json, nest-cli.json, .eslintrc/.prettierrc
  prisma/schema.prisma, prisma/migrations/, prisma/seed.ts
  docker/postgres-init.sql                 # tạo DB karvocab_test
  src/main.ts, src/app.module.ts, src/bootstrap.ts   # bootstrap dùng chung cho main và e2e
  src/config/env.schema.ts                 # validate env (zod)
  src/common/
    http/response.interceptor.ts, http/all-exceptions.filter.ts, http/app.exception.ts, http/response-message.decorator.ts
    validation/validation.pipe.ts          # ValidationPipe với message tiếng Việt
    auth/jwt-auth.guard.ts, auth/public.decorator.ts, auth/current-user.decorator.ts
    rate-limit/rate-limit.guard.ts, rate-limit/rate-limit.decorator.ts
    time/clock.ts, time/tz.util.ts
    pagination/pagination.dto.ts
  src/infra/prisma/prisma.service.ts, src/infra/redis/redis.service.ts
  src/modules/
    health/  auth/  users/  collections/  vocabularies/  storage/  audio/  mail/
    ai/  quiz/  spaced-repetition/  streak/  gamification/  dashboard/  notifications/  sync/
  src/jobs/streak-reset.job.ts, src/jobs/review-reminder.job.ts
  test/jest-e2e.json, test/global-setup.ts, test/utils/{app.ts,db.ts,auth.ts}, test/*.e2e-spec.ts
  scripts/backup-db.sh, load/k6-submit-and-ai.js
.github/workflows/backend-ci.yml
```
Unit test (`*.spec.ts`) đặt cạnh file nguồn; e2e đặt trong `backend/test/`.

---

## Task 0: Chuẩn bị nhánh và commit tài liệu

- [ ] **Bước 1:** `git switch -c be/develop` (từ `main` hiện tại).
- [ ] **Bước 2:** Commit `CLAUDE.md` (đã dịch) và file kế hoạch này:
  ```bash
  git add CLAUDE.md docs/superpowers/plans/2026-11-19-karvocab-backend.md
  git commit -m "docs: thêm CLAUDE.md tiếng Việt và kế hoạch triển khai backend"
  ```
- [ ] **Bước 3:** Kiểm tra: `git log --oneline -2` thấy commit mới; `git status` sạch.

---

# F1 — `feat/be-01-foundation` (BE1-S1-01, BE1-S1-02, BE1-S1-08)

### Task 1: Khung NestJS, Docker Compose, config, health check

**Files:** tạo `backend/` (scaffold), `docker-compose.yml`, `docker/postgres-init.sql`, `Dockerfile`, `.env.example`, `.env.test`, `src/config/env.schema.ts`, `src/infra/prisma/prisma.service.ts`, `src/infra/redis/redis.service.ts`, `src/modules/health/*`, `src/bootstrap.ts`; test `test/health.e2e-spec.ts`; sửa `.gitignore` gốc (thêm `backend/.env`, `backend/uploads/`, `backend/dist/`, `backend/node_modules/`, `backend/coverage/`).

**Interfaces:**
- Produces: `PrismaService extends PrismaClient` (global module); `RedisService { readonly client: Redis; }` (ioredis, global module); `configureApp(app: INestApplication): void` trong `bootstrap.ts` (prefix `api/v1`, pipe, filter, interceptor, swagger, helmet, cors). `main.ts` và e2e đều gọi hàm này.

- [ ] **Bước 1:** `git switch -c feat/be-01-foundation be/develop`, rồi `npx @nestjs/cli@11 new backend --package-manager npm --skip-git --strict`.
- [ ] **Bước 2:** `docker-compose.yml` gồm 3 service:
  - `postgres:15-alpine`: cổng `5433:5432`, user/pass `karvocab`/`karvocab`, DB `karvocab`, mount `docker/postgres-init.sql` vào `/docker-entrypoint-initdb.d/` (file này chạy `CREATE DATABASE karvocab_test;`).
  - `redis:7-alpine`: cổng `6380:6379`.
  - `pgadmin`: đặt trong `profiles: ["tools"]`.
- [ ] **Bước 3:** `.env.example` (các biến dưới đây). `.env.test` giống hệt nhưng `DATABASE_URL` trỏ tới `karvocab_test` và `REDIS_DB=1`.
  ```
  NODE_ENV=development
  PORT=3000
  DATABASE_URL=postgresql://karvocab:karvocab@localhost:5433/karvocab
  REDIS_HOST=localhost
  REDIS_PORT=6380
  REDIS_DB=0
  JWT_ACCESS_SECRET=change-me
  JWT_ACCESS_TTL=15m
  REFRESH_TOKEN_TTL_DAYS=7
  CORS_ORIGINS=http://localhost:3000
  AI_PROVIDER=mock                 # mock | gemini
  GEMINI_API_KEY=
  GEMINI_MODEL=gemini-2.0-flash
  TTS_PROVIDER=mock                # mock | google
  GOOGLE_APPLICATION_CREDENTIALS=
  STORAGE_PROVIDER=local           # local | s3
  PUBLIC_BASE_URL=http://localhost:3000
  S3_ENDPOINT=
  S3_REGION=auto
  S3_BUCKET=
  S3_ACCESS_KEY_ID=
  S3_SECRET_ACCESS_KEY=
  S3_PUBLIC_URL=
  PUSH_PROVIDER=mock               # mock | fcm
  FIREBASE_SERVICE_ACCOUNT_PATH=
  MAIL_PROVIDER=console            # console | resend
  RESEND_API_KEY=
  MAIL_FROM=KarVocab <no-reply@karvocab.app>
  SOCIAL_AUTH_MODE=mock            # mock | real
  GOOGLE_CLIENT_ID=
  FACEBOOK_APP_ID=
  FACEBOOK_APP_SECRET=
  JOBS_ENABLED=true
  ```
- [ ] **Bước 4:** `env.schema.ts`: export `envSchema` (zod) và `validateEnv(raw): Env`. Thiếu biến bắt buộc → app không khởi động; `JWT_ACCESS_SECRET` phải dài ≥ 16 ký tự trừ khi `NODE_ENV=test`. Gắn vào `ConfigModule.forRoot({ isGlobal: true, validate: validateEnv })`.
- [ ] **Bước 5:** Cài script trong `package.json`:
  - `test:e2e`: `dotenv -e .env.test -- jest --config test/jest-e2e.json --runInBand`
  - `prisma:migrate`: `prisma migrate dev`
  - `db:seed`: `prisma db seed`

  Cài `dotenv-cli` (dev) và `@nestjs/config`, `zod`, `ioredis`, `prisma`, `@prisma/client`.
- [ ] **Bước 6: Viết test lỗi** `test/health.e2e-spec.ts`:
  ```ts
  it('GET /api/v1/health trả trạng thái db và redis', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
    expect(res.body).toMatchObject({ success: true, data: { db: 'up', redis: 'up' } });
  });
  ```
- [ ] **Bước 7:** `docker compose up -d`, sau đó `npm run test:e2e -- health`. Kỳ vọng: FAIL (404). *Nếu Docker không chạy: dừng lại, nhờ người dùng mở Docker Desktop.*
- [ ] **Bước 8:** Cài `HealthController` (`@Public()`, `GET /health`): `SELECT 1` qua Prisma và `PING` qua Redis, trả `{ db, redis }`. Viết `configureApp()`; `test/utils/app.ts` export `createTestApp(): Promise<INestApplication>` dựng `AppModule` rồi gọi `configureApp`.
- [ ] **Bước 9:** Chạy `npm run test:e2e -- health` → PASS; chạy `npm run lint && npm run build` → xanh.
- [ ] **Bước 10:** Commit `chore(infra): khởi tạo NestJS, docker compose, config và health check` (Refs: BE1-S1-01).

### Task 2: Chuẩn hoá response, lỗi, validation, Swagger

**Files:** `src/common/http/*`, `src/common/validation/validation.pipe.ts`, `src/common/pagination/pagination.dto.ts`, `src/common/time/clock.ts`; test `src/common/http/response.interceptor.spec.ts`, `src/common/http/all-exceptions.filter.spec.ts`, `test/core.e2e-spec.ts`.

**Interfaces:**
- Produces:
  - `class AppException extends HttpException { constructor(status: number, errorCode: string, message: string, errors?: unknown[]) }`
  - `@ResponseMessage(msg: string)`: ghi đè `message` mặc định `"Thành công"`.
  - `PaginationQueryDto { page = 1 (≥1); limit = 20 (1..50) }`
  - `paginated<T>(items: T[], total: number, q: PaginationQueryDto) => { items, meta: { page, limit, total, totalPages } }`
  - `abstract class Clock { abstract now(): Date }`, provider mặc định `SystemClock`. **Mọi chỗ cần "bây giờ" phải inject `Clock`**, không gọi `new Date()` trực tiếp.

- [ ] **Bước 1: Viết test lỗi** (unit):
  - `ResponseInterceptor` bọc `{ a: 1 }` thành `{ success: true, data: { a: 1 }, message: 'Thành công', timestamp: <ISO string> }`.
  - `AllExceptionsFilter`:
    - `AppException(404, 'COLLECTION_NOT_FOUND', 'Không tìm thấy học phần')` → status 404, body `{ success: false, data: null, errorCode: 'COLLECTION_NOT_FOUND', message: 'Không tìm thấy học phần' }`.
    - Lỗi không xác định → status 500, `errorCode: 'INTERNAL_ERROR'`, `message: 'Đã có lỗi xảy ra, vui lòng thử lại sau'`, không lộ stack.
- [ ] **Bước 2:** `npm test -- common/http` → FAIL.
- [ ] **Bước 3:** Cài interceptor + filter.
  - Lỗi validation → 400, `errorCode: 'VALIDATION_ERROR'`, `errors: [{ field, message }]`.
  - Lỗi Prisma `P2002` → 409 `CONFLICT`; `P2025` → 404 `NOT_FOUND`.
  - `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`.
  - Swagger `DocumentBuilder` có tiêu đề "KarVocab API" và `addBearerAuth()`.
- [ ] **Bước 4: Viết test e2e** `core.e2e-spec.ts`: `GET /api/docs-json` → 200 với `info.title === 'KarVocab API'`; route không tồn tại → 404 với `success: false`.
- [ ] **Bước 5:** `npm test && npm run test:e2e` → PASS.
- [ ] **Bước 6:** Commit `feat(core): chuẩn hoá response, xử lý lỗi, validation và swagger` (Refs: BE1-S1-08).

### Task 3: Prisma schema, migration `init`, seed huy hiệu, hạ tầng test DB

**Files:** `prisma/schema.prisma`, `prisma/migrations/<ts>_init/`, `prisma/seed.ts`, `test/global-setup.ts`, `test/utils/db.ts`, `test/jest-e2e.json`; test `test/schema.e2e-spec.ts`.

**Interfaces:**
- Produces: Prisma models với tên field camelCase như dưới; `resetDb(prisma: PrismaService): Promise<void>` (TRUNCATE … CASCADE mọi bảng trừ `badges`); `globalSetup` chạy `prisma migrate reset --force --skip-generate` trên DB test (seed đi kèm).

- [ ] **Bước 1: Viết `schema.prisma`** đúng như sau (mỗi field có `@map` snake_case, mỗi model có `@@map` theo tên bảng; `id String @id @default(uuid()) @db.Uuid`; `createdAt @default(now())`, `updatedAt @updatedAt` ở bảng có cột này):
  ```prisma
  enum Role { user admin }
  enum AuthProvider { local google facebook }
  enum Platform { ios android }
  enum Category { academic career life travel other }
  enum PartOfSpeech { noun verb adj adv idiom }
  enum CefrLevel { A1 A2 B1 B2 C1 C2 }
  enum VocabSource { manual ai_generated }
  enum ProgressStatus { new learning review mastered }
  enum QuizMode { listen_choose listen_type choose_meaning type_meaning }
  enum Language { vi en }
  enum SyncEntity { collection vocabulary }

  model User          { email String @unique; passwordHash String?; fullName String; avatarUrl String?
                        authProvider AuthProvider @default(local); providerId String?
                        currentStreak Int @default(0); highestStreak Int @default(0); lastStreakDate DateTime? @db.Date
                        dailyGoalWords Int @default(10); reminderTime String @default("20:00")
                        isNotificationEnabled Boolean @default(true); timezone String @default("Asia/Ho_Chi_Minh")
                        language Language @default(vi); role Role @default(user); createdAt; updatedAt
                        @@unique([authProvider, providerId]) }                      // users
  model UserDevice    { userId → User (Cascade); fcmToken String @unique; platform Platform; updatedAt }  // user_devices
  model RefreshToken  { userId → User (Cascade); tokenHash String @unique; expiresAt DateTime; isRevoked Boolean @default(false); createdAt }  // refresh_tokens
  model Collection    { userId → User (Cascade); title String; description String?; category Category @default(other)
                        iconName String @default("book"); isPublic Boolean @default(false); totalWords Int @default(0)
                        createdAt; updatedAt; @@index([userId, category]) }        // collections
  model Vocabulary    { collectionId → Collection (Cascade); term String; partOfSpeech PartOfSpeech
                        ipaUk String?; ipaUs String?; audioUkUrl String?; audioUsUrl String?
                        definitionEn String?; definitionVi String; exampleSentence String?
                        cefrLevel CefrLevel; source VocabSource @default(manual); createdAt; updatedAt
                        @@index([collectionId, term]) }                             // vocabularies
  model UserVocabProgress { userId → User (Cascade); vocabularyId → Vocabulary (Cascade)
                        repetitionLevel Int @default(0); easeFactor Float @default(2.5); intervalDays Int @default(0)
                        nextReviewAt DateTime?; lastReviewedAt DateTime?; reviewCount Int @default(0)
                        correctCount Int @default(0); incorrectCount Int @default(0)
                        status ProgressStatus @default(new); updatedAt
                        @@unique([userId, vocabularyId]); @@index([userId, nextReviewAt, status]) }  // user_vocab_progress
  model QuizSession   { userId → User (Cascade); collectionId → Collection? (SetNull); clientSessionId String? @db.Uuid
                        mode QuizMode; totalQuestions Int; correctCount Int; incorrectCount Int; scorePercentage Int
                        durationSeconds Int; completedAt DateTime @default(now())
                        @@unique([userId, clientSessionId]); @@index([userId, completedAt]) }  // quiz_sessions
  model QuizAnswer    { sessionId → QuizSession (Cascade); vocabularyId → Vocabulary (Cascade)
                        userAnswer String; isCorrect Boolean; responseTimeMs Int; createdAt }  // quiz_answers
  model Badge         { code String @unique; title String; description String; iconUrl String?; requiredPoints Int }  // badges
  model UserBadge     { userId → User (Cascade); badgeId → Badge (Cascade); unlockedAt DateTime @default(now())
                        @@unique([userId, badgeId]) }                               // user_badges
  model DeletedRecord { userId → User (Cascade); entityType SyncEntity; entityId String @db.Uuid; deletedAt DateTime @default(now())
                        @@index([userId, deletedAt]) }                              // deleted_records
  ```
- [ ] **Bước 2:** `npx prisma migrate dev --name init`. Kiểm tra: thư mục migration được tạo, chạy không lỗi.
- [ ] **Bước 3:** `prisma/seed.ts` upsert 3 huy hiệu theo mục "Quyết định bổ sung" #13:
  - `streak_7` "Chuỗi 7 Ngày": "Học liên tục 7 ngày".
  - `first_100` "Bách Khoa 100 Từ": "Học 100 từ vựng".
  - `explorer_5` "Nhà Thám Hiểm": "Tạo 5 học phần".

  Khai báo seed trong `package.json` theo dạng `"prisma": { "seed": "ts-node prisma/seed.ts" }`.
- [ ] **Bước 4: Viết test** `schema.e2e-spec.ts`:
  - Bảng `badges` có đúng 3 dòng với `code` là `['explorer_5', 'first_100', 'streak_7']` (sắp xếp).
  - Tạo user + collection, xoá user → collection bị xoá theo (cascade).
  - Tạo 2 progress cùng (user, vocab) → lỗi `P2002`.
- [ ] **Bước 5:** Cài `test/global-setup.ts` và `resetDb`, rồi `npm run test:e2e` → toàn bộ PASS.
- [ ] **Bước 6:** Commit `feat(db): thêm schema prisma 11 bảng, migration init và seed huy hiệu` (Refs: BE1-S1-02).
- [ ] **Bước 7: Cổng merge F1:** chạy kiểm tra cổng; `git switch be/develop && git merge --no-ff feat/be-01-foundation`.

---

# F2 — `feat/be-02-auth` (BE1-S1-03 … BE1-S1-07)

### Task 4: Token, JWT guard toàn cục, đăng ký và đăng nhập

**Files:** `src/modules/auth/{auth.module,auth.controller,auth.service,token.service,password.util}.ts`, `src/modules/auth/dto/*.ts`, `src/common/auth/*`; test `src/modules/auth/password.util.spec.ts`, `test/auth.e2e-spec.ts`, `test/utils/auth.ts`.

**Interfaces:**
- Produces:
  - `TokenService.issuePair(user: { id: string; email: string; role: Role }): Promise<{ accessToken: string; refreshToken: string }>`: access token là JWT có claims `sub`, `email`, `role`, `jti`; refresh token là chuỗi ngẫu nhiên, DB lưu `sha256` + `expiresAt = now + 7 ngày`.
  - `type AuthUser = { id: string; email: string; role: Role; jti: string; exp: number }`
  - `@CurrentUser()` trả về `AuthUser`.
  - `JwtAuthGuard` đăng ký global qua `APP_GUARD`; `@Public()` để bỏ qua guard.
  - `toUserDto(user): { id, email, fullName, avatarUrl }`
  - Helper test: `registerUser(app, overrides?) => Promise<{ accessToken, refreshToken, user }>`.

- [ ] **Bước 1: Viết test lỗi** `password.util.spec.ts`:
  - `isStrongPassword('Password123') === true`
  - `isStrongPassword('password123') === false` (thiếu chữ hoa)
  - `isStrongPassword('Passwordabc') === false` (thiếu số)
  - `isStrongPassword('Pass1') === false` (ngắn hơn 8)
- [ ] **Bước 2: Viết test lỗi** `auth.e2e-spec.ts`:
  - `POST /auth/register {email:'A@Example.com', password:'Password123', fullName:'Nguyen Van A'}` → 201; `data.accessToken` và `data.refreshToken` có giá trị; `data.user.email === 'a@example.com'` (đã lowercase); DB lưu `passwordHash` bắt đầu bằng `$2`.
  - Đăng ký trùng email → 409 `EMAIL_EXISTS`.
  - Mật khẩu yếu → 400 `VALIDATION_ERROR`, `errors[0].field === 'password'`.
  - `POST /auth/login` đúng → 200; sai mật khẩu hoặc email không tồn tại → đều 401 `INVALID_CREDENTIALS` với cùng message "Email hoặc mật khẩu không đúng".
  - `GET /health` không cần token → 200. Một route có guard mà không gửi token → 401 `UNAUTHORIZED`. (Dùng tạm route `GET /auth/me` trả `toUserDto`.)
- [ ] **Bước 3:** `npm test -- password && npm run test:e2e -- auth` → FAIL.
- [ ] **Bước 4:** Cài DTO (`IsEmail`, `fullName` 1..100 ký tự), `AuthService.register/login`, `TokenService`, guard, các decorator, `GET /auth/me`. Email luôn `trim().toLowerCase()`.
- [ ] **Bước 5:** Chạy lại → PASS.
- [ ] **Bước 6:** Commit `feat(auth): đăng ký, đăng nhập và JWT guard toàn cục` (Refs: BE1-S1-03, BE1-S1-04).

### Task 5: Refresh token xoay vòng và đăng xuất

**Files:** sửa `auth.controller.ts`, `auth.service.ts`, `token.service.ts`, `jwt-auth.guard.ts`; test bổ sung vào `test/auth.e2e-spec.ts`.

**Interfaces:**
- Produces:
  - `TokenService.rotate(refreshToken: string): Promise<{ pair, user }>`
  - `TokenService.revokeAllForUser(userId: string): Promise<void>`
  - `TokenService.blacklistAccess(jti: string, exp: number): Promise<void>`: ghi Redis key `bl:<jti>`, TTL = `exp − now`. Guard từ chối mọi token có `bl:<jti>`.

- [ ] **Bước 1: Viết test lỗi:**
  - `POST /auth/refresh {refreshToken}` → 200 kèm cặp token mới; dùng lại refresh token cũ → 401 `REFRESH_TOKEN_REUSED`, sau đó cả refresh token mới cũng bị 401 (toàn bộ token của user đã bị thu hồi).
  - Refresh token hết hạn (sửa `expiresAt` trong DB về quá khứ) → 401 `REFRESH_TOKEN_INVALID`.
  - `POST /auth/logout {refreshToken}` kèm Bearer → 200; sau đó `GET /auth/me` bằng access token cũ → 401; refresh bằng token đã logout → 401.
- [ ] **Bước 2:** Chạy test → FAIL.
- [ ] **Bước 3:** Cài đặt. `rotate` chạy trong một transaction: tìm theo hash → nếu `isRevoked` thì gọi `revokeAllForUser` và ném `REFRESH_TOKEN_REUSED` → đánh dấu revoked → phát cặp mới.
- [ ] **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(auth): refresh token xoay vòng, phát hiện dùng lại và đăng xuất` (Refs: BE1-S1-06).

### Task 6: Rate limit bằng Redis, chống brute-force đăng nhập

**Files:** `src/common/rate-limit/{rate-limit.guard,rate-limit.decorator}.ts`, sửa `auth.controller.ts`; test `src/common/rate-limit/rate-limit.guard.spec.ts`, bổ sung `test/auth.e2e-spec.ts`.

**Interfaces:**
- Produces: `@RateLimit({ key: string; limit: number; windowSec: number; by: 'ip' | 'user' | 'ip+email' | 'email' })`. Guard dùng Redis `INCR` + `EXPIRE` trên key `rl:<key>:<identity>`; vượt giới hạn → 429 `RATE_LIMITED`, message "Bạn thao tác quá nhanh, vui lòng thử lại sau", header `Retry-After` = TTL còn lại.

- [ ] **Bước 1: Viết test lỗi:**
  - Unit (Redis giả lập bằng map): `limit = 2` thì request 1 và 2 qua, request 3 ném 429 có `retryAfter > 0`.
  - E2E: 6 lần login sai cùng email trong 60 giây → lần thứ 6 nhận 429 kèm `Retry-After`.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài guard, gắn `@RateLimit({ key: 'login', limit: 5, windowSec: 60, by: 'ip+email' })` cho `/auth/login`. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(security): rate limit bằng redis và chống brute-force đăng nhập`.

### Task 7: Quên mật khẩu bằng OTP, mail provider

**Files:** `src/modules/mail/{mail.module,mail.provider,console-mail.provider,resend-mail.provider}.ts`, sửa auth; test `test/auth-otp.e2e-spec.ts`, `src/modules/mail/resend-mail.provider.spec.ts`.

**Interfaces:**
- Produces:
  - `abstract class MailProvider { abstract send(msg: { to: string; subject: string; html: string }): Promise<void> }`
  - `ConsoleMailProvider` ghi log và lưu `lastMessages: MailMessage[]` để test đọc lại.
  - `ResendMailProvider` gọi `POST https://api.resend.com/emails` bằng `fetch`.

- [ ] **Bước 1: Viết test lỗi:**
  - `POST /auth/forgot-password {email}` với email tồn tại → 200; mail console nhận 1 thư có mã 6 chữ số; Redis có key `otp:reset:<email>`, TTL trong khoảng (0, 300].
  - Email không tồn tại → vẫn 200 với cùng message "Nếu email tồn tại, mã xác nhận đã được gửi"; không gửi thư nào.
  - `POST /auth/reset-password` với OTP đúng → 200; đăng nhập bằng mật khẩu mới được, mật khẩu cũ bị 401; refresh token cũ bị 401.
  - OTP sai → 400 `OTP_INVALID`; sai 5 lần thì đến OTP đúng cũng 400 (OTP đã bị huỷ).
  - Gọi `forgot-password` lần thứ 4 trong 15 phút → 429.
  - Unit `ResendMailProvider` (mock `fetch`) gửi đúng header `Authorization: Bearer <key>` và body `{from, to, subject, html}`.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. OTP hash bằng sha256; key đếm lần thử sai `otp:reset:attempts:<email>`; rate limit `forgot-password` là 3 lần / 900 giây theo email. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(auth): quên mật khẩu bằng OTP redis và mail provider` (Refs: BE1-S1-07).

### Task 8: Social login Google / Facebook

**Files:** `src/modules/auth/social/{social-verifier,mock-social.verifier,google.verifier,facebook.verifier}.ts`, sửa auth; test `test/auth-social.e2e-spec.ts`, `src/modules/auth/social/facebook.verifier.spec.ts`.

**Interfaces:**
- Produces: `abstract class SocialVerifier { abstract verify(provider: 'google' | 'facebook', idToken: string): Promise<{ providerId: string; email: string; fullName: string; avatarUrl?: string }> }`.
  - Bản mock nhận token dạng `mock:<providerId>:<email>:<fullName>`, token sai dạng → 401 `SOCIAL_TOKEN_INVALID`.
  - Bản Google dùng `OAuth2Client.verifyIdToken({ audience: GOOGLE_CLIENT_ID })`.
  - Bản Facebook gọi `graph.facebook.com/debug_token` rồi `/me?fields=id,name,email,picture`.

- [ ] **Bước 1: Viết test lỗi:**
  - Lần đầu login Google → 200, tạo user mới với `authProvider: 'google'` và `passwordHash: null`.
  - Login lại với cùng `providerId` → cùng `user.id`.
  - Email trùng một tài khoản local có sẵn → liên kết vào tài khoản đó (cùng `id`), user vẫn đăng nhập bằng mật khẩu được.
  - Tài khoản social không có mật khẩu mà gọi `/auth/login` → 401 `INVALID_CREDENTIALS`.
  - Unit Facebook verifier (mock `fetch`): `is_valid: false` → ném lỗi.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Chọn bản cài đặt theo `SOCIAL_AUTH_MODE`. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(auth): đăng nhập google và facebook với verifier mock` (Refs: BE1-S1-05).
- [ ] **Bước 6: Cổng merge F2:** chạy kiểm tra cổng, merge `feat/be-02-auth` vào `be/develop`.

---

# F3 — `feat/be-03-collections-vocab` (BE1-S2-01 … BE1-S2-03)

### Task 9: CRUD học phần

**Files:** `src/modules/collections/{collections.module,collections.controller,collections.service}.ts`, `dto/*`; test `test/collections.e2e-spec.ts`.

**Interfaces:**
- Produces:
  - `CollectionsService.assertOwned(userId: string, collectionId: string): Promise<Collection>`: ném 404 `COLLECTION_NOT_FOUND` nếu không tồn tại hoặc không phải của user.
  - `CollectionsService.list(userId, q: { category?: Category; search?: string; page; limit })`
  - Collection DTO trả ra: `{ id, title, description, category, iconName, isPublic, totalWords, createdAt, updatedAt }`.

- [ ] **Bước 1: Viết test lỗi:**
  - `POST /collections {title:'IELTS Core', category:'academic', iconName:'book'}` → 201, `totalWords = 0`.
  - `title` rỗng hoặc dài hơn 100 ký tự → 400; `category` ngoài enum → 400.
  - `GET /collections?search=ielts` tìm được "IELTS Core" (không phân biệt hoa thường, tìm cả `title` lẫn `description`).
  - `GET /collections?category=travel` chỉ trả học phần travel.
  - `?page=2&limit=1` trả `meta: { page: 2, limit: 1, total: 2, totalPages: 2 }`; `limit=51` → 400.
  - User B gọi `GET`, `PATCH`, `DELETE /collections/<idCuaA>` → đều 404; học phần của A không đổi.
  - `DELETE /collections/:id` → 200; bảng `deleted_records` có 1 dòng `entityType = collection` và 1 dòng cho mỗi từ trong học phần.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Tìm kiếm dùng Prisma `contains` + `mode: 'insensitive'`; sắp xếp theo `updatedAt desc`; xoá và ghi tombstone trong cùng một transaction. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(collections): crud học phần có phân trang, tìm kiếm và lọc` (Refs: BE1-S2-01).

### Task 10: CRUD từ vựng và danh sách từ kèm tiến độ

**Files:** `src/modules/vocabularies/{vocabularies.module,vocabularies.controller,vocabularies.service,vocabulary.mapper}.ts`, `dto/*`; test `test/vocabularies.e2e-spec.ts`.

**Interfaces:**
- Consumes: `CollectionsService.assertOwned`.
- Produces:
  - `type CreateVocabularyInput = { term; partOfSpeech; ipaUk?; ipaUs?; definitionEn?; definitionVi; exampleSentence?; cefrLevel }`
  - `VocabulariesService.createBatch(userId: string, collectionId: string, words: CreateVocabularyInput[], source: VocabSource, tx?: Prisma.TransactionClient): Promise<{ saved: Vocabulary[]; skippedTerms: string[] }>`: bỏ qua từ trùng (không phân biệt hoa thường, kể cả trùng ngay trong batch); tạo progress `new`; cộng `totalWords`.
  - `VocabulariesService.assertOwned(userId, vocabularyId): Promise<Vocabulary & { collection }>`
  - `toVocabularyDto(v, progress?)` trả `{ id, collectionId, term, partOfSpeech, ipaUk, ipaUs, audioUkUrl, audioUsUrl, definitionEn, definitionVi, exampleSentence, cefrLevel, source, progress: { status, repetitionLevel, nextReviewAt } | null }`.
  - Event hook: sau khi tạo từ, gọi `this.events.emit('vocabulary.created', { ids })` (dùng `@nestjs/event-emitter`); F4 lắng nghe event này.

- [ ] **Bước 1: Viết test lỗi:**
  - `POST /collections/:id/words` (body như đặc tả 3.3) → 201; `totalWords` của học phần thành 1; có progress `status: 'new'`, `nextReviewAt: null`.
  - Thêm `"Coherent "` vào học phần đã có `coherent` → 409 `VOCABULARY_EXISTS`.
  - Thiếu `definitionVi` hoặc `cefrLevel: 'D1'` → 400.
  - `GET /collections/:id/words` trả danh sách kèm `progress`, sắp xếp `createdAt asc`.
  - `PUT /vocabularies/:id` sửa được `definitionVi`.
  - `DELETE /vocabularies/:id` → 200; progress bị xoá; `totalWords` giảm 1; có tombstone `vocabulary`.
  - User B gọi `PUT`/`DELETE` từ của A → 404.
  - Unit qua service: `createBatch` với `[coherent, COHERENT, mitigate]` trong học phần đã có `mitigate` → `saved.length = 1`, `skippedTerms = ['COHERENT', 'mitigate']`.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Khi thêm hoặc xoá, cập nhật `totalWords` bằng `increment`/`decrement` trong cùng transaction. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(vocab): crud từ vựng và danh sách từ kèm tiến độ ôn tập` (Refs: BE1-S2-02, BE1-S2-03).
- [ ] **Bước 6: Cổng merge F3.**

---

# F4 — `feat/be-04-storage-audio` (BE1-S2-04 … BE1-S2-06)

### Task 11: Storage service (local / S3)

**Files:** `src/modules/storage/{storage.module,storage.service,local-storage.service,s3-storage.service}.ts`; sửa `bootstrap.ts` (serve static `/uploads`); test `local-storage.service.spec.ts`, `s3-storage.service.spec.ts`.

**Interfaces:**
- Produces: `abstract class StorageService { abstract putObject(key: string, body: Buffer, contentType: string): Promise<string /* public URL */> }`.
  - `local`: ghi vào `backend/uploads/<key>`, trả `${PUBLIC_BASE_URL}/uploads/<key>`.
  - `s3`: `PutObjectCommand` (tương thích R2/MinIO qua `S3_ENDPOINT`), trả `${S3_PUBLIC_URL}/<key>`.

- [ ] **Bước 1: Viết test lỗi:**
  - Local: `putObject('audio/x-uk.mp3', Buffer.from('abc'), 'audio/mpeg')` → file tồn tại với nội dung `abc`; URL là `http://localhost:3000/uploads/audio/x-uk.mp3`.
  - Key chứa `..` → ném lỗi.
  - S3 (mock `S3Client.send`): nhận `PutObjectCommand` với `Bucket`, `Key` và `ContentType` đúng.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(storage): storage service local và s3` (Refs: BE1-S2-04).

### Task 12: TTS provider, hàng đợi audio và worker

**Files:** `src/modules/audio/{audio.module,tts.provider,mock-tts.provider,google-tts.provider,audio.producer,audio.processor}.ts`, `src/modules/audio/fixtures/silence.mp3`; test `audio.processor.spec.ts`, `test/audio.e2e-spec.ts`.

**Interfaces:**
- Consumes: event `vocabulary.created { ids: string[] }`, `StorageService.putObject`.
- Produces:
  - `abstract class TtsProvider { abstract synthesize(text: string, accent: 'uk' | 'us'): Promise<Buffer> }`. Bản Google dùng giọng `en-GB-Neural2-B` / `en-US-Neural2-D`, định dạng MP3.
  - `AudioProducer.enqueue(vocabularyIds: string[]): Promise<void>`: BullMQ queue `audio`, job `generate-vocab-audio`, `jobId = vocabularyId` (không tạo job trùng), `attempts: 3`, backoff mũ.
  - `AudioProcessor.handle(vocabularyId: string): Promise<void>`

- [ ] **Bước 1: Viết test lỗi:**
  - Unit processor (Prisma, TTS, Storage đều mock):
    - Từ chưa có audio → gọi `synthesize` 2 lần (uk, us), `putObject` với key `audio/<id>-uk.mp3` và `audio/<id>-us.mp3`, cập nhật `audioUkUrl` / `audioUsUrl`.
    - Từ đã có cả 2 URL → không gọi TTS.
    - Từ đã bị xoá → kết thúc không lỗi.
  - E2E: thêm một từ → trong 5 giây (poll), từ có `audioUkUrl` khác null (TTS mock + storage local).
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. `BullModule.forRootAsync` dùng cấu hình Redis; listener `@OnEvent('vocabulary.created')` gọi `enqueue`; gom nhiều id bằng `addBulk` (dùng chung cho batch AI). **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(audio): worker sinh audio tts qua hàng đợi bullmq` (Refs: BE1-S2-05, BE1-S2-06).
- [ ] **Bước 6: Cổng merge F4.**

---

# F5 — `feat/be-05-ai` (BE2-S1-01 … BE2-S1-06)

### Task 13: Sinh từ vựng bằng AI

**Files:** `src/modules/ai/{ai.module,ai.controller,ai.service,ai-vocab.provider,mock-ai-vocab.provider,gemini-ai-vocab.provider,vocab-response.schema}.ts`, `dto/generate-vocab.dto.ts`; test `ai.service.spec.ts`, `gemini-ai-vocab.provider.spec.ts`, `test/ai.e2e-spec.ts`.

**Interfaces:**
- Produces:
  - `abstract class AiVocabProvider { abstract generate(input: { topic: string; cefrLevel: CefrLevel; wordCount: number }, signal: AbortSignal): Promise<unknown> }`: trả JSON đã parse.
  - `AiService.generate(userId, dto): Promise<{ words: GeneratedWord[] }>`, trong đó `GeneratedWord = { term, partOfSpeech, ipa?, definitionEn, definitionVi, exampleSentence, cefrLevel, existsInCollection: boolean }`.
  - DTO: `topic` 3..100 ký tự (đã trim), `cefrLevel` từ A1 đến C1, `wordCount` 3..20, `collectionId?` (uuid; nếu có thì phải thuộc user, dùng để đánh dấu `existsInCollection`).

- [ ] **Bước 1: Viết test lỗi** `ai.service.spec.ts` (provider giả lập):
  - Trả đúng 5 từ hợp lệ → 5 từ.
  - Có 1 từ thiếu `definitionVi`, 1 từ có `partOfSpeech: 'pronoun'`, 1 từ `cefrLevel: 'Z9'` → các từ này bị lọc bỏ.
  - Hai từ trùng `term` (khác hoa thường) → giữ 1.
  - Kết quả trả về nhiều hơn `wordCount` → cắt còn `wordCount`.
  - Provider trả `"not json"` hoặc `{}` → 502 `AI_BAD_RESPONSE`, message "AI trả về dữ liệu không hợp lệ, vui lòng thử lại".
  - Lọc xong không còn từ nào → cũng 502 `AI_BAD_RESPONSE`.
  - Provider không trả lời quá 15000 ms (dùng jest fake timers) → 504 `AI_TIMEOUT`, message "AI đang phản hồi chậm, vui lòng thử lại".
  - Provider ném lỗi bất kỳ → 502 `AI_UNAVAILABLE`.
- [ ] **Bước 2: Viết test lỗi** `gemini-ai-vocab.provider.spec.ts` (mock `@google/genai`): gọi `models.generateContent` với `model = GEMINI_MODEL`, `config.responseMimeType = 'application/json'`, `config.responseSchema` bằng schema ở đặc tả 3.4; topic nằm trong prompt dưới dạng dữ liệu được đặt trong dấu ngoặc kép, không được ghép như một câu lệnh.
- [ ] **Bước 3: Viết test e2e:** `POST /ai/generate-vocab` (provider mock) → 200 với `data.words.length === wordCount`; lần gọi thứ 6 trong 1 phút → 429; `wordCount: 25` → 400; không có token → 401.
- [ ] **Bước 4:** Chạy test → FAIL. **Bước 5:** Cài đặt. Timeout dùng `AbortController` + `setTimeout(15000)`; `@RateLimit({ key: 'ai', limit: 5, windowSec: 60, by: 'user' })`. Provider mock trả các từ lấy từ một danh sách cố định theo `cefrLevel`, đủ ≥ 20 từ cho mỗi level, lấy 12 từ trong `MockVocabData` của FE làm gốc. **Bước 6:** Chạy test → PASS.
- [ ] **Bước 7:** Commit `feat(ai): sinh từ vựng bằng gemini có lọc dữ liệu, timeout và rate limit` (Refs: BE2-S1-01 … BE2-S1-04, BE2-S1-06).

### Task 14: Lưu hàng loạt từ AI (`batch-save`)

**Files:** sửa `vocabularies.controller.ts`, `dto/batch-save.dto.ts`; test bổ sung vào `test/vocabularies.e2e-spec.ts`.

**Interfaces:**
- Consumes: `VocabulariesService.createBatch(..., 'ai_generated')`, event `vocabulary.created`.
- Produces: `POST /vocabularies/batch-save { collectionId, words: CreateVocabularyInput[] (1..50) }` → 201 `{ savedCount, skippedTerms, vocabularies: VocabularyDto[] }`. Mỗi từ AI có `ipa` → map vào `ipaUk`.

- [ ] **Bước 1: Viết test lỗi:**
  - Lưu 3 từ → `savedCount = 3`, `source = 'ai_generated'`, có 3 progress `new`, `totalWords` tăng 3.
  - Có 1 từ không hợp lệ (thiếu `term`) → 400, **không lưu từ nào** (DB giữ nguyên).
  - `collectionId` của người khác → 404.
  - Sau khi lưu, các từ lần lượt có audio (poll như Task 12).
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt (một transaction duy nhất). **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(vocab): lưu hàng loạt từ vựng ai trong một transaction` (Refs: BE2-S1-05).
- [ ] **Bước 6: Cổng merge F5.**

---

# F6 — `feat/be-06-srs-quiz` (BE2-S2-01 … BE2-S2-06, BE2-S3-01 … BE2-S3-03)

### Task 15: Engine SM-2 (logic thuần)

**Files:** `src/modules/spaced-repetition/sm2.ts`; test `sm2.spec.ts`.

**Interfaces:**
- Produces:
  - `type SrsState = { repetitionLevel: number; easeFactor: number; intervalDays: number; status: ProgressStatus; nextReviewAt: Date | null }`
  - `applyAnswer(state: SrsState, isCorrect: boolean, now: Date): SrsState`
  - `INTERVALS = { 1: 1, 2: 3, 3: 7, 4: 16, 5: 35 }`

- [ ] **Bước 1: Viết test lỗi** (`now = 2026-11-19T10:00:00Z`):
  - Từ mới (level 0, ease 2.5) + đúng → level 1, interval 1, `nextReviewAt = 2026-11-20T10:00:00Z`, status `review`, ease 2.5 (không vượt 2.5).
  - Đúng liên tiếp từ level 0: interval lần lượt `[1, 3, 7, 16, 35]`; ở level 5 status là `mastered`.
  - Level 5 + đúng → vẫn level 5, interval 35, `mastered`.
  - Level 3 (ease 2.0) + sai → level 0, interval 1, ease 1.8, status `learning`, `nextReviewAt = now + 1 ngày`.
  - Ease 1.4 + sai → 1.3; ease 1.3 + sai → 1.3.
  - Ease 2.0 + đúng → 2.1 (so sánh với độ chính xác 1e-9).
- [ ] **Bước 2:** `npm test -- sm2` → FAIL. **Bước 3:** Cài đặt. Đúng: `level = min(5, level + 1)`; status `mastered` nếu level 5, ngược lại `review`. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(srs): engine sm-2 với chuỗi khoảng cách 1-3-7-16-35 ngày` (Refs: BE2-S3-01).

### Task 16: Chấm điểm, fuzzy matching và chọn phương án gây nhiễu

**Files:** `src/modules/quiz/grading.ts`, `src/modules/quiz/distractors.ts`; test `grading.spec.ts`, `distractors.spec.ts`.

**Interfaces:**
- Produces:
  - `normalizeAnswer(s: string): string`: trim, lowercase, gộp khoảng trắng, chuẩn hoá Unicode NFC.
  - `levenshtein(a: string, b: string): number`
  - `gradeAnswer(mode: QuizMode, userAnswer: string, expected: string): boolean`: chế độ chọn (`listen_choose`, `choose_meaning`) so khớp tuyệt đối sau khi chuẩn hoá; chế độ gõ (`listen_type`, `type_meaning`) chấp nhận `levenshtein ≤ 1`.
  - `expectedAnswer(mode, vocab): string`: `choose_meaning` → `definitionVi`, các chế độ còn lại → `term`.
  - `pickDistractors(target: Pick<Vocabulary,'id'|'partOfSpeech'|'term'|'definitionVi'>, pool: same[], count: number, rng: () => number): same[]`

- [ ] **Bước 1: Viết test lỗi:**
  - `gradeAnswer('listen_type', '  Coherent ', 'coherent') === true`
  - `gradeAnswer('type_meaning', 'coherant', 'coherent') === true`
  - `gradeAnswer('type_meaning', 'cohernat', 'coherent') === false` (khoảng cách 2)
  - `gradeAnswer('listen_choose', 'coherant', 'coherent') === false`
  - `gradeAnswer('choose_meaning', 'Mạch lạc, chặt chẽ', 'mạch lạc, chặt chẽ') === true`
  - `levenshtein('', 'abc') === 3`
  - `pickDistractors`:
    - Pool có ≥ 3 từ cùng `partOfSpeech` → trả đúng 3 từ cùng từ loại, không chứa target, không trùng `term`.
    - Pool chỉ có 1 từ cùng từ loại + 5 từ khác → trả 3 (1 cùng loại trước, 2 khác loại sau).
    - Pool chỉ có 1 phần tử → trả 1.
  - Hiệu năng: pool 5000 từ, chạy 10 lần mất < 50 ms mỗi lần (`performance.now()`).
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Distractor: ưu tiên cùng từ loại, xáo trộn bằng `rng`, loại trùng `term`/`definitionVi` với target. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(quiz): chấm điểm fuzzy levenshtein và chọn phương án gây nhiễu` (Refs: BE2-S2-04, BE2-S2-06).

### Task 17: API lấy câu hỏi, hàng đợi ôn tập, luyện lại câu sai

**Files:** `src/modules/quiz/{quiz.module,practice.controller,question.service}.ts`, `dto/*`; test `test/practice.e2e-spec.ts`.

**Interfaces:**
- Consumes: `CollectionsService.assertOwned`, `pickDistractors`, `expectedAnswer`, `Clock`.
- Produces:
  - `GET /practice/questions?collectionId?&mode&limit=10 (1..50)` → `{ mode, questions: Question[] }`. Trong đó `Question = { vocabularyId, prompt: { term?, ipa?, audioUrl?, definitionVi? }, options?: { vocabularyId, text }[], answer: string }`.
    - Nội dung `prompt` theo chế độ (mục "Quyết định bổ sung" #6). `ipa = ipaUk ?? ipaUs`, `audioUrl = audioUkUrl ?? audioUsUrl`.
    - Có `options` (target + distractor, xáo trộn) chỉ với chế độ chọn.
  - Thứ tự chọn từ:
    1. Từ đến hạn (`nextReviewAt ≤ now`, sớm nhất trước).
    2. Từ `new`.
    3. Các từ còn lại theo `nextReviewAt asc`.

    Lấy `limit` từ rồi xáo trộn thứ tự câu hỏi.
  - Pool distractor: từ trong cùng học phần, rồi tới các học phần khác của user; nếu không có `collectionId` thì lấy toàn bộ từ của user.
  - Không truyền `collectionId` → chỉ lấy từ đến hạn trên mọi học phần (Màn 16).
  - `GET /practice/due?limit=50` → `{ dueCount, words: VocabularyDto[] }`
  - `GET /practice/retry-missed?sessionId` → giống `/questions` nhưng chỉ gồm các từ bị sai trong session đó, dùng `mode` của session.

- [ ] **Bước 1: Viết test lỗi** (seed 6 từ, chỉnh progress trực tiếp trong DB, `Clock` cố định bằng override provider trong `createTestApp`):
  - `mode=choose_meaning&limit=4` → 4 câu, mỗi câu 4 phương án, `answer` là một trong các `text`, không có phương án nào trùng nhau.
  - Học phần có 2 từ đến hạn, 2 từ mới, 2 từ chưa đến hạn, `limit=4` → tập `vocabularyId` trả về đúng là {2 đến hạn, 2 mới}.
  - `mode=listen_type` → không có `options`, `prompt.term` là undefined.
  - Học phần rỗng → 200 với `questions: []`.
  - `collectionId` của người khác → 404. `mode=foo` → 400.
  - `/practice/due` trả đúng 2 từ đến hạn.
  - `retry-missed` với session người khác → 404 `SESSION_NOT_FOUND` (test này cần Task 18; đặt `it.todo` ở đây rồi bật lại ở Task 18).
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(quiz): api lấy câu hỏi 4 chế độ và hàng đợi ôn tập` (Refs: BE2-S2-01, BE2-S2-02, BE2-S3-03).

### Task 18: Nộp bài, cập nhật SM-2 và streak

**Files:** `src/modules/quiz/submit.service.ts`, sửa `practice.controller.ts`; `src/modules/streak/{streak.module,streak.service,streak.ts}.ts`; `src/common/time/tz.util.ts`; test `streak.spec.ts`, `tz.util.spec.ts`, `test/submit.e2e-spec.ts`.

**Interfaces:**
- Consumes: `applyAnswer`, `gradeAnswer`, `expectedAnswer`, `VocabulariesService`.
- Produces:
  - `localDateString(instant: Date, tz: string): string` (dạng `YYYY-MM-DD`); `startOfLocalDayUtc(instant: Date, tz: string): Date`; `localTimeHHmm(instant: Date, tz: string): string`.
  - `computeStreak(s: { currentStreak; highestStreak; lastStreakDate: string | null }, todayLocal: string): same`. Quy tắc: cùng ngày → giữ nguyên; hôm qua → +1; còn lại → 1; `highest = max(...)`.
  - `StreakService.recordActivity(tx, userId: string, now: Date): Promise<StreakSummary>`, với `StreakSummary = { currentStreak, highestStreak, isStreakActiveToday }`.
  - `SubmitService.submit(userId, dto): Promise<SessionResult>`, với `SessionResult = { sessionId, totalQuestions, correctCount, incorrectCount, scorePercentage, durationSeconds, streak: StreakSummary, newBadges: BadgeDto[], answers: { vocabularyId, isCorrect, correctAnswer }[] }`. Ở task này `newBadges` luôn là `[]`; Task 19 nối vào.
  - DTO: `clientSessionId?` (uuid), `collectionId?`, `mode`, `durationSeconds` (0..86400), `answers` (1..100) gồm `{ vocabularyId, userAnswer (≤ 200 ký tự), isCorrect? (bị bỏ qua), responseTimeMs (0..600000) }`.

- [ ] **Bước 1: Viết test lỗi** (unit):
  - `localDateString(new Date('2026-11-19T17:30:00Z'), 'Asia/Ho_Chi_Minh') === '2026-11-20'`
  - `startOfLocalDayUtc(new Date('2026-11-19T17:30:00Z'), 'Asia/Ho_Chi_Minh')` bằng `2026-11-19T17:00:00Z`
  - `computeStreak({ 3, 5, '2026-11-19' }, '2026-11-20')` → 4/5
  - `computeStreak({ 3, 5, '2026-11-20' }, '2026-11-20')` → 3/5
  - `computeStreak({ 3, 5, '2026-11-17' }, '2026-11-20')` → 1/5
  - `computeStreak({ 5, 5, '2026-11-19' }, '2026-11-20')` → 6/6
  - `computeStreak({ 0, 0, null }, '2026-11-20')` → 1/1
- [ ] **Bước 2: Viết test lỗi** (e2e, `Clock` cố định):
  - Nộp 2 câu (1 đúng `coherent`, 1 sai) với `isCorrect` client gửi ngược lại → server chấm `[true, false]`; `scorePercentage = 50`; có 1 `quiz_sessions` và 2 `quiz_answers`; progress từ đúng ở level 1 / `review`, từ sai ở `learning`; `streak.currentStreak = 1`.
  - Gửi lại đúng request với cùng `clientSessionId` → 200 với cùng `sessionId`; DB vẫn chỉ 1 session; `reviewCount` của progress không đổi.
  - `answers` chứa `vocabularyId` của user khác → 404 `VOCABULARY_NOT_FOUND`, không ghi gì vào DB.
  - Cùng một từ xuất hiện 2 lần (sai rồi đúng) → SM-2 chạy theo thứ tự, kết quả cuối là level 1.
  - Múi giờ: nộp lúc `2026-11-19T16:30:00Z` (23:30 giờ VN) rồi `2026-11-19T17:30:00Z` (00:30 ngày 20 giờ VN) → streak 1 rồi 2.
  - `answers: []` → 400.
  - Bật lại test `retry-missed` của Task 17: trả đúng 1 câu cho từ bị sai.
- [ ] **Bước 3:** Chạy test → FAIL.
- [ ] **Bước 4:** Cài đặt. Toàn bộ `submit` chạy trong một `prisma.$transaction`:
  1. Kiểm tra quyền sở hữu mọi `vocabularyId`.
  2. Chấm điểm.
  3. Tạo session và các answer.
  4. Áp SM-2 cho từng answer theo thứ tự (`upsert` progress; tăng `reviewCount` và `correctCount`/`incorrectCount`; ghi `lastReviewedAt`).
  5. Cập nhật streak.

  Vi phạm unique `(userId, clientSessionId)` → đọc session cũ và trả lại kết quả cũ.
- [ ] **Bước 5:** Chạy test → PASS.
- [ ] **Bước 6:** Commit `feat(quiz): nộp bài có chấm điểm server, cập nhật sm-2, streak và chống nộp trùng` (Refs: BE2-S2-03, BE2-S2-05, BE2-S3-02).
- [ ] **Bước 7: Cổng merge F6.**

---

# F7 — `feat/be-07-users-gamification-dashboard` (BE1-S3-01 … BE1-S3-03, BE2-S3-04, BE2-S4-03)

### Task 19: Engine huy hiệu

**Files:** `src/modules/gamification/{gamification.module,gamification.service,badge-rules}.ts`, sửa `submit.service.ts`; test `badge-rules.spec.ts`, bổ sung `test/submit.e2e-spec.ts`.

**Interfaces:**
- Produces:
  - `BADGE_RULES: Record<'streak_7' | 'first_100' | 'explorer_5', (m: UserMetrics) => number>`: trả về giá trị hiện tại của chỉ số, so sánh với `requiredPoints`.
  - `UserMetrics = { currentStreak; learnedWords; collectionsCount }`
  - `GamificationService.getMetrics(tx, userId): Promise<UserMetrics>`
  - `GamificationService.evaluate(tx, userId): Promise<BadgeDto[]>`: chỉ trả huy hiệu **mới** mở khoá.
  - `GamificationService.listForUser(userId): Promise<(BadgeDto & { unlocked: boolean; unlockedAt: Date | null; progress: number })[]>`
  - `BadgeDto = { code, title, description, iconUrl, requiredPoints }`

- [ ] **Bước 1: Viết test lỗi:**
  - Unit: `streak_7` với `currentStreak = 7` → 7 (đạt).
  - E2E: user có `currentStreak = 6`, `lastStreakDate` là hôm qua; nộp bài → `newBadges` chứa `streak_7`; nộp thêm một bài nữa → `newBadges = []` (không mở khoá lần hai).
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt; gọi `evaluate` ở cuối transaction submit. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(gamification): engine huy hiệu chạy sau mỗi phiên học` (Refs: BE2-S4-03).

### Task 20: Hồ sơ, cài đặt, đổi mật khẩu, avatar, thiết bị

**Files:** `src/modules/users/{users.module,users.controller,users.service}.ts`, `dto/*`; test `test/users.e2e-spec.ts`.

**Interfaces:**
- Consumes: `GamificationService.listForUser/getMetrics`, `StorageService`, `TokenService.revokeAllForUser`.
- Produces:
  - `GET /users/profile` → `{ user: { id, email, fullName, avatarUrl, authProvider }, stats: { learnedWords, masteredWords, collectionsCount, currentStreak, highestStreak }, settings: { dailyGoalWords, reminderTime, isNotificationEnabled, timezone, language }, badges: [...] }`
  - `PATCH /users/settings`: các field `dailyGoalWords` (5..30, theo stepper của FE), `reminderTime` (`^([01]\d|2[0-3]):[0-5]\d$`), `isNotificationEnabled`, `timezone` (IANA hợp lệ, kiểm tra bằng `Intl.supportedValuesOf('timeZone')`), `language` (`vi|en`); đều tuỳ chọn.
  - `PATCH /users/profile { fullName }`
  - `PATCH /users/password { currentPassword, newPassword }`: tài khoản social chưa có mật khẩu thì bỏ qua `currentPassword`. Đổi xong thu hồi toàn bộ refresh token và trả cặp token mới.
  - `POST /users/avatar` (multipart, field `file`, chỉ `image/png|jpeg|webp`, ≤ 2 MB) → `{ avatarUrl }`
  - `POST /users/devices { fcmToken, platform }`: upsert theo `fcmToken` (token đổi chủ thì chuyển sang user mới). `DELETE /users/devices { fcmToken }`.
  - `PushService.sendPushNotification` (Task 22) đọc từ bảng `user_devices`.

- [ ] **Bước 1: Viết test lỗi:**
  - Profile mới đăng ký: `stats` toàn 0; `settings.reminderTime = '20:00'`; có 3 huy hiệu, mỗi cái `unlocked: false`.
  - `PATCH /users/settings { dailyGoalWords: 15, reminderTime: '21:30' }` → 200, đọc lại thấy giá trị mới.
  - `dailyGoalWords: 31`, `reminderTime: '25:00'`, `timezone: 'Mars/Base'` → mỗi trường hợp 400.
  - Đổi mật khẩu với `currentPassword` sai → 400 `PASSWORD_INCORRECT`; đúng → 200, refresh token cũ bị 401.
  - Upload file `.txt` → 400; upload PNG 1 KB → `avatarUrl` bắt đầu bằng `http://localhost:3000/uploads/avatars/`.
  - Cùng `fcmToken` đăng ký bởi A rồi B → DB chỉ có 1 dòng, thuộc B.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Upload dùng `FileInterceptor` + `ParseFilePipe`; key là `avatars/<userId>-<timestamp>.<ext>`. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(users): hồ sơ, cài đặt, đổi mật khẩu, avatar và đăng ký thiết bị` (Refs: BE1-S3-01 … BE1-S3-03).

### Task 21: Dashboard trang chủ

**Files:** `src/modules/dashboard/{dashboard.module,dashboard.controller,dashboard.service}.ts`; test `test/dashboard.e2e-spec.ts`.

**Interfaces:**
- Produces: `GET /home/dashboard` trả đúng dạng ở đặc tả 3.2:
  - `streak.isStreakActiveToday` = `lastStreakDate` có bằng ngày hôm nay theo giờ địa phương không.
  - `dailyGoal.wordsLearnedToday`: theo mục "Quyết định bổ sung" #14.
  - `progressPercentage = min(100, round(learned / target × 100))`.
  - `reviewReminder.dueWordsCount` = số progress có `nextReviewAt ≤ now`.
  - `quickCollections` = 3 học phần có `updatedAt` mới nhất, dạng Collection DTO.

- [ ] **Bước 1: Viết test lỗi** (`Clock` cố định):
  - User mới → `{ streak: { currentStreak: 0, highestStreak: 0, isStreakActiveToday: false }, dailyGoal: { targetWords: 10, wordsLearnedToday: 0, progressPercentage: 0 }, reviewReminder: { hasPendingReview: false, dueWordsCount: 0 }, quickCollections: [] }`.
  - Sau khi nộp 1 phiên có 7 từ đúng khác nhau → `wordsLearnedToday = 7`, `progressPercentage = 70`, `isStreakActiveToday = true`.
  - Đáp án đúng ghi lúc 23:30 hôm qua (giờ VN) không được tính vào hôm nay.
  - 12 từ đúng với mục tiêu 10 → `progressPercentage = 100`.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. Đếm `distinct vocabularyId` từ `quiz_answers` join `quiz_sessions` với `isCorrect = true` và `completedAt ≥ startOfLocalDayUtc(now, tz)`. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(dashboard): api tổng quan trang chủ với streak, mục tiêu ngày và từ cần ôn` (Refs: BE2-S3-04).
- [ ] **Bước 6: Cổng merge F7.**

---

# F8 — `feat/be-08-notifications-jobs` (BE1-S3-04, BE1-S3-05, BE2-S4-01, BE2-S4-02)

### Task 22: Push notification (mock / FCM)

**Files:** `src/modules/notifications/{notifications.module,push.service,push.provider,mock-push.provider,fcm-push.provider}.ts`; test `push.service.spec.ts`, `fcm-push.provider.spec.ts`.

**Interfaces:**
- Produces:
  - `abstract class PushProvider { abstract sendMulticast(tokens: string[], msg: { title; body; data?: Record<string,string> }): Promise<{ invalidTokens: string[]; successCount: number }> }`
  - `PushService.sendPushNotification(userId: string, title: string, body: string, data?: Record<string, string>): Promise<{ sent: number; removed: number }>`: tự xoá các token chết.
  - `MockPushProvider.sent: { tokens, msg }[]` để test đọc lại.

- [ ] **Bước 1: Viết test lỗi:**
  - User có 2 thiết bị, provider báo 1 token không hợp lệ → `{ sent: 1, removed: 1 }` và DB chỉ còn 1 thiết bị.
  - User không có thiết bị → `{ sent: 0, removed: 0 }`, không gọi provider.
  - Unit FCM (mock `firebase-admin` `messaging().sendEachForMulticast`): lỗi `messaging/registration-token-not-registered` và `messaging/invalid-registration-token` được đưa vào `invalidTokens`.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(notifications): push service đa thiết bị, tự dọn token chết` (Refs: BE1-S3-04, BE1-S3-05).

### Task 23: Cron reset streak và nhắc ôn tập

**Files:** `src/jobs/{jobs.module,streak-reset.job,review-reminder.job}.ts`; test `test/jobs.e2e-spec.ts`.

**Interfaces:**
- Consumes: `localDateString`, `localTimeHHmm`, `PushService`, `Clock`.
- Produces:
  - `StreakResetJob.run(): Promise<number>` (số user bị reset): `@Cron('0 * * * *')`.
  - `ReviewReminderJob.run(): Promise<number>` (số user được nhắc): `@Cron('*/15 * * * *')`.
  - Cả hai chỉ đăng ký cron khi `JOBS_ENABLED=true`; trong test gọi trực tiếp `run()`.

- [ ] **Bước 1: Viết test lỗi:**
  - Streak, `now = 2026-11-19T17:30:00Z` (00:30 ngày 20 giờ VN):
    - User A `lastStreakDate = '2026-11-19'`, streak 5 → giữ nguyên.
    - User B `lastStreakDate = '2026-11-18'`, streak 3 → về 0.
    - User C có `timezone = 'America/New_York'`, `lastStreakDate = '2026-11-18'` (bên đó đang 12:30 ngày 19) → giữ nguyên.
    - `run()` trả 1.
  - Nhắc nhở, `now` = 20:05 giờ VN:
    - User có `reminderTime = '20:00'`, bật thông báo, 3 từ đến hạn → nhận đúng 1 push với body "Bạn có 3 từ cần ôn tập hôm nay".
    - Gọi `run()` lần nữa trong cùng ngày → không gửi lại (Redis key `notified:<userId>:<localDate>`, TTL 36 giờ).
    - User tắt thông báo, user không có từ đến hạn, user có `reminderTime = '21:00'` → không nhận push.
- [ ] **Bước 2:** Chạy test → FAIL.
- [ ] **Bước 3:** Cài đặt.
  - Reset: `current_streak > 0` và `lastStreakDate < hôm qua theo giờ địa phương` (tính theo từng user, gom theo timezone).
  - Nhắc: giờ địa phương nằm trong `[reminderTime, reminderTime + 15 phút)`.
- [ ] **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(jobs): cron reset streak theo múi giờ và nhắc ôn tập qua push` (Refs: BE2-S4-01, BE2-S4-02).
- [ ] **Bước 6: Cổng merge F8.**

---

# F9 — `feat/be-09-sync-hardening` (BE1-S4-01 … BE1-S4-04, BE2-S4-04, SHARED-BE-01)

### Task 24: Đồng bộ offline (`GET /sync/delta`)

**Files:** `src/modules/sync/{sync.module,sync.controller,sync.service}.ts`; test `test/sync.e2e-spec.ts`.

**Interfaces:**
- Produces: `GET /sync/delta?since=<ISO, tuỳ chọn>` → `{ serverTime, collections: CollectionDto[], vocabularies: VocabularyDto[], progress: { vocabularyId, status, repetitionLevel, easeFactor, intervalDays, nextReviewAt, lastReviewedAt }[], deleted: { entityType, entityId, deletedAt }[] }`.
  - Lọc `updatedAt > since` (với deleted là `deletedAt > since`).
  - Không có `since` → trả toàn bộ, `deleted = []`.
  - `since` không hợp lệ → 400.
  - FE lưu `serverTime` để dùng làm `since` cho lần đồng bộ sau.

- [ ] **Bước 1: Viết test lỗi:**
  - Lấy `t0` = `serverTime` của lần gọi đầu.
  - Sửa 1 từ, xoá 1 học phần, nộp 1 phiên → `delta(since = t0)` trả đúng: 1 từ đã sửa, 1 dòng deleted cho học phần + các dòng cho từ của nó, progress của các từ vừa luyện.
  - Không trả dữ liệu của user khác.
- [ ] **Bước 2:** Chạy test → FAIL. **Bước 3:** Cài đặt. **Bước 4:** Chạy test → PASS.
- [ ] **Bước 5:** Commit `feat(sync): api delta đồng bộ offline có tombstone` (Refs: BE1-S4-01).

### Task 25: Bảo mật và index

**Files:** sửa `bootstrap.ts`; migration mới `prisma/migrations/<ts>_search_indexes/`; test `test/security.e2e-spec.ts`.

- [ ] **Bước 1: Viết test lỗi:**
  - Response có header `x-content-type-options: nosniff` (helmet).
  - Request có `Origin` nằm trong `CORS_ORIGINS` → có header `access-control-allow-origin`; origin lạ → không có.
  - Body JSON > 1 MB → 413.
  - Body thừa field `role: 'admin'` khi đăng ký → 400 (`forbidNonWhitelisted`).
- [ ] **Bước 2:** Chạy test → FAIL.
- [ ] **Bước 3:** Cài đặt: `helmet()`, `enableCors({ origin: CORS_ORIGINS.split(',') })`, `json({ limit: '1mb' })`. Migration mới (SQL thô) thêm `CREATE EXTENSION IF NOT EXISTS pg_trgm` và index GIN trigram trên `collections.title` để tìm kiếm `ILIKE` nhanh. **Không sửa migration `init`.**
- [ ] **Bước 4:** Chạy test → PASS. Chạy thêm `EXPLAIN ANALYZE` cho câu truy vấn từ đến hạn (sau khi seed 10k progress bằng script tạm, không commit), kiểm tra kế hoạch có dùng index `user_vocab_progress_user_id_next_review_at_status_idx`.
- [ ] **Bước 5:** Commit `feat(security): helmet, cors, giới hạn body và index tìm kiếm trigram` (Refs: BE1-S4-02, BE1-S4-03).

### Task 26: Test E2E toàn luồng

**Files:** `test/full-flow.e2e-spec.ts`.

- [ ] **Bước 1: Viết test** một luồng liên tục:
  1. Đăng ký.
  2. Tạo học phần.
  3. AI sinh 5 từ (mock).
  4. `batch-save` 5 từ.
  5. Lấy câu hỏi `choose_meaning`.
  6. Nộp bài, trả lời đúng hết bằng `answer`.
  7. Dashboard: `wordsLearnedToday = 5`, `streak.currentStreak = 1`.
  8. Profile: `learnedWords = 5`.
  9. Sync delta: chứa 5 progress `review`.
  10. Đăng xuất: access token cũ bị 401.
- [ ] **Bước 2:** `npm run test:e2e -- full-flow` → PASS. Nếu FAIL, sửa lỗi ở module liên quan bằng commit `fix(<scope>): ...` riêng.
- [ ] **Bước 3:** Commit `test: thêm e2e toàn luồng auth, ai, quiz, sm-2, streak` (Refs: SHARED-BE-01).

### Task 27: CI, backup, load test, tài liệu bàn giao

**Files:** `.github/workflows/backend-ci.yml`, `backend/scripts/backup-db.sh`, `backend/load/k6-submit-and-ai.js`, `backend/README.md`, `docs/karvocab/FE-BE-ALIGNMENT.md`, `backend/docs/ai/prompt_log.md`; sửa `CLAUDE.md`.

- [ ] **Bước 1:** `backend-ci.yml`:
  - Trigger: `push`/`pull_request` có thay đổi trong `backend/**`.
  - Services: `postgres:15` và `redis:7`.
  - Các bước: `npm ci` → `npx prisma migrate deploy` → `npm run lint` → `npm run build` → `npm test` → `npm run test:e2e`, sau đó `docker build`.

  Kiểm tra: file là YAML hợp lệ (`npx yaml-lint .github/workflows/backend-ci.yml` hoặc đọc lại).
- [ ] **Bước 2:** `backup-db.sh`: chạy `pg_dump` qua `docker compose exec postgres`, gzip thành `backups/karvocab-<YYYYmmdd-HHMM>.sql.gz` và giữ lại 7 bản mới nhất. Chạy thử một lần, kiểm tra file `.sql.gz` tồn tại và lớn hơn 0 byte.
- [ ] **Bước 3:** Script k6 (`stages` tăng dần tới 500 VU; `thresholds: { http_req_duration: ['p(95)<300'] }`) cho `submit-session` và `generate-vocab`. Nếu máy có `k6` thì chạy thử với 10 VU; nếu không thì ghi rõ trong README là chưa chạy.
- [ ] **Bước 4:** `FE-BE-ALIGNMENT.md` liệt kê những thay đổi FE phải làm theo BE:
  - Mật khẩu ≥ 8 ký tự, có chữ hoa và số.
  - `ipa` → `ipaUk`/`ipaUs`; `audioUrl` → `audioUkUrl`/`audioUsUrl`.
  - Response được bọc trong `{ success, data, ... }`.
  - Các mã `errorCode` cần xử lý.
  - Category của FE là `academic | travel | life`; BE thêm `career`, `other`.
  - Các chế độ quiz và nội dung `answer`; dùng `clientSessionId` khi nộp bài.
  - `dailyGoalWords` trong khoảng 5..30.
  - Bảng ánh xạ Màn ↔ endpoint.
- [ ] **Bước 5:** `backend/README.md` (tiếng Việt) và thêm mục "Backend" vào `CLAUDE.md`, nêu:
  - Lệnh chạy (`docker compose up -d`, `npm run start:dev`, `npm test`, `npm run test:e2e`, chạy một test: `npm test -- sm2` / `npm run test:e2e -- auth`).
  - Bảng biến môi trường provider.
  - Quy trình nhánh/commit ở đầu file kế hoạch này.
- [ ] **Bước 6:** Thêm một phiên vào `backend/docs/ai/prompt_log.md`, theo cùng định dạng với `karvocab_flutter/docs/ai/prompt_log.md`.
- [ ] **Bước 7:** Commit `ci: thêm pipeline backend, script backup, k6 và tài liệu bàn giao` (Refs: BE1-S4-04, BE2-S4-04).
- [ ] **Bước 8: Cổng merge F9:** chạy kiểm tra cổng lần cuối, merge vào `be/develop`. Chạy `git log --oneline --graph be/develop` để xác nhận đủ 9 commit merge. **Không push.**
