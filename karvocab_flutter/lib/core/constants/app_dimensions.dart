/// Quy chuẩn kích thước chuẩn tiếp cận (Accessibility $\ge 48$dp theo Rubric INT1449)
class AppDimensions {
  // Touch Targets
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;

  // Paddings & Margins
  static const double screenMargin = 24.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusButton = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusPill = 100.0;

  // Icon
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 28.0;

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

  // Thanh điều hướng dưới
  static const double bottomNavHeight = 64.0;
  static const double bottomNavBorderWidth = 1.0;
}
