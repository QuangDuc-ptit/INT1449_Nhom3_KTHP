import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/dashboard_store.dart';
import 'quiz_controller.dart';
import 'quiz_mode_views.dart';
import 'quiz_result_screen.dart';
import 'widgets/feedback_banner.dart';

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
        title: Text('Thoát buổi luyện tập?', style: AppTypography.headingMedium),
        content: Text(
          'Tiến độ của phiên này sẽ không được lưu.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục học'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(88, 48),
              foregroundColor: AppColors.errorRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thoát'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateWidget(
          title: 'Chưa có câu hỏi nào',
          message: 'Hãy thêm từ vựng vào học phần rồi quay lại luyện tập nhé.',
          actionText: 'Quay lại',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

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
            backgroundColor: AppColors.mainBackground,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: IconButton(
                tooltip: 'Thoát',
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchTarget,
                  minHeight: AppDimensions.minTouchTarget,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: _confirmExit,
              ),
              title: Padding(
                padding: const EdgeInsets.only(right: AppDimensions.screenMargin),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        child: LinearProgressIndicator(
                          value: _controller.progress,
                          minHeight: 10,
                          backgroundColor: AppColors.secondaryBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Text(
                      '${_controller.index + 1}/${_controller.total}',
                      style: AppTypography.bodyBold,
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenMargin,
                      AppDimensions.space8,
                      AppDimensions.screenMargin,
                      AppDimensions.space24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.isRetry)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: Text(
                              'Luyện lại các từ đã làm sai',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warningOrange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildQuestion(q, record),
                      ],
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
          );
        },
      ),
    );
  }
}
