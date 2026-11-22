import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Ô gõ đáp án + nút "Kiểm tra" dùng cho Màn 19 & 20.
/// Tự focus khi mở, Enter = nộp bài, khoá lại sau khi đã trả lời.
class TypingAnswerField extends StatefulWidget {
  final bool locked;
  final ValueChanged<String> onSubmit;
  final String hint;

  const TypingAnswerField({
    super.key,
    required this.locked,
    required this.onSubmit,
    this.hint = AppStrings.quizTypingHint,
  });

  @override
  State<TypingAnswerField> createState() => _TypingAnswerFieldState();
}

class _TypingAnswerFieldState extends State<TypingAnswerField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.locked || _controller.text.trim().isEmpty) return;
    widget.onSubmit(_controller.text);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: AppDimensions.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            border: Border.all(
              color: _focus.hasFocus ? AppColors.borderFocused : AppColors.borderLight,
              width: AppDimensions.borderMedium,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            readOnly: widget.locked,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        AppButton(
          text: AppStrings.quizCheck,
          onPressed: _submit,
          isEnabled: !widget.locked && _controller.text.trim().isNotEmpty,
        ),
      ],
    );
  }
}
