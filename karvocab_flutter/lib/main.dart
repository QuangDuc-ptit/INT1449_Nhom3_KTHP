import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: AppColors.mainBackground,
        primaryColor: AppColors.primaryBlue,
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.mainBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.mainBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
