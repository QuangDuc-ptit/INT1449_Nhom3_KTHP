import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Thẻ trắng chứa đề bài của mọi màn chơi: lời nhắc ở đầu thẻ, nội dung bên dưới.
class QuizCard extends StatelessWidget {
  final String? prompt;
  final Widget child;
  final CrossAxisAlignment alignment;

  const QuizCard({
    super.key,
    this.prompt,
    required this.child,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final centered = alignment == CrossAxisAlignment.center;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.quizCardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.quizCardRadius),
        border: Border.all(color: AppColors.practiceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (prompt != null) ...[
            Text(
              prompt!,
              style: AppTypography.quizPrompt,
              textAlign: centered ? TextAlign.center : TextAlign.start,
            ),
            const SizedBox(height: AppDimensions.space16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Nhãn bo tròn nhỏ (chế độ chơi, cấp CEFR, loại từ...).
class QuizChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;

  const QuizChip({
    super.key,
    required this.label,
    this.icon,
    this.foreground = AppColors.practicePrimary,
    this.background = AppColors.practiceSelectedFill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppDimensions.quizChipHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space10,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppDimensions.quizChipIconSize, color: foreground),
            const SizedBox(width: AppDimensions.space6),
          ],
          Flexible(child: Text(label, style: AppTypography.quizChip.copyWith(color: foreground))),
        ],
      ),
    );
  }
}
