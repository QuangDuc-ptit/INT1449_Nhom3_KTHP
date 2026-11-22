import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Design Tokens: Typography Scale theo chuẩn Figma KarVocab
class AppTypography {
  static const String fontFamily = 'Nunito';

  /// Font dự phòng cho ký tự Nunito không có, chủ yếu là phiên âm IPA.
  static const List<String> fontFamilyFallback = ['NotoSansIPA'];

  // Thang cỡ chữ — dùng khi cần `copyWith(fontSize: ...)` trên một style có sẵn.
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize15 = 15.0;
  static const double fontSize16 = 16.0;
  static const double fontSize17 = 17.0;
  static const double fontSize20 = 20.0;
  static const double fontSize32 = 32.0;

  /// Giãn chữ của tiêu đề nhóm viết hoa (Màn 23 · Cài đặt).
  static const double sectionHeaderLetterSpacing = 0.8;

  /// Chữ thương hiệu "KarVocab" ở Màn 01 · Splash (Nunito ExtraBold 28).
  /// Màu tô riêng cho "Kar" / "Vocab" qua TextSpan.
  static const TextStyle brandWordmark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// Chữ "KarVocab" ở Màn 02/03 · Đăng nhập / Đăng ký — cùng cỡ với splash, ExtraBold.
  static const TextStyle authWordmark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 30.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 23.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Chữ nhỏ thường (dòng điều khoản cuối màn Đăng nhập / Đăng ký).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
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
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 26.0,
    fontWeight: FontWeight.w800,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Số liệu trên thẻ thống kê — 24 Bold.
  static const TextStyle homeStatValue = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Nhãn thẻ thống kê — 13 Regular.
  static const TextStyle homeStatLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.3,
  );

  /// Tiêu đề mục "Học phần của bạn" — 18 Bold.
  static const TextStyle homeSectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.3,
  );

  /// Tiêu đề trong thẻ (biểu đồ tuần, tên học phần) — 16 Bold.
  static const TextStyle homeCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.3,
  );

  /// Chữ thường 14.
  static const TextStyle homeBody = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Chữ 14 Bold màu BrandDark (dòng nhắc ôn tập, phần trăm tiến độ).
  static const TextStyle homeBodyBold = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.4,
  );

  /// Link "Xem tất cả" — 14 SemiBold màu BrandLight.
  static const TextStyle homeLink = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    height: 1.4,
  );

  /// Chữ nhỏ 12.
  static const TextStyle homeSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Nhãn trục Y biểu đồ — 11.
  static const TextStyle chartAxisLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
  );

  /// Số trên chấm thông báo — 11 Bold trắng.
  static const TextStyle notificationBadge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
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
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.35,
  );

  /// Tiêu đề thông báo ĐÃ đọc — 15 SemiBold, TextPrimary.
  static const TextStyle notificationTitleRead = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.notificationTextPrimary,
    height: 1.35,
  );

  /// Nội dung tóm tắt — 13.
  static const TextStyle notificationPreview = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.homeTextSecondary,
    height: 1.4,
  );

  /// Thời gian — 12 in nghiêng.
  static const TextStyle notificationTime = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.homeTextSecondary,
    height: 1.3,
  );

  /// Chữ thanh điều hướng dưới — 12 (mục đang chọn dùng SemiBold).
  static const TextStyle bottomNavLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  // ---------------------------------------------------------------------------
  // Màn 21 · Quên mật khẩu
  // ---------------------------------------------------------------------------

  /// Tiêu đề màn — 24 ExtraBold, BrandDark.
  static const TextStyle authScreenTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w800,
    color: AppColors.navyBlue,
    height: 1.25,
  );

  /// Mô tả, ghi chú, placeholder — 14 Regular, TextSecondary.
  static const TextStyle authBody = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextSecondary,
    height: 1.4,
  );

  /// Nhãn ô nhập — 14 Bold, TextPrimary.
  static const TextStyle authFieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: AppColors.authTextPrimary,
    height: 1.4,
  );

  /// Chữ nút chính cỡ lớn — 18 Bold trắng.
  static const TextStyle buttonTextLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  // ---------------------------------------------------------------------------
  // Màn 05 · Thư viện
  // ---------------------------------------------------------------------------

  /// Tiêu đề "Thư viện" — 28 ExtraBold, BrandDark.
  static const TextStyle libraryTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Chữ gõ trong ô tìm kiếm — 14, TextPrimary.
  static const TextStyle searchInput = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextPrimary,
    height: 1.4,
  );

  /// Chữ chip lọc — 14 SemiBold (màu theo trạng thái chọn).
  static const TextStyle filterChip = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Tên học phần — 16 Bold, TextPrimary.
  static const TextStyle courseTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.authTextPrimary,
    height: 1.3,
  );

  /// Nhãn trình độ (B1, B2…) — 11 Bold, BrandDark.
  static const TextStyle levelBadge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.2,
  );

  /// Số từ của học phần — 13, TextSecondary.
  static const TextStyle courseMeta = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextSecondary,
    height: 1.3,
  );

  /// Phần trăm giữa vòng tiến độ — 11 Bold, BrandDark.
  static const TextStyle progressPercent = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: AppColors.navyBlue,
    height: 1.0,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  // ---------------------------------------------------------------------------
  // Màn 10 · Luyện tập
  // ---------------------------------------------------------------------------

  /// Tiêu đề "Luyện tập" — 28 ExtraBold, xanh chính.
  static const TextStyle practiceTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practicePrimary,
    height: 1.2,
  );

  /// Nhãn trong khối thiết lập — 14 SemiBold.
  static const TextStyle practiceLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Giá trị trong ô chọn — 15 Medium.
  static const TextStyle practiceFieldValue = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Dòng phụ "Chọn tối đa 3 bộ" — 12, chữ phụ.
  static const TextStyle practiceHint = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.practiceTextSecondary,
    height: 1.3,
  );

  /// Chữ nút thứ tự hiển thị — 14 SemiBold (màu theo trạng thái chọn).
  static const TextStyle practiceOrderOption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Tiêu đề "Danh sách trò chơi" — 20 Bold.
  static const TextStyle practiceSectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Tên trò chơi — 15 Bold.
  static const TextStyle practiceGameTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );


  // ---------------------------------------------------------------------------
  // Màn chơi (08 / 19 / 20 / 25), phản hồi (11) và kết quả (12)
  // ---------------------------------------------------------------------------

  /// Bộ đếm câu "1/10" — 14 Bold.
  static const TextStyle quizCounter = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.2,
  );

  /// Nhãn chế độ chơi trên chip — 12 Bold, xanh chính.
  static const TextStyle quizChip = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practicePrimary,
    height: 1.2,
  );

  /// Lời nhắc đầu thẻ câu hỏi — 14 SemiBold, chữ phụ.
  static const TextStyle quizPrompt = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.practiceTextSecondary,
    height: 1.4,
  );

  /// Từ tiếng Anh lớn ở giữa thẻ — 32 ExtraBold.
  static const TextStyle quizTerm = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.2,
  );

  /// Phiên âm IPA — 16, chữ phụ.
  static const TextStyle quizIpa = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextSecondary,
    height: 1.3,
  );

  /// Nghĩa tiếng Việt (Màn 20) — 20 Bold.
  static const TextStyle quizDefinition = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.35,
  );

  /// Câu ví dụ — 15 nghiêng, chữ phụ.
  static const TextStyle quizExample = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.practiceTextSecondary,
    height: 1.5,
  );

  /// Nội dung đáp án — 16 SemiBold.
  static const TextStyle quizOption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.practiceTextPrimary,
    height: 1.35,
  );

  /// Chữ A/B/C/D — 14 ExtraBold.
  static const TextStyle quizOptionLetter = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w800,
    height: 1.0,
  );

  /// Chữ gõ trong ô trả lời — 18 SemiBold.
  static const TextStyle quizInput = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Tiêu đề phản hồi "Chính xác!" — 18 ExtraBold (màu theo kết quả).
  static const TextStyle quizFeedbackTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  /// Chữ nhỏ trong bảng phản hồi / kết quả — 13, chữ phụ.
  static const TextStyle quizCaption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextSecondary,
    height: 1.4,
  );

  /// Tiêu đề màn kết quả — 24 ExtraBold.
  static const TextStyle quizResultTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.25,
  );

  /// % chính xác trong vòng tròn — 28 ExtraBold (màu theo mức điểm).
  static const TextStyle quizResultPercent = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  /// Số liệu thống kê — 16 ExtraBold.
  static const TextStyle quizStatValue = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.2,
  );

  // ---------------------------------------------------------------------------
  // Màn 09 · Sửa từ vựng / Màn 24 · Thêm từ vựng
  // ---------------------------------------------------------------------------

  /// Tiêu đề "Sửa từ vựng" — 20 Bold, navy.
  static const TextStyle wordFormTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.25,
  );


  /// Nhãn trên ô nhập — 12 SemiBold, navy.
  static const TextStyle wordFormLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Nội dung ô nhập — 14 Medium, xanh xám đậm.
  static const TextStyle wordFormInput = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.wordFormInputText,
    height: 1.4,
  );

  /// Gợi ý trong ô trống (Màn 24) — 14, chữ phụ.
  static const TextStyle wordFormHint = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextSecondary,
    height: 1.4,
  );

  /// Lỗi dưới ô nhập — 12, đỏ.
  static const TextStyle wordFormError = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.errorRed,
    height: 1.3,
  );

  /// Chữ nút "Lưu thay đổi" — 18 Bold, trắng.
  static const TextStyle wordFormSave = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.2,
  );

  // ---------------------------------------------------------------------------
  // Màn 15 · Hồ sơ cá nhân
  // ---------------------------------------------------------------------------

  /// Tên người dùng — 20 ExtraBold.
  static const TextStyle profileName = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.25,
  );

  /// Mã ID — 15 Bold, giãn chữ để dễ đọc.
  static const TextStyle profileMemberId = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  // ---------------------------------------------------------------------------
  // Màn 07 · Chi tiết từ vựng
  // ---------------------------------------------------------------------------

  /// Từ tiếng Anh — 36 ExtraBold.
  static const TextStyle wordDetailTerm = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 36.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.15,
  );

  /// Phiên âm — 16 Medium.
  static const TextStyle wordDetailIpa = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextSecondary,
    height: 1.4,
  );

  /// Nhãn khối (NGHĨA TIẾNG VIỆT, VÍ DỤ SỬ DỤNG) — 12 Bold, giãn chữ.
  static const TextStyle wordDetailLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.practiceTextSecondary,
    height: 1.3,
  );

  /// Nghĩa tiếng Việt — 22 ExtraBold.
  static const TextStyle wordDetailMeaning = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Câu ví dụ, ghi chú — 15 Medium.
  static const TextStyle wordDetailBody = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.practiceTextPrimary,
    height: 1.5,
  );

  /// Tiêu đề nhóm từ đồng nghĩa / trái nghĩa — 14 Bold.
  static const TextStyle wordDetailGroupTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: AppColors.practiceTextPrimary,
    height: 1.3,
  );

  /// Chữ trong chip từ — 14 SemiBold.
  static const TextStyle wordDetailChip = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

}
