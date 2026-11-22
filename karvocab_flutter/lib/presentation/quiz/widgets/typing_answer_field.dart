import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/quiz_models.dart';

/// Ô gõ đáp án + nút "Kiểm tra" dùng cho Màn 19 & 20.
/// Tự focus khi mở, Enter = nộp bài. Sau khi chấm ([result] khác null) ô bị khoá
/// và viền đổi màu theo kết quả.
class TypingAnswerField extends StatefulWidget {
  final AnswerResult? result;
  final ValueChanged<String> onSubmit;
  final String hint;

  const TypingAnswerField({
    super.key,
    required this.result,
    required this.onSubmit,
    this.hint = AppStrings.quizTypingHint,
  });

  @override
  State<TypingAnswerField> createState() => _TypingAnswerFieldState();
}

class _TypingAnswerFieldState extends State<TypingAnswerField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool get _locked => widget.result != null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_locked || _controller.text.trim().isEmpty) return;
    widget.onSubmit(_controller.text);
    _focus.unfocus();
  }

  Color get _borderColor {
    switch (widget.result) {
      case AnswerResult.correct:
        return AppColors.successGreen;
      case AnswerResult.almost:
        return AppColors.warningOrange;
      case AnswerResult.wrong:
        return AppColors.errorRed;
      case null:
        return _focus.hasFocus ? AppColors.practicePrimary : AppColors.practiceCardBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: AppDimensions.quizFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.quizFieldRadius),
            border: Border.all(
              color: _borderColor,
              width: _focus.hasFocus || _locked ? AppDimensions.borderThick : AppDimensions.borderMedium,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            readOnly: _locked,
            autocorrect: false,
            enableSuggestions: false,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            cursorColor: AppColors.practicePrimary,
            onChanged: (_) => _refresh(),
            onSubmitted: (_) => _submit(),
            style: AppTypography.quizInput,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.quizPrompt,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (!_locked) ...[
          const SizedBox(height: AppDimensions.space16),
          AppButton(
            text: AppStrings.quizCheck,
            onPressed: _submit,
            backgroundColor: AppColors.practicePrimary,
            isEnabled: _controller.text.trim().isNotEmpty,
          ),
        ],
      ],
    );
  }
}
