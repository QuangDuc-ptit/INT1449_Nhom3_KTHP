import '../../data/models/user_profile_model.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/dashboard_store.dart';
import 'home_sample_data.dart';
import 'home_ui_state.dart';

/// Tạo [HomeUiState] cho Màn 04 từ store thật của hai track:
/// học phần/từ vựng lấy từ [CollectionStore] (FE1), streak/từ cần ôn từ [DashboardStore] (FE2).
class HomeStateBuilder {
  HomeStateBuilder._();

  /// Ước lượng thời gian ôn cho mỗi từ (dùng cho dòng "khoảng N phút").
  static const int secondsPerReviewWord = 15;

  static HomeUiState build({
    required CollectionStore collections,
    required DashboardStore dashboard,
    UserProfileModel? user,
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).weekday - 1; // 0 = T2 … 6 = CN
    final due = dashboard.dueVocabularies.length;
    final words = collections.collections.expand((c) => collections.wordsOf(c.id));

    return HomeUiState(
      userName: (user ?? UserProfileModel.mockDefault()).fullName,
      totalWords: collections.totalWordCount,
      streakDays: dashboard.streak,
      // Từ chưa có tiến độ ôn tập hoặc chưa lên level nào.
      newWords: words.where((w) {
        final p = dashboard.progressOf(w.id);
        return p == null || p.repetitionLevel == 0;
      }).length,
      wordsToReview: due,
      reviewMinutes: (due * secondsPerReviewWord / 60).ceil(),
      weeklyStats: _weekly(today, dashboard.reviewedToday),
      todayIndex: today,
      reviewedToday: dashboard.reviewedToday,
      dailyGoal: dashboard.dailyGoal,
      courses: [
        for (final c in collections.collections)
          HomeCourse(
            id: c.id,
            name: c.title,
            wordCount: c.totalWords,
            categoryId: c.category,
          ),
      ],
    );
  }

  /// [DashboardStore] mới chỉ lưu số từ ôn hôm nay. Các ngày trước dùng lịch sử mẫu
  /// (Demo Mode) cho tới khi có API thống kê tuần; các ngày sau hôm nay để trống.
  static List<int?> _weekly(int today, int reviewedToday) {
    final history = HomeSampleData.full.weeklyStats;
    return [
      for (var i = 0; i < 7; i++)
        if (i < today) history[i] ?? 0 else if (i == today) reviewedToday else null,
    ];
  }
}
