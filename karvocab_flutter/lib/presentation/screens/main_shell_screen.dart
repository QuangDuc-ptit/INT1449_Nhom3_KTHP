import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/dashboard_store.dart';
import '../ai_vocab/ai_generate_screen.dart';
import '../dashboard/review_today_screen.dart';
import '../home/home_state_builder.dart';
import '../home/home_ui_state.dart';
import '../notifications/notification_ui_state.dart';
import '../quiz/practice_mode_screen.dart';
import '../widgets/notification_popup.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/collection_form_sheet.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'word_list_screen.dart';

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

  /// Dữ liệu popup thông báo. Chưa có backend gửi thông báo nên bắt đầu trống
  /// (Empty State); các thao tác `_on…` bên dưới giữ sẵn cho Sprint 3 nối API.
  final ValueNotifier<NotificationUiState> _notifications = ValueNotifier(NotificationUiState.empty);

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
    // Chưa có API thông báo: không có gì mới để tải.
    _notifications.value = _notifications.value.copyWith(isRefreshing: false);
  }

  Future<void> _onLoadMore() async {
    _notifications.value = _notifications.value.copyWith(isLoadingMore: false, canLoadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    // 4 Màn hình tương ứng 4 Tab
    final List<Widget> pages = [
      // Màn 04 · Trang chủ — giao diện FE1, số liệu từ CollectionStore (FE1) + DashboardStore (FE2)
      ListenableBuilder(
        listenable: Listenable.merge([
          CollectionStore.instance,
          DashboardStore.instance,
          AuthRepository.instance,
        ]),
        builder: (context, _) => HomeScreen(
          state: HomeStateBuilder.build(
            collections: CollectionStore.instance,
            dashboard: DashboardStore.instance,
            user: AuthRepository.instance.currentUser,
          ),
          notifications: _notifications,
          notificationCallbacks: NotificationPopupCallbacks(
            onNotificationClick: _onNotificationClick,
            onMarkAllRead: _onMarkAllRead,
            onRefresh: _onRefresh,
            onLoadMore: _onLoadMore,
          ),
          onStartReviewClick: _openReviewToday,
          onStatClick: _onStatClick,
          onSeeAllCoursesClick: () => _selectTab(_libraryTab),
          onCourseClick: _openCourse,
          onCreateCourseClick: _createFirstCourse,
          onAiGenerateClick: _openAiGenerate,
        ),
      ),
      const LibraryScreen(), // Tab Thư viện do FE1 phát triển
      const PracticeModeScreen(), // Tab Luyện tập do FE2 phát triển (Màn 10)
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
  static const int _profileTab = 3;

  void _selectTab(int index) => setState(() => _currentIndex = index);

  // ---------------------------------------------------------------------------
  // Nối Trang chủ (FE1) với các màn của FE2 / Thư viện
  // ---------------------------------------------------------------------------

  /// "Bắt đầu ôn tập" / thẻ nhắc ôn → Màn 16 (FE2).
  void _openReviewToday() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReviewTodayScreen()));
  }

  void _onStatClick(HomeStat stat) {
    switch (stat) {
      case HomeStat.wordsToReview:
        _openReviewToday();
      case HomeStat.totalWords:
      case HomeStat.newWords:
        _selectTab(_libraryTab);
      case HomeStat.streak:
        _selectTab(_profileTab);
    }
  }

  /// Trang chủ trống → mở sheet tạo học phần (như nút "Tạo mới" ở Thư viện), xong vào Màn 06.
  Future<void> _createFirstCourse() async {
    final store = CollectionStore.instance;
    final created = await showCollectionFormSheet(context, store: store);
    if (created == null || !mounted) return;
    AppToast.success(context, AppStrings.libraryCourseCreated(created.title));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WordListScreen(collection: created, store: store)),
    );
  }

  /// Trang chủ trống → Màn 13 (tạo từ bằng AI, có thể tạo học phần mới ở bước lưu).
  void _openAiGenerate() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AiGenerateScreen()));
  }

  /// Học phần ở Trang chủ → Màn 06.
  void _openCourse(HomeCourse course) {
    final collection = CollectionStore.instance.findCollection(course.id);
    if (collection == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WordListScreen(collection: collection)),
    );
  }
}
