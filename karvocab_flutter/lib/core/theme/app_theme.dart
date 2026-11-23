import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

/// Theme chung của app; dùng cho `MaterialApp` và các bản xem thử giao diện.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryBlue,
        fontFamily: AppTypography.fontFamily,
        fontFamilyFallback: AppTypography.fontFamilyFallback,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.background,
        ),
        // Màn con (có nút quay lại): tiêu đề căn giữa, cỡ headingMedium.
        // Màn gốc của tab (Trang chủ, Thư viện, Luyện tập, Hồ sơ) dùng tiêu đề lớn căn trái.
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.headingMedium,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        // Nút quay lại của AppBar giống WordScreenHeader: chevron xanh.
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (_) => const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.practicePrimary,
            size: AppDimensions.iconLarge,
          ),
        ),
      );
}
