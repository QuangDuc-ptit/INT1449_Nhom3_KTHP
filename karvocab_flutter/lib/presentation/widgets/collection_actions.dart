import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/collection_store.dart';
import 'collection_form_sheet.dart';
import 'delete_word_dialog.dart';

enum _CollectionAction { edit, delete }

/// Menu "Sửa học phần / Xoá học phần" (Màn 05 nút ⋮ trên thẻ, Màn 06 nút ⋮ trên AppBar).
///
/// Sửa: mở lại form Màn 22 với dữ liệu cũ. Xoá: hỏi xác nhận rồi xoá học phần
/// cùng các từ trong đó; xoá xong gọi [onDeleted] (vd Màn 06 quay về Thư viện).
Future<void> showCollectionActions(
  BuildContext context, {
  required CollectionModel collection,
  CollectionStore? store,
  VoidCallback? onDeleted,
}) async {
  final s = store ?? CollectionStore.instance;
  final action = await showModalBottomSheet<_CollectionAction>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusCard)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('collection_action_edit'),
              leading: const Icon(Icons.edit_outlined, color: AppColors.actionPrimary),
              title: Text(AppStrings.collectionEdit, style: AppTypography.bodyBold),
              onTap: () => Navigator.of(ctx).pop(_CollectionAction.edit),
            ),
            ListTile(
              key: const Key('collection_action_delete'),
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
              title: Text(
                AppStrings.collectionDelete,
                style: AppTypography.bodyBold.copyWith(color: AppColors.errorRed),
              ),
              onTap: () => Navigator.of(ctx).pop(_CollectionAction.delete),
            ),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _CollectionAction.edit:
      final saved = await showCollectionFormSheet(context, store: s, initial: collection);
      if (saved != null && context.mounted) AppToast.success(context, AppStrings.collectionUpdated(saved.title));
    case _CollectionAction.delete:
      final words = s.wordsOf(collection.id).length;
      final confirmed = await showDeleteConfirmDialog(
        context,
        title: AppStrings.collectionDeleteTitle(collection.title),
        message: AppStrings.collectionDeleteMessage(words),
        confirmText: AppStrings.collectionDelete,
      );
      if (!confirmed || !context.mounted) return;
      s.deleteCollection(collection.id);
      AppToast.success(context, AppStrings.collectionDeleted(collection.title));
      onDeleted?.call();
  }
}
