import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../data/repositories/quiz_question_factory.dart';
import '../quiz/quiz_session_screen.dart';

/// Màn 16 — Hàng đợi ôn tập hôm nay (từ có `next_review_at <= NOW`).
class ReviewTodayScreen extends StatelessWidget {
  const ReviewTodayScreen({super.key});

  String _overdueLabel(DateTime due) {
    final diff = DateTime.now().difference(due);
    if (diff.inHours < 1) return AppStrings.reviewDueNow;
    if (diff.inHours < 24) return AppStrings.reviewOverdueHours(diff.inHours);
    return AppStrings.reviewOverdueDays(diff.inDays);
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
        title: Text(AppStrings.reviewTitle, style: AppTypography.headingLarge),
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
                          Text(
                            _overdueLabel(p.nextReviewAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warningOrange,
                            ),
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
