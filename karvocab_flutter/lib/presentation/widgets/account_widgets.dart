import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/account_plan.dart';

/// Tên, màu và icon của từng loại tài khoản.
extension AccountPlanUi on AccountPlan {
  String get label {
    switch (this) {
      case AccountPlan.standard:
        return AppStrings.planStandard;
      case AccountPlan.plus:
        return AppStrings.planPlus;
      case AccountPlan.vip:
        return AppStrings.planVip;
    }
  }

  Color get color {
    switch (this) {
      case AccountPlan.standard:
        return AppColors.planStandard;
      case AccountPlan.plus:
        return AppColors.planPlus;
      case AccountPlan.vip:
        return AppColors.planVip;
    }
  }

  Color get tint {
    switch (this) {
      case AccountPlan.standard:
        return AppColors.planStandardTint;
      case AccountPlan.plus:
        return AppColors.planPlusTint;
      case AccountPlan.vip:
        return AppColors.planVipTint;
    }
  }

  IconData get icon {
    switch (this) {
      case AccountPlan.standard:
        return Icons.person_rounded;
      case AccountPlan.plus:
        return Icons.bolt_rounded;
      case AccountPlan.vip:
        return Icons.workspace_premium_rounded;
    }
  }
}

/// Nhãn viên thuốc hiện loại tài khoản (vd "Plus").
class PlanChip extends StatelessWidget {
  final AccountPlan plan;

  const PlanChip({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppDimensions.quizChipHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space10, vertical: AppDimensions.space4),
      decoration: BoxDecoration(
        color: plan.tint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(plan.icon, size: AppDimensions.quizChipIconSize, color: plan.color),
          const SizedBox(width: AppDimensions.space4),
          Text(plan.label, style: AppTypography.quizChip.copyWith(color: plan.color)),
        ],
      ),
    );
  }
}

/// Hộp chọn ngày sinh (không cho chọn ngày trong tương lai).
Future<DateTime?> pickBirthDate(BuildContext context, {DateTime? initial}) {
  final today = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(today.year - 18, today.month, today.day),
    firstDate: DateTime(1900),
    lastDate: today,
    helpText: AppStrings.profileBirthDateHelp,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
}
