import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Tiêu đề lớn đầu 4 tab chính (Trang chủ, Thư viện, Luyện tập, Hồ sơ cá nhân).
///
/// Dùng chung để cả 4 tab cùng cỡ chữ, màu và vị trí: hàng cao 48dp, chữ một
/// dòng, nút bên phải (chuông, "+", cài đặt) căn giữa theo tiêu đề.
/// Màn gọi tự đặt lề: trái/phải 20dp, trên 16dp.
class TabHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const TabHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypography.tabTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppDimensions.space12), trailing!],
        ],
      ),
    );
  }
}
