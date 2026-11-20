import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Design Tokens: Bóng đổ của thẻ (card) dùng chung.
class AppShadows {
  /// Thẻ thường (học phần, hồ sơ) — đen 3%, blur 8, lệch xuống 3.
  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// Thẻ nhỏ (thống kê, huy hiệu, từ vựng) — đen 2%, blur 6, lệch xuống 2.
  static final List<BoxShadow> cardSoft = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Thẻ nổi bật (chi tiết từ) — đen 4%, blur 10, lệch xuống 4.
  static final List<BoxShadow> cardRaised = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
