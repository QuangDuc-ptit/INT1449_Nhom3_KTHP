import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/dashboard_store.dart';
import 'quiz_controller.dart';
import 'quiz_mode_views.dart';
import 'quiz_result_screen.dart';
import 'widgets/feedback_banner.dart';
import 'widgets/quiz_card.dart';

/// Màn hình làm bài — dùng chung cho Màn 08 / 19 / 20 / 25 và Màn 26 (thử lại câu sai).
/// Mỗi câu hỏi tự chọn giao diện theo `question.mode`.
class QuizSessionScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final bool isRetry;

  const QuizSessionScreen({
    super.key,
    required this.questions,
    this.isRetry = false,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  late final QuizController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuizController(
      questions: widget.questions,
      isRetry: widget.isRetry,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        title: Text(AppStrings.quizExitTitle, style: AppTypography.headingMedium),
        content: Text(
          AppStrings.quizExitMessage,
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(AppDimensions.dialogTextButtonMinWidth, AppDimensions.minTouchTarget)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.quizExitStay),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(AppDimensions.dialogTextButtonMinWidth, AppDimensions.minTouchTarget),
              foregroundColor: AppColors.errorRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.quizExitLeave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _onContinue() {
    final hasNext = _controller.next();
    if (hasNext) return;

    final summary = _controller.buildSummary();
    DashboardStore.instance.recordSessionResult(summary);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => QuizResultScreen(summary: summary)),
    );
  }

  Widget _buildQuestion(QuizQuestion q, QuizAnswerRecord? record) {
    final key = ValueKey(q.id);
    switch (q.mode) {
      case QuizMode.listenChoose:
        return ListenChooseView(
            key: key, question: q, record: record, onSubmit: _controller.submitChoice);
      case QuizMode.listenType:
        return ListenTypeView(
            key: key, question: q, record: record, onSubmit: _controller.submitTyped);
      case QuizMode.meaningChoose:
        return MeaningChooseView(
            key: key, question: q, record: record, onSubmit: _controller.submitChoice);
      case QuizMode.recallType:
        return RecallTypeView(
            key: key, question: q, record: record, onSubmit: _controller.submitTyped);
      case QuizMode.pronunciation:
        return PronunciationView(
            key: key,
            question: q,
            record: record,
            onSubmit: _controller.submitSpoken,
            onSkip: _controller.skip);
      case QuizMode.synonymAntonym:
        return SynonymAntonymView(
            key: key, question: q, record: record, onSubmit: _controller.submitChoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateWidget(
          title: AppStrings.quizNoQuestionsTitle,
          message: AppStrings.quizNoQuestionsMessage,
          actionText: AppStrings.back,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final mode = widget.questions.first.mode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final q = _controller.current;
          final record = _controller.lastRecord;

          return Scaffold(
            backgroundColor: AppColors.practiceBackground,
            body: SafeArea(
              bottom: record == null,
              child: Column(
                children: [
                  _centered(_buildHeader()),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space24),
                      child: _centered(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: AppDimensions.space8,
                              runSpacing: AppDimensions.space8,
                              children: [
                                QuizChip(icon: mode.icon, label: mode.title),
                                if (widget.isRetry)
                                  const QuizChip(
                                    icon: Icons.replay_rounded,
                                    label: AppStrings.quizRetryChip,
                                    foreground: AppColors.warningOrange,
                                    background: AppColors.quizAlmostTint,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            _buildQuestion(q, record),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (record != null)
                    FeedbackBanner(
                      record: record,
                      isLast: _controller.isLast,
                      onContinue: _onContinue,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Giới hạn bề rộng nội dung và căn giữa trên tablet / web.
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

  /// Nút đóng + thanh tiến độ + bộ đếm câu.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
      child: Row(
        children: [
          SizedBox(
            width: AppDimensions.minTouchTarget,
            height: AppDimensions.minTouchTarget,
            child: Center(
              child: Material(
                color: AppColors.white,
                shape: const CircleBorder(side: BorderSide(color: AppColors.practiceCardBorder)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _confirmExit,
                  child: const SizedBox(
                    width: AppDimensions.quizCloseButtonSize,
                    height: AppDimensions.quizCloseButtonSize,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.practiceTextPrimary,
                      size: AppDimensions.iconSmall,
                      semanticLabel: AppStrings.quizExitTooltip,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _controller.progress),
              duration: AppDurations.pageTransition,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: AppDimensions.quizProgressHeight,
                  backgroundColor: AppColors.practiceSelectedFill,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.practicePrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Text(
            AppStrings.quizProgress(_controller.index + 1, _controller.total),
            style: AppTypography.quizCounter,
          ),
        ],
      ),
    );
  }
}
