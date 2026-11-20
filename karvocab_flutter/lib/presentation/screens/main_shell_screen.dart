import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../home/home_sample_data.dart';
import '../notifications/notification_sample_data.dart';
import '../notifications/notification_ui_state.dart';
import '../widgets/notification_popup.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Khung Điều hướng chính (Main Shell Screen) với Bottom Navigation 4 Tab
/// Chuẩn Figma & Đảm bảo Dev FE1 và FE2 không bị xung đột code
class MainShellScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainShellScreen({super.key, this.initialTabIndex = 1}); // Mặc định mở Thư viện

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  /// Dữ liệu popup thông báo. Chưa có backend: bắt đầu từ dữ liệu mẫu và
  /// giả lập các thao tác ngay trên bộ nhớ (xem các hàm `_on…` bên dưới).
  final ValueNotifier<NotificationUiState> _notifications =
      ValueNotifier(NotificationSampleData.full(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Giả lập thao tác thông báo (Sprint 3 thay bằng gọi API, giữ nguyên chữ ký)
  // ---------------------------------------------------------------------------

  void _setItems(List<NotificationItem> items, {int? totalCount, bool? canLoadMore}) {
    _notifications.value = _notifications.value.copyWith(
      items: items,
      unreadCount: items.where((n) => !n.isRead).length,
      totalCount: totalCount,
      canLoadMore: canLoadMore,
    );
  }

  void _onNotificationClick(String id) {
    _setItems([
      for (final n in _notifications.value.items) n.id == id ? n.copyWith(isRead: true) : n,
    ]);
  }

  void _onMarkAllRead() {
    _setItems([for (final n in _notifications.value.items) n.copyWith(isRead: true)]);
  }

  Future<void> _onRefresh() async {
    _notifications.value = _notifications.value.copyWith(isRefreshing: true);
    await Future<void>.delayed(NotificationSampleData.simulatedLatency);
    if (!mounted) return;
    _notifications.value = _notifications.value.copyWith(isRefreshing: false);
  }

  Future<void> _onLoadMore() async {
    _notifications.value = _notifications.value.copyWith(isLoadingMore: true);
    await Future<void>.delayed(NotificationSampleData.simulatedLatency);
    if (!mounted) return;
    final items = [..._notifications.value.items, ...NotificationSampleData.nextPage(DateTime.now())];
    _setItems(items, totalCount: items.length, canLoadMore: false);
    _notifications.value = _notifications.value.copyWith(isLoadingMore: false);
  }

  @override
  Widget build(BuildContext context) {
    // 4 Màn hình tương ứng 4 Tab
    final List<Widget> pages = [
      // Màn 04 · Trang chủ — dữ liệu mẫu cho tới khi có backend
      HomeScreen(
        state: HomeSampleData.full,
        notifications: _notifications,
        notificationCallbacks: NotificationPopupCallbacks(
          onNotificationClick: _onNotificationClick,
          onMarkAllRead: _onMarkAllRead,
          onRefresh: _onRefresh,
          onLoadMore: _onLoadMore,
        ),
        onSeeAllCoursesClick: () => _selectTab(_libraryTab),
      ),
      const LibraryScreen(), // Tab Thư viện do FE1 phát triển
      _buildPracticePlaceholder(), // Tab Luyện tập chờ FE2 cắm Quiz Engine
      const ProfileScreen(), // Tab Hồ sơ cá nhân do FE1 phát triển (Màn 15)
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _selectTab,
      ),
    );
  }

  static const int _libraryTab = 1;

  void _selectTab(int index) => setState(() => _currentIndex = index);

  // Placeholder cho Luyện tập (Màn 10 - do FE2 phụ trách)
  Widget _buildPracticePlaceholder() {
    return Scaffold(
      appBar: AppBar(title: Text('Luyện tập & Quiz', style: AppTypography.headingLarge)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.softBlueSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 64, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text('Khu vực Luyện tập (Quiz Engine)', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              '4 Chế độ luyện tập đang được FE2 hoàn thiện.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
