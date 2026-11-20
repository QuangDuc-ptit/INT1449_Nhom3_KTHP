/// Quy chuẩn kích thước chuẩn tiếp cận (Accessibility $\ge 48$dp theo Rubric INT1449)
class AppDimensions {
  // Touch Targets
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;

  // Paddings & Margins
  static const double screenMargin = 24.0;
  static const double space2 = 2.0;
  static const double space3 = 3.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusTiny = 2.0;
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusButton = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusPill = 100.0;

  // Icon
  static const double iconTiny = 14.0;
  static const double iconXSmall = 16.0;
  static const double iconCompact = 18.0;
  static const double iconSmall = 20.0;
  static const double iconSocial = 22.0;
  static const double iconMedium = 24.0;
  static const double iconFeature = 26.0;
  static const double iconLarge = 28.0;
  static const double iconDialog = 30.0;
  static const double iconState = 40.0;
  static const double iconHero = 64.0;

  // Viền
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // Vòng xoay tải
  static const double buttonLoaderSize = 24.0;
  static const double buttonLoaderStroke = 2.5;
  static const double stateLoaderSize = 36.0;
  static const double stateLoaderStroke = 3.0;

  // Empty / Error State
  static const double stateIllustrationSize = 80.0;
  static const double emptyActionWidth = 220.0;
  static const double retryButtonWidth = 200.0;

  // Nhãn nhỏ dạng viên thuốc (CEFR, chủ đề, cấp độ huy hiệu)
  static const double chipPaddingH = space10;
  static const double chipPaddingV = space3;

  // Ô icon / avatar
  static const double collectionIconBoxSize = 50.0;
  static const double badgeIconBoxSize = 48.0;
  static const double dialogIconBoxSize = 56.0;
  static const double avatarSize = 72.0;
  static const double audioButtonSize = 52.0;

  // Thanh tiến độ / độ mạnh mật khẩu
  static const double passwordStrengthBarHeight = 4.0;
  static const double badgeProgressHeight = 5.0;

  // Sóng âm (SoundWaveIndicator)
  static const double soundWaveBarWidth = 3.0;
  static const double soundWaveBarGap = 1.5;
  static const double soundWaveInlineHeight = 14.0;

  // Màn 21 · Quên mật khẩu
  static const double authHorizontalPadding = 20.0;
  /// Bo góc ô nhập và nút của màn Quên mật khẩu.
  static const double authControlRadius = 14.0;

  // Màn 23 · Cài đặt
  static const double dailyGoalValueMinWidth = 36.0;
  static const double dialogActionWidth = 132.0;

  // Màn 04 · Trang chủ
  static const double homeHorizontalPadding = 20.0;
  static const double homeBlockGap = 16.0;
  static const double homeGridGap = 12.0;
  static const double homeCardRadius = 16.0;
  static const double homeCardPadding = 16.0;
  static const double homeCardBorderWidth = 1.0;
  static const double homeHeaderHeight = 56.0;
  static const double bellButtonSize = 44.0;
  static const double notificationBadgeSize = 18.0;
  static const double statCardHeight = 96.0;
  static const double reviewButtonRadius = 14.0;
  static const double chartHeight = 180.0;
  static const double chartBarRadius = 6.0;
  /// Cột rộng 60% khoảng của mỗi ngày.
  static const double chartBarWidthFactor = 0.6;
  static const double chartGridLineWidth = 1.0;
  static const double courseIconBoxSize = 44.0;
  static const double courseIconBoxRadius = 12.0;
  static const double progressBarHeight = 6.0;

  // Popup thông báo (Màn 04)
  /// Cách mép trái/phải màn hình → popup rộng = màn hình − 32dp.
  static const double notificationPopupMargin = 16.0;
  /// Khoảng cách từ đáy nút chuông tới mép trên popup.
  static const double notificationPopupGap = 8.0;
  /// Cao tối đa = 70% chiều cao màn hình.
  static const double notificationPopupMaxHeightFactor = 0.7;
  static const double notificationPopupRadius = 16.0;
  static const double notificationPopupElevation = 8.0;
  /// Độ trượt khi mở/đóng, tính theo tỉ lệ chiều cao popup.
  static const double notificationPopupSlideFactor = 0.04;
  static const double notificationRowPadding = 16.0;
  static const double notificationUnreadDotSize = 8.0;
  static const double notificationEmptyIconSize = 48.0;
  static const double notificationLoaderSize = 20.0;
  static const double notificationLoaderStroke = 2.0;
  static const double scrollbarThickness = 3.0;
  static const double dividerThickness = 1.0;
  /// Độ mờ của nút icon khi bị khoá.
  static const double disabledOpacity = 0.4;

  // Độ mờ (alpha) dùng chung
  /// Nền nhạt phía sau icon (ô icon lỗi, ô icon thống kê, hộp thoại xoá).
  static const double tintOpacity = 0.12;
  /// Viền nhấn mạnh nhạt (thẻ huy hiệu đã mở khoá).
  static const double accentBorderOpacity = 0.3;
  /// Nền ô icon huy hiệu chưa mở khoá.
  static const double halfOpacity = 0.5;
  /// Nền thẻ huy hiệu chưa mở khoá.
  static const double lockedSurfaceOpacity = 0.6;
  /// Độ mờ thấp nhất của hiệu ứng nhấp nháy skeleton.
  static const double skeletonMinOpacity = 0.45;

  // Thanh điều hướng dưới
  static const double bottomNavHeight = 64.0;
  static const double bottomNavBorderWidth = 1.0;
}
