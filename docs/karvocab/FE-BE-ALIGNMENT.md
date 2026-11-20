# ĐỐI CHIẾU FE ↔ BE: NHỮNG THAY ĐỔI FE CẦN LÀM THEO BACKEND

> Nguyên tắc đã chốt: khi FE và BE lệch nhau thì **làm theo BE**, FE sửa theo.
> Chi tiết từng API xem Swagger tại `http://localhost:3100/api/docs` khi chạy backend.

## 1. Định dạng response chung

Mọi API trả về dạng bọc:

```json
{ "success": true, "data": { }, "message": "Thành công", "timestamp": "2026-11-19T10:00:00.000Z" }
```

Lỗi:

```json
{ "success": false, "data": null, "message": "Thông báo tiếng Việt", "errorCode": "MA_LOI", "errors": [{ "field": "password", "message": "..." }], "timestamp": "..." }
```

- FE đọc dữ liệu ở `data`, hiển thị `message` cho người dùng; `errors` chỉ có ở lỗi validation (400).
- Danh sách phân trang (`GET /collections`): `data = { items: [...], meta: { page, limit, total, totalPages } }`.
- Mọi request cần đăng nhập gửi header `Authorization: Bearer <accessToken>`.

## 2. Mã lỗi FE nên xử lý riêng

| errorCode | HTTP | Gợi ý xử lý trên FE |
| --- | --- | --- |
| `VALIDATION_ERROR` | 400 | Hiện lỗi dưới từng ô theo `errors[].field` |
| `UNAUTHORIZED` | 401 | Gọi `/auth/refresh`; thất bại thì về màn Đăng nhập |
| `INVALID_CREDENTIALS` | 401 | "Email hoặc mật khẩu không đúng" (Màn 02) |
| `REFRESH_TOKEN_INVALID`, `REFRESH_TOKEN_REUSED` | 401 | Xoá token đã lưu, về màn Đăng nhập |
| `EMAIL_EXISTS` | 409 | Báo ở ô email (Màn 03) |
| `OTP_INVALID` | 400 | Báo ở ô mã OTP (Màn 21) |
| `PASSWORD_INCORRECT` | 400 | Báo ở ô mật khẩu hiện tại (Màn 23) |
| `COLLECTION_NOT_FOUND`, `VOCABULARY_NOT_FOUND`, `SESSION_NOT_FOUND` | 404 | Quay lại danh sách, hiện Empty/Error state |
| `VOCABULARY_EXISTS` | 409 | "Từ đã có trong học phần" (Màn 24) |
| `RATE_LIMITED` | 429 | Thông báo chờ; header `Retry-After` là số giây |
| `AI_TIMEOUT` (504), `AI_BAD_RESPONSE`, `AI_UNAVAILABLE` (502) | | Error state có nút "Thử lại" (Màn 13) |
| `FILE_REQUIRED`, `FILE_TYPE_INVALID` | 400 | Ảnh đại diện phải là PNG/JPEG/WebP |
| `PAYLOAD_TOO_LARGE` | 413 | Ảnh quá 2 MB |

## 3. Thay đổi bắt buộc trong code FE hiện tại

| Chỗ trong FE | Hiện tại | Theo BE |
| --- | --- | --- |
| `login_screen.dart`, hộp thoại đổi mật khẩu ở `settings_screen.dart` | Mật khẩu ≥ 6 ký tự | **≥ 8 ký tự, có ít nhất 1 chữ hoa và 1 chữ số** |
| `VocabularyModel.ipa` | Một trường `ipa` | `ipaUk`, `ipaUs` (có thể null). Hiển thị `ipaUk ?? ipaUs` |
| `VocabularyModel` (audio) | Chưa có | `audioUkUrl`, `audioUsUrl` (có thể null khi đang sinh, worker điền sau vài giây) |
| `VocabularyModel.definitionEn`, `exampleSentence` | Bắt buộc | Có thể null |
| `VocabularyModel.isMastered` | bool | Lấy từ `progress.status == 'mastered'`; `progress` gồm `status`, `repetitionLevel`, `nextReviewAt` |
| `VocabularyModel.partOfSpeech` | noun/verb/adj/adv | Thêm `idiom` |
| `VocabularyModel.cefrLevel` | A1–C1 | A1–**C2** (AI chỉ sinh A1–C1) |
| `VocabularyModel` (nguồn) | Chưa có | `source`: `manual` \| `ai_generated` |
| `CollectionModel.category` | academic/career/life/travel | Thêm `other` (mặc định khi không chọn) |
| `CollectionModel` | Chưa có | `isPublic`, `createdAt`, `updatedAt` |
| `UserProfileModel` | Phẳng | `GET /users/profile` trả `{ user, stats, settings, badges }` (xem mục 4) |
| `UserProfileModel.totalWordsLearned` | | `stats.learnedWords` (từ đã ôn ít nhất 1 lần); thêm `stats.masteredWords` |
| `BadgeModel.isUnlocked`, `currentProgress`, `maxProgress` | | `unlocked`, `progress`, `requiredPoints`; thêm `unlockedAt`, `iconUrl` |
| Stepper mục tiêu ngày | | Giới hạn **5–30** từ |
| Cài đặt | Chưa có | Thêm `timezone` (IANA, mặc định `Asia/Ho_Chi_Minh`) và `language` (`vi` \| `en`) |
| Đổi mật khẩu | | `PATCH /users/password` trả **cặp token mới**; FE phải lưu đè token cũ |

## 4. Bảng ánh xạ Màn hình ↔ API

| Màn | Chức năng | API |
| --- | --- | --- |
| 01 | Khởi động, kiểm tra phiên | `GET /auth/me`; hết hạn thì `POST /auth/refresh` |
| 02 | Đăng nhập | `POST /auth/login`, `POST /auth/social-login` |
| 03 | Đăng ký | `POST /auth/register` |
| 21 | Quên mật khẩu | `POST /auth/forgot-password`, `POST /auth/reset-password` |
| 04 | Trang chủ | `GET /home/dashboard` |
| 05 | Thư viện học phần | `GET /collections?search=&category=&page=&limit=` |
| 22 | Tạo học phần | `POST /collections` (sửa: `PATCH /collections/:id`, xoá: `DELETE /collections/:id`) |
| 06 | Danh sách từ | `GET /collections/:id/words` |
| 07 | Chi tiết từ | Dữ liệu từ Màn 06 (phát `audioUkUrl`/`audioUsUrl`) |
| 24 | Thêm từ | `POST /collections/:id/words` |
| 09 | Sửa từ | `PUT /vocabularies/:id` |
| 28 | Xoá từ | `DELETE /vocabularies/:id` |
| 13 | Sinh từ bằng AI | `POST /ai/generate-vocab` (gửi `collectionId` để biết từ nào đã có) |
| 14 | Xem trước và lưu | `POST /vocabularies/batch-save` (bỏ trường `existsInCollection` trước khi gửi) |
| 08, 19, 20, 25 | 4 chế độ luyện tập | `GET /practice/questions?collectionId=&mode=&limit=` |
| 11 | Phản hồi đáp án | Dùng `answer` trong câu hỏi để phản hồi ngay |
| 12 | Tổng kết phiên | `POST /practice/submit-session` |
| 26 | Luyện lại câu sai | `GET /practice/retry-missed?sessionId=` |
| 16 | Ôn tập hôm nay | `GET /practice/due`; câu hỏi ôn: `GET /practice/questions?mode=` (không truyền `collectionId`) |
| 15 | Hồ sơ | `GET /users/profile`, `PATCH /users/profile`, `POST /users/avatar` |
| 23 | Cài đặt | `PATCH /users/settings`, `PATCH /users/password` |
| Đăng xuất | | `POST /auth/logout`, `DELETE /users/devices` |
| Push | Sau khi đăng nhập | `POST /users/devices` với FCM token |
| Offline | Đồng bộ SQLite/Hive | `GET /sync/delta?since=<serverTime lần trước>`. Server lùi mốc 2 giây để không sót dữ liệu, nên có thể trả lại bản ghi đã nhận: FE **upsert theo `id`** |

## 5. Luyện tập: quy ước quan trọng

- **Nội dung đề theo chế độ** (`prompt`):
  - `listen_choose`: `audioUrl`, `ipa` → chọn đúng **từ tiếng Anh** trong 4 `options`.
  - `listen_type`: `audioUrl`, `ipa` → **gõ từ tiếng Anh**.
  - `choose_meaning`: `term`, `ipa` → chọn đúng **nghĩa tiếng Việt** trong 4 `options`.
  - `type_meaning`: `definitionVi` → **gõ từ tiếng Anh**.
- Chế độ chọn luôn có 4 `options`. User chưa đủ từ thì server bù phương án từ danh sách mẫu; các phương án này có `vocabularyId: null`. Xác định đáp án đúng bằng `text == answer`.
- Chế độ nghe: nếu từ chưa có file audio, `prompt` có `speakText` thay cho `audioUrl`; FE dùng TTS của thiết bị đọc chuỗi này. Server tự đẩy job sinh lại audio cho lần sau.
- **Chống học dồn:** mỗi từ chỉ tính câu trả lời đầu tiên trong một phiên; trả lời đúng chỉ lên level khi từ đã đến hạn ôn hoặc còn là từ mới.
- `answer` là đáp án đúng để FE phản hồi ngay (Màn 11). **Server tự chấm lại khi nộp bài** và bỏ qua `isCorrect` FE gửi lên. Chế độ gõ chấp nhận sai 1 ký tự với từ từ 3 ký tự trở lên.
- **Mỗi phiên học, FE sinh một `clientSessionId` (UUID)** và gửi kèm khi nộp. Nếu mạng lỗi, gửi lại đúng request đó; server trả lại kết quả cũ, không tính hai lần.
- Kết quả nộp bài có `streak` mới và `newBadges` để hiện popup huy hiệu (Màn 12).

## 6. Tài khoản Demo / không có mạng

Backend mặc định chạy mock cho AI, TTS, email, push và đăng nhập mạng xã hội. Đăng nhập Google/Facebook ở chế độ mock nhận token dạng `mock:<id>:<email>:<họ tên>`, ví dụ `mock:demo-1:demo@karvocab.app:Demo User`.
