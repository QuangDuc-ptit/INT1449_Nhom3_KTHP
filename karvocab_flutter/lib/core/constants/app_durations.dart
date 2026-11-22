/// Design Tokens: Thời lượng hiệu ứng / hiển thị trên giao diện.
class AppDurations {
  /// Chuyển trạng thái nhanh (nút phát âm, popup thông báo).
  static const Duration fast = Duration(milliseconds: 200);

  /// Chuyển màn (Splash → màn tiếp theo).
  static const Duration pageTransition = Duration(milliseconds: 400);

  /// Một chu kỳ nhấp nháy skeleton / sóng âm.
  static const Duration pulse = Duration(milliseconds: 900);

  /// Toast / SnackBar ngắn (đổi ngôn ngữ).
  static const Duration snackShort = Duration(seconds: 1);

  /// Toast mặc định.
  static const Duration toast = Duration(seconds: 3);

  /// SnackBar cần đọc kỹ (hiển thị mã OTP demo).
  static const Duration snackLong = Duration(seconds: 8);

  /// Một nhịp phóng to / thu nhỏ của nút loa khi đang phát (Màn 08, 19).
  static const Duration audioPulse = Duration(milliseconds: 700);

  /// Một chu kỳ nhấp nháy khung chờ khi AI đang sinh từ (Màn 13).
  static const Duration aiShimmer = Duration(milliseconds: 1100);

  /// Quá thời gian này coi như AI timeout (FE spec §4.4: > 15s).
  static const Duration aiTimeout = Duration(seconds: 15);
}
