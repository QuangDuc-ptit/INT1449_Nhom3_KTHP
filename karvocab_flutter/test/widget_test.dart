import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/core/widgets/cefr_badge.dart';
import 'package:karvocab_flutter/main.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';

void main() {
  group('Kiểm thử Giao diện & Luồng chính (Widget Tests - Rubric INT1449)', () {
    testWidgets('1. SplashScreen hiển thị logo + chữ KarVocab rồi tự chuyển màn', (WidgetTester tester) async {
      await tester.pumpWidget(const KarVocabApp());
      await tester.pump(const Duration(milliseconds: 1000));

      // Trước khi chuyển màn ở 1.5s: logo + chữ thương hiệu, không có nút/loading
      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
      expect(find.text('KarVocab', findRichText: true), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);

      // Chưa có phiên đăng nhập → tự chuyển sang Màn 02, splash bị thay thế
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byKey(const Key('splash_logo')), findsNothing);
      // Không còn route nào phía sau để Back quay về splash
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('2. LoginScreen hiển thị đúng bố cục form Đăng nhập', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.byKey(const Key('auth_wordmark')), findsOneWidget);
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
      expect(find.text('Địa chỉ email'), findsOneWidget);
      expect(find.text('name@email.com'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsNothing);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đăng nhập'), findsOneWidget);
      expect(find.text('Hoặc tiếp tục với'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Đăng ký ngay.'), findsOneWidget);
    });

    testWidgets('3. Bấm "Đăng ký ngay." chuyển sang form Đăng ký', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final registerNow = find.byKey(const Key('auth_register_now'));
      await tester.ensureVisible(registerNow);
      await tester.tap(registerNow);
      await tester.pump();

      expect(find.text('Tạo tài khoản\nKarVocab của bạn'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đăng ký'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsNothing);
      expect(find.text('Đăng ký ngay.'), findsNothing);
    });

    testWidgets('4. AppButton phản hồi đúng sự kiện nhấn và đảm bảo touch target >= 48dp', (WidgetTester tester) async {
      bool isClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Nút kiểm tra',
              onPressed: () => isClicked = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);

      // Kiểm tra chiều cao nút >= 48dp theo Rubric Tiêu chí 2
      final Size buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Bấm nút
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(isClicked, isTrue);
    });

    testWidgets('5. CefrBadge hiển thị đúng cấp độ CEFR', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CefrBadge(level: 'B2'),
          ),
        ),
      );

      expect(find.text('B2'), findsOneWidget);
    });
  });
}
