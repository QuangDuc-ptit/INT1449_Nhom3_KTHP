import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'pronunciation_service.dart';
import 'speech_service.dart';

/// Phát âm bằng TTS có sẵn của thiết bị (gói `flutter_tts`): Android, iOS và web.
///
/// Đây là phương án dự phòng trong FE spec (Audio Quick Play) và FE-BE-ALIGNMENT
/// (từ chưa có audio thì FE dùng TTS của máy). Vì đọc trực tiếp chữ của từ nên
/// từ vừa tạo thủ công hay bằng AI đều phát âm được ngay, không cần chờ file mp3.
/// Khi nối backend (Sprint 3), từ có `audioUkUrl`/`audioUsUrl` sẽ phát file đó,
/// còn lại vẫn dùng lớp này.
class DeviceTts {
  DeviceTts._();

  static final DeviceTts instance = DeviceTts._();

  /// Giới hạn chờ một lần đọc, để nút loa không kẹt ở trạng thái "đang phát"
  /// nếu máy không báo đọc xong (một số trình duyệt / máy thiếu giọng tiếng Anh).
  static const Duration speakTimeout = Duration(seconds: 8);

  /// Android: 0.5 là tốc độ thường; đọc chậm hơn một chút cho người học.
  static const double androidSpeechRate = 0.42;

  final FlutterTts _tts = FlutterTts();
  Future<void>? _setup;

  Future<void> _ensureSetup() => _setup ??= () async {
        await _tts.awaitSpeakCompletion(true);
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          await _tts.setSpeechRate(androidSpeechRate);
        }
      }();

  /// Đọc [text] bằng giọng [language] (vd `en-GB`, `en-US`); xong mới trả về.
  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (text.trim().isEmpty) return;
    try {
      await _ensureSetup();
      await _tts.stop();
      await _tts.setLanguage(language);
      await _tts.speak(text).timeout(speakTimeout);
    } on TimeoutException {
      await stop();
    } catch (e) {
      // Thiếu engine TTS / giọng tiếng Anh: không làm hỏng màn hình, chỉ ghi log.
      debugPrint('DeviceTts: không đọc được "$text" ($e)');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static String languageOf(Accent accent) => accent == Accent.uk ? 'en-GB' : 'en-US';
}

/// [PronunciationEngine] cho Thư viện / Chi tiết từ (Màn 06, 07): giọng UK hoặc US.
class DeviceTtsPronunciationEngine implements PronunciationEngine {
  const DeviceTtsPronunciationEngine();

  @override
  Future<void> speak(String text, Accent accent) =>
      DeviceTts.instance.speak(text, language: DeviceTts.languageOf(accent));

  @override
  Future<void> stop() => DeviceTts.instance.stop();
}

/// [SpeechService] cho các chế độ "Nghe" trong quiz (Track B).
class DeviceTtsSpeechService implements SpeechService {
  @override
  Future<void> speak(String text) => DeviceTts.instance.speak(text);
}
