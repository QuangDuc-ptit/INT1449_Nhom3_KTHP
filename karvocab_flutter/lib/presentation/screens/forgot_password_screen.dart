import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../forgot_password/forgot_password_ui_state.dart';

/// Màn 21 · Quên mật khẩu — chỉ giao diện.
///
/// Ba bước theo [ForgotPasswordUiState.step]: Email → mã OTP 6 số → mật khẩu
/// mới. Màn hình đọc [state] và đưa mọi thao tác ra callback; không tự điều
/// hướng, không gọi API. Nơi mở màn ([ForgotPasswordFlow]) giữ state, gọi
/// AuthRepository và quyết định nút "<" lùi bước hay đóng màn.
class ForgotPasswordScreen extends StatefulWidget {
  final ForgotPasswordUiState state;
  final ValueChanged<String> onEmailChange;
  final VoidCallback onSendOtpClick;
  final ValueChanged<String> onOtpChange;
  final VoidCallback onVerifyOtpClick;
  final VoidCallback onResendOtpClick;
  final ValueChanged<String> onNewPasswordChange;
  final ValueChanged<String> onConfirmPasswordChange;
  final VoidCallback onResetPasswordClick;

  /// Nút "<" ở mọi bước và nút "Quay lại đăng nhập" ở bước Email.
  final VoidCallback onBackClick;

  const ForgotPasswordScreen({
    super.key,
    required this.state,
    required this.onEmailChange,
    required this.onSendOtpClick,
    required this.onOtpChange,
    required this.onVerifyOtpClick,
    required this.onResendOtpClick,
    required this.onNewPasswordChange,
    required this.onConfirmPasswordChange,
    required this.onResetPasswordClick,
    required this.onBackClick,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  /// Nút "<" có vùng chạm 48dp nhưng icon chỉ 24dp: lùi hàng tiêu đề sang trái
  /// phần đệm này để icon vẫn thẳng lề 20dp và cách tiêu đề đúng 12dp.
  static const double _backButtonInset = (AppDimensions.minTouchTarget - AppDimensions.iconMedium) / 2;

  late final TextEditingController _emailController = TextEditingController(text: widget.state.email);
  late final TextEditingController _otpController = TextEditingController(text: widget.state.otp);
  late final TextEditingController _newPasswordController = TextEditingController(text: widget.state.newPassword);
  late final TextEditingController _confirmController = TextEditingController(text: widget.state.confirmPassword);

  @override
  void didUpdateWidget(covariant ForgotPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // State đổi từ bên ngoài (không phải do gõ phím) → đồng bộ lại ô nhập.
    _sync(_emailController, widget.state.email);
    _sync(_otpController, widget.state.otp);
    _sync(_newPasswordController, widget.state.newPassword);
    _sync(_confirmController, widget.state.confirmPassword);
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // Bàn phím bật lên: Scaffold thu nhỏ vùng body, nội dung cuộn được.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.authHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.space16),
                    ...switch (widget.state.step) {
                      ForgotPasswordStep.email => _buildEmailStep(),
                      ForgotPasswordStep.otp => _buildOtpStep(),
                      ForgotPasswordStep.newPassword => _buildNewPasswordStep(),
                    },
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.authHorizontalPadding - _backButtonInset),
      child: Row(
        children: [
          Semantics(
            label: AppStrings.backButtonSemantics,
            button: true,
            excludeSemantics: true,
            child: IconButton(
              key: const Key('forgot_back_icon'),
              onPressed: widget.onBackClick,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppDimensions.minTouchTarget,
                minHeight: AppDimensions.minTouchTarget,
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppDimensions.iconMedium,
                color: AppColors.navyBlue,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12 - _backButtonInset),
          Expanded(
            child: Text(AppStrings.forgotPasswordTitle, style: AppTypography.authScreenTitle),
          ),
          const SizedBox(width: AppDimensions.authHorizontalPadding),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bước 1 · Email
  // ---------------------------------------------------------------------------

  List<Widget> _buildEmailStep() {
    final state = widget.state;
    return [
      const Text(AppStrings.forgotPasswordDescription, style: AppTypography.authBody),
      const SizedBox(height: AppDimensions.space40),
      AppTextField(
        key: const Key('forgot_email'),
        label: AppStrings.forgotPasswordEmailLabel,
        hintText: AppStrings.forgotPasswordEmailHint,
        controller: _emailController,
        onChanged: widget.onEmailChange,
        keyboardType: TextInputType.emailAddress,
        // Done: Flutter tự đóng bàn phím khi bấm.
        textInputAction: TextInputAction.done,
        errorText: state.emailError,
        labelStyle: AppTypography.authFieldLabel,
        hintStyle: AppTypography.authBody,
        borderColor: AppColors.authDivider,
        borderRadius: AppDimensions.authControlRadius,
      ),
      const SizedBox(height: AppDimensions.space24),
      const Text(AppStrings.forgotPasswordNote, style: AppTypography.authBody),
      const SizedBox(height: AppDimensions.space40),
      _primaryButton(
        key: const Key('forgot_send'),
        text: AppStrings.forgotPasswordSend,
        onPressed: widget.onSendOtpClick,
        isEnabled: state.canSendOtp,
      ),
      const SizedBox(height: AppDimensions.space12),
      AppButton(
        key: const Key('forgot_back_to_login'),
        text: AppStrings.forgotPasswordBackToLogin,
        onPressed: widget.onBackClick,
        variant: AppButtonVariant.outline,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navyBlue,
        borderColor: AppColors.primaryBlue,
        borderWidth: AppDimensions.borderThin,
        borderRadius: AppDimensions.authControlRadius,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Bước 2 · Mã OTP
  // ---------------------------------------------------------------------------

  List<Widget> _buildOtpStep() {
    final state = widget.state;
    final offlineOtp = state.offlineOtp;
    return [
      const Text(AppStrings.forgotPasswordOtpDescription, style: AppTypography.authBody),
      Text(state.email.trim(), key: const Key('forgot_otp_email'), style: AppTypography.authFieldLabel),
      if (offlineOtp != null) ...[
        const SizedBox(height: AppDimensions.space24),
        _OfflineOtpNote(code: offlineOtp),
        const SizedBox(height: AppDimensions.space24),
      ] else
        const SizedBox(height: AppDimensions.space40),
      AppTextField(
        key: const Key('forgot_otp'),
        label: AppStrings.forgotPasswordOtpLabel,
        hintText: AppStrings.forgotPasswordOtpHint,
        controller: _otpController,
        onChanged: widget.onOtpChange,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: 6,
        errorText: state.otpError,
        labelStyle: AppTypography.authFieldLabel,
        hintStyle: AppTypography.authBody,
        borderColor: AppColors.authDivider,
        borderRadius: AppDimensions.authControlRadius,
      ),
      const SizedBox(height: AppDimensions.space40),
      _primaryButton(
        key: const Key('forgot_verify'),
        text: AppStrings.forgotPasswordVerify,
        onPressed: widget.onVerifyOtpClick,
        isEnabled: state.canVerifyOtp,
      ),
      const SizedBox(height: AppDimensions.space12),
      Center(
        child: TextButton(
          key: const Key('forgot_resend'),
          onPressed: state.canResendOtp ? widget.onResendOtpClick : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
          ),
          child: Text(
            state.resendSecondsLeft > 0
                ? AppStrings.forgotPasswordResendIn(state.resendSecondsLeft)
                : AppStrings.forgotPasswordResend,
            style: AppTypography.authFieldLabel.copyWith(
              color: state.canResendOtp ? AppColors.navyBlue : AppColors.textMuted,
            ),
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Bước 3 · Mật khẩu mới
  // ---------------------------------------------------------------------------

  List<Widget> _buildNewPasswordStep() {
    final state = widget.state;
    return [
      const Text(AppStrings.forgotPasswordNewPasswordDescription, style: AppTypography.authBody),
      const SizedBox(height: AppDimensions.space40),
      AppTextField(
        key: const Key('forgot_new_password'),
        label: AppStrings.forgotPasswordNewPasswordLabel,
        hintText: AppStrings.forgotPasswordNewPasswordHint,
        controller: _newPasswordController,
        onChanged: widget.onNewPasswordChange,
        isPassword: true,
        errorText: state.newPasswordError,
        labelStyle: AppTypography.authFieldLabel,
        hintStyle: AppTypography.authBody,
        borderColor: AppColors.authDivider,
        borderRadius: AppDimensions.authControlRadius,
      ),
      const SizedBox(height: AppDimensions.space16),
      AppTextField(
        key: const Key('forgot_confirm_password'),
        label: AppStrings.forgotPasswordConfirmLabel,
        hintText: AppStrings.forgotPasswordConfirmHint,
        controller: _confirmController,
        onChanged: widget.onConfirmPasswordChange,
        isPassword: true,
        textInputAction: TextInputAction.done,
        errorText: state.confirmPasswordError,
        labelStyle: AppTypography.authFieldLabel,
        hintStyle: AppTypography.authBody,
        borderColor: AppColors.authDivider,
        borderRadius: AppDimensions.authControlRadius,
      ),
      const SizedBox(height: AppDimensions.space40),
      _primaryButton(
        key: const Key('forgot_reset'),
        text: AppStrings.forgotPasswordReset,
        onPressed: widget.onResetPasswordClick,
        isEnabled: state.canResetPassword,
      ),
    ];
  }

  Widget _primaryButton({
    required Key key,
    required String text,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isEnabled: isEnabled,
      isLoading: widget.state.isSubmitting,
      borderRadius: AppDimensions.authControlRadius,
      textStyle: AppTypography.buttonTextLarge,
    );
  }
}

/// Khung ghi chú hiện mã OTP khi chạy offline: máy không gửi email thật.
class _OfflineOtpNote extends StatelessWidget {
  final String code;

  const _OfflineOtpNote({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('forgot_offline_otp'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.softBlueSurface,
        borderRadius: BorderRadius.circular(AppDimensions.authControlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.forgotPasswordOfflineTitle, style: AppTypography.authBody),
          const SizedBox(height: AppDimensions.space4),
          Text(
            AppStrings.forgotPasswordOfflineCode(code),
            style: AppTypography.authFieldLabel.copyWith(color: AppColors.navyBlue),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Preview (Flutter Widget Previewer)
// -----------------------------------------------------------------------------

Widget _previewFrame(ForgotPasswordUiState state) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ForgotPasswordScreen(
      state: state,
      onEmailChange: (_) {},
      onSendOtpClick: () {},
      onOtpChange: (_) {},
      onVerifyOtpClick: () {},
      onResendOtpClick: () {},
      onNewPasswordChange: (_) {},
      onConfirmPasswordChange: (_) {},
      onResetPasswordClick: () {},
      onBackClick: () {},
    ),
  );
}

@Preview(name: 'Quên mật khẩu · email trống (nút khoá)', size: Size(390, 844))
Widget forgotPasswordEmptyPreview() => _previewFrame(const ForgotPasswordUiState());

@Preview(name: 'Quên mật khẩu · đã nhập email', size: Size(390, 844))
Widget forgotPasswordFilledPreview() => _previewFrame(const ForgotPasswordUiState(email: 'learner@karvocab.com'));

@Preview(name: 'Quên mật khẩu · nhập OTP (offline, đang đếm ngược)', size: Size(390, 844))
Widget forgotPasswordOtpPreview() => _previewFrame(const ForgotPasswordUiState(
      step: ForgotPasswordStep.otp,
      email: 'learner@karvocab.com',
      offlineOtp: '482913',
      resendSecondsLeft: 42,
    ));

@Preview(name: 'Quên mật khẩu · mật khẩu mới', size: Size(390, 844))
Widget forgotPasswordNewPasswordPreview() => _previewFrame(const ForgotPasswordUiState(
      step: ForgotPasswordStep.newPassword,
      email: 'learner@karvocab.com',
    ));
