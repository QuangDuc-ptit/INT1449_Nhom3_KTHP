import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_durations.dart';

/// Toast (SnackBar nổi) dùng thống nhất cho các thông báo thành công / lỗi / thông tin.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message, {SnackBarAction? action}) =>
      _show(context, message, AppColors.successGreen, Icons.check_circle_rounded, action);

  static void error(BuildContext context, String message, {SnackBarAction? action}) =>
      _show(context, message, AppColors.errorRed, Icons.error_outline_rounded, action);

  static void info(BuildContext context, String message, {SnackBarAction? action, Duration? duration}) =>
      _show(context, message, AppColors.primaryBlue, Icons.info_outline_rounded, action, duration);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    SnackBarAction? action, [
    Duration? duration,
  ]) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: AppDimensions.iconSmall),
              const SizedBox(width: AppDimensions.space8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          action: action,
          duration: duration ?? AppDurations.toast,
        ),
      );
  }
}
