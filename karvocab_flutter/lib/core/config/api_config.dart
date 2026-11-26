/// Cấu hình kết nối backend (NestJS, thư mục `backend/`).
///
/// Mặc định app chạy Demo Mode (offline, dữ liệu trong bộ nhớ). Truyền địa chỉ API
/// lúc chạy để nối backend thật:
///
/// ```bash
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3100/api/v1
/// ```
///
/// Android emulator gọi máy tính qua `10.0.2.2` thay cho `localhost`.
class ApiConfig {
  ApiConfig._();

  /// Địa chỉ gốc của API, vd `http://localhost:3100/api/v1`. Rỗng = Demo Mode.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isEnabled => baseUrl.isNotEmpty;

  /// BE bắt buộc `cefrLevel` khi sinh từ bằng AI; app không cho chọn nên gửi mức mặc định.
  static const String defaultAiCefrLevel = 'B1';

  /// Thời gian chờ tối đa cho một request thường (AI có timeout riêng 15 giây ở BE).
  static const Duration requestTimeout = Duration(seconds: 20);
}
