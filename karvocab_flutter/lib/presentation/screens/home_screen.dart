import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../home/home_sample_data.dart';
import '../home/home_ui_state.dart';
import '../notifications/notification_sample_data.dart';
import '../notifications/notification_ui_state.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/course_icon.dart';
import '../widgets/notification_popup.dart';
import '../widgets/stat_card.dart';
import '../widgets/tab_header.dart';
import '../widgets/weekly_bar_chart.dart';

/// Màn 04 · Trang chủ.
///
/// Chỉ hiển thị [state]; mọi thao tác bấm được đưa ra ngoài qua callback,
/// màn hình không tự điều hướng. Thanh điều hướng dưới nằm ở `MainShellScreen`
/// ([AppBottomNavBar]).
class HomeScreen extends StatelessWidget {
  final HomeUiState state;

  /// Dữ liệu popup thông báo (badge trên chuông = `unreadCount`).
  /// `null` thì ẩn badge và chuông không mở popup.
  final ValueListenable<NotificationUiState>? notifications;

  /// Thao tác trong popup thông báo, chuyển thẳng ra ngoài.
  final NotificationPopupCallbacks notificationCallbacks;

  final VoidCallback? onStartReviewClick;
  final ValueChanged<HomeStat>? onStatClick;
  final VoidCallback? onSeeAllCoursesClick;
  final ValueChanged<HomeCourse>? onCourseClick;

  /// Trạng thái trống (chưa có học phần): tạo học phần / tạo từ bằng AI.
  final VoidCallback? onCreateCourseClick;
  final VoidCallback? onAiGenerateClick;

  /// Số học phần tối đa hiển thị trên Trang chủ.
  static const int maxCourses = 3;

  const HomeScreen({
    super.key,
    required this.state,
    this.notifications,
    this.notificationCallbacks = const NotificationPopupCallbacks(),
    this.onStartReviewClick,
    this.onStatClick,
    this.onSeeAllCoursesClick,
    this.onCourseClick,
    this.onCreateCourseClick,
    this.onAiGenerateClick,
  });

  /// Người dùng mới: chưa có học phần nào nên mọi số liệu đều 0.
  bool get _isNewUser => state.courses.isEmpty && state.totalWords == 0;

  @override
  Widget build(BuildContext context) {
    const blockGap = SizedBox(height: AppDimensions.homeBlockGap);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.homeHorizontalPadding,
            AppDimensions.homeBlockGap,
            AppDimensions.homeHorizontalPadding,
            AppDimensions.homeBlockGap,
          ),
          children: [
            _Header(notifications: notifications, notificationCallbacks: notificationCallbacks),
            blockGap,
            if (_isNewUser)
              _NewUserCard(onCreateCourse: onCreateCourseClick, onAiGenerate: onAiGenerateClick)
            else ...[
              _StatGrid(state: state, onStatClick: onStatClick),
              blockGap,
              _DailyGoalCard(done: state.reviewedToday, goal: state.dailyGoal),
              blockGap,
              // Một khối duy nhất: thông tin phiên ôn tập + nút bắt đầu (trước đây là 2 nút cùng chức năng).
              _ReviewPanel(
                wordsToReview: state.wordsToReview,
                reviewMinutes: state.reviewMinutes,
                onStart: onStartReviewClick,
              ),
              blockGap,
              _WeeklyActivityCard(weeklyStats: state.weeklyStats, todayIndex: state.todayIndex),
              blockGap,
              _CoursesSection(
                courses: state.courses,
                onSeeAllCoursesClick: onSeeAllCoursesClick,
                onCourseClick: onCourseClick,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái trống của Trang chủ (rubric: Axolotl + CTA) thay cho các ô số 0,
/// nút "Không có từ cần ôn" bị khoá và biểu đồ rỗng.
class _NewUserCard extends StatelessWidget {
  final VoidCallback? onCreateCourse;
  final VoidCallback? onAiGenerate;

  const _NewUserCard({required this.onCreateCourse, required this.onAiGenerate});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        key: const Key('home_empty_state'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            AppAssets.logo,
            width: AppDimensions.libraryEmptyLogoSize,
            height: AppDimensions.libraryEmptyLogoSize,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: AppDimensions.space16),
          const Text(AppStrings.homeEmptyTitle, style: AppTypography.headingMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.space8),
          const Text(AppStrings.homeEmptyMessage, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.space20),
          AppButton(
            key: const Key('home_empty_create'),
            text: AppStrings.homeEmptyCreate,
            onPressed: onCreateCourse ?? () {},
          ),
          const SizedBox(height: AppDimensions.space12),
          AppButton(
            key: const Key('home_empty_ai'),
            text: AppStrings.homeEmptyAi,
            variant: AppButtonVariant.outline,
            onPressed: onAiGenerate ?? () {},
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Header
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final ValueListenable<NotificationUiState>? notifications;
  final NotificationPopupCallbacks notificationCallbacks;

  const _Header({required this.notifications, required this.notificationCallbacks});

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: AppStrings.homeGreeting,
      trailing: _BellButton(notifications: notifications, callbacks: notificationCallbacks),
    );
  }
}

/// Nút chuông: hình tròn 44dp, vùng chạm 48dp (rubric ≥ 48dp).
/// Bấm → mở popup thông báo ngay bên dưới; badge = số chưa đọc.
class _BellButton extends StatelessWidget {
  final ValueListenable<NotificationUiState>? notifications;
  final NotificationPopupCallbacks callbacks;

  const _BellButton({required this.notifications, required this.callbacks});

  void _openPopup(BuildContext context) {
    final state = notifications;
    final box = context.findRenderObject() as RenderBox?;
    if (state == null || box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    showNotificationPopup(context: context, anchor: anchor, state: state, callbacks: callbacks);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.homeNotificationsTooltip,
      child: InkResponse(
        key: const Key('home_bell'),
        onTap: notifications == null ? null : () => _openPopup(context),
        radius: AppDimensions.minTouchTarget / 2,
        child: SizedBox(
          width: AppDimensions.minTouchTarget,
          height: AppDimensions.minTouchTarget,
          child: Center(
            child: SizedBox(
              width: AppDimensions.bellButtonSize,
              height: AppDimensions.bellButtonSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: AppDimensions.iconMedium,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  ),
                  if (notifications != null)
                    ValueListenableBuilder<NotificationUiState>(
                      valueListenable: notifications!,
                      builder: (context, value, _) => value.unreadCount > 0
                          ? Positioned(top: 0, right: 0, child: _UnreadBadge(count: value.unreadCount))
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chấm đỏ số chưa đọc; > 99 hiện "99+". Hình viên thuốc để "99+" vừa chữ.
class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home_notification_badge'),
      constraints: const BoxConstraints(
        minWidth: AppDimensions.notificationBadgeSize,
        minHeight: AppDimensions.notificationBadgeSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      decoration: BoxDecoration(
        color: AppColors.notificationBadge,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      alignment: Alignment.center,
      child: Text(count > 99 ? AppStrings.notificationBadgeOverflow : '$count', style: AppTypography.notificationBadge),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Lưới thẻ thống kê 2 × 2
// -----------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  final HomeUiState state;
  final ValueChanged<HomeStat>? onStatClick;

  const _StatGrid({required this.state, required this.onStatClick});

  VoidCallback? _tap(HomeStat stat) => onStatClick == null ? null : () => onStatClick!(stat);

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: AppDimensions.homeGridGap, height: AppDimensions.homeGridGap);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${state.totalWords}',
                label: AppStrings.homeStatTotalWords,
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.primaryBlue,
                onTap: _tap(HomeStat.totalWords),
              ),
            ),
            gap,
            Expanded(
              child: StatCard(
                value: AppStrings.homeStreakValue(state.streakDays),
                label: AppStrings.homeStatStreak,
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.streak,
                onTap: _tap(HomeStat.streak),
              ),
            ),
          ],
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${state.newWords}',
                label: AppStrings.homeStatNewWords,
                icon: Icons.add_circle_outline_rounded,
                iconColor: AppColors.primaryBlue,
                onTap: _tap(HomeStat.newWords),
              ),
            ),
            gap,
            Expanded(
              child: StatCard(
                value: '${state.wordsToReview}',
                label: AppStrings.homeStatToReview,
                icon: Icons.autorenew_rounded,
                iconColor: AppColors.primaryBlue,
                backgroundColor: AppColors.homeSurfaceTint,
                onTap: _tap(HomeStat.wordsToReview),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Mục tiêu hôm nay (số từ ôn / mục tiêu đặt ở Cài đặt)
// -----------------------------------------------------------------------------

class _DailyGoalCard extends StatelessWidget {
  final int done;
  final int goal;

  const _DailyGoalCard({required this.done, required this.goal});

  @override
  Widget build(BuildContext context) {
    final reached = goal > 0 && done >= goal;
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final color = reached ? AppColors.successGreen : AppColors.actionPrimary;
    return _HomeCard(
      child: Column(
        key: const Key('home_daily_goal'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                reached ? Icons.check_circle_rounded : Icons.flag_rounded,
                size: AppDimensions.iconMedium,
                color: color,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  reached ? AppStrings.homeDailyGoalReached : AppStrings.homeDailyGoalTitle,
                  style: AppTypography.homeBodyBold,
                ),
              ),
              Text(
                AppStrings.homeDailyGoalProgress(done, goal),
                style: AppTypography.homeBodyBold.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Semantics(
            value: AppStrings.homeDailyGoalProgress(done, goal),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: SizedBox(
                height: AppDimensions.homeGoalBarHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.homeDivider),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Thẻ nhắc ôn tập & 4. Nút chính
// -----------------------------------------------------------------------------

/// Khối ôn tập: có từ cần ôn thì hiện số từ + thời lượng ngay trên nút bắt đầu;
/// không có thì chỉ còn nút bị khoá.
class _ReviewPanel extends StatelessWidget {
  final int wordsToReview;
  final int reviewMinutes;
  final VoidCallback? onStart;

  const _ReviewPanel({required this.wordsToReview, required this.reviewMinutes, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final button = _StartReviewButton(wordsToReview: wordsToReview, onPressed: onStart);
    if (wordsToReview <= 0) return button;
    return Container(
      key: const Key('home_review_reminder'),
      padding: const EdgeInsets.all(AppDimensions.homeCardPadding),
      decoration: BoxDecoration(
        color: AppColors.homeSurfaceTint,
        borderRadius: BorderRadius.circular(AppDimensions.homeCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: AppDimensions.iconMedium, color: AppColors.navyBlue),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.homeReviewReminderTitle(wordsToReview), style: AppTypography.homeBodyBold),
                    const SizedBox(height: AppDimensions.space4),
                    Text(AppStrings.homeReviewReminderSubtitle(reviewMinutes), style: AppTypography.homeSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          button,
        ],
      ),
    );
  }
}

class _StartReviewButton extends StatelessWidget {
  final int wordsToReview;
  final VoidCallback? onPressed;

  const _StartReviewButton({required this.wordsToReview, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final hasWords = wordsToReview > 0;
    return AppButton(
      text: hasWords ? AppStrings.homeStartReview(wordsToReview) : AppStrings.homeNoWordsToReview,
      // Luôn truyền callback (kể cả rỗng) để trạng thái khoá chỉ phụ thuộc số từ cần ôn.
      onPressed: onPressed ?? () {},
      isEnabled: hasWords,
      disabledBackgroundColor: AppColors.actionPrimary.withValues(alpha: AppDimensions.disabledOpacity),
      borderRadius: AppDimensions.reviewButtonRadius,
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Thẻ biểu đồ tuần
// -----------------------------------------------------------------------------

class _WeeklyActivityCard extends StatelessWidget {
  final List<int?> weeklyStats;
  final int todayIndex;

  const _WeeklyActivityCard({required this.weeklyStats, required this.todayIndex});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.homeWeeklyActivity, style: AppTypography.homeCardTitle),
          const SizedBox(height: AppDimensions.space16),
          WeeklyBarChart(values: weeklyStats, dayLabels: AppStrings.weekdayShort, todayIndex: todayIndex),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Học phần của bạn
// -----------------------------------------------------------------------------

class _CoursesSection extends StatelessWidget {
  final List<HomeCourse> courses;
  final VoidCallback? onSeeAllCoursesClick;
  final ValueChanged<HomeCourse>? onCourseClick;

  const _CoursesSection({required this.courses, required this.onSeeAllCoursesClick, required this.onCourseClick});

  @override
  Widget build(BuildContext context) {
    final shown = courses.take(HomeScreen.maxCourses).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text(AppStrings.homeYourCourses, style: AppTypography.homeSectionTitle)),
            TextButton(
              onPressed: onSeeAllCoursesClick,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
              ),
              child: const Text(AppStrings.homeSeeAll, style: AppTypography.homeLink),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        if (shown.isEmpty)
          const _HomeCard(
            child: Center(child: Text(AppStrings.homeNoCourses, style: AppTypography.homeBody)),
          )
        else
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.homeGridGap),
            _CourseCard(course: shown[i], onTap: onCourseClick == null ? null : () => onCourseClick!(shown[i])),
          ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final HomeCourse course;
  final VoidCallback? onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      onTap: onTap,
      child: Row(
        children: [
          CourseIcon(categoryId: course.categoryId),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, style: AppTypography.homeCardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppDimensions.space2),
                Text(AppStrings.homeCourseWordCount(course.wordCount), style: AppTypography.homeSmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.navInactive),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Thẻ nền Surface dùng chung: bo 16dp, padding 16dp, viền 1dp màu Divider.
// -----------------------------------------------------------------------------

class _HomeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HomeCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: const EdgeInsets.all(AppDimensions.homeCardPadding), child: child);
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.homeCardRadius),
        side: const BorderSide(color: AppColors.homeDivider, width: AppDimensions.homeCardBorderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

// -----------------------------------------------------------------------------
// Preview (Flutter Widget Previewer)
// -----------------------------------------------------------------------------

Widget _previewFrame(HomeUiState state, NotificationUiState notifications) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: HomeScreen(state: state, notifications: ValueNotifier(notifications)),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0, onTabSelected: (_) {}),
    ),
  );
}

@Preview(name: 'Trang chủ · đầy đủ dữ liệu', size: Size(390, 844))
Widget homeScreenFullPreview() => _previewFrame(HomeSampleData.full, NotificationSampleData.full(DateTime.now()));

@Preview(name: 'Trang chủ · trạng thái trống', size: Size(390, 844))
Widget homeScreenEmptyPreview() => _previewFrame(HomeSampleData.empty, NotificationSampleData.empty);
