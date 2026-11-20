import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Danh sách điều kiện mật khẩu mạnh, tick xanh khi đạt — dùng cho Màn 21.
class PasswordRulesHint extends StatelessWidget {
  final String password;

  const PasswordRulesHint({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = <String, bool>{
      'Ít nhất 8 ký tự': password.length >= 8,
      '1 chữ hoa': RegExp(r'[A-Z]').hasMatch(password),
      '1 chữ số': RegExp(r'[0-9]').hasMatch(password),
    };
    return Wrap(
      spacing: AppDimensions.space12,
      runSpacing: AppDimensions.space4,
      children: rules.entries.map((rule) {
        final ok = rule.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: ok ? AppColors.successGreen : AppColors.textMuted,
            ),
            const SizedBox(width: AppDimensions.space4),
            Text(
              rule.key,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color: ok ? AppColors.successGreen : AppColors.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
