import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';

/// Đầu trang dùng chung cho Màn 07 (Chi tiết), 09 (Sửa) và 24 (Thêm từ):
/// chevron quay lại, tiêu đề 20px và nút tuỳ chọn bên phải.
class WordScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const WordScreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space8,
        AppDimensions.space8,
        AppDimensions.space12,
        AppDimensions.space8,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.back,
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.practicePrimary,
              size: AppDimensions.iconLarge,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppDimensions.space4),
          Expanded(
            child: Semantics(header: true, child: Text(title, style: AppTypography.wordFormTitle)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Khung nội dung chung: nền xanh trắng, căn giữa, rộng tối đa [AppDimensions.wordFormMaxWidth].
/// Thanh cuộn nằm ở mép màn hình (không bị co theo khung nội dung).
class WordScreenBody extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  const WordScreenBody({super.key, required this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    Widget constrain(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.wordFormMaxWidth),
        child: child,
      ),
    );
    return SafeArea(
      child: Column(
        children: [
          constrain(header),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(0, AppDimensions.space12, 0, AppDimensions.wordFormBottomSpace),
              child: constrain(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.wordFormHorizontalPadding),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
