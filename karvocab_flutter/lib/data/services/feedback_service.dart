import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Phản hồi âm thanh + rung khi trả lời (DEV2-S1-06).
///
/// Phát `assets/sounds/correct.wav` / `incorrect.wav` bằng gói `audioplayers`
/// (chạy được trên Android, iOS và web). Hai file do nhóm tự tạo bằng script
/// nên không vướng bản quyền. Rung chỉ có tác dụng trên điện thoại.
class FeedbackService {
  FeedbackService();

  /// Có thể thay thế (ví dụ bản im lặng khi chạy test).
  static FeedbackService instance = FeedbackService();

  static const String correctSound = 'sounds/correct.wav';
  static const String incorrectSound = 'sounds/incorrect.wav';

  bool soundEnabled = true;
  bool hapticEnabled = true;

  // Mỗi âm một player riêng để bấm liên tục không bị cắt tiếng của nhau.
  // Tạo khi cần (lazy) để không gọi plugin lúc chưa phát gì.
  AudioPlayer? _correctPlayer;
  AudioPlayer? _incorrectPlayer;

  Future<void> playCorrect() async {
    if (soundEnabled) {
      _correctPlayer ??= AudioPlayer();
      await _play(_correctPlayer!, correctSound);
    }
    if (hapticEnabled) await HapticFeedback.lightImpact();
  }

  Future<void> playIncorrect() async {
    if (soundEnabled) {
      _incorrectPlayer ??= AudioPlayer();
      await _play(_incorrectPlayer!, incorrectSound);
    }
    if (hapticEnabled) await HapticFeedback.heavyImpact();
  }

  /// Lỗi phát âm thanh (thiếu plugin, trình duyệt chặn tự phát...) không được
  /// làm hỏng phiên quiz, nên chỉ ghi log.
  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('FeedbackService: không phát được $asset ($e)');
    }
  }

  Future<void> dispose() async {
    await _correctPlayer?.dispose();
    await _incorrectPlayer?.dispose();
  }
}
