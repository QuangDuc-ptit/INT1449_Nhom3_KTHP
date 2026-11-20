import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';

/// Ô nhập liệu chuẩn Figma: Chiều cao 52dp, bo góc 16dp, hiển thị lỗi rõ ràng
class AppTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool isReadOnly;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Màu viền khi không có lỗi; mặc định [AppColors.borderLight].
  final Color? borderColor;

  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.prefixIcon,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.onSubmitted,
    this.autofocus = false,
    this.borderColor,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool isMultiline = widget.maxLines > 1 && !widget.isPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: AppTypography.bodyBold.copyWith(
            fontSize: 14.0,
            color: hasError ? AppColors.errorRed : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),

        // Input Field Container
        Container(
          // 52.0 dp >= 48 dp; ô nhiều dòng giữ chiều cao tối thiểu 52dp và tự giãn
          height: isMultiline ? null : AppDimensions.inputHeight,
          constraints: isMultiline
              ? const BoxConstraints(minHeight: AppDimensions.inputHeight)
              : null,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            border: Border.all(
              color: hasError
                  ? AppColors.errorRed
                  : widget.borderColor ?? AppColors.borderLight,
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: AppDimensions.space16),
                  child: widget.prefixIcon!,
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  readOnly: widget.isReadOnly,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  autofocus: widget.autofocus,
                  maxLines: isMultiline ? widget.maxLines : 1,
                  minLines: 1,
                  maxLength: widget.maxLength,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: AppDimensions.space12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (widget.isPassword) ...[
                IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ],
            ],
          ),
        ),

        // Error message text
        if (hasError) ...[
          const SizedBox(height: AppDimensions.space4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.errorRed),
              const SizedBox(width: AppDimensions.space4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
