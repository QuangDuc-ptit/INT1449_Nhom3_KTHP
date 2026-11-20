import 'notification_ui_state.dart';

/// Dữ liệu mẫu cho popup thông báo khi chưa có backend (dùng cho app và Preview).
/// Thời gian tính lùi từ [now] để chuỗi "… trước" luôn hợp lý.
class NotificationSampleData {
  NotificationSampleData._();

  /// Độ trễ giả lập khi Làm mới / Tải thêm.
  static const Duration simulatedLatency = Duration(seconds: 1);

  static List<NotificationItem> firstPage(DateTime now) => [
        NotificationItem(
          id: 'n1',
          title: 'Đến giờ ôn tập rồi!',
          preview: 'Bạn có 18 từ đang chờ ôn tập. Một phiên ngắn chỉ khoảng 5 phút thôi.',
          createdAt: now.subtract(const Duration(seconds: 20)),
          isRead: false,
        ),
        NotificationItem(
          id: 'n2',
          title: 'Sắp mất chuỗi 7 ngày học',
          preview: 'Hôm nay bạn chưa học từ nào. Học ít nhất 1 từ trước 23:59 để giữ chuỗi nhé.',
          createdAt: now.subtract(const Duration(minutes: 25)),
          isRead: false,
        ),
        NotificationItem(
          id: 'n3',
          title: 'Học phần mới: Tiếng Anh Công việc',
          preview: 'Học phần "Tiếng Anh Công việc" với 48 từ đã được thêm vào thư viện của bạn.',
          createdAt: now.subtract(const Duration(hours: 3)),
          isRead: false,
        ),
        NotificationItem(
          id: 'n4',
          title: 'Chúc mừng! Bạn đã giữ chuỗi 7 ngày học liên tiếp',
          preview: 'Tuyệt vời! Tiếp tục duy trì để mở khoá huy hiệu "Chuỗi 30 ngày".',
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
          isRead: true,
        ),
        NotificationItem(
          id: 'n5',
          title: 'Bạn đã đạt mốc 200 từ đã học',
          preview: 'Bạn đã ghi nhớ 200 từ vựng. Còn 100 từ nữa để đạt huy hiệu "Bách Khoa 300 Từ".',
          createdAt: now.subtract(const Duration(days: 4)),
          isRead: true,
        ),
        NotificationItem(
          id: 'n6',
          title: 'Nhắc ôn tập từ khó',
          preview: '5 từ bạn hay trả lời sai đã đến hạn ôn lại theo lịch Spaced Repetition.',
          createdAt: now.subtract(const Duration(days: 9)),
          isRead: true,
        ),
      ];

  /// Trang tiếp theo, trả về khi bấm "Tải thêm".
  static List<NotificationItem> nextPage(DateTime now) => [
        NotificationItem(
          id: 'n7',
          title: 'Học phần mới: Tiếng Anh Du lịch',
          preview: 'Học phần "Tiếng Anh Du lịch & Trải nghiệm" với 80 từ đã được thêm.',
          createdAt: now.subtract(const Duration(days: 12)),
          isRead: true,
        ),
        NotificationItem(
          id: 'n8',
          title: 'Bạn đã đạt mốc 100 từ đã học',
          preview: 'Chúc mừng bạn mở khoá huy hiệu "Bách Khoa 100 Từ".',
          createdAt: now.subtract(const Duration(days: 20)),
          isRead: true,
        ),
        NotificationItem(
          id: 'n9',
          title: 'Chào mừng bạn đến với KarVocab',
          preview: 'Bắt đầu bằng cách tạo học phần đầu tiên hoặc sinh từ vựng bằng AI.',
          createdAt: now.subtract(const Duration(days: 30)),
          isRead: true,
        ),
      ];

  /// Có dữ liệu (vừa đọc vừa chưa đọc), còn trang sau để tải thêm.
  static NotificationUiState full(DateTime now) {
    final items = firstPage(now);
    return NotificationUiState(
      items: items,
      totalCount: items.length + nextPage(now).length,
      unreadCount: items.where((n) => !n.isRead).length,
      canLoadMore: true,
    );
  }

  /// Đang tải thêm.
  static NotificationUiState loadingMore(DateTime now) =>
      full(now).copyWith(isLoadingMore: true);

  /// Không có thông báo nào.
  static const NotificationUiState empty = NotificationUiState(
    items: [],
    totalCount: 0,
    unreadCount: 0,
  );
}
