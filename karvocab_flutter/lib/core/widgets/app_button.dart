import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline }

/// Nút bấm đạt chuẩn Rubric INT1449: Vùng chạm $\ge 48$dp, hỗ trợ loading & disabled state
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final Widget? icon;
  final double? width;
  final double height;

  /// Màu nền khi bấm được (áp cho [AppButtonVariant.primary] và
  /// [AppButtonVariant.outline]); mặc định primary = [AppColors.primaryBlue],
  /// outline = trong suốt.
  final Color? backgroundColor;

  /// Màu chữ khi bấm được (chỉ áp cho [AppButtonVariant.outline]);
  /// mặc định [AppColors.primaryBlue].
  final Color? foregroundColor;

  /// Màu viền khi bấm được (chỉ áp cho [AppButtonVariant.outline]);
  /// mặc định [AppColors.primaryBlue].
  final Color? borderColor;

  /// Độ dày viền (chỉ áp cho [AppButtonVariant.outline]);
  /// mặc định [AppDimensions.borderMedium].
  final double? borderWidth;

  /// Kiểu chữ; mặc định [AppTypography.buttonText]. Màu chữ vẫn do biến thể quyết định.
  final TextStyle? textStyle;

  /// Màu nền khi bị khoá (chỉ áp cho [AppButtonVariant.primary]).
  final Color? disabledBackgroundColor;

  /// Bo góc; mặc định [AppDimensions.radiusButton].
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight, // 52.0 dp >= 48 dp
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.textStyle,
    this.disabledBackgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPress = isEnabled && !isLoading && onPressed != null;

    Color background;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        background = canPress ? (backgroundColor ?? AppColors.primaryBlue) : (disabledBackgroundColor ?? AppColors.textMuted.withValues(alpha: AppDimensions.disabledOpacity));
        textColor = AppColors.white;
        break;
      case AppButtonVariant.secondary:
        background = canPress ? AppColors.secondaryBackground : AppColors.borderLight;
        textColor = canPress ? AppColors.navyBlue : AppColors.textMuted;
        break;
      case AppButtonVariant.outline:
        background = canPress ? (backgroundColor ?? AppColors.transparent) : AppColors.transparent;
        textColor = canPress ? (foregroundColor ?? AppColors.primaryBlue) : AppColors.textMuted;
        borderSide = BorderSide(
          color: canPress ? (borderColor ?? AppColors.primaryBlue) : AppColors.borderLight,
          width: borderWidth ?? AppDimensions.borderMedium,
        );
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusButton),
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canPress ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: AppDimensions.buttonLoaderSize,
                    height: AppDimensions.buttonLoaderSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimensions.buttonLoaderStroke,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: AppDimensions.space8),
                      ],
                      Text(
                        text,
                        style: (textStyle ?? AppTypography.buttonText).copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
