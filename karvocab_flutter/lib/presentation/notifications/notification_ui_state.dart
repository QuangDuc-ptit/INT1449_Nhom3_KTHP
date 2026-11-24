/// Một thông báo trong popup thông báo (Màn 04).
class NotificationItem {
  final String id;
  final String title;
  final String preview;

  /// Thời điểm tạo; popup hiển thị dạng tương đối ("5 phút trước"...).
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.isRead,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        preview: preview,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

/// Dữ liệu hiển thị của popup thông báo. Popup chỉ đọc state này.
class NotificationUiState {
  final List<NotificationItem> items;

  /// Tổng số thông báo (kể cả những cái chưa tải về).
  final int totalCount;
  final int unreadCount;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool canLoadMore;

  const NotificationUiState({
    required this.items,
    required this.totalCount,
    required this.unreadCount,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.canLoadMore = false,
  });

  /// Không có thông báo nào.
  static const NotificationUiState empty = NotificationUiState(items: [], totalCount: 0, unreadCount: 0);

  NotificationUiState copyWith({
    List<NotificationItem>? items,
    int? totalCount,
    int? unreadCount,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? canLoadMore,
  }) {
    return NotificationUiState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      unreadCount: unreadCount ?? this.unreadCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      canLoadMore: canLoadMore ?? this.canLoadMore,
    );
  }
}
