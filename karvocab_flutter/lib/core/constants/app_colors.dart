import 'package:flutter/material.dart';

/// Design Tokens: Bảng màu chuẩn trích xuất từ Figma KarVocab
class AppColors {
  // Brand & Action Colors
  static const Color primaryBlue = Color(0xFF0095E8);
  static const Color navyBlue = Color(0xFF0054AC);
  static const Color lightBlue = Color(0xFF4FC3FF);
  static const Color softBlueSurface = Color(0xFFDDF2FF);

  // Thương hiệu "KarVocab": "Kar" và "Vocab" tô 2 màu (Màn 01 · Splash)
  static const Color brandKar = primaryBlue; // #0095E8
  static const Color brandVocab = navyBlue; // #0054AC

  // Màn 02/03 · Đăng nhập / Đăng ký
  /// Nền nút chính "Đăng nhập" / "Đăng ký".
  static const Color authButton = Color(0xFF0070BE);

  /// Link "Đăng ký ngay."
  static const Color authLink = Color(0xFF009EEA);

  // Màu thương hiệu của nút đăng nhập mạng xã hội
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color facebookBlue = Color(0xFF1877F2);

  // Màn 04 · Trang chủ (và thanh điều hướng dưới dùng chung)
  /// Nền thẻ nhấn mạnh (thẻ "Cần ôn lại", thẻ nhắc ôn tập, ô icon học phần).
  static const Color homeSurfaceTint = Color(0xFFE3F2FD);

  /// Chữ phụ của Trang chủ — khác [textSecondary] (#64748B) của các màn khác.
  static const Color homeTextSecondary = Color(0xFF6B7A90);

  /// Đường kẻ, viền thẻ, nền thanh tiến độ; viền trên thanh điều hướng.
  static const Color homeDivider = Color(0xFFE6EDF5);

  static const Color chartBar = Color(0xFF9FD3F7);
  static const Color chartBarToday = primaryBlue; // #0095E8
  static const Color streak = Color(0xFFFF7A1A);
  static const Color notificationBadge = errorRed; // #EF4444
  static const Color navInactive = Color(0xFF8A97A8);

  // Popup thông báo (Màn 04)
  /// Tiêu đề thông báo đã đọc — khác [textPrimary] (#17324D) của các màn khác.
  static const Color notificationTextPrimary = Color(0xFF1F2A3D);

  // Màn 21 · Quên mật khẩu (dùng lại màu đã có, đặt tên theo bảng màu của màn)
  /// TextPrimary #1F2A3D.
  static const Color authTextPrimary = notificationTextPrimary;
  /// TextSecondary #6B7A90.
  static const Color authTextSecondary = homeTextSecondary;
  /// Divider #E6EDF5.
  static const Color authDivider = homeDivider;

  // Bảng màu của các mô tả thiết kế mới (Thư viện …) — trỏ tới màu đã có.
  /// SurfaceTint #E3F2FD.
  static const Color surfaceTint = homeSurfaceTint;
  /// Divider #E6EDF5.
  static const Color divider = homeDivider;

  // Background Surfaces
  /// Màu nền chung của toàn app (#F5FAFE). Theme dùng màu này làm
  /// scaffoldBackgroundColor; native splash Android dùng cùng giá trị
  /// (android/app/src/main/res/values/colors.xml → splash_background).
  static const Color background = Color(0xFFF5FAFE);

  /// Tên cũ của [background], giữ lại để các màn hiện có không phải sửa.
  static const Color mainBackground = background;
  static const Color secondaryBackground = Color(0xFFEAF6FD);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  /// Màu gốc của bóng đổ (đen); độ mờ áp dụng trong [AppShadows].
  static const Color shadow = Color(0xFF000000);

  // Text Colors
  static const Color textPrimary = Color(0xFF17324D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnBlue = Color(0xFFFFFFFF);

  // Status & Feedback Colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF0EA5E9);

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0095E8);

  // CEFR Badge Colors
  static const Color cefrA1 = Color(0xFFE2F9E5);
  static const Color cefrA1Text = Color(0xFF16A34A);
  static const Color cefrB1 = Color(0xFFDDF2FF);
  static const Color cefrB1Text = Color(0xFF0095E8);
  static const Color cefrC1 = Color(0xFFEDE9FE);
  static const Color cefrC1Text = Color(0xFF7C3AED);
}
