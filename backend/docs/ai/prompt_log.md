# NHẬT KÝ SỬ DỤNG TRỢ LÝ AI: BACKEND (AI ASSISTANT LOG)
## HỌC PHẦN INT1449 · LẬP TRÌNH DI ĐỘNG · NHÓM 03

> - Công cụ sử dụng: Claude Code (mô hình Claude Opus 5.5).
> - Mục đích: lập kế hoạch triển khai backend theo `docs/karvocab/BE-SPECIFICATION.md`, viết mã nguồn NestJS theo quy trình kiểm thử trước (TDD), viết test unit/e2e, CI và tài liệu bàn giao.
> - Toàn bộ mã nguồn do AI sinh ra cần được thành viên phụ trách đọc lại và kiểm tra trước khi nộp.

---

### Phiên làm việc ngày 19/11/2026: Lập kế hoạch và hoàn thiện backend (BE-1 và BE-2)

#### 1. Yêu cầu đầu vào (Prompts)
- Dịch `CLAUDE.md` sang tiếng Việt; chuẩn bị đầy đủ để làm backend, lên kế hoạch cụ thể, kiểm thử từng phần, xong feature nào thì commit lên nhánh mới, quy chuẩn commit rõ ràng.
- Thành viên phụ trách làm toàn bộ backend; khi FE và BE lệch nhau thì làm theo BE, FE sửa theo.
- Commit phần BE-1 và BE-2 dưới tài khoản của từng thành viên; không thêm dòng đồng tác giả AI.

#### 2. Kết quả và đóng góp của AI
- **Kế hoạch:** `docs/superpowers/plans/2026-11-19-karvocab-backend.md` gồm 28 task, các quyết định bổ sung so với đặc tả (cột cài đặt cho `users`, bảng tombstone, `clientSessionId` chống nộp trùng, server tự chấm bài...) và quy trình nhánh/commit.
- **BE-1:** hạ tầng Docker, schema Prisma 11 bảng, chuẩn hoá response/lỗi, Swagger; đăng ký, đăng nhập, refresh token xoay vòng, đăng xuất, chống brute-force, quên mật khẩu bằng OTP, đăng nhập Google/Facebook; CRUD học phần và từ vựng; lưu file local/S3; worker sinh audio TTS qua BullMQ; hồ sơ, cài đặt, avatar, thiết bị; push FCM; đồng bộ offline; helmet/CORS/giới hạn body, index trigram; CI GitHub Actions và script backup.
- **BE-2:** sinh từ bằng Gemini (Structured Output, timeout 15 giây, rate limit 5 lần/phút) và lưu hàng loạt; engine SM-2; chấm điểm fuzzy Levenshtein; chọn phương án gây nhiễu; API câu hỏi 4 chế độ, hàng đợi ôn tập, luyện lại câu sai; nộp bài có chống nộp trùng; streak theo múi giờ; huy hiệu; dashboard; cron reset streak và nhắc ôn tập; test e2e toàn luồng; script k6; tài liệu đối chiếu FE–BE.
- **Kiểm thử:** 114 unit test và 161 e2e test chạy trên Postgres/Redis thật (Docker); `npm run lint`, `npm run typecheck`, `npm run build` sạch; `npm run db:drift` xác nhận schema khớp migration.
- **Lỗi phát hiện nhờ test:** (1) token vẫn dùng được sau đăng xuất khi đồng hồ ứng dụng lệch giờ hệ thống; (2) bản build đặt sai thư mục khiến `node dist/main` không chạy; (3) lỗi phân loại timeout của AI. Cả ba đã được sửa.
- **Chưa làm:** deploy production và giám sát (Sentry/Grafana); chạy k6 với 500 người dùng đồng thời (máy chưa cài k6, mới có script).

---

### Phiên làm việc ngày 20/11/2026: Review độc lập và sửa lỗi

#### 1. Yêu cầu đầu vào (Prompts)
- Review toàn bộ nhánh backend bằng một reviewer AI độc lập; sửa các lỗi tìm được.
- Áp dụng đề xuất chống học dồn cho SM-2; làm đến khi xong toàn bộ backend.

#### 2. Kết quả và đóng góp của AI
- Reviewer báo 1 lỗi nghiêm trọng, 4 lỗi quan trọng, 10 lỗi nhỏ; cả 15 đã được sửa, mỗi lỗi kèm test tái hiện (fail trước, pass sau).
- Lỗi nghiêm trọng: chế độ đăng nhập mạng xã hội mock cho phép chiếm tài khoản có mật khẩu cùng email. Đã chặn liên kết khi email chưa được nhà cung cấp xác minh và bắt buộc `SOCIAL_AUTH_MODE=real` ở production.
- Lỗi quan trọng: gửi `null` gây lỗi 500; đổi từ không sinh lại audio; học dồn làm từ thành "đã thuộc" ngay trong một tối (quyết định bổ sung #16); DB mới không có huy hiệu khi chạy bằng Docker.
- Lỗi nhỏ: tìm kiếm ký tự `%`/`_`; lệch schema index trigram; race khi reset streak, khi nộp bài song song, khi thêm trùng từ song song; một lần gửi push lỗi làm dừng lượt nhắc; câu trắc nghiệm thiếu phương án; câu nghe thiếu audio; đồng bộ offline bỏ sót transaction chậm; Google thiếu `email_verified`.
- Thêm bước `typecheck` và kiểm tra lệch schema vào cổng kiểm tra và CI; CI chạy thử Docker image trên DB trống.
