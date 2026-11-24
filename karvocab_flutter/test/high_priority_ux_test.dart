import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
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

  test('Dữ liệu mẫu nhất quán: hôm nay chưa học, có streak, có từ đã học / đã thuộc / mới', () {
    final dashboard = DashboardStore.forTest();
    final store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    final home = HomeStateBuilder.build(collections: store, dashboard: dashboard);
    final ids = MockVocabData.initialVocabularies.map((v) => v.id);

    // Mục tiêu ngày và cột hôm nay của biểu đồ cùng là 0 khi streak chỉ tính tới hôm qua.
    expect(dashboard.studiedToday, isFalse);
    expect(dashboard.streak, greaterThan(0));
    expect(home.reviewedToday, 0);
    expect(home.weeklyStats[home.todayIndex], 0);

    // Đã có lịch sử học nên phải có từ đã học, khớp với "Từ chưa học" ở Trang chủ.
    final learned = ids.where(dashboard.isLearned).length;
    expect(learned, greaterThan(0));
    expect(home.newWords, home.totalWords - learned);
    expect(ids.where((id) => dashboard.progressOf(id)!.mastered), isNotEmpty);

    // Từ đến hạn ôn đều là từ đã học (từ mới không bị gọi là "ôn lại").
    expect(dashboard.dueVocabularies.where((v) => dashboard.isLearned(v.id)), isNotEmpty);
  });
}
