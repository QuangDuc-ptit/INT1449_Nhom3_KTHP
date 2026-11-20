import 'package:flutter/foundation.dart';
import '../models/vocabulary_model.dart';

/// Giọng phát âm chuẩn (Màn 07: UK / US).
enum Accent { uk, us }

extension AccentLabel on Accent {
  String get label => this == Accent.uk ? 'UK' : 'US';
}

/// Bộ máy phát âm thực tế. Bản mặc định là giả lập để chạy offline/Demo không cần package.
/// Khi nhóm thêm `flutter_tts` hoặc `just_audio`, chỉ cần viết một class implement
/// [PronunciationEngine] và gán vào [PronunciationService.instance] trong `main()`.
abstract class PronunciationEngine {
  Future<void> speak(String text, Accent accent);
  Future<void> stop();
}

class SimulatedPronunciationEngine implements PronunciationEngine {
  final Duration duration;
  const SimulatedPronunciationEngine({this.duration = const Duration(milliseconds: 1100)});

  @override
  Future<void> speak(String text, Accent accent) => Future<void>.delayed(duration);

  @override
  Future<void> stop() async {}
}

/// Audio Player Service của Track A (Màn 06, 07).
/// Quản lý từ nào đang phát để UI hiển thị hiệu ứng sóng âm, chặn phát chồng nhiều từ,
/// và ghi nhớ các từ đã phát (bộ đệm — khi có file mp3 thật sẽ lưu đường dẫn cache).
class PronunciationService extends ChangeNotifier {
  PronunciationService(this._engine);

  static PronunciationService instance = PronunciationService(const SimulatedPronunciationEngine());

  final PronunciationEngine _engine;
  final Set<String> _cachedKeys = {};

  String? _playingWordId;
  Accent _accent = Accent.uk;

  String? get playingWordId => _playingWordId;
  Accent get accent => _accent;
  bool isPlaying(String wordId) => _playingWordId == wordId;
  bool isCached(String term, Accent accent) => _cachedKeys.contains(_key(term, accent));

  set accent(Accent value) {
    if (_accent == value) return;
    _accent = value;
    notifyListeners();
  }

  /// Phát âm [word]. Nếu đang phát từ khác thì dừng từ đó trước.
  Future<void> play(VocabularyModel word, {Accent? accent}) async {
    final useAccent = accent ?? _accent;
    if (_playingWordId == word.id) return;
    if (_playingWordId != null) await _engine.stop();

    _playingWordId = word.id;
    notifyListeners();
    try {
      await _engine.speak(word.term, useAccent);
      _cachedKeys.add(_key(word.term, useAccent));
    } finally {
      // Chỉ xoá trạng thái nếu không có từ khác chen vào trong lúc phát.
      if (_playingWordId == word.id) {
        _playingWordId = null;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    await _engine.stop();
    if (_playingWordId != null) {
      _playingWordId = null;
      notifyListeners();
    }
  }

  String _key(String term, Accent accent) => '${term.toLowerCase()}#${accent.name}';
}
