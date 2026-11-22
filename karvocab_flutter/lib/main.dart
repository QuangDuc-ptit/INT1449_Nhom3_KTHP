import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/track_sync.dart';
import 'data/services/device_tts_service.dart';
import 'data/services/pronunciation_service.dart';
import 'data/services/speech_recognition_service.dart';
import 'data/services/speech_service.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Màn 01: giải mã logo trước frame đầu để nối liền với splash native
  SplashScreen.precacheLogoBeforeFirstFrame();
  // Đồng bộ mục tiêu ngày và streak giữa Track A và Track B
  TrackSync.attach();
  // Phát âm thật bằng TTS của thiết bị (thay bản giả lập): Thư viện, Chi tiết từ và quiz Nghe.
  PronunciationService.instance = PronunciationService(const DeviceTtsPronunciationEngine());
  SpeechService.instance = DeviceTtsSpeechService();
  SpeechRecognitionService.instance = DeviceSpeechRecognition();
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
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
