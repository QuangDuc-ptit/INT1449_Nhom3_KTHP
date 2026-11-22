import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'data/repositories/track_sync.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Màn 01: giải mã logo trước frame đầu để nối liền với splash native
  SplashScreen.precacheLogoBeforeFirstFrame();
  // Đồng bộ mục tiêu ngày và streak giữa Track A và Track B
  TrackSync.attach();
  runApp(const KarVocabApp());
}

/// Ứng dụng KarVocab — Learn Smart, Remember Longer
/// Khung đồ án INT1449 Lập trình di động (Flutter)
class KarVocabApp extends StatelessWidget {
  const KarVocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KarVocab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryBlue,
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
