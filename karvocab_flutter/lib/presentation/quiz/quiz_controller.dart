import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/fuzzy_match.dart';
import '../../core/utils/session_id.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/quiz_settings_store.dart';
import '../../data/services/feedback_service.dart';

/// Quiz Engine Controller (DEV2-S1-01): state machine của 1 phiên luyện tập.
/// Trạng thái: đang trả lời → đã trả lời (hiện banner Màn 11) → câu kế → kết thúc.
///
/// Mỗi câu có đồng hồ đếm ngược theo trò chơi ([QuizSettingsStore.timeLimitFor]).
/// 5 giây cuối phát tiếng tích tắc; hết giờ thì câu đó tính là sai.
class QuizController extends ChangeNotifier {
  QuizController({
    required this.questions,
    this.isRetry = false,
    FeedbackService? feedback,
    QuizSettingsStore? settings,
  })  : _feedback = feedback ?? FeedbackService.instance,
        _settings = settings ?? QuizSettingsStore.instance {
    _total.start();
    _question.start();
    if (questions.isNotEmpty) _startTimer();
  }

  final List<QuizQuestion> questions;
  final bool isRetry;
  final FeedbackService _feedback;
  final QuizSettingsStore _settings;

  Timer? _ticker;
  int? _timeLimit;
  int _remaining = 0;
  bool _paused = false;

  /// UUID của phiên, gửi kèm khi nộp bài.
  final String clientSessionId = generateClientSessionId();

  final Stopwatch _total = Stopwatch();
  final Stopwatch _question = Stopwatch();
  final List<QuizAnswerRecord> _records = [];

  int _index = 0;
  QuizAnswerRecord? _lastRecord;

  int get index => _index;
  int get total => questions.length;
  QuizQuestion get current => questions[_index];
  QuizAnswerRecord? get lastRecord => _lastRecord;
  bool get isAnswered => _lastRecord != null;
  bool get isLast => _index >= questions.length - 1;
  double get progress => total == 0 ? 0 : (_index + (isAnswered ? 1 : 0)) / total;
  List<QuizAnswerRecord> get records => List.unmodifiable(_records);

  /// Số giây của câu hiện tại, `null` khi người dùng tắt đếm ngược.
  int? get timeLimit => _timeLimit;
  bool get isTimed => _timeLimit != null;

  /// Số giây còn lại của câu hiện tại (đứng yên sau khi đã trả lời).
  int get remainingSeconds => _remaining;

  /// Tỉ lệ thời gian còn lại 0 – 1 (dùng cho thanh đếm ngược).
  double get remainingRatio =>
      (_timeLimit ?? 0) == 0 ? 0 : (_remaining / _timeLimit!).clamp(0.0, 1.0);

  /// Đang ở 5 giây cuối và chưa trả lời.
  bool get isTimeWarning =>
      isTimed && !isAnswered && _remaining <= QuizSettingsStore.warningSeconds;

  bool get isPaused => _paused;

  /// Chế độ trắc nghiệm: so khớp tuyệt đối với đáp án đúng.
  void submitChoice(String option) {
    if (isAnswered) return;
    final isRight = option == current.correctAnswer;
    _commit(option, isRight ? AnswerResult.correct : AnswerResult.wrong);
  }

  /// Chế độ gõ chữ: trim + lowercase + fuzzy matching (Levenshtein = 1 với từ ≥ 3 ký tự).
  void submitTyped(String text) {
    if (isAnswered || text.trim().isEmpty) return;
    _commit(text.trim(), evaluateTypedAnswer(text, current.correctAnswer));
  }

  /// Game phát âm: chấm từng phương án máy nghe được, lấy kết quả tốt nhất.
  void submitSpoken(List<String> alternatives) {
    if (isAnswered || alternatives.isEmpty) return;
    var best = alternatives.first;
    var bestResult = AnswerResult.wrong;
    for (final heard in alternatives) {
      final result = evaluateTypedAnswer(heard, current.correctAnswer);
      if (result.index < bestResult.index) {
        best = heard;
        bestResult = result;
      }
    }
    _commit(best, bestResult);
  }

  /// Bỏ qua câu hiện tại (vd máy không nhận dạng được giọng): tính là sai.
  void skip() {
    if (isAnswered) return;
    _commit('', AnswerResult.wrong);
  }

  /// Tạm dừng đồng hồ (vd khi mở hộp thoại thoát hoặc chỉnh âm lượng).
  void pause() {
    if (_paused) return;
    _paused = true;
    _question.stop();
    _total.stop();
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _total.start();
    if (!isAnswered) _question.start();
    notifyListeners();
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = null;
    _timeLimit = _settings.timeLimitFor(current.mode);
    final limit = _timeLimit;
    if (limit == null) return;
    _remaining = limit;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (_paused || isAnswered) return;
    _remaining -= 1;
    if (_remaining <= 0) {
      _remaining = 0;
      _commit('', AnswerResult.wrong, timedOut: true);
      return;
    }
    if (_remaining <= QuizSettingsStore.warningSeconds) {
      _feedback.volume = _settings.volume;
      _feedback.playTick();
    }
    notifyListeners();
  }

  void _commit(String userAnswer, AnswerResult result, {bool timedOut = false}) {
    _ticker?.cancel();
    _ticker = null;
    _question.stop();
    _lastRecord = QuizAnswerRecord(
      question: current,
      userAnswer: userAnswer,
      result: result,
      responseTimeMs: _question.elapsedMilliseconds,
      timedOut: timedOut,
    );
    _records.add(_lastRecord!);

    _feedback.volume = _settings.volume;
    if (result == AnswerResult.wrong) {
      _feedback.playIncorrect();
    } else {
      _feedback.playCorrect();
    }
    notifyListeners();
  }

  /// Sang câu kế tiếp. Trả về `false` nếu đã hết câu hỏi.
  bool next() {
    if (!isAnswered) return true;
    if (isLast) return false;
    _index += 1;
    _lastRecord = null;
    _question.reset();
    if (!_paused) _question.start();
    _startTimer();
    notifyListeners();
    return true;
  }

  QuizSummary buildSummary() {
    _ticker?.cancel();
    _total.stop();
    return QuizSummary(
      records: List.of(_records),
      durationSeconds: _total.elapsed.inSeconds,
      clientSessionId: clientSessionId,
      isRetry: isRetry,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
