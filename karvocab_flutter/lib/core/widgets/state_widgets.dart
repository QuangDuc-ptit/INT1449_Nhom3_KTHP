import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// 1. Trạng thái Chưa có dữ liệu (Empty State) — Bắt buộc có lối ra theo Rubric
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenMargin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.stateIllustrationSize,
              height: AppDimensions.stateIllustrationSize,
              decoration: const BoxDecoration(
                color: AppColors.softBlueSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppDimensions.iconState, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppDimensions.space20),
            Text(
              title,
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                width: AppDimensions.emptyActionWidth,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 2. Trạng thái Lỗi (Error State) — Bắt buộc có nút Thử lại (Lối ra) theo Rubric
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback onRetry;
  final String retryText;

  const ErrorStateWidget({
    super.key,
    this.title = 'Đã có lỗi xảy ra',
    required this.errorMessage,
    required this.onRetry,
    this.retryText = 'Thử lại ngay',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenMargin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.stateIllustrationSize,
              height: AppDimensions.stateIllustrationSize,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: AppDimensions.tintOpacity),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconState,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),
            Text(
              title,
              style: AppTypography.headingMedium.copyWith(color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              errorMessage,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space24),
            AppButton(
              text: retryText,
              onPressed: onRetry,
              variant: AppButtonVariant.primary,
              width: AppDimensions.retryButtonWidth,
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Trạng thái Đang tải (Loading State) — Chuẩn chỉn chu không làm đơ giao diện
class LoadingStateWidget extends StatelessWidget {
  final String message;

  const LoadingStateWidget({
    super.key,
    this.message = 'Đang tải dữ liệu...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: AppDimensions.stateLoaderSize,
            height: AppDimensions.stateLoaderSize,
            child: CircularProgressIndicator(
              strokeWidth: AppDimensions.stateLoaderStroke,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
