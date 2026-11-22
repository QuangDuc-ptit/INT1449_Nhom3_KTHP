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

#### 2. Kết quả & Đóng góp của AI:
- Xoá `AccountPlan` và toàn bộ hạn mức (lượt AI / ngày, 500 từ); Màn 15 bỏ chip gói, dòng Loại tài khoản, khối Quyền lợi gói. Mã ID và ngày sinh giữ nguyên.
- Màn 05 Thư viện làm lại: thẻ tổng quan (từ đã thuộc / tổng, số học phần), icon và màu theo chủ đề, tên học phần 2 dòng, lưới 2–3 cột trên màn rộng, trạng thái trống có linh vật + nút Tạo học phần, không tìm thấy có nút Xoá bộ lọc.
- Cài đặt bỏ mục Ngôn ngữ giao diện; Trang chủ thêm thẻ "Mục tiêu hôm nay" (số từ đã ôn / mục tiêu, đổi màu khi đạt).
- Widget `TabHeader` dùng chung cho 4 tab: cùng kiểu chữ `AppTypography.tabTitle`, cùng lề và chiều cao; Hồ sơ bỏ AppBar.
- `flutter analyze` 0 error / 0 warning; `flutter test` 140/140 pass.
