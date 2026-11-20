/// Dữ liệu hiển thị của Màn 04 · Trang chủ.
///
/// Màn hình chỉ đọc state này, không tự lấy dữ liệu. Hiện dùng
/// `HomeSampleData`; khi có backend chỉ cần tạo state từ dữ liệu thật.
class HomeUiState {
  final String userName;
  final int totalWords;
  final int streakDays;
  final int newWords;
  final int wordsToReview;
  final int reviewMinutes;

  /// Đúng 7 giá trị từ T2 → CN; `null` = ngày chưa có dữ liệu (không vẽ cột).
  /// `WeeklyBarChart` kiểm tra độ dài khi chạy debug.
  final List<int?> weeklyStats;

  /// Vị trí hôm nay trong [weeklyStats] (0 = T2 … 6 = CN).
  final int todayIndex;

  final List<HomeCourse> courses;

  const HomeUiState({
    required this.userName,
    required this.totalWords,
    required this.streakDays,
    required this.newWords,
    required this.wordsToReview,
    required this.reviewMinutes,
    required this.weeklyStats,
    required this.todayIndex,
    required this.courses,
  });
}

/// Một học phần trong mục "Học phần của bạn".
class HomeCourse {
  final String id;
  final String name;
  final int wordCount;

  /// 0 – 100.
  final int progressPercent;

  const HomeCourse({
    required this.id,
    required this.name,
    required this.wordCount,
    required this.progressPercent,
  });
}

/// Thẻ thống kê được bấm (tham số của `onStatClick`).
enum HomeStat { totalWords, streak, newWords, wordsToReview }
