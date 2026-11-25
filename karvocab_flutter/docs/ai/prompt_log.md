# NHẬT KÝ SỬ DỤNG TRỢ LÝ AI (AI ASSISTANT LOG)
## HỌC PHẦN INT1449 · LẬP TRÌNH DI ĐỘNG

> **Quy định Rubric cuối kỳ:**
> - Công cụ sử dụng: Google Antigravity / Gemini 3.8
> - Mục đích: Hỗ trợ trích xuất Design Tokens từ Figma, tư vấn kiến trúc phân tầng (`core` → `data` → `presentation`, trạng thái bằng `ChangeNotifier`; ban đầu dự kiến BLoC nhưng không dùng), thiết kế Base Components chuẩn tiếp cận (touch target $\ge 48$dp), hỗ trợ tạo khung dự án và kiểm thử.
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

### Phiên làm việc ngày 20/11/2026: Hoàn thiện Track A (FE1) — Auth, Thư viện & Quản lý từ vựng

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Đối chiếu `docs/karvocab/FE-SPECIFICATION.md` §5 để xác định các task còn thiếu của DEV 1 (Track A) và hoàn thiện chúng, không sửa file của Track B.

#### 2. Kết quả & Đóng góp của AI:
- **Tầng dữ liệu:** `CollectionStore` (ChangeNotifier) làm nguồn dữ liệu chung cho Màn 05/06/07/09/15/22/24/28, có trạng thái Loading/Error/Ready và hiện thực hợp đồng `addWords(collectionId, words)` cho Track B; `AuthRepository` (đăng nhập, đăng ký, social mock, Demo Mode, OTP quên mật khẩu, đổi mật khẩu, đăng xuất); `BadgeRules`; `PronunciationService` (UK/US, trạng thái đang phát, cache); `ReminderService`.
- **Màn mới:** 03 Đăng ký (mật khẩu mạnh, khớp mật khẩu, checkbox điều khoản), 21 Quên mật khẩu (Email → OTP 6 số, đếm ngược 60s → mật khẩu mới), 24/09 Form thêm/sửa từ, 22 Bottom sheet tạo học phần (2–50 ký tự, chặn trùng tên), 28 Dialog xoá có Hoàn tác.
- **Nâng cấp màn cũ:** Login validate theo regex đặc tả, nút disable khi trống, chặn bấm lặp; Thư viện search debounce 300ms, skeleton loading, error có Thử lại, pull-to-refresh; Chi tiết từ in đậm từ khoá trong câu ví dụ, sóng âm khi phát; Hồ sơ tính huy hiệu từ thống kê thật, huy hiệu khoá hiển thị grayscale; Cài đặt lưu vào phiên, sửa lỗi dispose controller của dialog đổi mật khẩu.
- **Kiểm thử:** thêm `test/fe1_track_a_unit_test.dart` và `test/fe1_track_a_widget_test.dart`; cập nhật `test/widget_test.dart` theo hành vi mới.
- **Chưa làm (cần package/SDK):** gọi API backend thật, Secure Storage, FCM/local notification thật, TTS thật, SQLite offline.

---

### Phiên làm việc ngày 20/11/2026 (Phiên 2): Làm lại giao diện Đăng nhập / Đăng ký (Màn 02, 03)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Làm giao diện Đăng nhập / Đăng ký theo mô tả bố cục của nhóm (nền #F5FAFE, logo chữ "KarVocab", thanh tab Đăng nhập | Đăng ký, ô nhập viền #DDF2FF, nút chính #0070BE, nút Google/Facebook, dòng điều khoản cuối màn). Chỉ làm frontend, chưa nối backend.

#### 2. Kết quả & Đóng góp của AI:
- Gộp Màn 02 và 03 thành một `LoginScreen`, đổi form bằng `AuthSegmentTabs` hoặc link "Đăng ký ngay."; xoá `register_screen.dart`, chuyển `PasswordRulesHint` sang `presentation/widgets/` cho Màn 21 dùng tiếp.
- Bỏ khỏi màn những phần không có trong mô tả: nút Demo Mode, phụ đề, icon trái ô nhập, ô Họ và tên, checkbox điều khoản, validate.
- Thêm token màu (`authButton`, `authLink`, màu Google/Facebook), style `AppTypography.caption`, tham số `borderColor` cho `AppTextField` và `backgroundColor` cho `AppButton`.
- Hành vi: nút "Đăng nhập" chuyển tới tab Trang chủ của `MainShellScreen` (`initialTabIndex: 0`; mặc định của shell là tab Thư viện); "Đăng ký", Google, Facebook, "Quên mật khẩu?" chưa có hành động.
- Cập nhật widget test của Màn 02/03 (bố cục, chuyển tab, ẩn/hiện mật khẩu).

---

### Phiên làm việc ngày 20/11/2026 (Phiên 3): Giao diện Trang chủ (Màn 04)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Làm giao diện Trang chủ theo mô tả chi tiết của nhóm (header lời chào + chuông thông báo, lưới 4 thẻ thống kê, thẻ nhắc ôn tập, nút "Bắt đầu ôn tập", biểu đồ cột tuần vẽ tay, mục "Học phần của bạn", thanh điều hướng dưới). Chỉ frontend; không hardcode chữ/màu/kích thước; màn hình nhận `HomeUiState` và đưa mọi thao tác ra callback; có dữ liệu mẫu riêng và 2 Preview.
- Nhóm chốt: màu chữ phụ #6B7A90 là token riêng của Trang chủ; nút chuông vẽ 44dp nhưng vùng chạm 48dp; trong `MainShellScreen` chỉ nối "Xem tất cả" → tab Thư viện.

#### 2. Kết quả & Đóng góp của AI:
- Chuyển yêu cầu kiểu Android sang Flutter: `strings.xml` → `AppStrings`; colors/dimens → `AppColors`, `AppDimensions`, `AppTypography`; `@Preview` của Compose → `@Preview` của Flutter Widget Previewer.
- Tạo `HomeUiState`, `HomeSampleData` (đầy đủ / trống), `HomeScreen`, component `StatCard`, `WeeklyBarChart` (CustomPainter, trục Y làm tròn số đẹp chia 4 khoảng), `AppBottomNavBar` thay `BottomNavigationBar` cũ trong `MainShellScreen`.
- `AppButton` thêm tham số `borderRadius`, `disabledBackgroundColor`.
- Thêm `test/home_screen_test.dart` (5 test: đủ dữ liệu, trạng thái trống, chấm "9+", callback, trục Y).
- Lưu ý: Màn 04 thuộc Track B (FE2) theo FE spec §5; FE1 làm phần giao diện theo yêu cầu của nhóm.

---

### Phiên làm việc ngày 20/11/2026 (Phiên 4): Popup thông báo trên Trang chủ (Màn 04)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Bấm chuông ở Trang chủ → popup thả xuống ngay dưới chuông: header cố định (tổng số, nút Làm mới xoay khi đang làm mới, nút Đánh dấu tất cả đã đọc), danh sách cuộn (chưa đọc nền nhấn + chấm xanh, đã đọc nền trắng), thời gian tương đối, footer "Tải thêm", trạng thái trống, badge "99+". Chỉ frontend; không hardcode; popup nhận UI state và đưa mọi thao tác ra callback; dữ liệu mẫu riêng; 3 Preview.
- Nhóm chốt: chưa có backend thì `MainShellScreen` giả lập thao tác trên dữ liệu mẫu (đánh dấu đã đọc, làm mới/tải thêm có độ trễ ~1 giây).

#### 2. Kết quả & Đóng góp của AI:
- `NotificationItem`, `NotificationUiState`, `NotificationSampleData` (9 thông báo mẫu chia 2 trang), hàm `formatRelativeTime`.
- `NotificationPopup` + `showNotificationPopup` (PopupRoute: mờ dần + trượt nhẹ, đóng khi bấm ra ngoài/bấm lại chuông/Back), 3 `@Preview`.
- Trang chủ: badge lấy `unreadCount` của thông báo (bỏ `HomeUiState.unreadNotifications` để chỉ có một nguồn số liệu), badge dạng viên thuốc để vừa "99+".
- Thêm `test/notification_popup_test.dart` (13 test) và cập nhật test badge ở `test/home_screen_test.dart`.

---

### Phiên làm việc ngày 20/11/2026 (Phiên 5): Loại bỏ giá trị hardcode trên giao diện

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Chỉnh lại hết đi, không được dùng hardcode" — thay toàn bộ màu, cỡ chữ, kích thước, khoảng cách viết thẳng trong widget bằng design token.

#### 2. Kết quả & Đóng góp của AI:
- Bổ sung token: `AppColors.transparent`, `AppColors.shadow`; `AppDimensions` thêm khoảng cách (2/3/6/10), bo góc nhỏ, thang icon (14–64), độ dày viền, kích thước vòng tải, ô icon/avatar, độ mờ (alpha) dùng chung; `AppTypography` thêm thang cỡ chữ `fontSize11`…`fontSize32` và `sectionHeaderLetterSpacing`.
- File mới: `core/theme/app_shadows.dart` (`AppShadows.card` / `cardSoft` / `cardRaised`) và `core/constants/app_durations.dart` (thời lượng hiệu ứng, toast, chuyển màn).
- Thay ~150 chỗ hardcode ở 22 file trong `core/widgets`, `presentation/screens`, `presentation/widgets`; giá trị hiển thị giữ nguyên nên giao diện không đổi.
- Giữ nguyên (không phải token giao diện): độ trễ giả lập mạng, debounce tìm kiếm, đếm ngược OTP, dữ liệu mẫu, hình học logo Google và công thức sóng âm.
- `flutter analyze`: 0 error, 0 warning. `flutter test`: 56 pass, 2 fail — 2 test Màn 05 (Thư viện) đã fail từ trước khi sửa.

---

### Phiên làm việc ngày 20/11/2026 (Phiên 6): Báo lỗi đăng nhập sai & màn Quên mật khẩu (Màn 02, 21)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Màn Đăng nhập: bổ sung xử lý khi đăng nhập sai / sai mật khẩu.
- Màn Quên mật khẩu theo mô tả chi tiết của nhóm (thanh tiêu đề có nút "<", mô tả, ô email, ghi chú, nút "Gửi liên kết đặt lại" khoá khi email trống, nút viền "Quay lại đăng nhập"). Chỉ frontend; cấm tự thêm thành phần; không hardcode; màn nhận `ForgotPasswordUiState(email)` và đưa thao tác ra callback `onEmailChange`, `onSendResetLinkClick`, `onBackClick`; 2 Preview.
- Nhóm chốt (AI hỏi lại trước khi làm): lỗi hiện dưới ô nhập; tách 2 lỗi "Email chưa được đăng ký" / "Mật khẩu không đúng"; thay luồng OTP 3 bước cũ bằng màn mới; "Gửi liên kết đặt lại" hiện chỉ gọi callback.

#### 2. Kết quả & Đóng góp của AI:
- `AuthRepository.login`: `AuthException` thêm `field` (`AuthErrorField.email/password`) để biết lỗi thuộc ô nào; chữ ký hàm giữ nguyên.
- `LoginScreen`: nhận `authRepository` (inject được), gọi `login()`, lỗi hiện dưới ô tương ứng và tự mất khi gõ lại; "Quên mật khẩu?" mở Màn 21.
- Viết lại `ForgotPasswordScreen` + `ForgotPasswordUiState`, 2 `@Preview`. Dùng lại `AppTextField`/`AppButton` (thêm tham số `labelStyle`, `hintStyle`, `borderRadius`, `textStyle`, màu nền/viền/chữ cho nút viền) thay vì tạo component mới.
- Token mới: chuỗi trong `AppStrings`, màu `authTextPrimary/authTextSecondary/authDivider` (trỏ tới màu đã có), `space40`, `authControlRadius`, style `authScreenTitle`, `authBody`, `authFieldLabel`, `buttonTextLarge`.
- Thêm `test/login_forgot_password_test.dart` (11 test). `flutter analyze` 0 error / 0 warning; `flutter test` 67 pass, 2 fail (2 test Màn 05 đã fail từ trước).

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

---

### Phiên làm việc ngày 20/11/2026 (Phiên 7): Thiết kế lại màn Thư viện (Màn 05)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- Thiết kế lại tab Thư viện theo mô tả chi tiết của nhóm (gọn, ít chữ): tiêu đề, ô tìm kiếm có nút xoá, hàng chip lọc cuộn ngang lấy từ `categories`, thẻ học phần (icon sách · tên + trình độ + số từ · vòng tiến độ %), 2 trạng thái trống. Chỉ frontend; không hardcode; màn nhận `LibraryUiState(query, categories, selectedCategoryId, courses)`; lọc làm ở state holder; dữ liệu mẫu riêng `LibrarySampleData`; 3 Preview.
- Nhóm chốt (AI hỏi lại trước khi làm): thêm trường `level` cho học phần; giữ Loading (khung xương) + Error ("Thử lại") theo rubric; giữ nút "+" tạo học phần cạnh tiêu đề.

#### 2. Kết quả & Đóng góp của AI:
- `CollectionModel` thêm `level` (mặc định B1, dữ liệu mẫu B2/A2/B1).
- Tạo `library_ui_state.dart` (`Category`, `Course.progressPercent`, `LibraryUiState` + trạng thái tải), `library_sample_data.dart`, `library_controller.dart` (lọc qua `store.search`, debounce 300ms, xoá chữ thì hiện lại ngay), widget `CourseProgressRing` (vẽ bằng CustomPainter).
- `library_screen.dart` tách `LibraryScreen` (nối store, điều hướng, Màn 22) và `LibraryView` (chỉ UI), 3 `@Preview`. Chip cao 36dp nhưng vùng chạm 48dp.
- Sửa 2 test Màn 05 fail từ trước: nguyên nhân là `pump()` không thời lượng không chạy timer `Future.delayed(Duration.zero)` → dùng `pump(1ms)`.
- Thêm `test/library_screen_test.dart` (10 test). `flutter analyze` 0 error / 0 warning; `flutter test` 79/79 pass.

---

### Phiên làm việc ngày 21/11/2026: Merge code nhóm & nối Track A (FE1) với Track B (FE2)

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Cập nhật tiếp các push của thành viên khác đã push lên" → merge `main` (backend) và `feature/fe2-track-b` vào `feature/fe1-track-a`.
- "FE2 đã làm xong nhiệm vụ của họ chưa?" → đối chiếu code FE2 với FE spec §4, §5.2.
- "Nối các task của FE2 với FE1 sao cho không còn bị conflict." Nhóm chốt (AI hỏi lại): giữ Trang chủ giao diện FE1; lối vào Màn 13 đặt ở nút "Thêm từ" của Màn 06.

#### 2. Kết quả & Đóng góp của AI:
- Merge: giải conflict `main_shell_screen.dart` (Trang chủ FE1 + tab Luyện tập `PracticeModeScreen` của FE2), `settings.gradle.kts` (giữ AGP 9.3.1 / Kotlin 2.4.20), `prompt_log.md` (giữ cả hai phiên).
- `CollectionBridge` (FE2 gọi) chuyển phần bên trong sang `CollectionStore` của FE1 đúng hợp đồng §5.1, chữ ký giữ nguyên: lưu từ AI xong Thư viện cập nhật ngay, từ có id, tên học phần trùng tự thêm hậu tố.
- `HomeStateBuilder`: Trang chủ FE1 lấy số liệu thật (tổng từ, học phần từ `CollectionStore`; streak, từ cần ôn, số từ ôn hôm nay từ `DashboardStore`). Các ngày trước trong biểu đồ tuần vẫn dùng dữ liệu mẫu vì chưa có API thống kê tuần.
- `MainShellScreen`: "Bắt đầu ôn tập" / thẻ "Từ cần ôn" → Màn 16; bấm học phần → Màn 06.
- Màn 06: nút "Thêm từ" mở lựa chọn Thêm thủ công (Màn 24) / Tạo bằng AI (Màn 13, chọn sẵn học phần đang xem); lưu xong quay về Màn 06 theo luồng §3.2.
- `TrackSync` (gọi ở `main()`): mục tiêu ngày Cài đặt → `DashboardStore`; streak sau quiz → hồ sơ (Màn 15). Giới hạn mục tiêu ở Cài đặt đổi 50 → 30 cho khớp BE.
- Sửa nhỏ trong file FE2 (chỉ thêm tham số tuỳ chọn): `AiGenerateScreen`/`AiPreviewScreen` nhận `initialCollectionId`, Màn 14 trả `true` thay vì `popUntil`; Màn 10 đổi `Row` → `Wrap` để không tràn layout.
- Thêm `test/track_integration_test.dart` (4 test). `flutter analyze` 0 error / 0 warning; `flutter test` 105/105 pass.

---

### Phiên làm việc ngày 22/11/2026: Kiểm tra lỗi & thêm tài khoản test

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Còn lỗi gì không, trình chiếu giao diện lên cho tôi" → chạy `flutter analyze`, `flutter test`, mở app trên Chrome.
- "Tạo một tài khoản test admin@123 / 123456 để đăng nhập, không cần hiện text ở giao diện đăng nhập."
- Hỏi về phân công FE/BE: AI đối chiếu FE spec, việc tích hợp API thật thuộc FE ở Sprint 3 (`DEV1-S3-05`, `DEV2-S3-05`).

#### 2. Kết quả & Đóng góp của AI:
- `flutter analyze` 0 error / 0 warning (còn info deprecate `material.dart` của SDK mới); bỏ import thừa `foundation.dart` ở Màn 13.
- `AuthRepository` thêm `testEmail` / `testPassword` (`admin@123` / `123456`), có cả trong `debugReset()`; màn Đăng nhập không hiển thị gợi ý.
- Thêm 1 unit test đăng nhập bằng tài khoản test. `flutter test` 106/106 pass.

---

### Phiên làm việc ngày 22/11/2026 (tiếp): Luyện tập, màn chơi, phát âm, dọn code

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Thiết kế lại giao diện luyện tập" (kèm spec Figma), "giao diện luyện tập đang không responsive, thiết kế lại".
- "Thêm 2 trò chơi Đồng nghĩa và trái nghĩa, Nhớ từ qua nghĩa"; "có âm thanh khi làm đúng và sai, bạn tự tạo âm thanh".
- "Để từ có thể phát âm khi tạo"; "Loại từ sửa hết thành các options" (13 loại); "màn khởi động ảnh to hơn, chữ ExtraBold".
- "App không có emoji, xoá hết, ngoài ra clean code"; "thiết kế giao diện các game sao cho chuyên nghiệp".
- "Làm các game liên quan và liên kết với backend nếu đã có"; "Sửa lại giao diện sửa từ vựng" (kèm spec 393 × 852).

#### 2. Kết quả & Đóng góp của AI:
- Màn 10 Luyện tập: bố cục responsive theo breakpoint 600 / 1024, bottom sheet chọn học phần / số lượng / trạng thái, lưới 6 trò chơi; thanh điều hướng đổi kiểu viên thuốc.
- Màn chơi (08 / 19 / 20 / 25), phản hồi (11), kết quả (12) thiết kế lại cùng ngôn ngữ với Màn 10; nội dung tối đa 600px trên màn rộng.
- 2 game mới: Luyện phát âm (nhận dạng giọng nói của thiết bị qua `speech_to_text`, cho bỏ qua khi máy không hỗ trợ) và Đồng nghĩa / trái nghĩa (dữ liệu mẫu cho 12 từ). Đã kiểm tra backend: chưa có API cho 2 game này, FE chưa có lớp HTTP nên vẫn chạy Demo Mode; BE cần thêm cột `synonyms`, `antonyms`, `note` và 2 giá trị enum `QuizMode`.
- Âm thanh đúng / sai tự tạo (`assets/sounds`), phát âm bằng TTS của thiết bị (`flutter_tts`), nút nghe thử khi thêm từ; 13 loại từ (`PartOfSpeech`).
- Màn 09 / 24 Thêm & Sửa từ vựng làm lại theo spec: 7 trường, thêm "Ghi chú", nút "Lưu thay đổi" trong vùng cuộn.
- Splash: logo 184dp, chữ ExtraBold; `kotlin.incremental=false` sửa lỗi build khi project và pub cache khác ổ đĩa.
- Dọn code: xoá toàn bộ emoji, đưa chuỗi viết thẳng của Track B vào `AppStrings`, xoá file và token không dùng, sắp xếp import.
- `flutter analyze` 0 error / 0 warning; `flutter test` 126/126 pass.

---

### Phiên làm việc ngày 22/11/2026 (tối): Hồ sơ, loại tài khoản, Chi tiết từ, rà soát giao diện

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Giao diện huy hiệu thành tựu có nên bỏ không" → nhóm quyết định bỏ.
- "Sửa giao diện hồ sơ cá nhân": ảnh đại diện, mã ID `KM` + YYMMDD + số thứ tự (không sửa được), email (không sửa được), ngày sinh DD/MM/YYYY, loại tài khoản Thường / Plus / Vip kèm hạn mức. AI hỏi lại 3 điểm, nhóm chọn: số thứ tự quá 99 thì thành 3 chữ số; hỏi ngày sinh khi đăng ký, sửa được ở Cài đặt; hiển thị và chặn hạn mức ngay trong app.
- "Hãy chỉ ra những giao diện thiết kế kém chuyên nghiệp và sửa lại", "sửa tiếp cả 4 mục".
- "Sửa lại giao diện tạo từ thủ công đang không responsive, sửa giao diện chi tiết từ và chỉnh sửa" (kèm prompt tham khảo 393 × 852).
- "Hạn chế các title nhỏ giải thích cho tên lớn"; "thêm ô từ đồng nghĩa / trái nghĩa, nhấn cách thì thành thẻ có dấu × để xoá".

#### 2. Kết quả & Đóng góp của AI:
- Màn 15 Hồ sơ làm lại: bỏ huy hiệu (`BadgeRules`), thêm khối Thông tin tài khoản, Quyền lợi gói (lượt AI hôm nay, số từ đã lưu), Thành tựu. `AccountPlan` (Thường 3 lượt AI/ngày + 500 từ, Plus dùng thử 30 ngày + 10 lượt, Vip không giới hạn), `MemberId.generate`, `AuthRepository.updateBirthDate` / `recordAiGeneration` / `wordLimitError`.
- Màn 03 Đăng ký: thêm ô ngày sinh bắt buộc, nối nút Đăng ký (trước đây chưa có hành động). Cài đặt thêm dòng Ngày sinh. Màn 13 / 14 / 24 chặn khi hết lượt AI hoặc vượt 500 từ. Backend cần thêm `birthDate`, `memberId`, `plan`, `planExpiresAt`, bộ đếm lượt AI và tự kiểm tra lại hạn mức.
- Rà soát 12 màn bằng ảnh chụp: sửa tràn 36px ở Cài đặt, bỏ chữ kỹ thuật ("Localization", "Rubric INT1449", "MVP"), nút Đăng xuất đỏ đồng bộ, từ loại thống nhất nhãn tiếng Việt, ẩn công tắc "Mô phỏng lỗi AI" ở bản phát hành.
- Thống nhất một màu nút chính `AppColors.actionPrimary` (#0066CC, tương phản 5,6:1 với chữ trắng); gộp thẻ nhắc ôn tập và nút "Bắt đầu ôn tập" ở Trang chủ; tiêu đề màn con căn giữa qua `AppTheme`; thêm font `NotoSansIPA` (bản rút gọn, giấy phép OFL) làm font dự phòng để phiên âm hiện đủ ký tự.
- Màn 07 Chi tiết từ làm lại (thẻ từ, nút phát âm vuông, nghĩa, ví dụ, đồng nghĩa / trái nghĩa, nút xoá dạng chữ); Màn 09 / 24 dùng chung đầu trang, giãn theo chiều rộng (tối đa 600px), thêm ô thẻ đồng nghĩa / trái nghĩa (`TagInputField`).
- Bỏ các dòng mô tả lặp lại tiêu đề (thẻ trò chơi, Cài đặt, Hồ sơ, đầu trang màn từ vựng).
- `flutter analyze` 0 error / 0 warning; `flutter test` 140/140 pass.

---

### Phiên làm việc ngày 23/11/2026: Bỏ loại tài khoản, Thư viện, mục tiêu ngày, tiêu đề tab

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Tôi không muốn phân quyền tài khoản theo Thường, Vip, Plus nữa, xoá đi; ngoài ra design lại giao diện thư viện cho đẹp."
- "Mấy cái mục tiêu học tập hằng ngày, nhắc nhở ôn tập, ngôn ngữ giao diện có cần thiết không?" → AI đối chiếu FE spec và code, đề xuất: bỏ Ngôn ngữ (chưa có đa ngôn ngữ, chọn English không có tác dụng), nối Mục tiêu vào Trang chủ, giữ Nhắc nhở. Nhóm đồng ý.
- "Các text 'Xin chào, Karmate!', 'Thư viện', 'Luyện tập', 'Hồ sơ cá nhân' cùng font size, cùng màu, cùng vị trí."
- "Chỗ chi tiết từ vựng xoá cái giọng US hoặc giọng UK đi."
- "Thiết kế lại các giao diện học phần, chỉ cần tên và số từ, thêm 1 icon; ngoài ra có tính năng sửa, xoá các bộ học phần."
- "Thẻ học phần có nhất thiết phân theo chủ đề không, hơi ít chủ đề" → AI đối chiếu spec (FR-VOCAB-01/02, DEV1-S4-02, BE `category`), khuyên giữ và thêm "Khác" (`other` BE đã có). Nhóm đồng ý.

#### 2. Kết quả & Đóng góp của AI:
- Xoá `AccountPlan` và toàn bộ hạn mức (lượt AI / ngày, 500 từ); Màn 15 bỏ chip gói, dòng Loại tài khoản, khối Quyền lợi gói. Mã ID và ngày sinh giữ nguyên.
- Màn 05 Thư viện làm lại: thẻ tổng quan (từ đã thuộc / tổng, số học phần), icon và màu theo chủ đề, tên học phần 2 dòng, lưới 2–3 cột trên màn rộng, trạng thái trống có linh vật + nút Tạo học phần, không tìm thấy có nút Xoá bộ lọc.
- Cài đặt bỏ mục Ngôn ngữ giao diện; Trang chủ thêm thẻ "Mục tiêu hôm nay" (số từ đã ôn / mục tiêu, đổi màu khi đạt).
- Widget `TabHeader` dùng chung cho 4 tab: cùng kiểu chữ `AppTypography.tabTitle`, cùng lề và chiều cao; Hồ sơ bỏ AppBar.
- Màn 07 bỏ 2 nút chọn giọng UK / US (nút loa đọc giọng UK mặc định); xoá token không còn dùng.
- Thẻ học phần (Thư viện, Trang chủ) chỉ còn icon theo chủ đề, tên, số từ; thêm sửa / xoá học phần (`updateCollection`, `deleteCollection`, menu ⋮ ở Màn 05 và 06, xoá phải xác nhận); thêm chủ đề "Khác" làm mặc định. `flutter test` 145/145 pass.
- `flutter analyze` 0 error / 0 warning; `flutter test` 140/140 pass.

---

### Phiên làm việc ngày 24/11/2026: Rà soát UX theo góc nhìn BA và sửa nhóm lỗi mức cao

> Công cụ: Claude Code (Anthropic).

#### 1. Yêu cầu đầu vào (Prompts):
- "Bạn hãy đóng vai trò làm nhà BA chuyên nghiệp nhận xét app này những trang nào thiết kế chưa ổn" → AI chụp 20 màn (390 × 844, dữ liệu Demo), đối chiếu code, xếp nhận xét theo 3 mức.
- "Sửa nhóm mức cao từ 1 đến 4 đi nhưng không được phép sửa backend" → chỉ sửa trong `karvocab_flutter/`.

#### 2. Kết quả & Đóng góp của AI:
- Màn 03 Đăng ký: thêm ô Họ và tên bắt buộc (`Validators.fullName`), không còn lấy phần trước "@" của email làm tên. Nút Google / Facebook nối vào `AuthRepository.loginWithSocial` (trước đây bấm không có tác dụng).
- Số liệu thống nhất: Trang chủ "Số từ mới tạo" đổi thành "Từ chưa học"; Hồ sơ tính "Từ đã học" và "Chuỗi ngày" từ `DashboardStore` (cùng luật `isLearned`) thay cho số mẫu 42; Cài đặt đổi nhãn thành "Số từ cần học mỗi ngày" cho khớp cách đếm mục tiêu; Màn 10 "Chọn tối đa 3 học phần".
- Màn 09 / 24 Thêm từ: gợi ý có tiền tố "VD:", dấu * đỏ cho ô bắt buộc, Từ loại và Trình độ không còn chọn sẵn (chưa chọn thì báo lỗi); ô đồng nghĩa / trái nghĩa tách thẻ bằng dấu phẩy / chấm phẩy / Enter để nhập được cụm như "give up".
- Màn làm bài: đồng hồ đếm ngược thành viên tròn (vòng thời gian + số giây) thay cho thanh ngang thứ hai, đặt ở chỗ chip tên trò (tên trò đã có trong câu hướng dẫn). Trò Nghe chỉ bắt đầu đếm khi phát xong âm thanh lần đầu; trò Phát âm giữ đồng hồ trong lúc hỏi quyền micro và đang nghe (`holdCountdown` / `releaseCountdown`).
- Thêm test: lỗi họ tên, nút Google, Từ loại / Trình độ bắt buộc, cụm từ trong ô thẻ, giữ đồng hồ trò Nghe / Phát âm, Hồ sơ khớp Trang chủ.
- `flutter analyze` 0 error / 0 warning; `flutter test` 165/165 pass.

#### 3. Sửa tiếp nhóm mức trung bình (Prompt: "sửa tiếp nhóm mức trung bình"):
- Màn 10 Luyện tập: trên điện thoại / tablet, Trạng thái từ, Số lượng, Thứ tự, Thời gian thu gọn thành dòng "Tuỳ chọn khác" (tóm tắt "Chưa thuộc · 20 từ · A-Z · Có đếm giờ") để danh sách trò chơi hiện ngay màn đầu; máy tính vẫn mở sẵn. Thêm dòng báo số từ thật có ("Có 3 từ phù hợp · phiên chỉ có 3 câu"). Trò dễ lên trước, Luyện phát âm (cần micro) xuống cuối. Nút "Ngẫu nhiên" khi chưa chọn có nền trắng, viền và chữ đậm, không còn trông như bị khoá.
- Màn 13: bộ đếm "0/100" chỉ hiện khi gõ từ 80 ký tự, ô chủ đề gọn một dòng. Công tắc "Mô phỏng lỗi AI" vốn đã chỉ hiện ở bản debug (`kDebugMode`), không cần sửa.
- Màn 14: nút loa và bút lên cùng dòng với từ, nghĩa và câu ví dụ dùng trọn bề ngang thẻ; độ dày viền dùng token `AppDimensions.borderThin` / `borderMedium`.
- Màn 15 / 17: Ngày sinh chỉ sửa ở Hồ sơ (bỏ dòng trùng ở Cài đặt); thay icon ổ khoá cạnh Email bằng chú thích "Dùng để đăng nhập, không thể thay đổi".
- `flutter analyze` 0 error / 0 warning; `flutter test` 167/167 pass.

#### 4. Sửa tiếp nhóm mức thấp (Prompt: "sửa tiếp nhóm mức thấp"):
- Màn 07 Chi tiết từ: thêm khối "Tiến độ học" (Chưa học / Đang học · cấp n/5 / Đã thuộc) và lịch ôn lại, đọc từ `DashboardStore` (có tham số `dashboard` để test). Sửa chính tả "Xóa" thành "Xoá" cho thống nhất.
- Màn 12 Kết quả: mỗi từ sai hiện câu người dùng đã trả lời (hoặc "Hết giờ, chưa trả lời" / "Đã bỏ qua câu này") và lịch ôn lại theo SM-2 ("Ôn lại vào ngày mai").
- Màn 16 Ôn tập hôm nay: nhãn theo mức gấp, có nền tint: đến hạn hôm nay (xanh), quá hạn 1–2 ngày (cam), từ 3 ngày (đỏ). Thêm token `AppColors.warningOrangeText` / `errorRedText` cho chữ nhỏ đủ tương phản.
- Màn 05 Thư viện: nút "+" thêm chữ "Tạo mới" (giữ tooltip). Không thêm lại tiến độ vào thẻ học phần vì nhóm đã chủ động bỏ số "đã thuộc" ở Thư viện.
- Hàm dùng chung `reviewDueText` / `calendarDaysBetween` (`core/utils/review_schedule.dart`), tính theo ngày lịch nên không lệch khi đổi giờ mùa hè.
- Thêm `test/low_priority_ux_test.dart` (6 test). `flutter analyze` 0 error / 0 warning; `flutter test` 172/172 pass.

#### 5. Nhận xét lại vai trò BA và sửa nhóm mức cao lần 2 (Prompt: "nhận xét lại app với vai trò BA" → "sửa nhóm mức cao từ 1 đến 3 đi"):
- Chụp lại 28 trạng thái màn hình (kể cả trống / tải / lỗi, phản hồi quiz, AI) để đánh giá; mục mức cao được xác minh thêm trong code.
- Màn 02 Đăng nhập: kiểm tra email / mật khẩu trên máy trước khi gửi (dùng `Validators.email`, `Validators.loginPassword` như form Đăng ký). Trước đó để trống email bị báo nhầm "Email chưa được đăng ký".
- Dữ liệu Demo (`DashboardStore._seed`): bỏ số "đã học sáng nay" cố định (4) khiến Trang chủ ghi 4/10 trong khi Hồ sơ ghi 0 từ đã học. Nay mỗi từ mẫu có cấp SM-2 riêng (`_seedPlan`): 9 từ đã học, 1 từ đã thuộc, 3 từ mới; hôm nay chưa học nên mục tiêu 0/N khớp với streak tính tới hôm qua; từ quá hạn có đủ 3 mức màu ở Màn 16. Màn 07: từ chưa học hiện "Lịch ôn sẽ có sau lần luyện tập đầu tiên" thay vì "Ôn lại hôm nay".
- Màn 04 Trang chủ: người dùng chưa có học phần thấy thẻ trạng thái trống (Axolotl + "Tạo học phần" + "Tạo từ vựng bằng AI") thay cho các ô số 0, nút bị khoá và biểu đồ rỗng. `MainShellScreen` nối nút tạo với sheet tạo học phần rồi mở Màn 06, nút AI mở Màn 13.
- Thêm `test/high_priority_ux_test.dart` (3 test), cập nhật test trạng thái trống Trang chủ và test Hồ sơ theo dữ liệu mẫu mới. `flutter analyze` 0 error / 0 warning; `flutter test` 175/175 pass.

#### 6. Sửa nhóm mức trung bình lần 2 (Prompt: "sửa tiếp nhóm mức trung bình"):
- Màn 11 phản hồi sai: game trắc nghiệm đã tô xanh lựa chọn đúng nên bỏ dòng "Đáp án đúng" lặp lại; bảng phản hồi thấp hơn, không còn che lựa chọn D. Game gõ chữ vẫn hiện đáp án đúng.
- Màn 06 học phần trống: dùng Axolotl thay icon bàn chân (thêm tham số `mascot` cho `EmptyStateWidget`), ẩn nút "Thêm từ" ở góc khi đã có nút "Thêm từ mới ngay" giữa màn. Nút trong Empty State nay giãn theo chữ (tối thiểu 220dp) nên không tràn khi cỡ chữ lớn.
- Màn 10 danh sách trò chơi: "Nghe và điền từ" có icon bàn phím riêng; icon thẻ lấy chung từ `QuizModeIcon`; bỏ kiểu icon tô đậm ở thẻ đầu (trông như đang được chọn); tên trò luôn giữ chỗ 2 dòng để mọi thẻ cao bằng nhau.
- Dữ liệu mẫu: bỏ / thay các cặp trái nghĩa dễ tranh cãi (explore–ignore, opportunity–obstacle, ambitious–lazy, persistent–hesitant, investment–withdrawal).
- Thêm `test/medium_priority_ux_test.dart` (5 test), cập nhật test hết giờ ở `quiz_timer_test.dart`. `flutter analyze` 0 error / 0 warning; `flutter test` 180/180 pass.

#### 7. Sửa chế độ tạo từ bằng AI (Prompt: "chế độ tạo từ bằng AI fix lại cho tôi thứ nhất khi nhập chủ đề bằng tiếng việt nó cũng tạo cho và không cần chọn level từ theo khung CEFR ngoài ra tạo từ phải chuẩn vào đừng linh tinh"):
- Nguyên nhân "từ linh tinh": bản Demo chỉ nhận vài từ khoá tiếng Anh; chủ đề không khớp (vd tiếng Việt) thì trộn ngẫu nhiên từ của chủ đề khác cho đủ số lượng, và gán mọi từ theo cấp CEFR người dùng chọn dù trình độ thật khác.
- Kho từ Demo mới `lib/data/mock/mock_ai_vocab_bank.dart`: 8 chủ đề × 8 từ, mỗi chủ đề có từ khoá tiếng Anh và tiếng Việt; nhận diện không phân biệt dấu (kể cả dấu tổ hợp, "khoẻ"/"khỏe") và khớp theo nguyên từ. Mỗi từ ghi trình độ CEFR thật (tham khảo Oxford 3000/5000).
- `MockAiVocabRepository` chỉ trả từ đúng chủ đề, không chèn từ chủ đề khác; ít hơn số yêu cầu thì Màn 13 báo rõ. Chủ đề chưa có trong kho Demo → lỗi `TOPIC_UNSUPPORTED` kèm gợi ý chủ đề có sẵn.
- CEFR không bắt buộc: `cefrLevel` của `AiVocabRepository.generate` thành `String?`; bấm lại cấp đang chọn để bỏ chọn. Có chọn cấp thì ưu tiên đúng cấp, thiếu thì lấy cấp liền kề trong cùng chủ đề. Khi nối BE cần thống nhất để `cefrLevel` được phép bỏ trống.
- Gợi ý chủ đề và chữ mẫu trong ô nhập thêm tiếng Việt. Thêm `test/ai_generate_vocab_test.dart` (8 test). `flutter analyze` 0 error / 0 warning; `flutter test` 188/188 pass.

#### 8. Thiết kế lại Màn 13 (Prompt: "Thiết kế lại giao diện tạo từ bằng AI: giữ ô chủ đề, xóa chọn CEFR, số lượng từ dạng thanh kéo ngang"):
- Giữ nguyên ô chủ đề và gợi ý. Bỏ hẳn khối chọn CEFR (app luôn gửi `cefrLevel = null`; mỗi từ vẫn ghi đúng trình độ thật). Số lượng từ đổi từ nút cộng/trừ sang thanh kéo `Slider` 3–20, hiện số đang chọn ở góc phải.
- Cập nhật `test/ai_generate_vocab_test.dart` (kéo thanh về 3 và 20, vùng chạm ≥ 48dp). `flutter test` 188/188 pass.

#### 9. Nối app với backend (Prompt: "nối app với backend đi, gửi mặc định B1"):
- Thêm gói `http`, `core/config/api_config.dart` (đọc `--dart-define=API_BASE_URL`, rỗng = Demo Mode offline) và `data/remote/api_client.dart` (gắn Bearer token, bóc `{ success, data }`, đổi lỗi BE thành `ApiException`, 401 thì tự gọi `/auth/refresh` một lần).
- `AuthRepository`: đăng nhập, đăng ký, Google / Facebook (token mock của BE) và đăng xuất gọi BE khi có `API_BASE_URL`; Chế độ Dùng thử vẫn offline.
- `RemoteAiVocabRepository` gọi `POST /ai/generate-vocab`, gửi `cefrLevel = 'B1'` vì BE bắt buộc mà app đã bỏ ô chọn cấp độ. Màn 13 tự chọn bản thật khi đã đăng nhập qua BE, ngược lại dùng kho từ mẫu.
- Không sửa code backend; chỉ chỉnh file `.env` cục bộ (CORS cho `localhost:5173`). Thêm `test/backend_integration_test.dart` (5 test, dùng `MockClient`). `flutter test` 193/193 pass.

#### 10. Gọn chữ phụ + ngọn lửa chuỗi mới (Prompt: "chỉ cần title thôi hạn chế text nhỏ bên dưới lại chỉ cần những cái cần thiết… thiết kế lại ngọn lửa chuỗi đi"):
- Bỏ chữ phụ không cần thiết: "Một phiên ngắn · khoảng N phút" (Trang chủ), "Chọn tối đa 3 học phần" và dòng tóm tắt "Tuỳ chọn khác" (Màn 10), "N giây/câu" trên thẻ trò chơi, ghi chú dưới Email (Hồ sơ), dòng giải thích âm lượng, "Lịch ôn sẽ có sau…" khi từ chưa học. Giữ những dòng mang thông tin cần: cảnh báo thiếu từ (chỉ hiện khi thiếu), luật hết giờ, lịch ôn khi đã học.
- `core/widgets/streak_flame.dart`: ngọn lửa vẽ bằng `CustomPainter` (lửa ngoài đỏ cam → cam vàng có lưỡi lửa phụ, lõi vàng sáng; chuỗi 0 ngày thì xám). Thêm token màu `streakFlame*`, `streakCore*`, `streakOff*`. Dùng ở thẻ Chuỗi ngày học (Trang chủ) và Thành tựu (Hồ sơ).
- Thêm `test/streak_flame_test.dart`, sửa các test cũ còn tìm chữ đã bỏ. `flutter test` 195/195 pass.

#### 11. Sửa nhóm mức cao (BA lần 3) và bỏ dữ liệu giả (Prompt: "sửa nhóm mức cao đi, chưa cần tạo data giả xóa hết các data giả đi cho tôi"):
- **Bỏ dữ liệu giả khỏi app:** chuyển `MockVocabData`, `HomeSampleData`, `LibrarySampleData`, `NotificationSampleData` sang `test/fixtures/` (chỉ test dùng). Bỏ tiến độ SM-2 mẫu, chuỗi 7 ngày mẫu, lịch sử tuần mẫu, 3 thông báo mẫu, hồ sơ "Nguyễn Văn A" và lời chào cứng "Karmate". Tài khoản Demo vẫn đăng nhập được nhưng bắt đầu trống. Kho từ AI offline (`MockAiVocabBank`) giữ lại vì là nguồn tạo từ khi chưa có Gemini.
- **Lưu dữ liệu trên máy:** thêm `shared_preferences` + `crypto`, lớp `data/local/local_store.dart`. Tài khoản (mật khẩu băm SHA-256 có muối), phiên đăng nhập, học phần, từ vựng, tiến độ SM-2, chuỗi ngày, lịch sử từng ngày (biểu đồ tuần) và cài đặt luyện tập đều được lưu; dữ liệu hỏng thì bắt đầu trống. Hàng đợi ôn tập và đáp án nhiễu lấy từ thư viện thật của người dùng.
- **Huy hiệu ở Hồ sơ (đặc tả §4.6):** `Chuỗi 7 ngày`, `100 từ đầu tiên`, `Nhà thám hiểm`; chưa mở thì xám kèm điều kiện và tiến độ.
- **Tài liệu:** README, `prompt_log` và `CLAUDE.md` mô tả đúng kiến trúc (`ChangeNotifier`, không BLoC) và cách lưu dữ liệu.
- Thêm Empty State cho Luyện tập khi chưa có từ, chào bằng tên gọi. Thêm `test/persistence_test.dart` (7 test) và 2 test ở `high_priority_ux_test.dart`. `flutter test` 204/204 pass.

#### 12. Thông báo chỉ nhắc ôn tập (Prompt: "tôi nghĩ đến việc thông báo khi từ cần ôn tập thôi" → "làm cái 1"):
- Chuông ở Trang chủ trước đây chỉ là giao diện, không có nguồn thông báo. Nay chỉ còn một loại: "Đến giờ ôn tập — Có N từ đến hạn ôn", lấy từ `DashboardStore` (`ReviewNotificationBuilder`).
- Cùng luật với job nhắc ôn của backend (`review-reminder.job.ts`): chỉ đếm từ đã học đến hạn, từ mới không tính, không có từ đến hạn thì không báo, mỗi ngày một thông báo. Bấm vào thì đánh dấu đã đọc (lưu trên máy) và mở Màn 16 Ôn tập hôm nay; ôn xong hết thì thông báo tự mất.
- Chưa làm thông báo hệ thống điện thoại (`flutter_local_notifications`). Thêm `test/review_notification_test.dart` (5 test), `flutter test` 209/209 pass.

#### 13. Rà logic frontend theo hợp đồng backend (Prompt: "bọn tôi chỉ làm frontend dựa vào backend thôi nên là ko bịa thêm gì nhé hãy check xem logic frontend ổn chưa cả giao diện"):
- **Bỏ kho từ AI dựng sẵn** (`MockAiVocabBank`, `MockAiVocabRepository`): Màn 13 chỉ tạo từ qua `POST /ai/generate-vocab`. Không nối máy chủ hoặc đang Dùng thử thì hiện lý do ("Chưa kết nối máy chủ" / "Cần đăng nhập tài khoản") và khoá nút tạo.
- **Khớp `GenerateVocabDto`:** chủ đề 3–100 ký tự (báo lỗi ngay khi nhập 1–2 ký tự), số từ 3–20. BE có thể trả ít hơn số đã chọn (bỏ từ trùng / sai định dạng) nên app báo "AI trả về N/M từ hợp lệ".
- **Mật khẩu** đăng ký / đặt lại: thêm giới hạn tối đa 72 ký tự như BE.
- Đã kiểm tra: mã lỗi AI (RATE_LIMITED, AI_TIMEOUT, AI_BAD_RESPONSE, AI_UNAVAILABLE), thời gian chờ (BE 15 giây < app 20 giây), mục tiêu ngày 5–30 khớp BE và đồng bộ Cài đặt ↔ Trang chủ, các giới hạn độ dài khác ở app chặt hơn hoặc bằng BE.
- Viết lại `test/ai_generate_vocab_test.dart` theo hợp đồng BE (5 test), thêm test mật khẩu 72 ký tự.
