import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

/// Màn 01 · Khởi động (Splash Screen)
///
/// Gồm 2 lớp nối tiếp nhau:
/// 1. Splash native của Android (androidx core-splashscreen, xem
///    MainActivity.kt + res/values/styles.xml): nền #F5FAFE, logo 160dp ở giữa.
/// 2. Màn này: cùng nền, logo cùng vị trí/kích thước, thêm chữ "KarVocab"
///    gần đáy — nên khi native splash biến mất, logo không bị nhảy.
///
/// Sau tối thiểu 1.5 giây (spec FE §4.1) và khi đã khôi phục xong phiên đăng
/// nhập, chuyển sang Trang chủ / Đăng nhập bằng pushReplacement để splash
/// không còn trong back stack.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Đường dẫn asset logo, khai báo trong pubspec.yaml
  static const String logoAsset = 'assets/images/logoapp.webp';

  /// Logo rộng 160dp — khớp với res/drawable/splash_icon.xml (288dp − 2×64dp)
  static const double logoSize = 160;

  /// Thời gian hiển thị tối thiểu
  static const Duration minDisplay = Duration(milliseconds: 1500);

  /// Giải mã logo trước khi Flutter vẽ frame đầu, để frame đầu đã có logo
  /// (tránh một frame trống lúc native splash vừa tắt). Gọi trong main().
  static void precacheLogoBeforeFirstFrame() {
    final binding = WidgetsBinding.instance;
    binding.deferFirstFrame();
    var released = false;
    void release() {
      if (released) return;
      released = true;
      binding.allowFirstFrame();
    }

    final stream = const AssetImage(logoAsset).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener);
        release();
      },
      onError: (_, _) {
        stream.removeListener(listener);
        release();
      },
    );
    stream.addListener(listener);
    // Phòng hờ: không bao giờ giữ frame đầu quá 1 giây
    Timer(const Duration(seconds: 1), release);
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startUp();
  }

  /// Chờ song song: thời gian tối thiểu + khôi phục phiên đăng nhập
  Future<void> _startUp() async {
    final results = await Future.wait<Object?>([
      Future<void>.delayed(SplashScreen.minDisplay),
      AuthRepository.instance.restoreSession(),
    ]);
    if (!mounted) return;
    final hasSession = results[1] == true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppDurations.pageTransition,
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSession ? const MainShellScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chữ cách đáy màn hình 48dp (tính cả thanh điều hướng). Nếu thanh điều
    // hướng 3 nút cao hơn, đẩy chữ lên để không bị che.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final wordmarkBottom =
        math.max(AppDimensions.space48, bottomInset + AppDimensions.space16);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Logo ở chính giữa toàn màn hình (không dùng SafeArea) để trùng
          // vị trí với logo của splash native.
          Center(
            child: Image.asset(
              SplashScreen.logoAsset,
              key: const Key('splash_logo'),
              width: SplashScreen.logoSize,
              height: SplashScreen.logoSize,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              semanticLabel: 'Logo KarVocab',
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: wordmarkBottom,
            child: Text.rich(
              const TextSpan(
                style: AppTypography.brandWordmark,
                children: [
                  TextSpan(text: 'Kar', style: TextStyle(color: AppColors.brandKar)),
                  TextSpan(text: 'Vocab', style: TextStyle(color: AppColors.brandVocab)),
                ],
              ),
              key: const Key('splash_wordmark'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
