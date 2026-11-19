import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/core/widgets/cefr_badge.dart';
import 'package:karvocab_flutter/main.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';

void main() {
  group('Kiểm thử Giao diện & Luồng chính (Widget Tests - Rubric INT1449)', () {
    testWidgets('1. SplashScreen hiển thị đúng thương hiệu và slogan KarVocab', (WidgetTester tester) async {
      await tester.pumpWidget(const KarVocabApp());
      await tester.pump(const Duration(seconds: 2));

      // Kiểm tra sự xuất hiện của tên thương hiệu và slogan
      expect(find.text('KarVocab', findRichText: true), findsOneWidget);
      expect(find.text('Learn Smart, Remember Longer'), findsOneWidget);
    });

    testWidgets('2. LoginScreen hiển thị đầy đủ các trường nhập liệu và nút Demo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Kiểm tra tiêu đề và ô nhập liệu
      expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
      expect(find.text('Địa chỉ Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);

      // Kiểm tra nút Đăng nhập chính và nút Demo Mode
      expect(find.widgetWithText(AppButton, 'Đăng nhập'), findsOneWidget);
      expect(find.text('⚡ Chế độ Dùng thử (Demo Offline)'), findsOneWidget);
    });

    testWidgets('3. LoginScreen báo lỗi validation khi để trống thông tin', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Bấm nút Đăng nhập khi chưa điền form
      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      // Kiểm tra thông báo lỗi validation hiển thị
      expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
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
