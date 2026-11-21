import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_question_factory.dart';
import '../../data/services/speech_service.dart';
import 'quiz_session_screen.dart';

/// Màn 12 — Báo cáo kết quả buổi học (+ nút vào Màn 26 Luyện lại câu sai).
class QuizResultScreen extends StatelessWidget {
  final QuizSummary summary;

  const QuizResultScreen({super.key, required this.summary});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _retryMissed(BuildContext context) {
    final questions = QuizQuestionFactory.rebuildForRetry(summary.missedQuestions);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizSessionScreen(questions: questions, isRetry: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excellent = summary.accuracyPercent >= 80;
    final accent = excellent ? AppColors.successGreen : AppColors.warningOrange;
    final missed = summary.missedQuestions;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.screenMargin),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimensions.space16),
                      Text(excellent ? '🦎🎉' : '🦎💪', style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        excellent ? 'Xuất sắc!' : 'Cố gắng thêm một chút nhé!',
                        style: AppTypography.headingLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        summary.isRetry ? 'Kết quả luyện lại câu sai' : 'Kết quả buổi luyện tập',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: summary.accuracyPercent / 100,
                                strokeWidth: 12,
                                backgroundColor: AppColors.secondaryBackground,
                                valueColor: AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                            Text(
                              '${summary.accuracyPercent.round()}%',
                              style: AppTypography.displayLarge.copyWith(color: accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              color: AppColors.successGreen,
                              value: '${summary.correctCount}',
                              label: 'Đúng',
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.cancel_rounded,
                              color: AppColors.errorRed,
                              value: '${summary.wrongCount}',
                              label: 'Sai',
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.timer_rounded,
                              color: AppColors.primaryBlue,
                              value: _formatDuration(summary.durationSeconds),
                              label: 'Thời gian',
                            ),
                          ),
                        ],
                      ),
                      if (missed.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Từ cần ôn lại', style: AppTypography.headingMedium),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        for (final q in missed) ...[
                          _MissedWordTile(question: q),
                          const SizedBox(height: AppDimensions.space8),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenMargin,
                  AppDimensions.space8,
                  AppDimensions.screenMargin,
                  AppDimensions.space16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (missed.isNotEmpty) ...[
                      AppButton(
                        text: 'Luyện lại câu sai (${missed.length})',
                        variant: AppButtonVariant.outline,
                        onPressed: () => _retryMissed(context),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                    ],
                    AppButton(
                      text: 'Hoàn thành',
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppDimensions.space4),
          Text(value, style: AppTypography.headingMedium),
          Text(label, style: AppTypography.labelSmall),
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.term, style: AppTypography.bodyBold),
                  Text(v.definitionVi, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Nghe ${v.term}',
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primaryBlue),
            onPressed: () => SpeechService.instance.speak(v.term),
          ),
        ],
      ),
    );
  }
}
