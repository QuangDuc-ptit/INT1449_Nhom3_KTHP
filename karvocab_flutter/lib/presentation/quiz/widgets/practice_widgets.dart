import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Màn 10 · Ô chọn: giá trị bên trái, chevron xuống bên phải.
class PracticeSelectField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const PracticeSelectField({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.practiceFieldRadius),
      side: const BorderSide(color: AppColors.practiceBorder, width: AppDimensions.borderThin),
    );
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.practiceFieldFill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppDimensions.practiceFieldHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.practiceFieldValue,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppDimensions.iconMedium,
                    color: AppColors.practiceTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Màn 10 · Nút lựa chọn "Thứ tự hiển thị". Cao 40 nhưng vùng chạm 48dp.
class PracticeOrderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PracticeOrderButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.practiceOrderButtonRadius),
      side: BorderSide(
        color: selected ? AppColors.practicePrimary : AppColors.practiceBorder,
        width: AppDimensions.borderThin,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppDimensions.minTouchTarget,
          child: Center(
            child: Material(
              color: selected ? AppColors.practiceSelectedFill : AppColors.white,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: AppDimensions.practiceOrderButtonHeight,
                  width: double.infinity,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.practiceOrderOption.copyWith(
                          color: selected ? AppColors.practicePrimary : AppColors.practiceTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Màn 10 · Thẻ trò chơi: icon (trên trái) + chevron (trên phải) và tên trò chơi.
class PracticeGameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Dòng phụ dưới tên trò, vd thời gian mỗi câu "35 giây/câu".
  final String? subtitle;

  const PracticeGameCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.practiceGameCardRadius);
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.practiceCardBorder, width: AppDimensions.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.practiceGameCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppDimensions.practiceGameIconBox,
                      height: AppDimensions.practiceGameIconBox,
                      decoration: BoxDecoration(
                        color: AppColors.practiceSelectedFill,
                        borderRadius: BorderRadius.circular(AppDimensions.practiceGameIconRadius),
                      ),
                      child: Icon(
                        icon,
                        size: AppDimensions.iconSmall,
                        color: AppColors.practicePrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: AppDimensions.iconSmall,
                      color: AppColors.practiceTextSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space10),
                // Luôn giữ chỗ 2 dòng cho tên trò để mọi thẻ cao bằng nhau
                // (tên dài như "Đồng nghĩa và trái nghĩa" xuống dòng).
                Stack(
                  children: [
                    const Text(' \n ', style: AppTypography.practiceGameTitle),
                    Text(
                      title,
                      style: AppTypography.practiceGameTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.space4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: AppDimensions.iconTiny,
                        color: AppColors.practiceTextSecondary,
                      ),
                      const SizedBox(width: AppDimensions.space4),
                      Flexible(child: Text(subtitle!, style: AppTypography.practiceHint)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Màn 10 · Một dòng lựa chọn trong bottom sheet (dấu tích hoặc ô vuông bên phải).
class PracticeSheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multiSelect;
  final bool enabled;
  final VoidCallback onTap;

  const PracticeSheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? trailing = multiSelect
        ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
        : (selected ? Icons.check_rounded : null);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.practiceHorizontalPadding,
              vertical: AppDimensions.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.practiceFieldValue.copyWith(
                      color: selected
                          ? AppColors.practicePrimary
                          : (enabled ? AppColors.practiceTextPrimary : AppColors.practiceTextSecondary),
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(
                    trailing,
                    size: AppDimensions.iconMedium,
                    color: selected ? AppColors.practicePrimary : AppColors.practiceTextSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
