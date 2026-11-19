import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/mock/mock_vocab_data.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../data/repositories/quiz_question_factory.dart';
import '../ai_vocab/ai_generate_screen.dart';
import '../quiz/quiz_session_screen.dart';
import 'review_today_screen.dart';

/// Màn 04 — Trang chủ: Streak, Mục tiêu ngày, Nhắc ôn tập, lối tắt.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _quickPractice(BuildContext context) {
    final questions = QuizQuestionFactory.build(
      mode: QuizMode.meaningChoose,
      pool: MockVocabData.initialVocabularies,
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
        title: Text('Trang chủ', style: AppTypography.headingLarge),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final dueCount = store.dueVocabularies.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenMargin,
              AppDimensions.space8,
              AppDimensions.screenMargin,
              AppDimensions.space24,
            ),
            children: [
              Text('Xin chào! 👋', style: AppTypography.displayLarge),
              const SizedBox(height: AppDimensions.space4),
              Text('Mỗi ngày một chút, nhớ lâu hơn.', style: AppTypography.bodyMedium),
              const SizedBox(height: AppDimensions.space20),
              _StreakCard(streak: store.streak, studiedToday: store.studiedToday),
              const SizedBox(height: AppDimensions.space16),
              _DailyGoalCard(
                reviewed: store.reviewedToday,
                goal: store.dailyGoal,
                ratio: store.goalRatio,
                reached: store.goalReached,
              ),
              if (dueCount >= 1) ...[
                const SizedBox(height: AppDimensions.space16),
                _ReviewReminderCard(
                  dueCount: dueCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ReviewTodayScreen()),
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.space24),
              Text('Lối tắt học nhanh', style: AppTypography.headingMedium),
              const SizedBox(height: AppDimensions.space12),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutCard(
                      icon: Icons.bolt_rounded,
                      color: AppColors.primaryBlue,
                      label: 'Luyện nhanh\n10 câu',
                      onTap: () => _quickPractice(context),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: _ShortcutCard(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.warningOrange,
                      label: 'Tạo từ\nbằng AI',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AiGenerateScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool studiedToday;

  const _StreakCard({required this.streak, required this.studiedToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.warningOrange,
              size: 40,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ngày',
                  style: AppTypography.displayLarge.copyWith(color: AppColors.white),
                ),
                Text(
                  studiedToday
                      ? 'Chuỗi học liên tiếp — hôm nay đã xong! ✅'
                      : 'Chuỗi học liên tiếp — học ngay để giữ lửa!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final int reviewed;
  final int goal;
  final double ratio;
  final bool reached;

  const _DailyGoalCard({
    required this.reviewed,
    required this.goal,
    required this.ratio,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.successGreen : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Mục tiêu hôm nay', style: AppTypography.headingMedium)),
              if (reached)
                const Icon(Icons.emoji_events_rounded, color: AppColors.successGreen),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: AppColors.secondaryBackground,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            reached
                ? 'Tuyệt vời! Bạn đã hoàn thành mục tiêu ($reviewed/$goal từ) 🎉'
                : '$reviewed / $goal từ đã ôn hôm nay',
            style: AppTypography.bodyMedium.copyWith(
              color: reached ? AppColors.successGreen : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewReminderCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback onTap;

  const _ReviewReminderCard({required this.dueCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.warningOrange),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  'Bạn có $dueCount từ cần ôn hôm nay',
                  style: AppTypography.headingMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            'Ôn đúng hạn giúp bạn nhớ lâu hơn theo chu kỳ lặp lại ngắt quãng.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space16),
          AppButton(text: 'Ôn tập ngay', onPressed: onTap),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(label, style: AppTypography.bodyBold),
            ],
          ),
        ),
      ),
    );
  }
}
