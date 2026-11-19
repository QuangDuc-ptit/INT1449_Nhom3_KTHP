import 'vocabulary_model.dart';

/// 4 chế độ luyện tập (Màn 08 / 19 / 25 / 20) — khớp `mode` của API BE.
enum QuizMode { listenChoose, listenType, meaningChoose, recallType }

extension QuizModeX on QuizMode {
  /// Giá trị gửi lên `GET /practice/questions?mode=...` & `POST /practice/submit-session`
  String get apiKey {
    switch (this) {
      case QuizMode.listenChoose:
        return 'listen_choose';
      case QuizMode.listenType:
        return 'listen_type';
      case QuizMode.meaningChoose:
        return 'meaning_choose';
      case QuizMode.recallType:
        return 'recall_type';
    }
  }

  String get title {
    switch (this) {
      case QuizMode.listenChoose:
        return 'Nghe chọn từ';
      case QuizMode.listenType:
        return 'Nghe và điền từ';
      case QuizMode.meaningChoose:
        return 'Chọn nghĩa đúng';
      case QuizMode.recallType:
        return 'Nhớ từ qua nghĩa';
    }
  }

  String get description {
    switch (this) {
      case QuizMode.listenChoose:
        return 'Nghe phát âm rồi chọn từ đúng trong 4 đáp án.';
      case QuizMode.listenType:
        return 'Nghe phát âm và gõ chính xác chính tả của từ.';
      case QuizMode.meaningChoose:
        return 'Xem từ tiếng Anh, chọn nghĩa tiếng Việt chính xác.';
      case QuizMode.recallType:
        return 'Đọc nghĩa tiếng Việt, gõ lại từ tiếng Anh tương ứng.';
    }
  }

  /// Chế độ gõ chữ (Màn 19 & 20)
  bool get isTyping => this == QuizMode.listenType || this == QuizMode.recallType;
}

/// Kết quả chấm 1 câu trả lời.
/// `almost` = sai đúng 1 ký tự (Levenshtein = 1, từ dài > 6) → vẫn tính là đúng nhưng nhắc chính tả.
enum AnswerResult { correct, almost, wrong }

/// 1 câu hỏi trong phiên luyện tập.
class QuizQuestion {
  final String id;
  final VocabularyModel vocab;
  final QuizMode mode;

  /// Danh sách 4 đáp án đã xáo trộn (chỉ dùng cho chế độ trắc nghiệm, rỗng nếu là chế độ gõ).
  final List<String> options;

  /// Đáp án đúng: `term` (mode 08/19/20) hoặc `definitionVi` (mode 25).
  final String correctAnswer;

  const QuizQuestion({
    required this.id,
    required this.vocab,
    required this.mode,
    required this.options,
    required this.correctAnswer,
  });
}

/// Bản ghi trả lời 1 câu — khớp phần tử `answers[]` của `POST /practice/submit-session`.
class QuizAnswerRecord {
  final QuizQuestion question;
  final String userAnswer;
  final AnswerResult result;
  final int responseTimeMs;

  const QuizAnswerRecord({
    required this.question,
    required this.userAnswer,
    required this.result,
    required this.responseTimeMs,
  });

  bool get isCorrect => result != AnswerResult.wrong;
}

/// Tổng kết phiên luyện tập (Màn 12).
class QuizSummary {
  final List<QuizAnswerRecord> records;
  final int durationSeconds;
  final bool isRetry;

  const QuizSummary({
    required this.records,
    required this.durationSeconds,
    this.isRetry = false,
  });

  int get total => records.length;
  int get correctCount => records.where((r) => r.isCorrect).length;
  int get wrongCount => total - correctCount;

  /// Tỉ lệ chính xác 0–100
  double get accuracyPercent => total == 0 ? 0 : correctCount * 100 / total;

  List<QuizQuestion> get missedQuestions =>
      records.where((r) => !r.isCorrect).map((r) => r.question).toList();
}
