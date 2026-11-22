import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';

/// Thanh điều hướng dưới của app: Trang chủ · Thư viện · Luyện tập · Cá nhân.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTabSelected});

  static const List<_NavItem> _items = [
    _NavItem(AppStrings.navHome, Icons.home_outlined, Icons.home_rounded),
    _NavItem(AppStrings.navLibrary, Icons.library_books_outlined, Icons.library_books_rounded),
    _NavItem(AppStrings.navPractice, Icons.play_circle_outline_rounded, Icons.play_arrow_rounded),
    _NavItem(AppStrings.navProfile, Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.homeDivider, width: AppDimensions.bottomNavBorderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _buildItem(_items[i], i == currentIndex, () => onTabSelected(i))),
            ],
          ),
        ),
      ),
    );
  }

  /// Mục đang chọn: icon xanh trong nền viên thuốc xanh nhạt, nhãn xanh đậm.
  /// Mục khác: icon nét mảnh, chữ xám xanh.
  Widget _buildItem(_NavItem item, bool selected, VoidCallback onTap) {
    final color = selected ? AppColors.navyBlue : AppColors.navInactive;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: kThemeAnimationDuration,
              width: AppDimensions.navActivePillWidth,
              height: AppDimensions.navActivePillHeight,
              decoration: BoxDecoration(
                color: selected ? AppColors.navActivePill : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: AppDimensions.iconMedium,
                color: selected ? AppColors.practicePrimary : AppColors.navInactive,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              item.label,
              style: AppTypography.bottomNavLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}
