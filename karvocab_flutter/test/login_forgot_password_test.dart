import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/utils/validators.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/core/widgets/app_text_field.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/presentation/forgot_password/forgot_password_ui_state.dart';
import 'package:karvocab_flutter/presentation/screens/forgot_password_screen.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';

void main() {
  group('AuthRepository.login — tách lỗi theo ô nhập', () {
    final auth = AuthRepository(latency: Duration.zero);

    test('Email chưa đăng ký → lỗi gắn với ô Email', () async {
      await expectLater(
        auth.login('khongco@karvocab.com', 'Karvocab1'),
        throwsA(isA<AuthException>()
            .having((e) => e.field, 'field', AuthErrorField.email)
            .having((e) => e.message, 'message', AppStrings.loginEmailNotRegistered)),
      );
    });

    test('Sai mật khẩu → lỗi gắn với ô Mật khẩu', () async {
      await expectLater(
        auth.login(AuthRepository.demoEmail, 'sai-mat-khau'),
        throwsA(isA<AuthException>()
            .having((e) => e.field, 'field', AuthErrorField.password)
            .having((e) => e.message, 'message', AppStrings.loginWrongPassword)),
      );
    });
  });

  group('Màn 02 · Đăng nhập — báo lỗi dưới ô nhập', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(authRepository: AuthRepository(latency: Duration.zero))));
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('login_email')), matching: find.byType(TextField)), email);
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('login_password')), matching: find.byType(TextField)), password);
      final loginButton = find.widgetWithText(AppButton, 'Đăng nhập');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }

    AppTextField field(WidgetTester tester, String key) => tester.widget<AppTextField>(find.byKey(ValueKey(key)));

    testWidgets('Sai mật khẩu → lỗi dưới ô Mật khẩu, không rời màn', (tester) async {
      await login(tester, AuthRepository.demoEmail, 'sai-mat-khau');

      expect(find.text(AppStrings.loginWrongPassword), findsOneWidget);
      expect(field(tester, 'login_password').errorText, AppStrings.loginWrongPassword);
      expect(field(tester, 'login_email').errorText, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Email chưa đăng ký → lỗi dưới ô Email', (tester) async {
      await login(tester, 'khongco@karvocab.com', 'Karvocab1');

      expect(find.text(AppStrings.loginEmailNotRegistered), findsOneWidget);
      expect(field(tester, 'login_email').errorText, AppStrings.loginEmailNotRegistered);
      expect(field(tester, 'login_password').errorText, isNull);
    });

    testWidgets('Mật khẩu trống → lỗi Validators dưới ô Mật khẩu', (tester) async {
      await login(tester, AuthRepository.demoEmail, '');

      expect(field(tester, 'login_password').errorText, Validators.loginPassword(''));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Mật khẩu ngắn không bị chặn ở máy (khớp LoginDto): để AuthRepository báo sai mật khẩu',
        (tester) async {
      await login(tester, AuthRepository.demoEmail, '1');

      expect(field(tester, 'login_password').errorText, AppStrings.loginWrongPassword);
    });

    testWidgets('Gõ lại vào ô bị lỗi thì lỗi biến mất', (tester) async {
      await login(tester, AuthRepository.demoEmail, 'sai-mat-khau');
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('login_password')), matching: find.byType(TextField)), 'x');
      await tester.pump();

      expect(find.text(AppStrings.loginWrongPassword), findsNothing);
    });

    testWidgets('"Quên mật khẩu?" mở Màn 21, nút "<" quay lại', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(authRepository: AuthRepository(latency: Duration.zero))));
      await tester.tap(find.byKey(const Key('login_forgot_password')));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('forgot_back_icon')));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Màn 21 · Quên mật khẩu', () {
    Widget screen(
      ForgotPasswordUiState state, {
      ValueChanged<String>? onEmailChange,
      VoidCallback? onSend,
      VoidCallback? onBack,
    }) {
      return MaterialApp(
        home: ForgotPasswordScreen(
          state: state,
          onEmailChange: onEmailChange ?? (_) {},
          onSendResetLinkClick: onSend ?? () {},
          onBackClick: onBack ?? () {},
        ),
      );
    }

    testWidgets('Hiển thị đủ chữ theo mô tả', (tester) async {
      await tester.pumpWidget(screen(const ForgotPasswordUiState()));

      for (final text in [
        AppStrings.forgotPasswordTitle,
        AppStrings.forgotPasswordDescription,
        AppStrings.forgotPasswordEmailLabel,
        AppStrings.forgotPasswordEmailHint,
        AppStrings.forgotPasswordNote,
        AppStrings.forgotPasswordSend,
        AppStrings.forgotPasswordBackToLogin,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('Email trống → nút gửi bị khoá, bấm không gọi callback', (tester) async {
      var sent = 0;
      await tester.pumpWidget(screen(const ForgotPasswordUiState(email: '  '), onSend: () => sent++));

      expect(tester.widget<AppButton>(find.byKey(const Key('forgot_send'))).isEnabled, isFalse);
      await tester.tap(find.byKey(const Key('forgot_send')));
      expect(sent, 0);
    });

    testWidgets('Đã nhập email → bấm gửi gọi onSendResetLinkClick', (tester) async {
      var sent = 0;
      await tester.pumpWidget(screen(const ForgotPasswordUiState(email: 'a@b.com'), onSend: () => sent++));

      await tester.tap(find.byKey(const Key('forgot_send')));
      expect(sent, 1);
    });

    testWidgets('Gõ email gọi onEmailChange; hai nút quay lại gọi onBackClick', (tester) async {
      final typed = <String>[];
      var back = 0;
      await tester.pumpWidget(screen(const ForgotPasswordUiState(), onEmailChange: typed.add, onBack: () => back++));

      await tester.enterText(find.byType(TextField), 'learner@karvocab.com');
      expect(typed.last, 'learner@karvocab.com');
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.keyboardType, TextInputType.emailAddress);
      expect(input.textInputAction, TextInputAction.done);

      await tester.tap(find.byKey(const Key('forgot_back_icon')));
      await tester.tap(find.byKey(const Key('forgot_back_to_login')));
      expect(back, 2);
    });

    testWidgets('Nút "<" có vùng chạm tối thiểu 48dp', (tester) async {
      await tester.pumpWidget(screen(const ForgotPasswordUiState()));

      final size = tester.getSize(find.byKey(const Key('forgot_back_icon')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
