# KarVocab — App Flutter

App di động học từ vựng tiếng Anh theo phương pháp lặp lại ngắt quãng SM-2 (đồ án INT1449, Nhóm 03).

Hướng dẫn đầy đủ (tính năng, kiến trúc, chạy trên điện thoại thật, nối backend, kiểm thử) nằm ở [README gốc của repo](../README.md).

## Chạy nhanh

```bash
flutter pub get
flutter analyze
flutter test
flutter run                                                        # ngoại tuyến
flutter run --dart-define=API_BASE_URL=http://localhost:3100/api/v1  # nối backend
```

Tài khoản demo ở chế độ ngoại tuyến: `learner@karvocab.com` / `Karvocab1`.
