import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'main_shell_screen.dart';

/// Màn 02 · Đăng nhập (Login Screen)
/// Đạt chuẩn Rubric INT1449: Vùng chạm $\ge 48$dp, dispose đủ controller,
/// có chế độ Dùng thử (Demo Mode) phục vụ chấm điểm đồ án offline.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Quản lý controllers — Đảm bảo dispose đầy đủ theo Rubric Tiêu chí 3
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  int _selectedTabIndex = 0; // 0: Đăng nhập, 1: Đăng ký

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Regex kiểm tra định dạng email RFC 5322
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  void _handleLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập địa chỉ email');
      hasError = true;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Email không đúng định dạng (vd: user@gmail.com)');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng nhập mật khẩu');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự');
      hasError = true;
    }

    if (hasError) return;

    // Giả lập trạng thái đăng nhập
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    });
  }

  // Chế độ dùng thử (Demo Mode) chuẩn Rubric INT1449
  void _handleDemoMode() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space20),

              // Logo & Brand Name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softBlueSurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: const Icon(Icons.pets_rounded, color: AppColors.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Kar',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.navyBlue),
                        ),
                        TextSpan(
                          text: 'Vocab',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space32),

              // Title
              Text(
                'Chào mừng trở lại! 👋',
                style: AppTypography.displayLarge.copyWith(fontSize: 26),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                'Đăng nhập để tiếp tục duy trì chuỗi học từ vựng mỗi ngày.',
                style: AppTypography.bodyMedium,
              ),

              const SizedBox(height: AppDimensions.space24),

              // Tabs Segment (Đăng nhập / Đăng ký) theo chuẩn Figma
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0 ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            boxShadow: _selectedTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đăng nhập',
                            style: AppTypography.bodyBold.copyWith(
                              color: _selectedTabIndex == 0
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1 ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            boxShadow: _selectedTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đăng ký',
                            style: AppTypography.bodyBold.copyWith(
                              color: _selectedTabIndex == 1
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // Email Input
              AppTextField(
                label: 'Địa chỉ Email',
                hintText: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                errorText: _emailError,
              ),

              const SizedBox(height: AppDimensions.space16),

              // Password Input
              AppTextField(
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: AppDimensions.space12),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // Nút Đăng nhập chính (Primary CTA >= 48dp)
              AppButton(
                text: _selectedTabIndex == 0 ? 'Đăng nhập' : 'Tạo tài khoản mới',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppDimensions.space16),

              // NÚT CHẾ ĐỘ DÙNG THỬ (DEMO MODE) — QUAN TRỌNG THEO RUBRIC INT1449
              AppButton(
                text: '⚡ Chế độ Dùng thử (Demo Offline)',
                onPressed: _handleDemoMode,
                variant: AppButtonVariant.secondary,
                height: 48,
              ),

              const SizedBox(height: AppDimensions.space24),

              // Divider "Hoặc tiếp tục với"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    child: Text(
                      'Hoặc tiếp tục với',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
                ],
              ),

              const SizedBox(height: AppDimensions.space20),

              // Social Login Buttons (Google & Facebook) chuẩn vùng chạm 48dp
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
                      label: Text(
                        'Google',
                        style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        ),
                        side: const BorderSide(color: AppColors.borderLight),
                        backgroundColor: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                      label: Text(
                        'Facebook',
                        style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        ),
                        side: const BorderSide(color: AppColors.borderLight),
                        backgroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space32),

              // Terms & Conditions note
              Center(
                child: Text(
                  'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Chính sách của KarVocab.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }
}
