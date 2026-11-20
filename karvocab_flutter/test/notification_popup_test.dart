import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/presentation/home/home_sample_data.dart';
import 'package:karvocab_flutter/presentation/notifications/notification_sample_data.dart';
import 'package:karvocab_flutter/presentation/notifications/notification_ui_state.dart';
import 'package:karvocab_flutter/presentation/notifications/relative_time.dart';
import 'package:karvocab_flutter/presentation/screens/home_screen.dart';
import 'package:karvocab_flutter/presentation/widgets/notification_popup.dart';

final DateTime _now = DateTime(2026, 11, 20, 10, 0);

Widget _popup(NotificationUiState state, {NotificationPopupCallbacks callbacks = const NotificationPopupCallbacks()}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: NotificationPopup(state: state, callbacks: callbacks, now: _now),
      ),
    ),
  );
}

IconButton _iconButton(WidgetTester tester, String key) => tester.widget<IconButton>(find.byKey(Key(key)));

void main() {
  group('Thời gian tương đối', () {
    test('Vừa xong / phút / giờ / ngày / dd/MM/yyyy', () {
      expect(formatRelativeTime(_now.subtract(const Duration(seconds: 59)), _now), 'Vừa xong');
      expect(formatRelativeTime(_now.subtract(const Duration(minutes: 25)), _now), '25 phút trước');
      expect(formatRelativeTime(_now.subtract(const Duration(hours: 3)), _now), '3 giờ trước');
      expect(formatRelativeTime(_now.subtract(const Duration(days: 6, hours: 23)), _now), '6 ngày trước');
      expect(formatRelativeTime(DateTime(2026, 11, 3, 9), _now), '03/11/2026');
    });
  });

  group('Popup thông báo', () {
    testWidgets('Có dữ liệu: header, chấm chưa đọc, thời gian, footer Tải thêm', (tester) async {
      await tester.pumpWidget(_popup(
        NotificationSampleData.full(_now),
        callbacks: NotificationPopupCallbacks(onMarkAllRead: () {}),
      ));

      expect(find.text('Thông báo của tôi (9)'), findsOneWidget);
      // Chưa đọc có chấm, đã đọc không có
      expect(find.byKey(const Key('notification_unread_dot_n1')), findsOneWidget);
      expect(find.byKey(const Key('notification_unread_dot_n4')), findsNothing);
      expect(find.text('Vừa xong'), findsOneWidget);
      expect(find.text('25 phút trước'), findsOneWidget);
      expect(find.byKey(const Key('notification_load_more')), findsOneWidget);
      expect(_iconButton(tester, 'notification_mark_all_read').onPressed, isNotNull);
    });

    testWidgets('Đang tải thêm: thay chữ bằng vòng xoay', (tester) async {
      await tester.pumpWidget(_popup(NotificationSampleData.loadingMore(_now)));

      expect(find.byKey(const Key('notification_loading_more')), findsOneWidget);
      expect(find.text('Tải thêm'), findsNothing);
    });

    testWidgets('Đang làm mới: icon làm mới không bấm được; hết chưa đọc thì khoá đánh dấu tất cả',
        (tester) async {
      final allRead = NotificationSampleData.full(_now);
      final state = allRead.copyWith(
        items: [for (final n in allRead.items) n.copyWith(isRead: true)],
        unreadCount: 0,
        isRefreshing: true,
      );
      await tester.pumpWidget(_popup(state));

      expect(_iconButton(tester, 'notification_refresh').onPressed, isNull);
      expect(_iconButton(tester, 'notification_mark_all_read').onPressed, isNull);
    });

    testWidgets('Trống: icon chuông + "Bạn chưa có thông báo nào", ẩn footer', (tester) async {
      await tester.pumpWidget(_popup(NotificationSampleData.empty));

      expect(find.text('Thông báo của tôi (0)'), findsOneWidget);
      expect(find.text('Bạn chưa có thông báo nào'), findsOneWidget);
      expect(find.byKey(const Key('notification_load_more')), findsNothing);
    });

    testWidgets('Hết trang (canLoadMore = false): ẩn footer', (tester) async {
      await tester.pumpWidget(_popup(NotificationSampleData.full(_now).copyWith(canLoadMore: false)));
      expect(find.byKey(const Key('notification_load_more')), findsNothing);
    });

    testWidgets('Callback: làm mới, đánh dấu tất cả, tải thêm', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(_popup(
        NotificationSampleData.full(_now),
        callbacks: NotificationPopupCallbacks(
          onRefresh: () => calls.add('refresh'),
          onMarkAllRead: () => calls.add('markAll'),
          onLoadMore: () => calls.add('loadMore'),
        ),
      ));

      await tester.tap(find.byKey(const Key('notification_refresh')));
      await tester.tap(find.byKey(const Key('notification_mark_all_read')));
      await tester.tap(find.byKey(const Key('notification_load_more')));
      expect(calls, ['refresh', 'markAll', 'loadMore']);
    });
  });

  group('Mở / đóng popup từ chuông Trang chủ', () {
    late ValueNotifier<NotificationUiState> notifications;

    setUp(() => notifications = ValueNotifier(NotificationSampleData.full(DateTime.now())));
    tearDown(() => notifications.dispose());

    Future<void> openPopup(WidgetTester tester, NotificationPopupCallbacks callbacks) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          state: HomeSampleData.full,
          notifications: notifications,
          notificationCallbacks: callbacks,
        ),
      ));
      await tester.tap(find.byKey(const Key('home_bell')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPopup), findsOneWidget);
    }

    testWidgets('Popup nằm dưới chuông, rộng = màn hình − 32dp', (tester) async {
      await openPopup(tester, const NotificationPopupCallbacks());

      final screenWidth = tester.getSize(find.byType(HomeScreen)).width;
      final popup = tester.getRect(find.byType(NotificationPopup));
      final bell = tester.getRect(find.byKey(const Key('home_bell')));
      expect(popup.width, screenWidth - 32);
      expect(popup.top, greaterThan(bell.bottom));
    });

    testWidgets('Bấm ra ngoài → đóng và gọi onDismiss', (tester) async {
      var dismissed = 0;
      await openPopup(tester, NotificationPopupCallbacks(onDismiss: () => dismissed++));

      // Góc dưới trái màn hình test (800×600): ngoài lề 16dp của popup
      await tester.tapAt(const Offset(5, 590));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPopup), findsNothing);
      expect(dismissed, 1);
    });

    testWidgets('Bấm lại chuông → đóng', (tester) async {
      await openPopup(tester, const NotificationPopupCallbacks());

      await tester.tap(find.byKey(const Key('home_bell')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPopup), findsNothing);
    });

    testWidgets('Nút Back → đóng', (tester) async {
      await openPopup(tester, const NotificationPopupCallbacks());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPopup), findsNothing);
      // Vẫn ở Trang chủ
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Bấm thông báo → onNotificationClick(id) rồi đóng popup', (tester) async {
      String? clicked;
      await openPopup(tester, NotificationPopupCallbacks(onNotificationClick: (id) => clicked = id));

      await tester.tap(find.byKey(const Key('notification_n2')));
      await tester.pumpAndSettle();
      expect(clicked, 'n2');
      expect(find.byType(NotificationPopup), findsNothing);
    });

    testWidgets('Popup tự cập nhật khi state đổi (đã mở)', (tester) async {
      await openPopup(tester, const NotificationPopupCallbacks());
      expect(find.byKey(const Key('notification_unread_dot_n1')), findsOneWidget);

      final s = notifications.value;
      notifications.value = s.copyWith(
        items: [for (final n in s.items) n.copyWith(isRead: true)],
        unreadCount: 0,
      );
      await tester.pump();
      expect(find.byKey(const Key('notification_unread_dot_n1')), findsNothing);
    });
  });
}
