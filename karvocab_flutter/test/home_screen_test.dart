import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/presentation/home/home_sample_data.dart';
import 'package:karvocab_flutter/presentation/home/home_ui_state.dart';
import 'package:karvocab_flutter/presentation/notifications/notification_ui_state.dart';
import 'package:karvocab_flutter/presentation/screens/home_screen.dart';
import 'package:karvocab_flutter/presentation/widgets/weekly_bar_chart.dart';

Widget _app(Widget home) => MaterialApp(home: home);

NotificationUiState _withUnread(int unread) =>
    NotificationUiState(items: const [], totalCount: unread, unreadCount: unread);

void main() {
  group('Màn 04 · Trang chủ', () {
    testWidgets('Đủ dữ liệu: thẻ thống kê, nhắc ôn tập, nút chính, tối đa 3 học phần', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(state: HomeSampleData.full)));

      expect(find.text('Xin chào, Karmate!'), findsOneWidget);
      expect(find.text('248'), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
      expect(find.text('18 từ đang chờ bạn ôn tập'), findsOneWidget);
      expect(find.text('Một phiên ngắn · khoảng 5 phút'), findsOneWidget);

      final start = find.widgetWithText(AppButton, 'Bắt đầu ôn tập · 18 từ');
      expect(start, findsOneWidget);
      expect(tester.widget<AppButton>(start).isEnabled, isTrue);

      await tester.scrollUntilVisible(find.text('Tiếng Anh Công việc'), 200);
      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);
      // Học phần thứ 4 không hiển thị
      expect(find.text('Từ vựng hằng ngày'), findsNothing);
    });

    testWidgets('Mục tiêu hôm nay: số từ đã ôn / mục tiêu; đạt thì đổi lời', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(state: HomeSampleData.full)));
      expect(find.byKey(const Key('home_daily_goal')), findsOneWidget);
      expect(find.text('Mục tiêu hôm nay'), findsOneWidget);
      expect(find.text('6/10 từ'), findsOneWidget);

      const done = HomeUiState(
        userName: 'Minh Anh',
        totalWords: 10,
        streakDays: 1,
        newWords: 0,
        wordsToReview: 0,
        reviewMinutes: 0,
        weeklyStats: [null, null, null, null, 12, null, null],
        todayIndex: 4,
        courses: [],
        reviewedToday: 12,
        dailyGoal: 10,
      );
      await tester.pumpWidget(_app(const HomeScreen(state: done)));
      expect(find.text('Đã hoàn thành mục tiêu hôm nay'), findsOneWidget);
      expect(find.text('12/10 từ'), findsOneWidget);
    });

    testWidgets('Trạng thái trống: Axolotl + 2 nút tạo, không còn ô số 0 và nút bị khoá', (tester) async {
      var created = 0, ai = 0;
      await tester.pumpWidget(_app(HomeScreen(
        state: HomeSampleData.empty,
        onCreateCourseClick: () => created++,
        onAiGenerateClick: () => ai++,
      )));

      expect(find.byKey(const Key('home_empty_state')), findsOneWidget);
      expect(find.text(AppStrings.homeEmptyTitle), findsOneWidget);
      expect(find.byKey(const Key('home_review_reminder')), findsNothing);
      expect(find.byKey(const Key('home_notification_badge')), findsNothing);
      expect(find.widgetWithText(AppButton, AppStrings.homeNoWordsToReview), findsNothing);
      expect(find.byKey(const Key('home_daily_goal')), findsNothing);

      await tester.tap(find.byKey(const Key('home_empty_create')));
      await tester.ensureVisible(find.byKey(const Key('home_empty_ai')));
      await tester.tap(find.byKey(const Key('home_empty_ai')));
      expect((created, ai), (1, 1));
    });

    testWidgets('Badge chuông = số chưa đọc; > 99 hiện "99+"; bằng 0 thì ẩn', (tester) async {
      final notifications = ValueNotifier(_withUnread(150));
      addTearDown(notifications.dispose);
      await tester.pumpWidget(_app(HomeScreen(state: HomeSampleData.full, notifications: notifications)));
      expect(find.text('99+'), findsOneWidget);

      notifications.value = _withUnread(4);
      await tester.pump();
      expect(find.text('4'), findsOneWidget);

      notifications.value = _withUnread(0);
      await tester.pump();
      expect(find.byKey(const Key('home_notification_badge')), findsNothing);
    });

    testWidgets('Callback: bấm nhắc ôn tập, thẻ thống kê và "Xem tất cả"', (tester) async {
      var reviewTaps = 0;
      HomeStat? tappedStat;
      var seeAllTaps = 0;
      await tester.pumpWidget(
        _app(
          HomeScreen(
            state: HomeSampleData.full,
            onStartReviewClick: () => reviewTaps++,
            onStatClick: (s) => tappedStat = s,
            onSeeAllCoursesClick: () => seeAllTaps++,
          ),
        ),
      );

      await tester.tap(
        find.descendant(of: find.byKey(const Key('home_review_reminder')), matching: find.byType(AppButton)),
      );
      await tester.tap(find.text('Tổng số từ'));
      await tester.scrollUntilVisible(find.text('Xem tất cả'), 200);
      await tester.tap(find.text('Xem tất cả'));

      expect(reviewTaps, 1);
      expect(tappedStat, HomeStat.totalWords);
      expect(seeAllTaps, 1);
    });
  });

  group('Biểu đồ tuần · trục Y', () {
    test('Làm tròn đỉnh trục lên số đẹp chia hết cho 4 khoảng', () {
      expect(WeeklyBarChart.niceAxisMax([12, 20, 8, 25, 15, null, null]), 40);
      expect(WeeklyBarChart.niceAxisMax([3, 1, null, null, null, null, null]), 4);
      expect(WeeklyBarChart.niceAxisMax([null, null, null, null, null, null, null]), 4);
      expect(WeeklyBarChart.niceAxisMax([150, 0, 0, 0, 0, 0, 0]), 200);
    });
  });
}
