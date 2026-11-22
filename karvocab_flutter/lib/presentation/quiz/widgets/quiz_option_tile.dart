import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

enum OptionVisualState { idle, correct, wrong, dimmed }

/// Thẻ đáp án A/B/C/D, cao tối thiểu [AppDimensions.quizOptionMinHeight] (60dp, ≥ 48dp theo Rubric).
/// Sau khi trả lời: đáp án đúng xanh lá, đáp án đã chọn sai đỏ, các thẻ còn lại mờ đi.
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
    var border = AppColors.practiceCardBorder;
    var background = AppColors.white;
    var letterBackground = AppColors.practiceSelectedFill;
    var letterForeground = AppColors.practicePrimary;
    IconData? trailing;
    Color? trailingColor;

    switch (state) {
      case OptionVisualState.idle:
      case OptionVisualState.dimmed:
        break;
      case OptionVisualState.correct:
        border = AppColors.successGreen;
        background = AppColors.quizCorrectTint;
        letterBackground = AppColors.successGreen;
        letterForeground = AppColors.white;
        trailing = Icons.check_circle_rounded;
        trailingColor = AppColors.successGreen;
        break;
      case OptionVisualState.wrong:
        border = AppColors.errorRed;
        background = AppColors.quizWrongTint;
        letterBackground = AppColors.errorRed;
        letterForeground = AppColors.white;
        trailing = Icons.cancel_rounded;
        trailingColor = AppColors.errorRed;
        break;
    }

    return Semantics(
      button: true,
      label: AppStrings.quizOptionSemantics(letter, text),
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: state == OptionVisualState.dimmed ? AppDimensions.quizDimmedOpacity : 1,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimensions.quizOptionRadius),
            border: Border.all(color: border, width: AppDimensions.borderMedium),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.quizOptionRadius),
              splashColor: AppColors.practiceSelectedFill,
              highlightColor: AppColors.practiceSelectedFill,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppDimensions.quizOptionMinHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppDimensions.quizOptionLetterSize,
                        height: AppDimensions.quizOptionLetterSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: letterBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.quizOptionLetterRadius),
                        ),
                        child: Text(
                          letter,
                          style: AppTypography.quizOptionLetter.copyWith(color: letterForeground),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(child: Text(text, style: AppTypography.quizOption)),
                      if (trailing != null) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Icon(trailing, color: trailingColor, size: AppDimensions.iconMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
