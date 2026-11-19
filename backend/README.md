# KarVocab Backend

API cho ứng dụng học từ vựng KarVocab (đồ án INT1449, Nhóm 03): xác thực, học phần, từ vựng, phát âm TTS, sinh từ bằng AI, luyện tập 4 chế độ với thuật toán SM-2, streak, huy hiệu, dashboard, push notification và đồng bộ offline.

- **Đặc tả:** `../docs/karvocab/BE-SPECIFICATION.md`
- **Kế hoạch triển khai và các quyết định bổ sung:** `../docs/superpowers/plans/2026-11-19-karvocab-backend.md`
- **Những thay đổi FE cần làm theo BE:** `../docs/karvocab/FE-BE-ALIGNMENT.md`

## Công nghệ

NestJS 11, TypeScript, Prisma 6, PostgreSQL 15, Redis 7 (blacklist token, OTP, rate limit, hàng đợi BullMQ), `@nestjs/schedule` cho cron, Jest và supertest.

## Chạy trên máy

Yêu cầu: Node 24, Docker Desktop.

```bash
cd backend
cp .env.example .env              # chỉnh nếu cần
docker compose up -d              # Postgres :5433, Redis :6380
npm install
npx prisma migrate deploy         # tạo bảng
npm run db:seed                   # 3 huy hiệu
npm run start:dev                 # http://localhost:3100
```

- API: `http://localhost:3100/api/v1`
- Swagger: `http://localhost:3100/api/docs`
- pgAdmin (tuỳ chọn): `docker compose --profile tools up -d`, mở `http://localhost:5050`

Mặc định mọi dịch vụ ngoài đều chạy **mock**, nên backend hoạt động đầy đủ khi không có mạng hay API key.

## Kiểm thử

```bash
npm run lint
npm run build
npm test                          # unit test
npm run test:e2e                  # e2e trên DB karvocab_test và Redis DB 1
npm test -- sm2                   # chạy riêng một file unit
npm run test:e2e -- auth          # chạy riêng một file e2e
```

E2E tự áp migration và seed lên DB `karvocab_test` trước khi chạy, rồi xoá dữ liệu giữa các test. Nếu schema của DB test bị lệch (ví dụ khi đổi migration cũ), hãy reset thủ công: `npx dotenv -e .env.test -- npx prisma migrate reset`.

## Biến môi trường chọn provider

| Biến | Giá trị | Ghi chú |
| --- | --- | --- |
| `AI_PROVIDER` | `mock` \| `gemini` | `gemini` cần `GEMINI_API_KEY`, model `GEMINI_MODEL` |
| `TTS_PROVIDER` | `mock` \| `google` | `google` dùng `GOOGLE_APPLICATION_CREDENTIALS` |
| `STORAGE_PROVIDER` | `local` \| `s3` | `local` lưu vào `UPLOAD_DIR`, phục vụ tại `/uploads`; `s3` hỗ trợ R2/MinIO qua `S3_ENDPOINT` |
| `PUSH_PROVIDER` | `mock` \| `fcm` | `fcm` cần `FIREBASE_SERVICE_ACCOUNT_PATH` |
| `MAIL_PROVIDER` | `console` \| `resend` | `resend` cần `RESEND_API_KEY` |
| `SOCIAL_AUTH_MODE` | `mock` \| `real` | `mock` nhận token dạng `mock:<id>:<email>:<tên>` và không liên kết vào tài khoản có mật khẩu; **production bắt buộc `real`** |
| `JOBS_ENABLED` | `true` \| `false` | Bật lịch cron (reset streak mỗi giờ, nhắc ôn mỗi 15 phút) |

## Cấu trúc

```
src/
  common/      response chuẩn, lỗi, validation, JWT guard, rate limit, Clock, múi giờ
  infra/       Prisma, Redis
  modules/     auth, users, collections, vocabularies, storage, audio, mail, ai,
               quiz, spaced-repetition, streak, gamification, dashboard,
               notifications, sync, health
  jobs/        cron reset streak và nhắc ôn tập
prisma/        schema, migrations, seed
test/          e2e (mỗi file một nhóm API)
scripts/       backup-db.sh
load/          k6-submit-and-ai.js
```

## Vận hành

- **Sao lưu CSDL:** `sh scripts/backup-db.sh` dump qua docker compose ra `backups/*.sql.gz` và giữ 7 bản mới nhất.
- **Load test:** `k6 run -e BASE_URL=http://localhost:3100 load/k6-submit-and-ai.js` (cần cài k6; script chưa được chạy trong quá trình phát triển).
- **Docker image:** `docker build -t karvocab-backend .`; container tự chạy `prisma migrate deploy` trước khi khởi động.
- **CI:** `.github/workflows/backend-ci.yml` chạy lint, build, unit, e2e rồi build image.

## Quy ước commit

Conventional Commits, mô tả tiếng Việt: `<type>(<scope>): <mô tả>`, kèm `Refs: <mã task trong đặc tả>`. Xem chi tiết trong file kế hoạch.
