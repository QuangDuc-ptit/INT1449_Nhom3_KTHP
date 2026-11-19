import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Design Tokens: Typography Scale theo chuẩn Figma KarVocab
class AppTypography {
  static const String fontFamily = 'Nunito';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
}
