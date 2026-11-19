import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'login_screen.dart';

/// Màn 01 · Khởi động (Splash Screen)
/// Hiển thị Logo Axolotl & Slogan "Learn Smart, Remember Longer"
/// Tự động kiểm tra phiên đăng nhập sau 1.5 giây
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Tự động kiểm tra phiên và điều hướng sau 1.8 giây
    Timer(const Duration(milliseconds: 1800), _checkSessionAndNavigate);
  }

  void _checkSessionAndNavigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container với hình ảnh linh vật Axolotl
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.softBlueSurface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        ),
                        child: const Icon(
                          Icons.pets_rounded, // Biểu tượng linh vật Axolotl
                          size: 56,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space24),

                  // Tên thương hiệu KarVocab
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Kar',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Vocab',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.lightBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space8),

                  // Slogan
                  Text(
                    'Learn Smart, Remember Longer',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space48),

                  // Indicator nhẹ nhàng
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
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
