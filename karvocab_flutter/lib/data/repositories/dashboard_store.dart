import 'package:flutter/foundation.dart';

import '../local/local_store.dart';
import '../models/quiz_models.dart';
import '../models/vocabulary_model.dart';
import 'collection_store.dart';

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

  Map<String, dynamic> toJson() => {
        'level': repetitionLevel,
        'interval': intervalDays,
        'ease': easeFactor,
        'next': nextReviewAt.toIso8601String(),
        'mastered': mastered,
      };

  factory SrsProgress.fromJson(Map<String, dynamic> json) => SrsProgress(
        repetitionLevel: (json['level'] as num).toInt(),
        intervalDays: (json['interval'] as num).toInt(),
        easeFactor: (json['ease'] as num).toDouble(),
        nextReviewAt: DateTime.parse(json['next'] as String),
        mastered: json['mastered'] as bool,
      );
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
///
/// Bắt đầu trống (chưa học từ nào, chuỗi 0 ngày). Có [LocalStore] thì tiến độ, chuỗi ngày và
/// lịch sử từng ngày được lưu trên máy.
class DashboardStore extends ChangeNotifier {
  DashboardStore._()
      : _clock = DateTime.now,
        _collections = null,
        _storage = LocalStore.app {
    _restore();
  }

  static final DashboardStore instance = DashboardStore._();

  /// Dùng trong unit test để có store sạch. [clock] cho phép giả lập sang ngày mới;
  /// [collections] là nguồn từ vựng cho hàng đợi ôn tập (mặc định [CollectionStore.instance]).
  @visibleForTesting
  DashboardStore.forTest({DateTime Function()? clock, this._collections, this._storage})
      : _clock = clock ?? DateTime.now {
    _restore();
  }

  final DateTime Function() _clock;
  final CollectionStore? _collections;
  final LocalStore? _storage;

  CollectionStore get _library => _collections ?? CollectionStore.instance;

  /// Số từ khác nhau học được theo từng ngày (khoá `yyyy-mm-dd`), dùng cho biểu đồ tuần.
  final Map<String, int> _history = {};

  int _streak = 0;
  int _highestStreak = 0;

  /// Ngày gần nhất có học (BE `lastStreakDate`), null nếu chưa học lần nào.
  DateTime? _lastStreakDate;

  int _dailyGoal = 10;

  /// Ngày mà [_learnedTodayIds] đang tính; sang ngày khác thì đếm lại từ 0.
  DateTime? _learnedDay;

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
  int get reviewedToday => _learnedDay == _today ? _learnedTodayIds.length : 0;

  /// BE `isStreakActiveToday`: hôm nay đã hoàn thành ít nhất một phiên.
  bool get studiedToday => _lastStreakDate == _today;

  double get goalRatio =>
      _dailyGoal == 0 ? 0 : (reviewedToday / _dailyGoal).clamp(0.0, 1.0);
  bool get goalReached => reviewedToday >= _dailyGoal;

  SrsProgress? progressOf(String vocabId) => _progress[vocabId];

  /// Từ đã học: đã trả lời đúng ít nhất một lần nên lên level ≥ 1.
  /// Trang chủ ("Từ chưa học") và Hồ sơ ("Từ đã học") cùng dùng luật này để số liệu khớp nhau.
  bool isLearned(String vocabId) => (_progress[vocabId]?.repetitionLevel ?? 0) > 0;

  /// Các từ đến hạn ôn: từ mới (chưa có tiến độ) và từ có `next_review_at <= NOW`, kể cả
  /// từ đã mastered (BE vẫn cho ôn lại sau 35 ngày). Sắp theo hạn ôn sớm nhất trước.
  List<VocabularyModel> get dueVocabularies {
    final now = _clock();
    DateTime dueAt(VocabularyModel v) => _progress[v.id]?.nextReviewAt ?? now;
    final due = _library.allWords.where((v) => !dueAt(v).isAfter(now)).toList();
    due.sort((a, b) => dueAt(a).compareTo(dueAt(b)));
    return due;
  }

  /// Số từ học được trong [day] (biểu đồ tuần ở Trang chủ).
  int learnedOn(DateTime day) => _history[_dayKey(day)] ?? 0;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Xoá toàn bộ tiến độ (đăng xuất / kiểm thử).
  void clear() {
    _streak = 0;
    _highestStreak = 0;
    _lastStreakDate = null;
    _learnedDay = null;
    _learnedTodayIds.clear();
    _progress.clear();
    _history.clear();
    notifyListeners();
  }

  /// Mỗi lần dữ liệu đổi thì lưu lại trên máy.
  @override
  void notifyListeners() {
    _storage?.writeJson(StorageKeys.dashboard, {
      'streak': _streak,
      'highestStreak': _highestStreak,
      'lastStreakDate': _lastStreakDate?.toIso8601String(),
      'dailyGoal': _dailyGoal,
      'learnedDay': _learnedDay?.toIso8601String(),
      'learnedToday': _learnedTodayIds.toList(),
      'progress': {for (final e in _progress.entries) e.key: e.value.toJson()},
      'history': _history,
    });
    super.notifyListeners();
  }

  void _restore() {
    final data = _storage?.readJson(StorageKeys.dashboard);
    if (data is! Map<String, dynamic>) return;
    try {
      DateTime? date(Object? v) => v is String ? DateTime.parse(v) : null;
      _streak = (data['streak'] as num?)?.toInt() ?? 0;
      _highestStreak = (data['highestStreak'] as num?)?.toInt() ?? _streak;
      _lastStreakDate = date(data['lastStreakDate']);
      _dailyGoal = ((data['dailyGoal'] as num?)?.toInt() ?? _dailyGoal).clamp(minDailyGoal, maxDailyGoal);
      _learnedDay = date(data['learnedDay']);
      _learnedTodayIds.addAll([for (final id in (data['learnedToday'] as List?) ?? const []) id as String]);
      final progress = data['progress'];
      if (progress is Map<String, dynamic>) {
        _progress.addAll({
          for (final e in progress.entries) e.key: SrsProgress.fromJson(e.value as Map<String, dynamic>),
        });
      }
      final history = data['history'];
      if (history is Map<String, dynamic>) {
        _history.addAll({for (final e in history.entries) e.key: (e.value as num).toInt()});
      }
    } on Object {
      // Dữ liệu lưu bị hỏng: bắt đầu lại từ đầu.
      clear();
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
      _learnedTodayIds.clear();
    }
    for (final r in summary.records) {
      if (r.isCorrect) _learnedTodayIds.add(r.question.vocab.id);
    }
    _history[_dayKey(today)] = _learnedTodayIds.length;

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
