import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

enum OptionVisualState { idle, correct, wrong, dimmed }

/// Thẻ đáp án A/B/C/D — cao tối thiểu 60dp (≥ 48dp theo Rubric).
class QuizOptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final OptionVisualState state;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.borderLight;
    Color bg = AppColors.white;
    Color letterBg = AppColors.secondaryBackground;
    Color letterFg = AppColors.navyBlue;
    Color textColor = AppColors.textPrimary;
    IconData? trailing;
    Color? trailingColor;

    switch (state) {
      case OptionVisualState.idle:
        break;
      case OptionVisualState.correct:
        border = AppColors.successGreen;
        bg = AppColors.successGreen.withValues(alpha: 0.10);
        letterBg = AppColors.successGreen;
        letterFg = AppColors.white;
        trailing = Icons.check_circle_rounded;
        trailingColor = AppColors.successGreen;
        break;
      case OptionVisualState.wrong:
        border = AppColors.errorRed;
        bg = AppColors.errorRed.withValues(alpha: 0.10);
        letterBg = AppColors.errorRed;
        letterFg = AppColors.white;
        trailing = Icons.cancel_rounded;
        trailingColor = AppColors.errorRed;
        break;
      case OptionVisualState.dimmed:
        textColor = AppColors.textMuted;
        letterFg = AppColors.textMuted;
        break;
    }

    return Semantics(
      button: true,
      label: 'Đáp án $letter: $text',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          side: BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: letterBg,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Text(
                      letter,
                      style: AppTypography.bodyBold.copyWith(color: letterFg),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodyLarge.copyWith(color: textColor),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppDimensions.space8),
                    Icon(trailing, color: trailingColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
