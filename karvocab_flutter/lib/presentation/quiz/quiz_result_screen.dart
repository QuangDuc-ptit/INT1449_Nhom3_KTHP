import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_question_factory.dart';
import '../../data/services/speech_service.dart';
import 'quiz_session_screen.dart';
import 'widgets/quiz_card.dart';

/// Màn 12 — Báo cáo kết quả buổi học (+ nút vào Màn 26 Luyện lại câu sai).
class QuizResultScreen extends StatelessWidget {
  final QuizSummary summary;

  const QuizResultScreen({super.key, required this.summary});

  /// Từ 80% trở lên được tính là "Xuất sắc".
  static const double excellentPercent = 80;

  String _formatDuration(int seconds) => AppStrings.resultDurationValue(seconds ~/ 60, seconds % 60);

  void _retryMissed(BuildContext context) {
    final questions = QuizQuestionFactory.rebuildForRetry(summary.missedQuestions);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizSessionScreen(questions: questions, isRetry: true),
      ),
    );
  }

  void _finish(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final excellent = summary.accuracyPercent >= excellentPercent;
    final accent = excellent ? AppColors.successGreen : AppColors.warningOrange;
    final missed = summary.missedQuestions;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.practiceBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.space24),
                  child: _centered(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          AppAssets.logo,
                          width: AppDimensions.mascotIllustrationSize,
                          height: AppDimensions.mascotIllustrationSize,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        Text(
                          excellent ? AppStrings.resultExcellent : AppStrings.resultEncourage,
                          style: AppTypography.quizResultTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          summary.isRetry ? AppStrings.resultRetrySubtitle : AppStrings.resultSubtitle,
                          style: AppTypography.quizPrompt,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        _ScoreCard(
                          summary: summary,
                          accent: accent,
                          duration: _formatDuration(summary.durationSeconds),
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        if (missed.isEmpty)
                          const QuizCard(
                            child: Row(
                              children: [
                                Icon(Icons.verified_rounded, color: AppColors.successGreen),
                                SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Text(AppStrings.resultNoMistakes, style: AppTypography.quizOption),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(AppStrings.resultMissedWords, style: AppTypography.practiceSectionTitle),
                              ),
                              QuizChip(
                                label: '${missed.length}',
                                foreground: AppColors.errorRed,
                                background: AppColors.quizWrongTint,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space12),
                          for (final q in missed) ...[
                            _MissedWordTile(question: q),
                            const SizedBox(height: AppDimensions.quizOptionGap),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _BottomBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (missed.isNotEmpty) ...[
                      AppButton(
                        text: AppStrings.resultRetryMissed(missed.length),
                        variant: AppButtonVariant.outline,
                        foregroundColor: AppColors.practicePrimary,
                        borderColor: AppColors.practicePrimary,
                        onPressed: () => _retryMissed(context),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                    ],
                    AppButton(
                      text: AppStrings.resultDone,
                      onPressed: () => _finish(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _centered(Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppDimensions.quizMaxContentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.quizHorizontalPadding),
        child: child,
      ),
    ),
  );
}

/// Vòng tròn % chính xác (chạy từ 0 khi mở màn) và 3 số liệu Đúng / Sai / Thời gian.
class _ScoreCard extends StatelessWidget {
  final QuizSummary summary;
  final Color accent;
  final String duration;

  const _ScoreCard({required this.summary, required this.accent, required this.duration});

  @override
  Widget build(BuildContext context) {
    return QuizCard(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: summary.accuracyPercent / 100),
            duration: AppDurations.pulse,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: AppDimensions.quizResultRingSize,
              height: AppDimensions.quizResultRingSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: AppDimensions.quizResultRingStroke,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.practiceSelectedFill,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.resultPercent((value * 100).round()),
                        style: AppTypography.quizResultPercent.copyWith(color: accent),
                      ),
                      const Text(AppStrings.resultAccuracy, style: AppTypography.quizCaption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          const Divider(height: 1, color: AppColors.practiceCardBorder),
          const SizedBox(height: AppDimensions.space16),
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(
                  icon: Icons.check_rounded,
                  color: AppColors.successGreen,
                  tint: AppColors.quizCorrectTint,
                  value: '${summary.correctCount}',
                  label: AppStrings.resultCorrect,
                ),
                const VerticalDivider(width: 1, color: AppColors.practiceCardBorder),
                _Stat(
                  icon: Icons.close_rounded,
                  color: AppColors.errorRed,
                  tint: AppColors.quizWrongTint,
                  value: '${summary.wrongCount}',
                  label: AppStrings.resultWrong,
                ),
                const VerticalDivider(width: 1, color: AppColors.practiceCardBorder),
                _Stat(
                  icon: Icons.schedule_rounded,
                  color: AppColors.practicePrimary,
                  tint: AppColors.practiceSelectedFill,
                  value: duration,
                  label: AppStrings.resultDuration,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.tint,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: AppDimensions.quizStatIconBox,
            height: AppDimensions.quizStatIconBox,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: AppDimensions.iconSmall),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(value, style: AppTypography.quizStatValue),
          const SizedBox(height: AppDimensions.space4),
          Text(label, style: AppTypography.quizCaption),
        ],
      ),
    );
  }
}

class _MissedWordTile extends StatelessWidget {
  final QuizQuestion question;

  const _MissedWordTile({required this.question});

  @override
  Widget build(BuildContext context) {
    final v = question.vocab;
    return Container(
      padding: const EdgeInsets.only(left: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.quizOptionRadius),
        border: Border.all(color: AppColors.practiceCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: v.term, style: AppTypography.quizStatValue),
                      TextSpan(
                        text: '  ${AppStrings.partOfSpeech(v.partOfSpeech)}',
                        style: AppTypography.quizCaption,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(v.definitionVi, style: AppTypography.quizCaption),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.quizListenWordTooltip(v.term),
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.practicePrimary),
            onPressed: () => SpeechService.instance.speak(v.term),
          ),
        ],
      ),
    );
  }
}

/// Thanh nút cố định dưới đáy, nền trắng với bóng nhẹ phía trên.
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.practiceTextPrimary.withValues(alpha: AppDimensions.quizSheetShadowOpacity),
            blurRadius: AppDimensions.quizSheetShadowBlur,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: _centered(child),
      ),
    );
  }
}
