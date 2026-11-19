import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/quiz_models.dart';

/// Banner phản hồi đáp án (Màn 11): xanh = đúng, cam = suýt đúng, đỏ = sai + đáp án đúng + giải thích.
class FeedbackBanner extends StatelessWidget {
  final QuizAnswerRecord record;
  final VoidCallback onContinue;
  final bool isLast;

  const FeedbackBanner({
    super.key,
    required this.record,
    required this.onContinue,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;

    switch (record.result) {
      case AnswerResult.correct:
        color = AppColors.successGreen;
        icon = Icons.check_circle_rounded;
        title = 'Chính xác! 🎉';
        break;
      case AnswerResult.almost:
        color = AppColors.warningOrange;
        icon = Icons.info_rounded;
        title = 'Suýt đúng! Chú ý chính tả: ${record.question.vocab.term}';
        break;
      case AnswerResult.wrong:
        color = AppColors.errorRed;
        icon = Icons.cancel_rounded;
        title = 'Chưa đúng rồi';
        break;
    }

    final vocab = record.question.vocab;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenMargin,
        AppDimensions.space16,
        AppDimensions.screenMargin,
        AppDimensions.space16,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), AppColors.white),
        border: Border(top: BorderSide(color: color, width: 2)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headingMedium.copyWith(color: color),
                  ),
                ),
              ],
            ),
            if (record.result == AnswerResult.wrong) ...[
              const SizedBox(height: AppDimensions.space8),
              Text('Đáp án đúng:', style: AppTypography.labelSmall),
              Text(
                record.question.correctAnswer,
                style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
              ),
            ],
            const SizedBox(height: AppDimensions.space8),
            Text(
              '${vocab.term} ${vocab.ipa} — ${vocab.definitionVi}',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.space16),
            SizedBox(
              height: AppDimensions.buttonHeight,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
                child: Text(
                  isLast ? 'Xem kết quả' : 'Tiếp tục',
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
