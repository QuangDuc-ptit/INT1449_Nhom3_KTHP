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
