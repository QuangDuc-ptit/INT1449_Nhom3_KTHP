import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/password_rules_hint.dart';

enum _ResetStep { email, otp, newPassword }

/// Màn 21 · Quên mật khẩu
/// Luồng: Nhập Email → Nhận mã OTP 6 số (đếm ngược 60s để gửi lại) → Đặt mật khẩu mới.
/// Khi hoàn tất, `pop` trả về email để Màn 02 điền sẵn.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final AuthRepository? authRepository;

  const ForgotPasswordScreen({super.key, this.initialEmail = '', this.authRepository});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int resendSeconds = 60;

  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  String? _error;
  String? _confirmError;
  int _secondsLeft = 0;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsLeft = resendSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final emailError = Validators.email(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    await _run(() async {
      final code = await _auth.requestPasswordReset(_emailController.text);
      if (!mounted) return;
      _otpController.clear();
      setState(() => _step = _ResetStep.otp);
      _startCountdown();
      // Chế độ offline: hiển thị mã thay cho email thật.
      AppToast.info(
        context,
        'Mã OTP (Demo) đã gửi tới ${_emailController.text.trim()}: $code',
        duration: const Duration(seconds: 8),
      );
    });
  }

  Future<void> _verifyOtp() async {
    final otpError = Validators.otp(_otpController.text);
    if (otpError != null) {
      setState(() => _error = otpError);
      return;
    }
    await _run(() async {
      await _auth.verifyOtp(_emailController.text, _otpController.text);
      if (!mounted) return;
      _countdown?.cancel();
      setState(() => _step = _ResetStep.newPassword);
    });
  }

  Future<void> _resetPassword() async {
    final passwordError = Validators.strongPassword(_passwordController.text);
    final confirmError = Validators.confirmPassword(_confirmController.text, _passwordController.text);
    setState(() {
      _error = passwordError;
      _confirmError = confirmError;
    });
    if (passwordError != null || confirmError != null) return;

    await _run(() async {
      await _auth.resetPassword(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim());
    });
  }

  void _handleBack() {
    switch (_step) {
      case _ResetStep.email:
        Navigator.of(context).pop();
        break;
      case _ResetStep.otp:
        _countdown?.cancel();
        setState(() {
          _step = _ResetStep.email;
          _error = null;
        });
        break;
      case _ResetStep.newPassword:
        setState(() {
          _step = _ResetStep.otp;
          _error = null;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _ResetStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        appBar: AppBar(
          title: Text('Quên mật khẩu', style: AppTypography.headingMedium),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Quay lại',
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIndicator(current: _step.index),
                const SizedBox(height: AppDimensions.space24),
                ..._buildStepContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepContent() {
    switch (_step) {
      case _ResetStep.email:
        return [
          Text('Đặt lại mật khẩu', style: AppTypography.headingLarge),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Nhập email đã đăng ký, KarVocab sẽ gửi cho bạn mã xác thực gồm 6 chữ số.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space24),
          AppTextField(
            label: 'Địa chỉ Email',
            hintText: 'name@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _sendOtp(),
          ),
          const SizedBox(height: AppDimensions.space24),
          AppButton(text: 'Gửi mã OTP', onPressed: _sendOtp, isLoading: _isLoading),
        ];

      case _ResetStep.otp:
        return [
          Text('Nhập mã xác thực', style: AppTypography.headingLarge),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Mã OTP đã được gửi tới ${_emailController.text.trim()}. Mã có hiệu lực trong 5 phút.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space24),
          AppTextField(
            label: 'Mã OTP (6 chữ số)',
            hintText: '••••••',
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            autofocus: true,
            prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textMuted, size: 20),
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _secondsLeft > 0 ? 'Gửi lại mã sau ${_secondsLeft}s' : 'Chưa nhận được mã?',
                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
              ),
              TextButton(
                onPressed: _secondsLeft > 0 || _isLoading ? null : _sendOtp,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                ),
                child: Text(
                  'Gửi lại mã',
                  style: AppTypography.bodyBold.copyWith(
                    fontSize: 14,
                    color: _secondsLeft > 0 ? AppColors.textMuted : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          AppButton(text: 'Xác nhận mã', onPressed: _verifyOtp, isLoading: _isLoading),
        ];

      case _ResetStep.newPassword:
        return [
          Text('Tạo mật khẩu mới', style: AppTypography.headingLarge),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Mật khẩu mới cần khác mật khẩu cũ và đủ mạnh để bảo vệ tài khoản.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space24),
          AppTextField(
            label: 'Mật khẩu mới',
            hintText: 'Tối thiểu 8 ký tự',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppDimensions.space8),
          PasswordRulesHint(password: _passwordController.text),
          const SizedBox(height: AppDimensions.space16),
          AppTextField(
            label: 'Xác nhận mật khẩu mới',
            hintText: 'Nhập lại mật khẩu mới',
            controller: _confirmController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textMuted, size: 20),
            errorText: _confirmError,
            onChanged: (_) => setState(() => _confirmError = null),
          ),
          const SizedBox(height: AppDimensions.space24),
          AppButton(text: 'Đặt lại mật khẩu', onPressed: _resetPassword, isLoading: _isLoading),
        ];
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Email', 'Mã OTP', 'Mật khẩu mới'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isDone = i < current;
        final isActive = i == current;
        final color = isDone || isActive ? AppColors.primaryBlue : AppColors.borderLight;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : AppDimensions.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  labels[i],
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    color: isActive ? AppColors.primaryBlue : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
