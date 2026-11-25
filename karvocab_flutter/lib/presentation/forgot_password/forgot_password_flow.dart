import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/repositories/auth_repository.dart';
import '../screens/forgot_password_screen.dart';
import 'forgot_password_ui_state.dart';

/// Nơi giữ [ForgotPasswordUiState] và nối callback của Màn 21 với
/// [AuthRepository]: requestPasswordReset → verifyOtp → resetPassword.
///
/// - Lỗi định dạng (Validators) và lỗi [AuthException] của từng bước hiện dưới
///   ô nhập của bước đó, giống Màn 02. Lỗi không gắn với ô nào (gửi lại mã,
///   phiên đặt lại hết hạn) hiện bằng toast.
/// - Chạy offline (không có backend) thì không có email thật: mã OTP do
///   requestPasswordReset trả về được hiện trong khung ghi chú ở bước OTP.
/// - Đặt lại thành công: toast rồi đóng màn, quay về Đăng nhập.
class ForgotPasswordFlow extends StatefulWidget {
  final AuthRepository? authRepository;

  const ForgotPasswordFlow({super.key, this.authRepository});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;

  ForgotPasswordUiState _state = const ForgotPasswordUiState();
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _update(ForgotPasswordUiState Function(ForgotPasswordUiState s) change) {
    if (!mounted) return;
    setState(() => _state = change(_state));
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _update((s) => s.copyWith(resendSecondsLeft: ForgotPasswordUiState.resendCooldownSeconds));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = _state.resendSecondsLeft - 1;
      if (left <= 0) timer.cancel();
      _update((s) => s.copyWith(resendSecondsLeft: left < 0 ? 0 : left));
    });
  }

  /// Gọi requestPasswordReset; trả về mã OTP hoặc `null` nếu lỗi (đã báo lỗi).
  Future<String?> _requestOtp({required bool isResend}) async {
    _update((s) => s.copyWith(isSubmitting: true));
    try {
      final code = await _auth.requestPasswordReset(_state.email.trim());
      _update((s) => s.copyWith(isSubmitting: false));
      return code;
    } on AuthException catch (e) {
      if (!mounted) return null;
      if (isResend) {
        _update((s) => s.copyWith(isSubmitting: false));
        AppToast.error(context, e.message);
      } else {
        _update((s) => s.copyWith(isSubmitting: false, emailError: e.message));
      }
      return null;
    }
  }

  Future<void> _handleSendOtp() async {
    if (_state.isSubmitting) return;
    FocusScope.of(context).unfocus();
    final emailError = Validators.email(_state.email);
    if (emailError != null) {
      _update((s) => s.copyWith(emailError: emailError));
      return;
    }
    _update((s) => s.copyWith(emailError: null));
    final code = await _requestOtp(isResend: false);
    if (code == null || !mounted) return;
    _update((s) => s.copyWith(
          step: ForgotPasswordStep.otp,
          otp: '',
          otpError: null,
          offlineOtp: _auth.usesBackend ? null : code,
        ));
    _startResendCountdown();
  }

  Future<void> _handleResendOtp() async {
    if (!_state.canResendOtp) return;
    FocusScope.of(context).unfocus();
    final code = await _requestOtp(isResend: true);
    if (code == null || !mounted) return;
    _update((s) => s.copyWith(
          otp: '',
          otpError: null,
          offlineOtp: _auth.usesBackend ? null : code,
        ));
    AppToast.info(context, AppStrings.forgotPasswordOtpResent);
    _startResendCountdown();
  }

  Future<void> _handleVerifyOtp() async {
    if (_state.isSubmitting) return;
    FocusScope.of(context).unfocus();
    final otpError = Validators.otp(_state.otp);
    if (otpError != null) {
      _update((s) => s.copyWith(otpError: otpError));
      return;
    }
    _update((s) => s.copyWith(isSubmitting: true, otpError: null));
    try {
      await _auth.verifyOtp(_state.email.trim(), _state.otp.trim());
    } on AuthException catch (e) {
      _update((s) => s.copyWith(isSubmitting: false, otpError: e.message));
      return;
    }
    _update((s) => s.copyWith(
          isSubmitting: false,
          step: ForgotPasswordStep.newPassword,
          newPassword: '',
          confirmPassword: '',
          newPasswordError: null,
          confirmPasswordError: null,
        ));
  }

  Future<void> _handleResetPassword() async {
    if (_state.isSubmitting) return;
    FocusScope.of(context).unfocus();
    final newPasswordError = Validators.strongPassword(_state.newPassword);
    final confirmError = Validators.confirmPassword(_state.confirmPassword, _state.newPassword);
    if (newPasswordError != null || confirmError != null) {
      _update((s) => s.copyWith(newPasswordError: newPasswordError, confirmPasswordError: confirmError));
      return;
    }
    _update((s) => s.copyWith(isSubmitting: true, newPasswordError: null, confirmPasswordError: null));
    try {
      await _auth.resetPassword(_state.email.trim(), _state.newPassword);
    } on AuthException catch (e) {
      if (!mounted) return;
      switch (e.field) {
        case AuthErrorField.otp:
          // Nối backend: mã chỉ được kiểm tra lúc đặt lại → lùi về bước OTP để nhập lại.
          _update((s) => s.copyWith(isSubmitting: false, step: ForgotPasswordStep.otp, otpError: e.message));
        case AuthErrorField.password:
          _update((s) => s.copyWith(isSubmitting: false, newPasswordError: e.message));
        case AuthErrorField.email:
        case null:
          _update((s) => s.copyWith(isSubmitting: false));
          AppToast.error(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    AppToast.success(context, AppStrings.forgotPasswordResetSuccess);
    Navigator.of(context).pop();
  }

  void _handleBack() {
    if (_state.isSubmitting) return;
    FocusScope.of(context).unfocus();
    switch (_state.step) {
      case ForgotPasswordStep.email:
        Navigator.of(context).pop();
      case ForgotPasswordStep.otp:
        // Về bước Email: bỏ mã cũ và bộ đếm, gửi lại thì mã mới thay mã cũ.
        _resendTimer?.cancel();
        _update((s) => s.copyWith(
              step: ForgotPasswordStep.email,
              otp: '',
              otpError: null,
              offlineOtp: null,
              resendSecondsLeft: 0,
            ));
      case ForgotPasswordStep.newPassword:
        _update((s) => s.copyWith(step: ForgotPasswordStep.otp));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Nút back hệ thống ở bước 2, 3 cũng lùi bước như nút "<".
      canPop: _state.step == ForgotPasswordStep.email && !_state.isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: ForgotPasswordScreen(
        state: _state,
        onEmailChange: (v) => _update((s) => s.copyWith(email: v, emailError: null)),
        onSendOtpClick: _handleSendOtp,
        onOtpChange: (v) => _update((s) => s.copyWith(otp: v, otpError: null)),
        onVerifyOtpClick: _handleVerifyOtp,
        onResendOtpClick: _handleResendOtp,
        onNewPasswordChange: (v) => _update((s) => s.copyWith(newPassword: v, newPasswordError: null)),
        onConfirmPasswordChange: (v) => _update((s) => s.copyWith(confirmPassword: v, confirmPasswordError: null)),
        onResetPasswordClick: _handleResetPassword,
        onBackClick: _handleBack,
      ),
    );
  }
}
