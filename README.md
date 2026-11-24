# KarVocab — Đồ án môn học INT1449 (Lập trình di động)
> **Học phần:** INT1449 · Lập trình thiết bị di động  
> **Nhóm thực hiện:** Nhóm 03  
> **Đề tài:** Ứng dụng di động học từ vựng tiếng Anh theo phương pháp Lặp lại ngắt quãng (Spaced Repetition SM-2) & Trí tuệ nhân tạo (AI)

---

## 📌 Giới thiệu dự án
**KarVocab** là ứng dụng di động hỗ trợ người học tiếng Anh ghi nhớ từ vựng lâu dài thông qua thuật toán khoa học SuperMemo SM-2 và khả năng sinh từ vựng ngữ cảnh tự động từ mô hình AI Google Gemini.

Dự án được xây dựng theo chuẩn **Rubric INT1449** với:
* **Kiến trúc phân tầng `core` → `data` → `presentation`:** quản lý trạng thái bằng `ChangeNotifier` + `ListenableBuilder` của Flutter (không dùng thư viện BLoC). Các store/repository là singleton có thể tiêm vào màn hình để kiểm thử.
* **Trải nghiệm tiếp cận người dùng (Accessibility):** 100% nút bấm và ô nhập liệu đạt kích thước cảm ứng tối thiểu $\ge 48$dp.
* **Chạy ngoại tuyến, lưu dữ liệu trên máy:** tài khoản, học phần, từ vựng, tiến độ SM-2 và chuỗi ngày được lưu bằng `shared_preferences`, mở lại app vẫn còn. App bắt đầu trống, không có dữ liệu mẫu.
* **Nối backend (tuỳ chọn):** chạy kèm `--dart-define=API_BASE_URL=http://localhost:3100/api/v1` để đăng nhập và tạo từ bằng AI qua backend (`backend/`).
* **Quy trình kiểm thử tự động:** Đạt chuẩn `flutter test` $\ge 15$ tests và `flutter analyze` 0 lỗi, 0 cảnh báo.

---

## 📂 Cấu trúc Repository

```text
├── docs/                      # Tài liệu thiết kế & đặc tả hệ thống
│   └── karvocab/
│       ├── FE-SPECIFICATION.md# Đặc tả 28 màn hình, Design Tokens & phân chia FE1 / FE2
│       └── BE-SPECIFICATION.md# Đặc tả 9 bảng ERD PostgreSQL, 18 REST APIs & thuật toán SM-2
├── karvocab_flutter/          # Mã nguồn ứng dụng di động Flutter
│   ├── lib/
│   │   ├── core/              # Design tokens, theme, typography, base widgets (>= 48dp)
│   │   ├── data/              # Models, repositories/stores, lưu trữ trên máy (local), gọi API (remote)
│   │   └── presentation/      # Splash, Login, Main Shell, Library, Words, Profile, Settings
│   ├── test/                  # Bộ kiểm thử tự động (Unit & Widget Tests); dữ liệu mẫu chỉ nằm trong test/fixtures
│   └── docs/ai/               # Nhật ký sử dụng AI (AI Prompt Log theo Rubric Tiêu chí 5)
```

---

## 🚀 Hướng dẫn cài đặt và chạy ứng dụng

### 1. Yêu cầu môi trường
* Flutter SDK $\ge 3.22.0$ (Dart SDK $\ge 3.4.0$)
* Android Studio / VS Code có cài đặt Flutter & Dart extension
* Trình duyệt Chrome hoặc Máy ảo Android (Android Emulator API 33+)

### 2. Khởi chạy
```bash
# Di chuyển vào thư mục ứng dụng Flutter
cd karvocab_flutter

# Cài đặt thư viện dependencies
flutter pub get

# Kiểm tra chất lượng mã nguồn (Đạt 0 lỗi)
flutter analyze

# Chạy kiểm thử tự động
flutter test

# Khởi chạy ứng dụng (ngoại tuyến)
flutter run

# Hoặc nối backend để đăng nhập và tạo từ AI thật
flutter run --dart-define=API_BASE_URL=http://localhost:3100/api/v1
```

Tài khoản Demo (bắt đầu trống): `learner@karvocab.com` / `Karvocab1`. Có thể đăng ký tài khoản mới ngay trong app.

---
*Dự án thuộc bản quyền học tập của Nhóm 03 — Học viện Công nghệ Bưu chính Viễn thông (PTIT).*
