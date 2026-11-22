import 'package:flutter/foundation.dart';

import '../../core/utils/fuzzy_match.dart';
import '../../core/utils/session_id.dart';
import '../../data/models/quiz_models.dart';
import '../../data/services/feedback_service.dart';

/// Quiz Engine Controller (DEV2-S1-01): state machine của 1 phiên luyện tập.
/// Trạng thái: đang trả lời → đã trả lời (hiện banner Màn 11) → câu kế → kết thúc.
class QuizController extends ChangeNotifier {
  QuizController({
    required this.questions,
    this.isRetry = false,
    FeedbackService? feedback,
  }) : _feedback = feedback ?? FeedbackService.instance {
    _total.start();
    _question.start();
  }

  final List<QuizQuestion> questions;
  final bool isRetry;
  final FeedbackService _feedback;

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

  void _commit(String userAnswer, AnswerResult result) {
    _question.stop();
    _lastRecord = QuizAnswerRecord(
      question: current,
      userAnswer: userAnswer,
      result: result,
      responseTimeMs: _question.elapsedMilliseconds,
    );
    _records.add(_lastRecord!);

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
    _question
      ..reset()
      ..start();
    notifyListeners();
    return true;
  }

  QuizSummary buildSummary() {
    _total.stop();
    return QuizSummary(
      records: List.of(_records),
      durationSeconds: _total.elapsed.inSeconds,
      clientSessionId: clientSessionId,
      isRetry: isRetry,
    );
  }
}
