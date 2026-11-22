import '../../core/constants/app_strings.dart';
import 'vocabulary_model.dart';

/// Các chế độ luyện tập. 4 chế độ đầu (Màn 08 / 19 / 25 / 20) khớp `mode` của API BE;
/// [pronunciation] và [synonymAntonym] là 2 game mới của Màn 10, BE chưa có (xem [apiKey]).
enum QuizMode {
  listenChoose,
  listenType,
  meaningChoose,
  recallType,
  pronunciation,
  synonymAntonym;

  /// Các chế độ dùng cho phiên ôn tập hỗn hợp (Màn 16): không cần micro và
  /// không cần dữ liệu đồng nghĩa / trái nghĩa, nên từ nào cũng ôn được.
  static const List<QuizMode> reviewModes = [listenChoose, listenType, meaningChoose, recallType];
}

extension QuizModeX on QuizMode {
  /// Giá trị gửi lên `GET /practice/questions?mode=...` & `POST /practice/submit-session`
  /// (theo FE-BE-ALIGNMENT mục 5: listen_choose | listen_type | choose_meaning | type_meaning)
  String get apiKey {
    switch (this) {
      case QuizMode.listenChoose:
        return 'listen_choose';
      case QuizMode.listenType:
        return 'listen_type';
      case QuizMode.meaningChoose:
        return 'choose_meaning';
      case QuizMode.recallType:
        return 'type_meaning';
      // Chưa có trong enum `QuizMode` của backend: BE cần thêm 2 giá trị này
      // trước khi nối `POST /practice/submit-session` cho 2 game mới.
      case QuizMode.pronunciation:
        return 'pronunciation';
      case QuizMode.synonymAntonym:
        return 'synonym_antonym';
    }
  }

  String get title {
    switch (this) {
      case QuizMode.listenChoose:
        return AppStrings.modeListenChoose;
      case QuizMode.listenType:
        return AppStrings.modeListenType;
      case QuizMode.meaningChoose:
        return AppStrings.modeMeaningChoose;
      case QuizMode.recallType:
        return AppStrings.modeRecallType;
      case QuizMode.pronunciation:
        return AppStrings.gamePronunciation;
      case QuizMode.synonymAntonym:
        return AppStrings.gameSynonymAntonym;
    }
  }

  /// Chế độ gõ chữ (Màn 19 & 20)
  bool get isTyping => this == QuizMode.listenType || this == QuizMode.recallType;
}

/// Kết quả chấm 1 câu trả lời.
/// `almost` = sai đúng 1 ký tự (Levenshtein = 1, từ ≥ 3 ký tự, theo BE) → vẫn tính là đúng nhưng nhắc chính tả.
enum AnswerResult { correct, almost, wrong }

/// 1 câu hỏi trong phiên luyện tập.
class QuizQuestion {
  final String id;
  final VocabularyModel vocab;
  final QuizMode mode;

  /// Danh sách 4 đáp án đã xáo trộn (chỉ dùng cho chế độ trắc nghiệm, rỗng nếu là chế độ gõ).
  final List<String> options;

  /// Đáp án đúng: `term` (mode 08/19/20, phát âm), `definitionVi` (mode 25)
  /// hoặc nhãn "Đồng nghĩa" / "Trái nghĩa" (game đồng nghĩa và trái nghĩa).
  final String correctAnswer;

  /// Game đồng nghĩa và trái nghĩa: từ được so với [vocab]. Các chế độ khác để null.
  final String? pairWord;

  const QuizQuestion({
    required this.id,
    required this.vocab,
    required this.mode,
    required this.options,
    required this.correctAnswer,
    this.pairWord,
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

  /// UUID sinh 1 lần cho mỗi phiên; gửi kèm `POST /practice/submit-session`
  /// để nếu mạng lỗi gửi lại thì server không tính hai lần.
  final String clientSessionId;

  const QuizSummary({
    required this.records,
    required this.durationSeconds,
    required this.clientSessionId,
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
