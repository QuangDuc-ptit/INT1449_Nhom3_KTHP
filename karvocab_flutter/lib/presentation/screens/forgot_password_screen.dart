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
/// Màn hình đọc [state] và đưa mọi thao tác ra callback; không tự điều hướng,
/// không gọi API. Nơi mở màn giữ [ForgotPasswordUiState] và quyết định làm gì
/// khi bấm "Gửi liên kết đặt lại" / quay lại.
class ForgotPasswordScreen extends StatefulWidget {
  final ForgotPasswordUiState state;
  final ValueChanged<String> onEmailChange;
  final VoidCallback onSendResetLinkClick;
  final VoidCallback onBackClick;

  const ForgotPasswordScreen({
    super.key,
    required this.state,
    required this.onEmailChange,
    required this.onSendResetLinkClick,
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

  @override
  void didUpdateWidget(covariant ForgotPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // State đổi từ bên ngoài (không phải do gõ phím) → đồng bộ lại ô nhập.
    if (_emailController.text != widget.state.email) {
      _emailController.value = TextEditingValue(
        text: widget.state.email,
        selection: TextSelection.collapsed(offset: widget.state.email.length),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                child: _buildBody(),
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

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.space16),
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
          labelStyle: AppTypography.authFieldLabel,
          hintStyle: AppTypography.authBody,
          borderColor: AppColors.authDivider,
          borderRadius: AppDimensions.authControlRadius,
        ),
        const SizedBox(height: AppDimensions.space24),
        const Text(AppStrings.forgotPasswordNote, style: AppTypography.authBody),
        const SizedBox(height: AppDimensions.space40),
        AppButton(
          key: const Key('forgot_send'),
          text: AppStrings.forgotPasswordSend,
          onPressed: widget.onSendResetLinkClick,
          isEnabled: widget.state.canSendResetLink,
          backgroundColor: AppColors.authButton,
          borderRadius: AppDimensions.authControlRadius,
          textStyle: AppTypography.buttonTextLarge,
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
        const SizedBox(height: AppDimensions.space24),
      ],
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
      onSendResetLinkClick: () {},
      onBackClick: () {},
    ),
  );
}

@Preview(name: 'Quên mật khẩu · email trống (nút khoá)', size: Size(390, 844))
Widget forgotPasswordEmptyPreview() => _previewFrame(const ForgotPasswordUiState());

@Preview(name: 'Quên mật khẩu · đã nhập email', size: Size(390, 844))
Widget forgotPasswordFilledPreview() => _previewFrame(const ForgotPasswordUiState(email: 'learner@karvocab.com'));
