import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Design Tokens: Typography Scale theo chuẩn Figma KarVocab
class AppTypography {
  static const String fontFamily = 'Nunito';

  /// Chữ thương hiệu "KarVocab" ở Màn 01 · Splash (Nunito Bold 28).
  /// Màu tô riêng cho "Kar" / "Vocab" qua TextSpan.
  static const TextStyle brandWordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Chữ "KarVocab" ở Màn 02/03 · Đăng nhập / Đăng ký — cùng cỡ với splash, ExtraBold.
  static const TextStyle authWordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Chữ nhỏ thường (dòng điều khoản cuối màn Đăng nhập / Đăng ký).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // Màn 04 · Trang chủ
  // ---------------------------------------------------------------------------

  /// Lời chào "Xin chào, {tên}!" — 26 ExtraBold.
  static const TextStyle homeGreeting = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26.0,
    fontWeight: FontWeight.w800,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Số liệu trên thẻ thống kê — 24 Bold.
  static const TextStyle homeStatValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Nhãn thẻ thống kê — 13 Regular.
  static const TextStyle homeStatLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.3,
  );

  /// Tiêu đề mục "Học phần của bạn" — 18 Bold.
  static const TextStyle homeSectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.3,
  );

  /// Tiêu đề trong thẻ (biểu đồ tuần, tên học phần) — 16 Bold.
  static const TextStyle homeCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.3,
  );

  /// Chữ thường 14.
  static const TextStyle homeBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Chữ 14 Bold màu BrandDark (dòng nhắc ôn tập, phần trăm tiến độ).
  static const TextStyle homeBodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.4,
  );

  /// Link "Xem tất cả" — 14 SemiBold màu BrandLight.
  static const TextStyle homeLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    height: 1.4,
  );

  /// Chữ nhỏ 12.
  static const TextStyle homeSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Nhãn trục Y biểu đồ — 11.
  static const TextStyle chartAxisLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
  );

  /// Số trên chấm thông báo — 11 Bold trắng.
  static const TextStyle notificationBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
  );

  // ---------------------------------------------------------------------------
  // Popup thông báo (Màn 04)
  // ---------------------------------------------------------------------------

  /// Tiêu đề thông báo CHƯA đọc — 15 Bold, BrandDark.
  static const TextStyle notificationTitleUnread = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.35,
  );

  /// Tiêu đề thông báo ĐÃ đọc — 15 SemiBold, TextPrimary.
  static const TextStyle notificationTitleRead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.notificationTextPrimary,
    height: 1.35,
  );

  /// Nội dung tóm tắt — 13.
  static const TextStyle notificationPreview = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Thời gian — 12 in nghiêng.
  static const TextStyle notificationTime = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.homeTextSecondary,
    height: 1.3,
  );

  /// Chữ thanh điều hướng dưới — 12 (mục đang chọn dùng SemiBold).
  static const TextStyle bottomNavLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
}
