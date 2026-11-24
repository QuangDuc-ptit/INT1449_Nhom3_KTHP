import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/review_schedule.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../data/repositories/quiz_question_factory.dart';
import '../quiz/quiz_session_screen.dart';

/// Màn 16 — Hàng đợi ôn tập hôm nay (từ có `next_review_at <= NOW`).
class ReviewTodayScreen extends StatelessWidget {
  const ReviewTodayScreen({super.key});

  /// Nhãn + màu theo mức gấp: đến hạn hôm nay (xanh), quá hạn 1–2 ngày (cam),
  /// quá hạn từ [urgentDays] ngày (đỏ).
  static const int urgentDays = 3;

  static ({String label, Color text, Color background}) overdueStyle(DateTime due, DateTime now) {
    final days = calendarDaysBetween(due, now);
    if (days <= 0) {
      return (label: AppStrings.reviewDueNow, text: AppColors.practicePrimary, background: AppColors.practiceSelectedFill);
    }
    if (days < urgentDays) {
      return (label: AppStrings.reviewOverdueDays(days), text: AppColors.warningOrangeText, background: AppColors.quizAlmostTint);
    }
    return (label: AppStrings.reviewOverdueDays(days), text: AppColors.errorRedText, background: AppColors.quizWrongTint);
  }

  void _start(BuildContext context, DashboardStore store) {
    final questions = QuizQuestionFactory.buildMixed(
      pool: store.dueVocabularies,
      count: 10,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizSessionScreen(questions: questions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DashboardStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reviewTitle, style: AppTypography.headingMedium),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final due = store.dueVocabularies;

          if (due.isEmpty) {
            return EmptyStateWidget(
              title: AppStrings.reviewDoneTitle,
              message: AppStrings.reviewDoneMessage,
              icon: Icons.verified_rounded,
              actionText: AppStrings.reviewBackHome,
              onAction: () => Navigator.of(context).pop(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.screenMargin),
                  itemCount: due.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.space12),
                  itemBuilder: (context, i) {
                    final v = due[i];
                    final p = store.progressOf(v.id)!;
                    final urgency = overdueStyle(p.nextReviewAt, DateTime.now());
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(v.term, style: AppTypography.headingMedium),
                                    const SizedBox(width: AppDimensions.space8),
                                    CefrBadge(level: v.cefrLevel),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space4),
                                Text(v.definitionVi, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space8,
                              vertical: AppDimensions.space4,
                            ),
                            decoration: BoxDecoration(
                              color: urgency.background,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                            child: Text(urgency.label, style: AppTypography.labelSmall.copyWith(color: urgency.text)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenMargin,
                    AppDimensions.space8,
                    AppDimensions.screenMargin,
                    AppDimensions.space16,
                  ),
                  child: AppButton(
                    text: AppStrings.reviewStart(due.length > 10 ? 10 : due.length),
                    onPressed: () => _start(context, store),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
