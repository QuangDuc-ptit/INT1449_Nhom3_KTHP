import 'package:flutter/services.dart';

/// Phản hồi âm thanh + rung khi trả lời (DEV2-S1-06).
/// Dùng SystemSound & Haptic có sẵn của Flutter nên không cần thêm package/asset.
/// Nếu muốn đúng file `correct.mp3` / `incorrect.mp3` theo đặc tả, thay phần SystemSound
/// bằng gói audioplayers (xem hướng dẫn).
class FeedbackService {
  FeedbackService();

  /// Có thể thay thế (ví dụ bản im lặng khi chạy test).
  static FeedbackService instance = FeedbackService();

  bool soundEnabled = true;
  bool hapticEnabled = true;

  Future<void> playCorrect() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.click);
    if (hapticEnabled) await HapticFeedback.lightImpact();
  }

  Future<void> playIncorrect() async {
    if (hapticEnabled) await HapticFeedback.heavyImpact();
  }
}
