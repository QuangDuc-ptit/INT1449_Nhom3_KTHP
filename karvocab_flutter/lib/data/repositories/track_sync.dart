import 'auth_repository.dart';
import 'dashboard_store.dart';

/// Đồng bộ dữ liệu dùng chung giữa Track A và Track B mà không sửa store của nhau:
/// - Mục tiêu ngày: Cài đặt (Màn 23, FE1) → [DashboardStore] (Màn 04, FE2).
/// - Streak: [DashboardStore] (cập nhật sau mỗi phiên quiz) → hồ sơ (Màn 15, FE1).
///
/// Gọi [attach] một lần trong `main()`. Sprint 3 khi có backend, hai giá trị này
/// lấy từ API nên lớp này có thể bỏ.
class TrackSync {
  TrackSync._();

  static bool _attached = false;

  static void attach({AuthRepository? auth, DashboardStore? dashboard}) {
    if (_attached) return;
    _attached = true;
    final a = auth ?? AuthRepository.instance;
    final d = dashboard ?? DashboardStore.instance;

    void pushGoal() {
      final user = a.currentUser;
      if (user != null && user.dailyGoalWords != d.dailyGoal) {
        d.setDailyGoal(user.dailyGoalWords);
      }
    }

    void pushStreak() {
      final user = a.currentUser;
      if (user != null && user.currentStreak != d.streak) {
        a.updateProfile(user.copyWith(currentStreak: d.streak));
      }
    }

    // So sánh trước khi ghi nên hai listener không gọi qua lại vô hạn.
    a.addListener(() {
      pushGoal();
      pushStreak();
    });
    d.addListener(pushStreak);
  }
}
