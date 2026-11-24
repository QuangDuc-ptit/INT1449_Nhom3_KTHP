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

  /// Tiếng tích tắc mỗi giây khi câu hỏi sắp hết giờ (5 giây cuối).
  static const String tickSound = 'sounds/tick.wav';

  bool soundEnabled = true;
  bool hapticEnabled = true;

  /// Âm lượng hiệu ứng 0.0 – 1.0, lấy từ cài đặt của người dùng (Màn 10).
  double volume = 1.0;

  // Mỗi âm một player riêng để bấm liên tục không bị cắt tiếng của nhau.
  // Tạo khi cần (lazy) để không gọi plugin lúc chưa phát gì.
  AudioPlayer? _correctPlayer;
  AudioPlayer? _incorrectPlayer;
  AudioPlayer? _tickPlayer;

  Future<void> playCorrect() async {
    if (soundEnabled) {
      _correctPlayer ??= _newPlayer();
      await _play(_correctPlayer, correctSound);
    }
    if (hapticEnabled) await HapticFeedback.lightImpact();
  }

  Future<void> playIncorrect() async {
    if (soundEnabled) {
      _incorrectPlayer ??= _newPlayer();
      await _play(_incorrectPlayer, incorrectSound);
    }
    if (hapticEnabled) await HapticFeedback.heavyImpact();
  }

  /// Một tiếng tích tắc của đồng hồ đếm ngược (không rung để khỏi làm phiền).
  Future<void> playTick() async {
    if (!soundEnabled) return;
    _tickPlayer ??= _newPlayer();
    await _play(_tickPlayer, tickSound);
  }

  /// Tạo player; nền tảng không có plugin (vd khi chạy test) thì trả `null`.
  AudioPlayer? _newPlayer() {
    try {
      return AudioPlayer();
    } catch (e) {
      debugPrint('FeedbackService: không tạo được AudioPlayer ($e)');
      return null;
    }
  }

  /// Lỗi phát âm thanh (thiếu plugin, trình duyệt chặn tự phát...) không được
  /// làm hỏng phiên quiz, nên chỉ ghi log.
  Future<void> _play(AudioPlayer? player, String asset) async {
    if (player == null || volume <= 0) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('FeedbackService: không phát được $asset ($e)');
    }
  }

  Future<void> dispose() async {
    await _correctPlayer?.dispose();
    await _incorrectPlayer?.dispose();
    await _tickPlayer?.dispose();
  }
}
