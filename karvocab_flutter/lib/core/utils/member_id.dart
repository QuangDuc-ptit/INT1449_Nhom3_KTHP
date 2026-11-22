/// Mã ID người dùng: `KM` + 2 số cuối năm sinh + tháng + ngày + số thứ tự.
///
/// Ví dụ sinh ngày 20/09/2005: người đầu tiên là `KM05092000`, người thứ hai
/// cùng ngày sinh là `KM05092001`... Số thứ tự có 2 chữ số; quá 99 người cùng
/// ngày sinh thì tự dài thành 3 chữ số (`KM050920100`) để không bao giờ hết mã.
///
/// Mã được cấp một lần và không đổi, kể cả khi người dùng sửa ngày sinh sau đó.
/// Khi nối API, backend phải cấp mã (cần khoá ở CSDL để hai người đăng ký cùng
/// lúc không nhận trùng mã); hàm này chỉ dùng cho Demo Mode.
class MemberId {
  MemberId._();

  static const String prefix = 'KM';

  /// Phần cố định theo ngày sinh, vd `KM050920`.
  static String stem(DateTime birthDate) {
    String two(int n) => (n % 100).toString().padLeft(2, '0');
    return '$prefix${two(birthDate.year)}${two(birthDate.month)}${two(birthDate.day)}';
  }

  /// Cấp mã nhỏ nhất chưa có trong [taken].
  static String generate(DateTime birthDate, Iterable<String> taken) {
    final used = taken.toSet();
    final base = stem(birthDate);
    for (var n = 0;; n++) {
      final id = '$base${n.toString().padLeft(2, '0')}';
      if (!used.contains(id)) return id;
    }
  }
}
