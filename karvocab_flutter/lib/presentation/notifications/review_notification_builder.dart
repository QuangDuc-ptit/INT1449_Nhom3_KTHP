import '../../core/constants/app_strings.dart';
import '../../data/repositories/dashboard_store.dart';
import 'notification_ui_state.dart';

/// Thông báo trong app chỉ có một loại: nhắc ôn tập khi có từ đến hạn.
///
/// Cùng luật với job nhắc ôn của backend (`review-reminder.job.ts`): chỉ đếm từ
/// **đã học** có hạn ôn tới rồi, từ mới chưa học không tính. Không có từ đến hạn
/// thì không có thông báo. Mỗi ngày một thông báo (id theo ngày), nên đọc rồi thì
/// hôm sau có từ đến hạn sẽ lại thành chưa đọc.
class ReviewNotificationBuilder {
  ReviewNotificationBuilder._();

  static const String _prefix = 'review-';

  /// Id thông báo của ngày [day], vd `review-2026-11-24`.
  static String idFor(DateTime day) =>
      '$_prefix${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static bool isReviewId(String id) => id.startsWith(_prefix);

  static NotificationUiState build({
    required DashboardStore dashboard,
    required DateTime now,
    String? readId,
  }) {
    final due = dashboard.dueVocabularies.where((v) => dashboard.isLearned(v.id)).toList();
    if (due.isEmpty) return NotificationUiState.empty;

    // Thời điểm thông báo = lúc từ đầu tiên đến hạn (popup hiện "2 giờ trước"...).
    var since = now;
    for (final v in due) {
      final next = dashboard.progressOf(v.id)?.nextReviewAt;
      if (next != null && next.isBefore(since)) since = next;
    }

    final id = idFor(now);
    final read = readId == id;
    return NotificationUiState(
      items: [
        NotificationItem(
          id: id,
          title: AppStrings.notificationReviewTitle,
          preview: AppStrings.notificationReviewPreview(due.length),
          createdAt: since,
          isRead: read,
        ),
      ],
      totalCount: 1,
      unreadCount: read ? 0 : 1,
    );
  }
}
