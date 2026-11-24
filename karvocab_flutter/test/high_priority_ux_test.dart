import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/presentation/home/home_state_builder.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';

void main() {
  group('Màn 02 · Đăng nhập kiểm tra form trên máy', () {
    Future<AuthRepository> pumpLogin(WidgetTester tester) async {
      final auth = AuthRepository(latency: Duration.zero);
      await tester.pumpWidget(MaterialApp(home: LoginScreen(authRepository: auth)));
      return auth;
    }

    testWidgets('Để trống → báo nhập email / mật khẩu, không báo "chưa được đăng ký"', (tester) async {
      final auth = await pumpLogin(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.text('Email chưa được đăng ký'), findsNothing);
      expect(auth.isLoggedIn, isFalse);
    });

    testWidgets('Email sai định dạng → báo không hợp lệ', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(find.byType(TextField).at(0), 'abc');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pump();
      expect(find.textContaining('Email không hợp lệ'), findsOneWidget);
    });
  });

  test('Không còn dữ liệu giả: thư viện, tiến độ, chuỗi ngày và biểu đồ tuần đều bắt đầu trống', () {
    final store = CollectionStore(latency: Duration.zero);
    final dashboard = DashboardStore.forTest(collections: store);
    final home = HomeStateBuilder.build(collections: store, dashboard: dashboard);

    expect(store.collections, isEmpty);
    expect(store.totalWordCount, 0);
    expect(dashboard.streak, 0);
    expect(dashboard.dueVocabularies, isEmpty);
    expect(home.weeklyStats.whereType<int>().every((v) => v == 0), isTrue);
    expect(home.userName, isEmpty);
  });

  test('Lời chào dùng tên gọi (chữ cuối họ tên); chưa có tên thì chỉ "Xin chào!"', () {
    expect(AppStrings.homeGreeting('Nguyễn Minh Anh'), 'Xin chào, Anh!');
    expect(AppStrings.homeGreeting('  '), 'Xin chào!');
  });
}
