import 'package:flutter/foundation.dart';

import '../local/local_store.dart';
import '../models/quiz_models.dart';

/// Cài đặt khi làm bài (Màn 10): thời gian đếm ngược mỗi câu theo từng trò chơi
/// và âm lượng hiệu ứng (đúng / sai / tích tắc).
///
/// Có [storage] thì cài đặt được lưu trên máy; Sprint 3 có thể đồng bộ cùng `PATCH /users/me/settings`.
class QuizSettingsStore extends ChangeNotifier {
  QuizSettingsStore({this._storage}) {
    _restore();
  }

  /// Instance dùng chung toàn app. Test tạo instance riêng rồi truyền vào màn hình.
  static QuizSettingsStore instance = QuizSettingsStore(storage: LocalStore.app);

  final LocalStore? _storage;

  /// Thời gian mặc định (giây) cho mỗi câu, theo độ khó của từng trò:
  /// trò chọn đáp án nhanh hơn, trò phải gõ hoặc nói cần nhiều thời gian hơn.
  static const Map<QuizMode, int> defaultSeconds = {
    QuizMode.listenChoose: 25, // nghe rồi chọn 1 trong 4 từ
    QuizMode.meaningChoose: 35, // đọc 4 nghĩa tiếng Việt rồi chọn
    QuizMode.synonymAntonym: 20, // chỉ có 2 lựa chọn
    QuizMode.listenType: 40, // nghe (có thể nghe lại) rồi gõ
    QuizMode.recallType: 45, // nhớ lại từ từ nghĩa rồi gõ
    QuizMode.pronunciation: 30, // bấm micro, đọc, chờ nhận dạng
  };

  static const int minSeconds = 10;
  static const int maxSeconds = 120;
  static const int stepSeconds = 5;

  /// Còn bao nhiêu giây thì bắt đầu phát tiếng tích tắc.
  static const int warningSeconds = 5;

  static const double defaultVolume = 0.7;
  static const double volumeStep = 0.1;

  bool _timerEnabled = true;
  final Map<QuizMode, int> _seconds = Map.of(defaultSeconds);
  double _volume = defaultVolume;

  bool get timerEnabled => _timerEnabled;

  /// Âm lượng hiệu ứng 0.0 – 1.0 (0 = tắt tiếng).
  double get volume => _volume;

  /// Âm lượng dạng phần trăm để hiển thị (0 – 100).
  int get volumePercent => (_volume * 100).round();

  int secondsFor(QuizMode mode) => _seconds[mode] ?? defaultSeconds[mode]!;

  /// Thời gian của câu hỏi [mode], hoặc `null` khi đã tắt đếm ngược.
  int? timeLimitFor(QuizMode mode) => _timerEnabled ? secondsFor(mode) : null;

  bool get isDefault =>
      _timerEnabled &&
      _volume == defaultVolume &&
      defaultSeconds.entries.every((e) => _seconds[e.key] == e.value);

  void setTimerEnabled(bool value) {
    if (_timerEnabled == value) return;
    _timerEnabled = value;
    notifyListeners();
  }

  /// Đặt thời gian cho [mode], làm tròn theo bước 5 giây và giữ trong 10 – 120 giây.
  void setSeconds(QuizMode mode, int seconds) {
    final rounded = (seconds / stepSeconds).round() * stepSeconds;
    final value = rounded.clamp(minSeconds, maxSeconds);
    if (_seconds[mode] == value) return;
    _seconds[mode] = value;
    notifyListeners();
  }

  void increaseSeconds(QuizMode mode) => setSeconds(mode, secondsFor(mode) + stepSeconds);
  void decreaseSeconds(QuizMode mode) => setSeconds(mode, secondsFor(mode) - stepSeconds);

  void setVolume(double value) {
    // Làm tròn 2 chữ số để bấm +/- nhiều lần không bị sai số 0.30000000000000004
    final v = (value.clamp(0.0, 1.0) * 100).round() / 100;
    if (_volume == v) return;
    _volume = v;
    notifyListeners();
  }

  void increaseVolume() => setVolume(_volume + volumeStep);
  void decreaseVolume() => setVolume(_volume - volumeStep);

  void resetDefaults() {
    _timerEnabled = true;
    _seconds
      ..clear()
      ..addAll(defaultSeconds);
    _volume = defaultVolume;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    _storage?.writeJson(StorageKeys.quizSettings, {
      'timerEnabled': _timerEnabled,
      'volume': _volume,
      'seconds': {for (final e in _seconds.entries) e.key.name: e.value},
    });
    super.notifyListeners();
  }

  void _restore() {
    final data = _storage?.readJson(StorageKeys.quizSettings);
    if (data is! Map<String, dynamic>) return;
    _timerEnabled = (data['timerEnabled'] as bool?) ?? true;
    _volume = ((data['volume'] as num?)?.toDouble() ?? defaultVolume).clamp(0.0, 1.0);
    final seconds = data['seconds'];
    if (seconds is Map<String, dynamic>) {
      for (final mode in QuizMode.values) {
        final v = seconds[mode.name];
        if (v is num) _seconds[mode] = v.toInt().clamp(minSeconds, maxSeconds);
      }
    }
  }
}
