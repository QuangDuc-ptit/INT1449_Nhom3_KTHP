/// Bộ quy tắc validation dùng chung cho các form của Track A (FE1).
/// Mỗi hàm trả về `null` khi hợp lệ, hoặc thông báo lỗi tiếng Việt khi không hợp lệ.
/// Quy tắc lấy theo FE-SPECIFICATION §4.1 & §4.3.
class Validators {
  Validators._();

  /// Regex email theo đặc tả: `^[^\s@]+@[^\s@]+\.[^\s@]+$`.
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập địa chỉ email';
    if (!_emailRegex.hasMatch(v)) {
      return 'Email không hợp lệ (vd: user@gmail.com)';
    }
    return null;
  }

  /// Mật khẩu khi đăng nhập: bắt buộc, tối thiểu 6 ký tự (Màn 02).
  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  /// Mật khẩu mạnh khi đăng ký / đặt lại: ≥ 8 ký tự, ≥ 1 chữ hoa, ≥ 1 chữ số (Màn 03, 21).
  static String? strongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (v.length > 72) return 'Mật khẩu tối đa 72 ký tự';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Mật khẩu cần ít nhất 1 chữ hoa';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Mật khẩu cần ít nhất 1 chữ số';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu';
    if (value != original) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập họ và tên';
    if (v.length < 2) return 'Họ và tên quá ngắn';
    if (v.length > 50) return 'Họ và tên tối đa 50 ký tự';
    return null;
  }

  /// Mã OTP gồm đúng 6 chữ số (Màn 21).
  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mã OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Mã OTP gồm đúng 6 chữ số';
    return null;
  }

  /// Tên học phần: bắt buộc, 2 – 50 ký tự (Màn 22).
  static String? collectionTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập tên học phần';
    if (v.length < 2) return 'Tên học phần cần ít nhất 2 ký tự';
    if (v.length > 50) return 'Tên học phần tối đa 50 ký tự';
    return null;
  }

  /// Từ tiếng Anh: bắt buộc, chỉ gồm chữ cái, khoảng trắng, dấu gạch nối hoặc nháy đơn (Màn 24, 09).
  static String? term(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập từ tiếng Anh';
    if (v.length > 60) return 'Từ vựng tối đa 60 ký tự';
    if (!RegExp(r"^[A-Za-z][A-Za-z '\-]*$").hasMatch(v)) {
      return 'Từ tiếng Anh chỉ gồm chữ cái, khoảng trắng, "-" hoặc "\'"';
    }
    return null;
  }

  static String? required(String? value, String message) {
    if ((value?.trim() ?? '').isEmpty) return message;
    return null;
  }
}
