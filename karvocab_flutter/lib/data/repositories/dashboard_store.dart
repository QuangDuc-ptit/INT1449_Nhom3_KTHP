import 'package:flutter/foundation.dart';

import '../mock/mock_vocab_data.dart';
import '../models/quiz_models.dart';
import '../models/user_profile_model.dart';
import '../models/vocabulary_model.dart';

/// Tiến độ Spaced Repetition của 1 từ (bảng USER_VOCAB_PROGRESS phía BE).
class SrsProgress {
  final int repetitionLevel; // 0..5
  final int intervalDays;
  final double easeFactor; // 1.3..2.5
  final DateTime nextReviewAt;
  final bool mastered;

  const SrsProgress({
    required this.repetitionLevel,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewAt,
    required this.mastered,
  });
}

/// Thuật toán SM-2 biến thể theo BE-SPECIFICATION mục 4.1 (dùng offline cho chế độ Demo).
class Sm2Engine {
  static const List<int> intervals = [1, 3, 7, 16, 35];

  static SrsProgress initial(DateTime nextReviewAt) => SrsProgress(
        repetitionLevel: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewAt: nextReviewAt,
        mastered: false,
      );

  static SrsProgress apply(SrsProgress old, bool isCorrect, DateTime now) {
    if (isCorrect) {
      final level = old.repetitionLevel + 1;
      final interval = intervals[(level > 5 ? 5 : level) - 1];
      final ease = old.easeFactor + 0.1 > 2.5 ? 2.5 : old.easeFactor + 0.1;
      return SrsProgress(
        repetitionLevel: level,
        intervalDays: interval,
        easeFactor: ease,
        nextReviewAt: now.add(Duration(days: interval)),
        mastered: level >= 5,
      );
    }
    final ease = old.easeFactor - 0.2 < 1.3 ? 1.3 : old.easeFactor - 0.2;
    return SrsProgress(
      repetitionLevel: 0,
      intervalDays: 1,
      easeFactor: ease,
      nextReviewAt: now.add(const Duration(days: 1)),
      mastered: false,
    );
  }
}

/// Store trung tâm cho Trang chủ (Màn 04) & Hàng đợi ôn tập (Màn 16).
/// Cầu nối với Quiz: sau mỗi phiên chỉ cần gọi `recordSessionResult(summary)`.
class DashboardStore extends ChangeNotifier {
  DashboardStore._() {
    _seed();
  }

  static final DashboardStore instance = DashboardStore._();

  /// Dùng trong unit test để có store sạch.
  @visibleForTesting
  DashboardStore.forTest() {
    _seed();
  }

  int _streak = 0;
  int _dailyGoal = 10;
  int _reviewedToday = 0;
  bool _studiedToday = false;
  final Map<String, SrsProgress> _progress = {};

  int get streak => _streak;
  int get dailyGoal => _dailyGoal;
  int get reviewedToday => _reviewedToday;
  bool get studiedToday => _studiedToday;

  double get goalRatio =>
      _dailyGoal == 0 ? 0 : (_reviewedToday / _dailyGoal).clamp(0.0, 1.0);
  bool get goalReached => _reviewedToday >= _dailyGoal;

  SrsProgress? progressOf(String vocabId) => _progress[vocabId];

  /// Các từ đến hạn ôn: `next_review_at <= NOW` và chưa mastered.
  List<VocabularyModel> get dueVocabularies {
    final now = DateTime.now();
    final due = MockVocabData.initialVocabularies.where((v) {
      final p = _progress[v.id];
      return p != null && !p.mastered && !p.nextReviewAt.isAfter(now);
    }).toList();
    due.sort((a, b) =>
        _progress[a.id]!.nextReviewAt.compareTo(_progress[b.id]!.nextReviewAt));
    return due;
  }

  void _seed() {
    final profile = UserProfileModel.mockDefault();
    _streak = profile.currentStreak;
    _dailyGoal = profile.dailyGoalWords;
    _reviewedToday = 4;
    _studiedToday = false;
    _progress.clear();

    final now = DateTime.now();
    final vocabs = MockVocabData.initialVocabularies;
    for (var i = 0; i < vocabs.length; i++) {
      // 6 từ đầu đã đến hạn ôn, các từ còn lại hẹn trong những ngày tới.
      final next = i < 6
          ? now.subtract(Duration(hours: i + 1))
          : now.add(Duration(days: (i % 3) + 1));
      _progress[vocabs[i].id] = Sm2Engine.initial(next);
    }
  }

  void setDailyGoal(int value) {
    _dailyGoal = value;
    notifyListeners();
  }

  /// Gọi khi kết thúc 1 phiên quiz: cập nhật SM-2, tiến độ ngày và streak.
  void recordSessionResult(QuizSummary summary) {
    final now = DateTime.now();

    for (final r in summary.records) {
      final old = _progress[r.question.vocab.id] ??
          Sm2Engine.initial(now);
      _progress[r.question.vocab.id] = Sm2Engine.apply(old, r.isCorrect, now);
    }

    // Phiên "Thử lại câu sai" không cộng lại vào mục tiêu ngày để tránh đếm đôi.
    if (!summary.isRetry) {
      _reviewedToday += summary.total;
      // Duy trì streak: ≥ 1 phiên với tối thiểu 5 từ trong ngày.
      if (!_studiedToday && summary.total >= 5) {
        _studiedToday = true;
        _streak += 1;
      }
    }
    notifyListeners();
  }
}
