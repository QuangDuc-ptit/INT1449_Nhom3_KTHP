import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Lý do không nghe được giọng người dùng.
enum RecognitionFailure {
  /// Máy / trình duyệt không hỗ trợ nhận dạng giọng nói.
  unavailable,

  /// Người dùng chưa cấp quyền micro.
  permissionDenied,

  /// Đã nghe nhưng không nhận ra từ nào (im lặng, ồn quá...).
  noSpeech,
}

class RecognitionException implements Exception {
  final RecognitionFailure failure;
  const RecognitionException(this.failure);

  @override
  String toString() => 'RecognitionException($failure)';
}

/// Nhận dạng giọng nói cho game "Luyện phát âm" (Màn 10).
///
/// Backend chưa có API chấm phát âm, nên FE dùng bộ nhận dạng có sẵn của thiết bị:
/// nghe một lượt, lấy các phương án chữ mà máy nghe được rồi so với từ cần đọc.
/// Tests gán [instance] bằng bản giả để không cần micro.
abstract class SpeechRecognitionService {
  static SpeechRecognitionService instance = UnavailableSpeechRecognition();

  /// Nghe một lượt bằng giọng [localeId]. Trả về các phương án nhận dạng
  /// (phương án đầu là tin cậy nhất). [onPartial] nhận chữ tạm thời khi đang nói.
  /// Ném [RecognitionException] nếu không nghe được.
  Future<List<String>> listenOnce({
    String localeId = 'en_US',
    ValueChanged<String>? onPartial,
  });

  /// Dừng nghe sớm (người dùng bấm lại nút micro).
  Future<void> stop();
}

/// Mặc định khi chưa gán bản thật (vd trong test): luôn báo không hỗ trợ.
class UnavailableSpeechRecognition implements SpeechRecognitionService {
  @override
  Future<List<String>> listenOnce({String localeId = 'en_US', ValueChanged<String>? onPartial}) =>
      Future.error(const RecognitionException(RecognitionFailure.unavailable));

  @override
  Future<void> stop() async {}
}

/// Bản thật dùng gói `speech_to_text` (Android, iOS, Chrome).
class DeviceSpeechRecognition implements SpeechRecognitionService {
  /// Nghe tối đa 6 giây, dừng sau 2 giây im lặng (đủ cho một từ / cụm từ).
  static const Duration listenFor = Duration(seconds: 6);
  static const Duration pauseFor = Duration(seconds: 2);

  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  Completer<List<String>>? _pending;
  List<String> _latest = const [];

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      _ready = await _stt.initialize(onError: (_) => _finish(), onStatus: _onStatus);
    } catch (e) {
      debugPrint('Không khởi tạo được nhận dạng giọng nói: $e');
      _ready = false;
    }
    if (!_ready) {
      final allowed = await _stt.hasPermission.catchError((_) => false);
      throw RecognitionException(
        allowed ? RecognitionFailure.unavailable : RecognitionFailure.permissionDenied,
      );
    }
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _onResult(SpeechRecognitionResult result, ValueChanged<String>? onPartial) {
    _latest = [
      for (final a in result.alternates)
        if (a.recognizedWords.trim().isNotEmpty) a.recognizedWords.trim(),
    ];
    if (_latest.isNotEmpty) onPartial?.call(_latest.first);
    if (result.finalResult) _finish();
  }

  void _finish() {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    _pending = null;
    if (_latest.isEmpty) {
      pending.completeError(const RecognitionException(RecognitionFailure.noSpeech));
    } else {
      pending.complete(_latest);
    }
  }

  @override
  Future<List<String>> listenOnce({String localeId = 'en_US', ValueChanged<String>? onPartial}) async {
    await _ensureReady();
    if (_stt.isListening) await _stt.cancel();
    _latest = const [];
    final pending = _pending = Completer<List<String>>();
    await _stt.listen(
      onResult: (r) => _onResult(r, onPartial),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
    return pending.future;
  }

  @override
  Future<void> stop() async {
    await _stt.stop();
    _finish();
  }
}
