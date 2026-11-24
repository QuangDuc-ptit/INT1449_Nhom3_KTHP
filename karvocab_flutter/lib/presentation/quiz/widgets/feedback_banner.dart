import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/vocab_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/quiz_models.dart';
import '../../../data/services/speech_service.dart';

/// Bảng phản hồi đáp án (Màn 11) trượt lên từ đáy:
/// xanh = đúng, cam = suýt đúng, đỏ = sai kèm đáp án đúng. Luôn nhắc lại từ, phiên âm và nghĩa.
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
    final Color tint;
    final IconData icon;
    final String title;

    switch (record.result) {
      case AnswerResult.correct:
        color = AppColors.successGreen;
        tint = AppColors.quizCorrectTint;
        icon = Icons.check_rounded;
        title = AppStrings.feedbackCorrect;
        break;
      case AnswerResult.almost:
        color = AppColors.warningOrange;
        tint = AppColors.quizAlmostTint;
        icon = Icons.priority_high_rounded;
        title = AppStrings.feedbackAlmost(record.question.vocab.term);
        break;
      case AnswerResult.wrong:
        color = AppColors.errorRed;
        tint = AppColors.quizWrongTint;
        icon = record.timedOut ? Icons.timer_off_outlined : Icons.close_rounded;
        title = record.timedOut ? AppStrings.feedbackTimeUp : AppStrings.feedbackWrong;
        break;
    }

    final question = record.question;
    final vocab = question.vocab;
    // Màn 25 hỏi nghĩa: đáp án đúng chính là nghĩa, không cần nhắc lại lần hai.
    final showMeaning = question.correctAnswer != vocab.definitionVi;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.sheetRadius)),
        boxShadow: [
          BoxShadow(
            color: AppColors.practiceTextPrimary.withValues(alpha: AppDimensions.quizSheetShadowOpacity),
            blurRadius: AppDimensions.quizSheetShadowBlur,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppDimensions.quizMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.quizHorizontalPadding,
                AppDimensions.space20,
                AppDimensions.quizHorizontalPadding,
                AppDimensions.space16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppDimensions.quizFeedbackIconBox,
                        height: AppDimensions.quizFeedbackIconBox,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: Icon(icon, color: AppColors.white, size: AppDimensions.iconSmall),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Text(title, style: AppTypography.quizFeedbackTitle.copyWith(color: color)),
                      ),
                    ],
                  ),
                  if (record.result == AnswerResult.wrong) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(AppStrings.feedbackCorrectAnswer, style: AppTypography.quizCaption),
                    const SizedBox(height: AppDimensions.space4),
                    Text(question.correctAnswer, style: AppTypography.quizStatValue),
                  ],
                  const SizedBox(height: AppDimensions.space12),
                  _WordSummary(term: vocab.term, ipa: vocab.ipaText, meaning: showMeaning ? vocab.definitionVi : null),
                  const SizedBox(height: AppDimensions.space16),
                  AppButton(
                    text: isLast ? AppStrings.feedbackSeeResult : AppStrings.feedbackContinue,
                    onPressed: onContinue,
                    backgroundColor: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng nhắc lại từ vựng: từ + phiên âm + nút nghe, nghĩa ở dòng dưới.
class _WordSummary extends StatelessWidget {
  final String term;
  final String ipa;
  final String? meaning;

  const _WordSummary({required this.term, required this.ipa, this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.quizOptionRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.space10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: term, style: AppTypography.quizStatValue),
                      TextSpan(text: '  $ipa', style: AppTypography.quizCaption),
                    ]),
                  ),
                  if (meaning != null) ...[
                    const SizedBox(height: AppDimensions.space4),
                    Text(meaning!, style: AppTypography.quizCaption),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.quizListenWordTooltip(term),
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.practicePrimary),
            onPressed: () => SpeechService.instance.speak(term),
          ),
        ],
      ),
    );
  }
}
