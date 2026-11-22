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
  static const double iconLarge = 28.0;
  static const double iconDialog = 30.0;
  static const double iconState = 40.0;

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

  // Nhãn nhỏ dạng viên thuốc (CEFR, chủ đề)
  static const double chipPaddingH = space10;
  static const double chipPaddingV = space3;

  // Ô icon / avatar
  static const double dialogIconBoxSize = 56.0;

  // Sóng âm (SoundWaveIndicator)
  static const double soundWaveBarWidth = 3.0;
  static const double soundWaveBarGap = 1.5;
  static const double soundWaveInlineHeight = 14.0;

  // Màn 21 · Quên mật khẩu
  static const double authHorizontalPadding = 20.0;
  /// Bo góc ô nhập và nút của màn Quên mật khẩu.
  static const double authControlRadius = 14.0;

  // Màn 05 · Thư viện
  static const double libraryHorizontalPadding = 20.0;
  static const double searchFieldHeight = 48.0;
  static const double searchFieldRadius = 14.0;
  static const double filterChipHeight = 36.0;
  /// Phần đệm trên/dưới mỗi chip để vùng chạm đủ [minTouchTarget] (36 + 2×6 = 48).
  static const double filterChipTouchInset = (minTouchTarget - filterChipHeight) / 2;
  static const double courseCardRadius = 16.0;
  static const double libraryCourseIconBoxSize = 48.0;
  static const double courseCardIconRadius = 12.0;
  static const double levelBadgeRadius = 6.0;
  static const double levelBadgePaddingH = 6.0;
  static const double levelBadgePaddingV = 2.0;
  static const double progressRingSize = 44.0;
  static const double progressRingStroke = 4.0;
  static const double libraryEmptyIconSize = 48.0;
  /// Số thẻ khung xương khi đang tải và độ rộng 2 dòng chữ giả (theo tỉ lệ).
  static const int skeletonCardCount = 3;
  static const double skeletonTitleWidthFactor = 0.7;
  static const double skeletonMetaWidthFactor = 0.4;

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
  /// Độ mờ thấp nhất của hiệu ứng nhấp nháy skeleton.
  static const double skeletonMinOpacity = 0.45;

  // Thanh điều hướng dưới
  static const double bottomNavHeight = 64.0;
  static const double bottomNavBorderWidth = 1.0;

  /// Bo góc trên của bottom sheet và banner phản hồi.
  static const double sheetRadius = 24.0;
  /// Bề rộng tối thiểu nút chữ trong hộp thoại (cao = [minTouchTarget]).
  static const double dialogTextButtonMinWidth = 88.0;

  // ===========================================================================
  // TRACK B (FE2)
  // ===========================================================================

  // Màn 08 / 19 · Nút loa lớn
  static const double quizAudioButtonSize = 88.0;
  /// Vòng sáng quanh nút loa (lan ra khi đang phát).
  static const double quizAudioHaloSize = 128.0;
  /// Icon chiếm 45% đường kính nút.
  static const double quizAudioIconFactor = 0.45;
  /// Vòng sáng phóng to thêm tối đa 12% khi đang phát.
  static const double quizAudioPulseScale = 0.12;

  // Thẻ đáp án A/B/C/D
  static const double quizOptionMinHeight = 60.0;
  static const double quizOptionLetterSize = 32.0;

  // Thanh tiến độ phiên làm bài
  static const double quizProgressHeight = 8.0;

  // ---------------------------------------------------------------------------
  // Màn 10 · Luyện tập
  // ---------------------------------------------------------------------------
  /// Responsive: < 600 điện thoại (1 cột), 600–1023 tablet (1 cột, lưới 3 thẻ),
  /// ≥ 1024 máy tính (2 cột: thiết lập bên trái, trò chơi bên phải).
  static const double practiceTabletBreakpoint = 600.0;
  static const double practiceDesktopBreakpoint = 1024.0;
  static const double practiceMaxWidthTablet = 720.0;
  static const double practiceMaxWidthDesktop = 1100.0;
  static const double practiceSettingsPanelWidth = 400.0;
  static const double practiceColumnGap = 24.0;
  static const double practiceHorizontalPadding = 22.0;
  static const double practiceHorizontalPaddingWide = 32.0;
  static const double practicePanelRadius = 20.0;
  static const double practicePanelPadding = 16.0;
  /// Ô chọn: ảnh thiết kế ~44px, nâng lên 48dp theo quy tắc vùng chạm của rubric.
  static const double practiceFieldHeight = 48.0;
  static const double practiceFieldRadius = 8.0;
  static const double practiceOrderButtonHeight = 40.0;
  static const double practiceOrderButtonRadius = 8.0;
  /// Nút "Theo thứ tự (A-Z)" rộng hơn nút "Ngẫu nhiên".
  static const int practiceOrderPrimaryFlex = 3;
  static const int practiceOrderSecondaryFlex = 2;
  static const double practiceGridGap = 12.0;
  static const double practiceGameCardRadius = 14.0;
  static const double practiceGameCardPadding = 12.0;
  static const double practiceGameIconBox = 40.0;
  static const double practiceGameIconRadius = 12.0;
  static const int practiceMaxCollections = 3;
  static const double practiceSheetHandleWidth = 40.0;

  // Thanh điều hướng dưới: viên thuốc bao icon của mục đang chọn.
  static const double navActivePillWidth = 56.0;
  static const double navActivePillHeight = 30.0;

  /// Chiều cao tối đa của menu thả xuống (vd chọn Loại từ ở Màn 24).
  static const double dropdownMenuMaxHeight = 360.0;

  /// Linh vật Axolotl minh hoạ (Màn 12 kết quả quiz, Màn 13 AI đang tạo từ).
  static const double mascotIllustrationSize = 96.0;

  // ---------------------------------------------------------------------------
  // Màn chơi (08 / 19 / 20 / 25), phản hồi (11) và kết quả (12)
  // ---------------------------------------------------------------------------
  /// Nội dung màn chơi rộng tối đa 600 và căn giữa trên tablet / web.
  static const double quizMaxContentWidth = 600.0;
  static const double quizHorizontalPadding = 20.0;
  /// Nút đóng: hình tròn 40 nhưng vùng chạm 48dp.
  static const double quizCloseButtonSize = 40.0;
  static const double quizCardRadius = 20.0;
  static const double quizCardPadding = 20.0;
  static const double quizOptionRadius = 14.0;
  static const double quizOptionLetterRadius = 10.0;
  static const double quizOptionGap = 10.0;
  static const double quizDimmedOpacity = 0.5;
  static const double quizFieldHeight = 56.0;
  static const double quizFieldRadius = 14.0;
  static const double quizChipHeight = 28.0;
  static const double quizChipIconSize = 14.0;
  static const double quizFeedbackIconBox = 36.0;
  static const double quizResultRingSize = 120.0;
  static const double quizResultRingStroke = 10.0;
  static const double quizStatIconBox = 32.0;
  /// Bóng rất nhẹ của bảng phản hồi / thanh nút dưới đáy.
  static const double quizSheetShadowBlur = 24.0;
  static const double quizSheetShadowOpacity = 0.06;

  // ---------------------------------------------------------------------------
  // Màn 09 · Sửa từ vựng / Màn 24 · Thêm từ vựng (thiết kế gốc 393 × 852)
  // ---------------------------------------------------------------------------
  /// Trên màn rộng, form căn giữa với bề rộng tối đa bằng khung thiết kế.
  /// Màn Thêm/Sửa/Chi tiết từ: điện thoại dùng hết chiều rộng, máy tính bảng/web
  /// giới hạn để dòng chữ và ô nhập không bị kéo quá dài.
  static const double wordFormMaxWidth = 600.0;
  static const double wordFormHorizontalPadding = 22.0;
  static const double wordFormFieldHeight = 52.0;
  static const double wordFormFieldRadius = 14.0;
  static const double wordFormFieldPaddingH = 15.0;
  static const double wordFormSelectPaddingV = 14.5;
  static const double wordFormLabelGap = 7.0;
  static const double wordFormGroupGap = 12.0;
  /// Khoảng cách từ ô "Ghi chú" tới nút lưu.
  static const double wordFormSaveGap = 44.0;
  static const double wordFormSaveRadius = 16.0;
  /// Khoảng trống dưới nút lưu.
  static const double wordFormBottomSpace = 32.0;

  // ---------------------------------------------------------------------------
  // Màn 15 · Hồ sơ cá nhân
  // ---------------------------------------------------------------------------
  static const double profileMaxWidth = 600.0;
  static const double profileAvatarSize = 88.0;
  static const double profileAvatarBorder = 3.0;
  static const double profileRowMinHeight = 56.0;
  static const double profileUsageBarHeight = 6.0;
  static const double profileStatIconBox = 36.0;

  // ---------------------------------------------------------------------------
  // Màn 07 · Chi tiết từ vựng
  // ---------------------------------------------------------------------------
  static const double wordDetailCardRadius = 20.0;
  static const double wordDetailCardPadding = 20.0;
  static const double wordDetailSpeakSize = 56.0;
  static const double wordDetailSpeakRadius = 16.0;
  static const double wordDetailSectionGap = 30.0;
  static const double wordDetailBlockGap = 20.0;
  static const double wordDetailExamplePadding = 18.0;
  static const double wordDetailChipRadius = 10.0;
  static const double wordDetailChipHeight = 36.0;

  // Ô nhập dạng thẻ (đồng nghĩa / trái nghĩa)
  static const double tagHeight = 32.0;
  static const double tagCloseIcon = 16.0;
  static const double tagInputMinWidth = 80.0;

  // Token cũ còn được màn hình chưa cập nhật dùng; xoá ở commit dọn dẹp.
  static const double radiusXSmall = 4.0;
  static const double iconFeature = 26.0;
  static const double badgeIconBoxSize = 48.0;
  static const double avatarSize = 72.0;
  static const double audioButtonSize = 52.0;
  static const double badgeProgressHeight = 5.0;
  /// Viền nhấn mạnh nhạt (thẻ huy hiệu đã mở khoá).
  static const double accentBorderOpacity = 0.3;
  /// Nền ô icon huy hiệu chưa mở khoá.
  static const double halfOpacity = 0.5;
  /// Nền thẻ huy hiệu chưa mở khoá.
  static const double lockedSurfaceOpacity = 0.6;
}
