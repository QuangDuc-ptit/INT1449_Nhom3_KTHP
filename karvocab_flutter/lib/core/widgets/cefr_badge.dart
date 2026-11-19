import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';

/// Huy hiệu chuẩn CEFR (A1, A2, B1, B2, C1) bo tròn dạng pill
class CefrBadge extends StatelessWidget {
  final String level;

  const CefrBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    final upper = level.toUpperCase();
    if (upper.startsWith('A')) {
      bg = AppColors.cefrA1;
      text = AppColors.cefrA1Text;
    } else if (upper.startsWith('B')) {
      bg = AppColors.cefrB1;
      text = AppColors.cefrB1Text;
    } else {
      bg = AppColors.cefrC1;
      text = AppColors.cefrC1Text;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(
        upper,
        style: AppTypography.labelSmall.copyWith(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
