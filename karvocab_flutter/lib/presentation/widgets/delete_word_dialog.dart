import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Màn 28 · Hộp thoại xác nhận xoá từ vựng.
/// Trả về `true` khi người dùng bấm "Xoá từ", `false` khi huỷ hoặc bấm ra ngoài.
Future<bool> showDeleteWordDialog(BuildContext context, String term) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      icon: Container(
        width: AppDimensions.dialogIconBoxSize,
        height: AppDimensions.dialogIconBoxSize,
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: AppDimensions.tintOpacity),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: AppDimensions.iconDialog),
      ),
      title: Text('Xoá từ vựng này?', style: AppTypography.headingMedium, textAlign: TextAlign.center),
      content: Text(
        'Từ "$term" và toàn bộ tiến độ ôn tập của nó sẽ bị xoá khỏi học phần. '
        'Bạn có thể hoàn tác ngay sau khi xoá.',
        style: AppTypography.bodyMedium,
        textAlign: TextAlign.center,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        0,
        AppDimensions.space16,
        AppDimensions.space16,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
                child: Text('Huỷ', style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
                child: Text('Xoá từ', style: AppTypography.buttonText),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
