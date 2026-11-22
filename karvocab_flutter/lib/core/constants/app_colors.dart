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

  // ---------------------------------------------------------------------------
  // Màn 10 · Luyện tập (theo ảnh thiết kế mới)
  // ---------------------------------------------------------------------------
  static const Color practiceBackground = Color(0xFFF4FAFE);
  static const Color practicePrimary = Color(0xFF0066CC);

  /// Màu duy nhất cho nút hành động chính (nền xanh, chữ trắng) trên mọi màn.
  /// Đủ tương phản với chữ trắng (5,6:1, đạt WCAG AA); `primaryBlue` sáng hơn
  /// (3,2:1) nên chỉ dùng cho icon và điểm nhấn, không làm nền nút có chữ.
  static const Color actionPrimary = practicePrimary;
  static const Color practiceTextPrimary = Color(0xFF173858);
  static const Color practiceTextSecondary = Color(0xFF8191A8);
  static const Color practiceBorder = Color(0xFFC3E1FF);
  /// Nền ô chọn / nút chưa chọn — xanh rất nhạt.
  static const Color practiceFieldFill = Color(0xFFF4FAFE);
  /// Nền nút thứ tự đang chọn và nền icon thẻ trò chơi.
  static const Color practiceSelectedFill = Color(0xFFE6F2FF);
  /// Viền thẻ trò chơi và đường phân cách — rất nhạt.
  static const Color practiceCardBorder = Color(0xFFE3EEF9);

  // Thanh điều hướng dưới: nền viên thuốc của mục đang chọn.
  static const Color navActivePill = practiceSelectedFill;

  // ---------------------------------------------------------------------------
  // Màn chơi & kết quả: nền nhạt cho trạng thái đúng / suýt đúng / sai
  // ---------------------------------------------------------------------------
  static const Color quizCorrectTint = Color(0xFFE9F9EF);
  static const Color quizAlmostTint = Color(0xFFFEF4E6);
  static const Color quizWrongTint = Color(0xFFFDEDED);

  // ---------------------------------------------------------------------------
  // Màn 09 · Sửa từ vựng / Màn 24 · Thêm từ vựng
  // ---------------------------------------------------------------------------
  /// Chữ trong ô nhập: xanh xám đậm.
  static const Color wordFormInputText = Color(0xFF2E4A66);

  // ---------------------------------------------------------------------------
  // Màn 05 · Thư viện: màu theo chủ đề học phần (icon + nền nhạt)
  // ---------------------------------------------------------------------------
  static const Color categoryAcademic = practicePrimary;
  static const Color categoryAcademicTint = practiceSelectedFill;
  static const Color categoryCareer = Color(0xFF0E8A7E);
  static const Color categoryCareerTint = Color(0xFFE0F4F1);
  static const Color categoryLife = Color(0xFFD9670B);
  static const Color categoryLifeTint = Color(0xFFFFEFE0);
  static const Color categoryTravel = Color(0xFF7C3AED);
  static const Color categoryTravelTint = Color(0xFFF0EAFE);

  /// Chữ phụ và rãnh thanh tiến độ trên nền xanh của thẻ tổng quan.
  static const Color onPrimaryMuted = Color(0xD9FFFFFF);
  static const Color onPrimaryTrack = Color(0x40FFFFFF);
}
