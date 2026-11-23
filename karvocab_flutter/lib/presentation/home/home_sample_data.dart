import 'home_ui_state.dart';

/// Dữ liệu mẫu cho Màn 04 · Trang chủ khi chưa có backend (dùng cho app và Preview).
class HomeSampleData {
  HomeSampleData._();

  /// Đầy đủ dữ liệu.
  static const HomeUiState full = HomeUiState(
    userName: 'Minh Anh',
    totalWords: 248,
    streakDays: 7,
    newWords: 12,
    wordsToReview: 18,
    reviewMinutes: 5,
    weeklyStats: [12, 20, 8, 25, 15, null, null],
    todayIndex: 4,
    reviewedToday: 6,
    dailyGoal: 10,
    courses: [
      HomeCourse(id: 'c1', name: 'Học thuật & IELTS Core', wordCount: 120, categoryId: 'academic'),
      HomeCourse(id: 'c2', name: 'Tiếng Anh Du lịch & Trải nghiệm', wordCount: 80, categoryId: 'travel'),
      HomeCourse(id: 'c3', name: 'Tiếng Anh Công việc', wordCount: 48, categoryId: 'career'),
      HomeCourse(id: 'c4', name: 'Từ vựng hằng ngày', wordCount: 30),
    ],
  );

  /// Trạng thái trống: không có từ cần ôn, chưa có học phần, chưa có dữ liệu tuần.
  static const HomeUiState empty = HomeUiState(
    userName: 'Minh Anh',
    totalWords: 0,
    streakDays: 0,
    newWords: 0,
    wordsToReview: 0,
    reviewMinutes: 0,
    weeklyStats: [null, null, null, null, null, null, null],
    todayIndex: 4,
    courses: [],
  );
}
