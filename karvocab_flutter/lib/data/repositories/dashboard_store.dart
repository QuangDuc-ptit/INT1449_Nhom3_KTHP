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

  /// Level cao nhất (BE `MAX_LEVEL`); đạt level này là mastered.
  static const int maxLevel = 5;

  static SrsProgress initial(DateTime nextReviewAt) => SrsProgress(
        repetitionLevel: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewAt: nextReviewAt,
        mastered: false,
      );

  static SrsProgress apply(SrsProgress old, bool isCorrect, DateTime now) {
    if (isCorrect) {
      // Giữ level trong 0..5 như BE (sm2.ts), mastered vẫn ôn lại sau 35 ngày
      final level = old.repetitionLevel + 1 > maxLevel ? maxLevel : old.repetitionLevel + 1;
      final interval = intervals[level - 1];
      final ease = _round2(old.easeFactor + 0.1 > 2.5 ? 2.5 : old.easeFactor + 0.1);
      return SrsProgress(
        repetitionLevel: level,
        intervalDays: interval,
        easeFactor: ease,
        nextReviewAt: now.add(Duration(days: interval)),
        mastered: level == maxLevel,
      );
    }
    final ease = _round2(old.easeFactor - 0.2 < 1.3 ? 1.3 : old.easeFactor - 0.2);
    return SrsProgress(
      repetitionLevel: 0,
      intervalDays: 1,
      easeFactor: ease,
      nextReviewAt: now.add(const Duration(days: 1)),
      mastered: false,
    );
  }

  /// Làm tròn 2 chữ số thập phân như BE (`Math.round(n * 100) / 100`).
  static double _round2(double n) => (n * 100).round() / 100;
}

/// Ngày địa phương (bỏ giờ) để so sánh streak và mục tiêu ngày.
DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Ngày liền trước (không trừ 24 giờ để tránh lệch ngày khi đổi giờ mùa hè).
DateTime _previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// Store trung tâm cho Trang chủ (Màn 04) & Hàng đợi ôn tập (Màn 16).
/// Cầu nối với Quiz: sau mỗi phiên chỉ cần gọi `recordSessionResult(summary)`.
/// Luật tính mục tiêu ngày, streak và SM-2 giữ giống BE (dashboard.service.ts,
/// streak.ts, sm2.ts) để khi nối API số liệu không đổi.
class DashboardStore extends ChangeNotifier {
  DashboardStore._() : _clock = DateTime.now {
    _seed();
  }

  static final DashboardStore instance = DashboardStore._();

  /// Dùng trong unit test để có store sạch. [clock] cho phép giả lập sang ngày mới.
  @visibleForTesting
  DashboardStore.forTest({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
  }

  final DateTime Function() _clock;

  int _streak = 0;
  int _highestStreak = 0;

  /// Ngày gần nhất có học (BE `lastStreakDate`), null nếu chưa học lần nào.
  DateTime? _lastStreakDate;

  int _dailyGoal = 10;

  /// Ngày mà [_learnedTodayIds] đang tính; sang ngày khác thì đếm lại từ 0.
  DateTime? _learnedDay;

  /// Số từ mẫu "đã học sáng nay" của dữ liệu Demo (chỉ tính trong ngày seed).
  int _seedLearnedCount = 0;

  /// Các từ khác nhau đã trả lời đúng trong ngày (BE đếm distinct vocabularyId).
  final Set<String> _learnedTodayIds = {};

  final Map<String, SrsProgress> _progress = {};

  DateTime get _today => _dateOnly(_clock());

  /// Streak hiện tại. Bỏ trọn một ngày không học thì về 0 (như job streak-reset của BE).
  int get streak {
    final last = _lastStreakDate;
    if (last == null) return 0;
    final yesterday = _previousDay(_today);
    return last.isBefore(yesterday) ? 0 : _streak;
  }

  int get highestStreak => _highestStreak;
  int get dailyGoal => _dailyGoal;

  /// Số từ khác nhau trả lời đúng hôm nay (BE `wordsLearnedToday`).
  int get reviewedToday =>
      _learnedDay == _today ? _seedLearnedCount + _learnedTodayIds.length : 0;

  /// BE `isStreakActiveToday`: hôm nay đã hoàn thành ít nhất một phiên.
  bool get studiedToday => _lastStreakDate == _today;

  double get goalRatio =>
      _dailyGoal == 0 ? 0 : (reviewedToday / _dailyGoal).clamp(0.0, 1.0);
  bool get goalReached => reviewedToday >= _dailyGoal;

  SrsProgress? progressOf(String vocabId) => _progress[vocabId];

  /// Các từ đến hạn ôn: `next_review_at <= NOW`, kể cả từ đã mastered (BE vẫn
  /// cho ôn lại từ mastered sau 35 ngày). Sắp theo hạn ôn sớm nhất trước.
  List<VocabularyModel> get dueVocabularies {
    final now = _clock();
    final due = MockVocabData.initialVocabularies.where((v) {
      final p = _progress[v.id];
      return p != null && !p.nextReviewAt.isAfter(now);
    }).toList();
    due.sort((a, b) =>
        _progress[a.id]!.nextReviewAt.compareTo(_progress[b.id]!.nextReviewAt));
    return due;
  }

  void _seed() {
    final profile = UserProfileModel.mockDefault();
    final today = _today;
    _streak = profile.currentStreak;
    _highestStreak = profile.currentStreak;
    // Streak mẫu: học liên tục tới hôm qua, hôm nay chưa học
    _lastStreakDate = _streak > 0 ? _previousDay(today) : null;
    _dailyGoal = profile.dailyGoalWords.clamp(minDailyGoal, maxDailyGoal);
    _learnedDay = today;
    _seedLearnedCount = 4;
    _learnedTodayIds.clear();
    _progress.clear();

    final now = _clock();
    final vocabs = MockVocabData.initialVocabularies;
    for (var i = 0; i < vocabs.length; i++) {
      // 6 từ đầu đã đến hạn ôn, các từ còn lại hẹn trong những ngày tới.
      final next = i < 6
          ? now.subtract(Duration(hours: i + 1))
          : now.add(Duration(days: (i % 3) + 1));
      _progress[vocabs[i].id] = Sm2Engine.initial(next);
    }
  }

  /// BE chỉ nhận mục tiêu ngày trong khoảng 5–30 từ.
  static const int minDailyGoal = 5;
  static const int maxDailyGoal = 30;

  void setDailyGoal(int value) {
    _dailyGoal = value.clamp(minDailyGoal, maxDailyGoal);
    notifyListeners();
  }

  /// Gọi khi kết thúc 1 phiên quiz: cập nhật SM-2, tiến độ ngày và streak.
  void recordSessionResult(QuizSummary summary) {
    if (summary.records.isEmpty) return; // BE từ chối phiên không có câu trả lời
    final now = _clock();
    final today = _dateOnly(now);

    // Chống học dồn (BE applySession): mỗi từ chỉ tính câu trả lời ĐẦU TIÊN
    // trong phiên; trả lời đúng chỉ lên level khi từ đã đến hạn hoặc còn là từ mới.
    final counted = <String>{};
    for (final r in summary.records) {
      final id = r.question.vocab.id;
      if (!counted.add(id)) continue;

      final old = _progress[id] ?? Sm2Engine.initial(now);
      final isNew = old.repetitionLevel == 0 && old.intervalDays == 0;
      final isDue = !old.nextReviewAt.isAfter(now);
      if (r.isCorrect && !isNew && !isDue) continue;

      _progress[id] = Sm2Engine.apply(old, r.isCorrect, now);
    }

    // Mục tiêu ngày (BE): số từ khác nhau có ít nhất một câu đúng trong các
    // phiên hôm nay, kể cả phiên "Thử lại câu sai". Dùng tập hợp nên không đếm đôi.
    if (_learnedDay != today) {
      _learnedDay = today;
      _seedLearnedCount = 0;
      _learnedTodayIds.clear();
    }
    for (final r in summary.records) {
      if (r.isCorrect) _learnedTodayIds.add(r.question.vocab.id);
    }

    // Streak (BE computeStreak): mọi phiên đã nộp đều tính, mỗi ngày tăng tối đa 1.
    if (_lastStreakDate != today) {
      final yesterday = _previousDay(today);
      final continues = _lastStreakDate == yesterday && _streak > 0;
      _streak = continues ? _streak + 1 : 1;
      if (_streak > _highestStreak) _highestStreak = _streak;
      _lastStreakDate = today;
    }
    notifyListeners();
  }
}
