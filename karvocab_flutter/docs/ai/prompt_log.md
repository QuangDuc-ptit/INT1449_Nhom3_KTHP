# NHẬT KÝ SỬ DỤNG TRỢ LÝ AI (AI ASSISTANT LOG)
## HỌC PHẦN INT1449 · LẬP TRÌNH DI ĐỘNG

> **Quy định Rubric cuối kỳ:**
> - Công cụ sử dụng: Google Antigravity / Gemini 3.8
> - Mục đích: Hỗ trợ trích xuất Design Tokens từ Figma, tư vấn kiến trúc Clean Architecture + BLoC, thiết kế Base Components chuẩn tiếp cận (touch target $\ge 48$dp), hỗ trợ tạo khung dự án và kiểm thử.
> - Thành viên nhóm đã đọc, hiểu và làm chủ 100% mã nguồn được sinh ra.

---

### Phiên làm việc ngày 18/11/2026: Khởi tạo Nền tảng & Giao diện Đăng nhập

#### 1. Yêu cầu đầu vào (Prompts):
- Trích xuất Design System từ file Figma `KarVocab` (Màu sắc, Typography Nunito, bố cục 8px grid).
- Phân tích Rubric môn học INT1449: Yêu cầu chuẩn vùng chạm $\ge 48\text{ dp}$, có đủ 3 trạng thái (Loading, Error, Empty) có lối ra, kiến trúc tách biệt giao diện - logic - dữ liệu, có chế độ Demo (không lộ API key).
- Khởi tạo cấu trúc dự án Flutter chuẩn Clean Architecture.
- Viết mã nguồn cho:
  1. `AppColors`: Toàn bộ mã màu từ Figma (#0095E8, #0054AC, #4FC3FF, #F5FAFE, #22C55E, #EF4444...).
  2. `AppTypography`: Phông chữ Nunito với các scale (Display 30, Heading 23, Body 14-16, Label 11-13).
  3. `Base Components`:
     - `AppButton`: Chiều cao tối thiểu $52\text{ dp}$ ($\ge 48\text{ dp}$ theo Rubric), hỗ trợ Primary, Secondary, Disabled, Loading state.
     - `AppTextField`: Chiều cao $52\text{ dp}$, toggle ẩn/hiện mật khẩu, thông báo lỗi màu đỏ `#EF4444`.
     - `CefrBadge`: Hiển thị cấp độ CEFR A1 - C1.
     - `EmptyStateWidget`: Hiển thị hình ảnh minh họa + tiêu đề + nút hành động (lối ra).
     - `ErrorStateWidget`: Thông báo lỗi rõ ràng kèm nút "Thử lại".
  4. Màn 01: `SplashScreen` hiển thị logo Axolotl, kiểm tra phiên đăng nhập tự động.
  5. Màn 02: `LoginScreen` với form validation regex, nút đăng nhập Social (Google, Facebook) và **Nút "Chế độ Dùng thử (Demo Mode)"** để phục vụ chấm điểm đồ án offline.

#### 2. Kết quả & Đóng góp của AI:
- Đã xuất bản cấu trúc thư mục phân tầng sạch sẽ: `core/`, `presentation/`, `data/`, `domain/`.
- Đảm bảo tuân thủ tiêu chí giao diện không có lỗi bố cục, responsive và không hardcode màu sắc bừa bãi.


---

### Phiên làm việc ngày 18/11/2026 (Phiên 2): Xây dựng Khung Bottom Navigation & Module Thư viện (Màn 05, 06, 07)

#### 1. Yêu cầu đầu vào (Prompts):
- Xác định phạm vi công việc của Frontend Developer 1 (FE1) khi chưa có Backend.
- Triển khai kiến trúc phân tầng độc lập giúp FE1 làm chủ 85-90% công việc với dữ liệu Mock/Local mà không bị nghẽn (blocking).
- Xây dựng:
  1. `MainShellScreen`: Khung điều hướng 4 Tab (Trang chủ, Thư viện, Luyện tập, Cá nhân).
  2. Data Models: `CollectionModel` và `VocabularyModel`.
  3. `MockVocabData`: Bộ dữ liệu mẫu chuẩn trích xuất trực tiếp từ file Figma (các từ: coherent, inevitable, mitigate, perspective, investment, itinerary, destination, explore, souvenir, ambitious, persistent, opportunity).
  4. `LibraryScreen` (Màn 05): Quản lý bộ từ vựng, tìm kiếm debounce, bộ lọc chip (Học thuật, Du lịch, Đời sống), modal tạo học phần mới (Màn 22).
  5. `WordListScreen` (Màn 06): Danh sách từ cuộn mượt dạng thẻ, hiển thị phiên âm IPA, loại từ, nghĩa tiếng Việt, huy hiệu CEFR (A1-C1) và nút loa phát âm nhanh.
  6. `WordDetailScreen` (Màn 07): Chi tiết phát âm, định nghĩa song ngữ, ví dụ câu ngữ cảnh và hộp thoại xác nhận xoá từ vựng (Màn 28).

#### 2. Kết quả & Đóng góp của AI:
- Hoàn thiện luồng người dùng mượt mà: Bấm "⚡ Chế độ Dùng thử (Demo Offline)" ở Màn Đăng nhập sẽ dẫn thẳng vào khung app 4 tab và mở ngay Thư viện từ vựng để thử nghiệm.
- Mã nguồn tuân thủ Clean Architecture, widget nhỏ gọn, dễ bảo trì, giải phóng controller đúng chuẩn rubric.


---

### Phiên làm việc ngày 19/11/2026: Hoàn thiện Cụm 1 — Cá nhân & Cài đặt (Màn 15, Màn 23)

#### 1. Yêu cầu đầu vào (Prompts):
- Xây dựng hoàn chỉnh Cụm 1: Cá nhân theo chuẩn Figma và Rubric INT1449:
  1. `UserProfileModel` & `BadgeModel`: Định nghĩa cấu trúc dữ liệu người học, thống kê số từ, chuỗi streak và huy hiệu thành tựu.
  2. `ProfileScreen` (Màn 15):
     - Thẻ danh tính người học với Avatar linh vật Axolotl.
     - 3 thẻ chỉ số thống kê (Số từ đã học, Chuỗi streak ngọn lửa cam, Số học phần).
     - Hệ thống Huy hiệu thành tựu (Chuỗi 7 Ngày, Nhà Thám Hiểm, Bách Khoa 100 Từ kèm thanh tiến độ 42/100).
     - Nút chuyển hướng sang Cài đặt tài khoản.
  3. `SettingsScreen` (Màn 23):
     - Bộ tăng giảm số từ cần ôn mỗi ngày (Daily Goal Stepper 5-30 từ) với nút bấm $\ge 48$dp.
     - Toggle bật/tắt nhắc nhở thông báo và Time Picker chọn giờ nhắc học (`20:00`).
     - Tùy chọn ngôn ngữ hiển thị Tiếng Việt / English (đạt điểm cộng +2 Rubric).
     - Hộp thoại đổi mật khẩu với đầy đủ validation và xử lý `dispose()`.
     - Hộp thoại xác nhận đăng xuất tài khoản và điều hướng an toàn về Màn Đăng nhập.
  4. Ghép nối `ProfileScreen` vào Tab 3 ("Cá nhân") của `MainShellScreen`.

#### 2. Kết quả & Đóng góp của AI:
- Hoàn thành trọn vẹn Tab "Cá nhân", nâng tiến độ của FE1 từ ~55% lên **~70%**.
- Đáp ứng các tiêu chí tiếp cận (Accessibility), không hardcode màu sắc, hỗ trợ đầy đủ các lối thoát/hủy trong dialog.


---

### Phiên làm việc ngày 19/11/2026: FE2 — Track B (Dashboard, Quiz Engine, AI Vocab Generator)

#### 1. Yêu cầu đầu vào (Prompts):
- Tôi là FE2 (Track B). Đọc FE-SPECIFICATION (phần Track B), `core/constants`, `core/widgets`, `vocabulary_model.dart`; không sửa màn hình Track A; nút trắc nghiệm ≥ 48dp; hỗ trợ Demo offline.
- Dựng: Quiz Engine Controller; 4 chế độ Màn 08/19/20/25; Phản hồi đáp án (Màn 11); Kết quả (Màn 12) & Thử lại câu sai (Màn 26); Chọn chế độ (Màn 10); Trang chủ Streak & Daily Goal (Màn 04); Ôn tập hôm nay SM-2 (Màn 16); AI Vocab Generator (Màn 13/14).

#### 2. Kết quả & Đóng góp của AI:
- `lib/data/models/quiz_models.dart`, `ai_vocab_draft.dart`; `lib/core/utils/fuzzy_match.dart` (Levenshtein = 1 cho từ > 6 ký tự).
- `lib/data/repositories/`: `quiz_question_factory`, `dashboard_store` (SM-2 theo BE-SPEC 4.1), `ai_vocab_repository` (mock + công tắc giả lập lỗi), `collection_bridge`.
- `lib/presentation/quiz/`, `dashboard/`, `ai_vocab/`; `test/track_b_quiz_test.dart` (14 test).
- Sửa duy nhất 1 file chung: `main_shell_screen.dart` (thay 2 placeholder bằng `HomeScreen` và `PracticeModeScreen`).
