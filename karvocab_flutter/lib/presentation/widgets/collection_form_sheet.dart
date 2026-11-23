import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/collection_store.dart';

/// Các chủ đề học phần (đặc tả Màn 05: Học thuật, Sự nghiệp, Đời sống + Du lịch từ Figma)
/// và "Khác" (`other`, BE dùng làm mặc định khi không chọn — FE-BE-ALIGNMENT).
class CollectionCategories {
  CollectionCategories._();

  static const Map<String, String> labels = {
    'academic': 'Học thuật',
    'career': 'Sự nghiệp',
    'life': 'Đời sống',
    'travel': 'Du lịch',
    'other': 'Khác',
  };

  static IconData icon(String iconName) {
    switch (iconName) {
      case 'school_rounded':
        return Icons.school_rounded;
      case 'flight_takeoff_rounded':
        return Icons.flight_takeoff_rounded;
      case 'chat_bubble_outline_rounded':
        return Icons.chat_bubble_outline_rounded;
      case 'work_outline_rounded':
        return Icons.work_outline_rounded;
      case 'folder_rounded':
        return Icons.folder_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}

/// Màn 22 · Tạo / sửa học phần (Bottom Sheet).
/// [initial] khác `null` → sửa học phần đó. Trả về học phần vừa lưu, hoặc `null`
/// nếu người dùng đóng sheet.
Future<CollectionModel?> showCollectionFormSheet(
  BuildContext context, {
  CollectionStore? store,
  CollectionModel? initial,
}) {
  return showModalBottomSheet<CollectionModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => CollectionFormSheet(store: store ?? CollectionStore.instance, initial: initial),
  );
}

class CollectionFormSheet extends StatefulWidget {
  final CollectionStore store;

  /// Học phần đang sửa; `null` = tạo mới.
  final CollectionModel? initial;

  const CollectionFormSheet({super.key, required this.store, this.initial});

  bool get isEditing => initial != null;

  @override
  State<CollectionFormSheet> createState() => _CollectionFormSheetState();
}

class _CollectionFormSheetState extends State<CollectionFormSheet> {
  late final _titleController = TextEditingController(text: widget.initial?.title);
  late final _descController = TextEditingController(text: widget.initial?.description);
  late String _category = widget.initial?.category ?? CollectionModel.defaultCategory;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    var error = Validators.collectionTitle(title);
    if (error == null && widget.store.isTitleTaken(title, excludeId: widget.initial?.id)) {
      error = 'Bạn đã có học phần tên "$title"';
    }
    if (error != null) {
      setState(() => _titleError = error);
      return;
    }
    final initial = widget.initial;
    final saved = initial == null
        ? widget.store.createCollection(title: title, description: _descController.text, category: _category)
        : widget.store.updateCollection(
            initial.id,
            title: title,
            description: _descController.text,
            category: _category,
          );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.screenMargin,
        right: AppDimensions.screenMargin,
        top: AppDimensions.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.space24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusCard)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditing ? AppStrings.collectionEdit : AppStrings.libraryCreateCourse,
                    style: AppTypography.headingMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
              AppTextField(
                label: 'Tên học phần *',
                hintText: 'ví dụ: Từ vựng Marketing B2',
                controller: _titleController,
                maxLength: 50,
                autofocus: !widget.isEditing,
                errorText: _titleError,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                label: 'Mô tả ngắn',
                hintText: 'ví dụ: Dùng ôn thi chứng chỉ trong tháng tới',
                controller: _descController,
                maxLines: 3,
                maxLength: 150,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppDimensions.space16),
              Text('Chủ đề', style: AppTypography.bodyBold.copyWith(fontSize: AppTypography.fontSize14)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: CollectionCategories.labels.entries.map((entry) {
                  final isSelected = _category == entry.key;
                  return ChoiceChip(
                    avatar: Icon(
                      CollectionCategories.icon(CollectionStore.iconForCategory(entry.key)),
                      size: AppDimensions.iconCompact,
                      color: isSelected ? AppColors.white : AppColors.primaryBlue,
                    ),
                    label: Text(entry.value),
                    labelStyle: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.white,
                    showCheckmark: false,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() => _category = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                key: const Key('collection_form_submit'),
                text: widget.isEditing ? AppStrings.collectionSave : 'Tạo học phần',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
