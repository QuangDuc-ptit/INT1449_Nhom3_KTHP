/// Huy hiệu ở Hồ sơ (Màn 15, đặc tả §4.6). Luật mở khoá tính từ dữ liệu học thật.
enum LearningBadgeKind { streak7, first100, explorer }

class LearningBadge {
  final LearningBadgeKind kind;

  /// Tiến độ hiện tại và mốc cần đạt, vd chuỗi 3/7 ngày.
  final int progress;
  final int target;

  const LearningBadge(this.kind, {required this.progress, required this.target});

  bool get unlocked => progress >= target;

  /// Tiến độ hiển thị, không vượt quá mốc.
  int get shownProgress => progress > target ? target : progress;

  /// - `7-day streak`: chuỗi dài nhất đạt 7 ngày liên tục.
  /// - `First 100`: đã học đủ 100 từ.
  /// - `Word Explorer`: đã tạo trên 5 học phần (từ 6 trở lên).
  static List<LearningBadge> evaluate({
    required int highestStreak,
    required int wordsLearned,
    required int collections,
  }) => [
    LearningBadge(LearningBadgeKind.streak7, progress: highestStreak, target: 7),
    LearningBadge(LearningBadgeKind.first100, progress: wordsLearned, target: 100),
    LearningBadge(LearningBadgeKind.explorer, progress: collections, target: 6),
  ];
}
