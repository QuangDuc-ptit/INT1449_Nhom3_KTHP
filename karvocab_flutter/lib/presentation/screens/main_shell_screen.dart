import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/local/local_store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../data/repositories/track_sync.dart';
import '../ai_vocab/ai_generate_screen.dart';
import '../dashboard/review_today_screen.dart';
import '../home/home_state_builder.dart';
import '../home/home_ui_state.dart';
import '../notifications/notification_ui_state.dart';
import '../notifications/review_notification_builder.dart';
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

  const MainShellScreen({super.key, this.initialTabIndex = 0}); // Mặc định mở Trang chủ

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  /// Popup thông báo: chỉ nhắc ôn tập khi có từ đã học đến hạn (xem
  /// [ReviewNotificationBuilder]). Tự cập nhật khi tiến độ ôn tập thay đổi.
  final ValueNotifier<NotificationUiState> _notifications = ValueNotifier(NotificationUiState.empty);

  /// Id thông báo đã đọc gần nhất, lưu trên máy để mở lại app vẫn nhớ.
  String? _readId;

  /// Khoá lưu "đã đọc" riêng cho từng tài khoản.
  String get _readKey {
    final user = TrackSync.userKeyOf(AuthRepository.instance);
    return user == null ? StorageKeys.notificationRead : StorageKeys.forUser(StorageKeys.notificationRead, user);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _readId = LocalStore.app.read(_readKey);
    _refreshNotifications();
    DashboardStore.instance.addListener(_refreshNotifications);
    CollectionStore.instance.addListener(_refreshNotifications);
  }

  @override
  void dispose() {
    DashboardStore.instance.removeListener(_refreshNotifications);
    CollectionStore.instance.removeListener(_refreshNotifications);
    _notifications.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Thông báo nhắc ôn tập
  // ---------------------------------------------------------------------------

  void _refreshNotifications() {
    _notifications.value = ReviewNotificationBuilder.build(
      dashboard: DashboardStore.instance,
      now: DateTime.now(),
      readId: _readId,
    );
  }

  void _markRead(String id) {
    _readId = id;
    LocalStore.app.write(_readKey, id);
    _refreshNotifications();
  }

  /// Bấm thông báo nhắc ôn → đánh dấu đã đọc rồi mở Màn 16. Mở sau khung hình
  /// hiện tại để popup đóng xong trước (popup đóng bằng `Navigator.pop`).
  void _onNotificationClick(String id) {
    _markRead(id);
    if (!ReviewNotificationBuilder.isReviewId(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openReviewToday();
    });
  }

  void _onMarkAllRead() {
    final items = _notifications.value.items;
    if (items.isNotEmpty) _markRead(items.first.id);
  }

  Future<void> _onRefresh() async => _refreshNotifications();

  /// Chỉ có tối đa một thông báo nên không có trang sau.
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

    // Nút Back của Android: đang ở tab khác thì về Trang chủ, đang ở Trang chủ mới thoát app.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTabSelected: _selectTab,
        ),
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
