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
      VoidCallback? onResend,
      VoidCallback? onBack,
    }) {
      return MaterialApp(
        home: ForgotPasswordScreen(
          state: state,
          onEmailChange: onEmailChange ?? (_) {},
          onSendOtpClick: onSend ?? () {},
          onOtpChange: (_) {},
          onVerifyOtpClick: () {},
          onResendOtpClick: onResend ?? () {},
          onNewPasswordChange: (_) {},
          onConfirmPasswordChange: (_) {},
          onResetPasswordClick: () {},
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

    testWidgets('Đã nhập email → bấm gửi gọi onSendOtpClick', (tester) async {
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

    testWidgets('Bước OTP: hiện email, khung mã offline; đang đếm ngược thì khoá "Gửi lại mã"', (tester) async {
      var resent = 0;
      await tester.pumpWidget(screen(
        const ForgotPasswordUiState(
          step: ForgotPasswordStep.otp,
          email: 'a@b.com',
          offlineOtp: '482913',
          resendSecondsLeft: 42,
        ),
        onResend: () => resent++,
      ));

      expect(find.text(AppStrings.forgotPasswordOtpDescription), findsOneWidget);
      expect(find.text('a@b.com'), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordOfflineCode('482913')), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordResendIn(42)), findsOneWidget);
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.keyboardType, TextInputType.number);
      expect(input.maxLength, 6);

      await tester.tap(find.byKey(const Key('forgot_resend')));
      expect(resent, 0);
      expect(tester.getSize(find.byKey(const Key('forgot_resend'))).height, greaterThanOrEqualTo(48));
    });

    testWidgets('Bước OTP: hết đếm ngược thì "Gửi lại mã" gọi callback; không có mã offline thì ẩn khung',
        (tester) async {
      var resent = 0;
      await tester.pumpWidget(screen(
        const ForgotPasswordUiState(step: ForgotPasswordStep.otp, email: 'a@b.com'),
        onResend: () => resent++,
      ));

      expect(find.byKey(const Key('forgot_offline_otp')), findsNothing);
      await tester.tap(find.text(AppStrings.forgotPasswordResend));
      expect(resent, 1);
    });

    testWidgets('Bước mật khẩu mới: hai ô ẩn mật khẩu, nút khoá khi chưa nhập đủ', (tester) async {
      await tester.pumpWidget(screen(const ForgotPasswordUiState(
        step: ForgotPasswordStep.newPassword,
        email: 'a@b.com',
        newPassword: 'Karvocab9',
      )));

      expect(find.text(AppStrings.forgotPasswordNewPasswordLabel), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordConfirmLabel), findsOneWidget);
      expect(tester.widgetList<TextField>(find.byType(TextField)).every((f) => f.obscureText), isTrue);
      expect(tester.widget<AppButton>(find.byKey(const Key('forgot_reset'))).isEnabled, isFalse);
    });
  });

  group('Màn 21 · Luồng quên mật khẩu với AuthRepository', () {
    late AuthRepository auth;

    setUp(() => auth = AuthRepository(latency: Duration.zero));

    Finder input(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
    AppTextField field(WidgetTester tester, String key) => tester.widget<AppTextField>(find.byKey(Key(key)));

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> openFlow(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(authRepository: auth)));
      await tester.tap(find.byKey(const Key('login_forgot_password')));
      await tester.pumpAndSettle();
    }

    Future<void> sendOtp(WidgetTester tester, String email) async {
      await tester.enterText(input('forgot_email'), email);
      await tapKey(tester, 'forgot_send');
    }

    /// Đọc mã OTP từ khung ghi chú offline.
    String shownOtp(WidgetTester tester) {
      final prefix = AppStrings.forgotPasswordOfflineCode('');
      final text = tester.widget<Text>(find.textContaining(prefix)).data!;
      return text.substring(prefix.length);
    }

    testWidgets('Email sai định dạng → lỗi Validators dưới ô Email, không gửi mã', (tester) async {
      await openFlow(tester);
      await sendOtp(tester, 'khong-phai-email');

      expect(field(tester, 'forgot_email').errorText, Validators.email('khong-phai-email'));
      expect(find.byKey(const Key('forgot_otp')), findsNothing);
    });

    testWidgets('Email chưa đăng ký → lỗi AuthException dưới ô Email; gõ lại thì lỗi mất', (tester) async {
      await openFlow(tester);
      await sendOtp(tester, 'khongco@karvocab.com');

      expect(field(tester, 'forgot_email').errorText, 'Không tìm thấy tài khoản với email này');
      await tester.enterText(input('forgot_email'), 'khongco@karvocab.co');
      await tester.pump();
      expect(field(tester, 'forgot_email').errorText, isNull);
    });

    testWidgets('Gửi mã → bước OTP, đếm ngược 60 giây rồi mới gửi lại được', (tester) async {
      await openFlow(tester);
      await sendOtp(tester, AuthRepository.demoEmail);

      expect(find.byKey(const Key('forgot_otp')), findsOneWidget);
      expect(shownOtp(tester), matches(RegExp(r'^\d{6}$')));
      expect(find.text(AppStrings.forgotPasswordResend), findsNothing);
      expect(tester.widget<TextButton>(find.byKey(const Key('forgot_resend'))).onPressed, isNull);

      await tester.pump(const Duration(seconds: 61));
      expect(find.text(AppStrings.forgotPasswordResend), findsOneWidget);

      await tapKey(tester, 'forgot_resend');
      expect(find.text(AppStrings.forgotPasswordOtpResent), findsOneWidget);
      expect(
        find.text(AppStrings.forgotPasswordResendIn(ForgotPasswordUiState.resendCooldownSeconds)),
        findsOneWidget,
      );
      // Mã mới thay mã cũ: mã đang hiện xác nhận được.
      await tester.enterText(input('forgot_otp'), shownOtp(tester));
      await tapKey(tester, 'forgot_verify');
      expect(find.byKey(const Key('forgot_new_password')), findsOneWidget);
    });

    testWidgets('Nút "<" ở bước OTP quay về bước Email, giữ email đã nhập', (tester) async {
      await openFlow(tester);
      await sendOtp(tester, AuthRepository.demoEmail);

      await tester.tap(find.byKey(const Key('forgot_back_icon')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('forgot_email')), findsOneWidget);
      expect(tester.widget<TextField>(input('forgot_email')).controller!.text, AuthRepository.demoEmail);
    });

    testWidgets('Đủ luồng: sai mã, mật khẩu yếu, không khớp → lỗi dưới ô; đúng hết → toast, về Đăng nhập',
        (tester) async {
      await openFlow(tester);
      await sendOtp(tester, AuthRepository.demoEmail);
      final code = shownOtp(tester);

      await tester.enterText(input('forgot_otp'), '12a');
      await tapKey(tester, 'forgot_verify');
      expect(field(tester, 'forgot_otp').errorText, Validators.otp('12a'));

      await tester.enterText(input('forgot_otp'), code == '000000' ? '111111' : '000000');
      await tapKey(tester, 'forgot_verify');
      expect(field(tester, 'forgot_otp').errorText, 'Mã OTP không chính xác');

      await tester.enterText(input('forgot_otp'), code);
      await tapKey(tester, 'forgot_verify');
      expect(find.byKey(const Key('forgot_new_password')), findsOneWidget);

      await tester.enterText(input('forgot_new_password'), 'yeu');
      await tester.enterText(input('forgot_confirm_password'), 'yeu');
      await tapKey(tester, 'forgot_reset');
      expect(field(tester, 'forgot_new_password').errorText, Validators.strongPassword('yeu'));

      await tester.enterText(input('forgot_new_password'), 'Karvocab9');
      await tester.enterText(input('forgot_confirm_password'), 'Karvocab8');
      await tapKey(tester, 'forgot_reset');
      expect(field(tester, 'forgot_new_password').errorText, isNull);
      expect(field(tester, 'forgot_confirm_password').errorText, Validators.confirmPassword('Karvocab8', 'Karvocab9'));

      await tester.enterText(input('forgot_confirm_password'), 'Karvocab9');
      await tapKey(tester, 'forgot_reset');
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordResetSuccess), findsOneWidget);

      // Mật khẩu mới đăng nhập được.
      await tester.runAsync(() => auth.login(AuthRepository.demoEmail, 'Karvocab9'));
      expect(auth.currentUser, isNotNull);
    });
  });
}
