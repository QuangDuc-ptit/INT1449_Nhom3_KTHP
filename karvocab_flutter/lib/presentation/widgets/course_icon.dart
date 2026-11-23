import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/repositories/collection_store.dart';
import 'collection_form_sheet.dart';

/// Icon và màu riêng của từng chủ đề học phần (Học thuật, Sự nghiệp, Đời sống, Du lịch, Khác).
class CategoryStyle {
  final IconData icon;
  final Color color;
  final Color tint;

  const CategoryStyle._(this.icon, this.color, this.tint);

  static CategoryStyle of(String categoryId) {
    final icon = CollectionCategories.icon(CollectionStore.iconForCategory(categoryId));
    return switch (categoryId) {
      'career' => CategoryStyle._(icon, AppColors.categoryCareer, AppColors.categoryCareerTint),
      'life' => CategoryStyle._(icon, AppColors.categoryLife, AppColors.categoryLifeTint),
      'travel' => CategoryStyle._(icon, AppColors.categoryTravel, AppColors.categoryTravelTint),
      'other' => CategoryStyle._(icon, AppColors.categoryOther, AppColors.categoryOtherTint),
      _ => CategoryStyle._(icon, AppColors.categoryAcademic, AppColors.categoryAcademicTint),
    };
  }
}

/// Ô icon vuông 48dp của học phần (Thư viện, Trang chủ).
class CourseIcon extends StatelessWidget {
  final String categoryId;

  const CourseIcon({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(categoryId);
    return Container(
      width: AppDimensions.libraryCourseIconBoxSize,
      height: AppDimensions.libraryCourseIconBoxSize,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(AppDimensions.courseCardIconRadius),
      ),
      child: Icon(style.icon, size: AppDimensions.iconMedium, color: style.color),
    );
  }
}
