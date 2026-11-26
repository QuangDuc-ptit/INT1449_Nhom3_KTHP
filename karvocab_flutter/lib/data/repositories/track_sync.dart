import 'auth_repository.dart';
import 'collection_store.dart';
import 'dashboard_store.dart';

/// Đồng bộ dữ liệu dùng chung giữa Track A và Track B mà không sửa store của nhau:
/// - Tài khoản: đăng nhập / đăng xuất → [CollectionStore] và [DashboardStore] mở dữ liệu
///   riêng của tài khoản đó (tài khoản khác không thấy học phần, tiến độ của nhau).
/// - Mục tiêu ngày: Cài đặt (Màn 23, FE1) → [DashboardStore] (Màn 04, FE2).
/// - Streak: [DashboardStore] (cập nhật sau mỗi phiên quiz) → hồ sơ (Màn 15, FE1).
///
/// Gọi [attach] một lần trong `main()`. Sprint 3 khi có backend, các giá trị này
/// lấy từ API nên lớp này có thể bỏ.
class TrackSync {
  TrackSync._();

  static bool _attached = false;

  /// Khoá dữ liệu của tài khoản đang đăng nhập (email chuẩn hoá), `null` khi đã đăng xuất.
  static String? userKeyOf(AuthRepository auth) => auth.currentUser?.email.trim().toLowerCase();

  static void attach({AuthRepository? auth, DashboardStore? dashboard, CollectionStore? collections}) {
    if (_attached) return;
    _attached = true;
    final a = auth ?? AuthRepository.instance;
    final d = dashboard ?? DashboardStore.instance;
    final c = collections ?? CollectionStore.instance;

    // Đổi dữ liệu theo tài khoản TRƯỚC khi đồng bộ mục tiêu / streak, để số liệu
    // của tài khoản cũ không bị ghi sang tài khoản mới.
    void switchUser() {
      final key = userKeyOf(a);
      c.switchUser(key);
      d.switchUser(key);
      if (key != null && a.usesBackend && !a.isDemo) {
        c.ensureLoaded();
        d.loadDashboard();
      }
    }

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
      switchUser();
      pushGoal();
      pushStreak();
    });
    d.addListener(pushStreak);
    // Đã đăng nhập sẵn (vd khôi phục phiên trước khi gắn) thì mở dữ liệu ngay.
    switchUser();
  }
}
