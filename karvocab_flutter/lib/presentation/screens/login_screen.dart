import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import '../forgot_password/forgot_password_ui_state.dart';
import 'forgot_password_screen.dart';
import 'main_shell_screen.dart';

/// Màn 02 · Đăng nhập & Màn 03 · Đăng ký — một màn, đổi form bằng thanh tab.
///
/// - "Đăng nhập" → kiểm tra qua [AuthRepository.login]. Đúng → Trang chủ
///   ([MainShellScreen]); email chưa đăng ký / sai mật khẩu → lỗi dưới ô tương ứng.
/// - "Quên mật khẩu?" → Màn 21 ([ForgotPasswordScreen]).
/// - "Đăng ký", Google, Facebook → chưa có hành động.
class LoginScreen extends StatefulWidget {
  /// 0 = Đăng nhập, 1 = Đăng ký.
  final int initialTab;

  /// Mặc định [AuthRepository.instance]; test truyền bản riêng.
  final AuthRepository? authRepository;

  const LoginScreen({super.key, this.initialTab = 0, this.authRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  late int _tab = widget.initialTab;

  String? _loginEmailError;
  String? _loginPasswordError;

  /// Chặn bấm "Đăng nhập" nhiều lần khi đang chờ kết quả.
  bool _isSubmitting = false;

  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;

  bool get _isLogin => _tab == 0;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tab) return;
    FocusScope.of(context).unfocus();
    setState(() => _tab = index);
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _loginEmailError = null;
      _loginPasswordError = null;
    });
    try {
      await _auth.login(_loginEmailController.text, _loginPasswordController.text);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (e.field == AuthErrorField.email) {
          _loginEmailError = e.message;
        } else {
          _loginPasswordError = e.message;
        }
      });
      return;
    }
    if (!mounted) return;
    // Mở tab 0 · Trang chủ (MainShellScreen mặc định mở tab Thư viện).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShellScreen(initialTabIndex: 0)),
      (route) => false,
    );
  }

  void _openForgotPassword() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ForgotPasswordRoute()));
  }

  // Chưa làm: chỉ có giao diện.
  void _noAction() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
            child: ConstrainedBox(
              // Khi nội dung ngắn hơn màn hình, dòng điều khoản nằm sát đáy.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(),
                  const Padding(
                    padding: EdgeInsets.only(top: AppDimensions.space32, bottom: AppDimensions.space24),
                    child: Text(
                      'Tiếp tục nghĩa là bạn đồng ý với\n'
                      'Điều khoản sử dụng và Chính sách bảo mật.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.space20),
        Text.rich(
          const TextSpan(
            style: AppTypography.authWordmark,
            children: [
              TextSpan(
                text: 'Kar',
                style: TextStyle(color: AppColors.brandKar),
              ),
              TextSpan(
                text: 'Vocab',
                style: TextStyle(color: AppColors.brandVocab),
              ),
            ],
          ),
          key: const Key('auth_wordmark'),
        ),
        const SizedBox(height: AppDimensions.space32),
        Text(
          _isLogin ? 'Chào mừng trở lại' : 'Tạo tài khoản\nKarVocab của bạn',
          style: AppTypography.displayLarge.copyWith(color: AppColors.navyBlue),
        ),
        const SizedBox(height: AppDimensions.space24),
        AuthSegmentTabs(selectedIndex: _tab, onSelected: _selectTab),
        const SizedBox(height: AppDimensions.space24),

        // Key riêng cho từng form để trạng thái ẩn/hiện mật khẩu không bị
        // dùng lẫn giữa Đăng nhập và Đăng ký.
        if (_isLogin) ..._buildLoginFields() else ..._buildRegisterFields(),

        const SizedBox(height: AppDimensions.space24),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderLight, thickness: AppDimensions.borderThin)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: Text(
                'Hoặc tiếp tục với',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.borderLight, thickness: AppDimensions.borderThin)),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),
        Row(
          children: [
            Expanded(
              child: _SocialButton(label: 'Google', icon: const _GoogleIcon(), onPressed: _noAction),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                icon: const Icon(Icons.facebook, color: AppColors.facebookBlue, size: AppDimensions.iconSocial),
                onPressed: _noAction,
              ),
            ),
          ],
        ),
        if (_isLogin) ...[
          const SizedBox(height: AppDimensions.space20),
          // SizedBox full ngang để Wrap căn giữa theo cả dòng
          // (Column cha căn trái nên Wrap tự co theo nội dung).
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Bạn chưa có tài khoản? ', style: AppTypography.bodyMedium),
                InkWell(
                  key: const Key('auth_register_now'),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  onTap: () => _selectTab(1),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
                    child: Center(
                      widthFactor: 1,
                      child: Text('Đăng ký ngay.', style: AppTypography.bodyBold.copyWith(color: AppColors.authLink)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      AppTextField(
        key: const ValueKey('login_email'),
        label: 'Địa chỉ email',
        hintText: 'name@email.com',
        controller: _loginEmailController,
        keyboardType: TextInputType.emailAddress,
        borderColor: AppColors.softBlueSurface,
        errorText: _loginEmailError,
        onChanged: (_) {
          if (_loginEmailError != null) setState(() => _loginEmailError = null);
        },
      ),
      const SizedBox(height: AppDimensions.space16),
      AppTextField(
        key: const ValueKey('login_password'),
        label: 'Mật khẩu',
        hintText: 'Nhập mật khẩu của bạn',
        controller: _loginPasswordController,
        isPassword: true,
        textInputAction: TextInputAction.done,
        borderColor: AppColors.softBlueSurface,
        errorText: _loginPasswordError,
        onChanged: (_) {
          if (_loginPasswordError != null) setState(() => _loginPasswordError = null);
        },
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          key: const Key('login_forgot_password'),
          onPressed: _openForgotPassword,
          style: TextButton.styleFrom(
            minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
          ),
          child: Text(
            'Quên mật khẩu?',
            style: AppTypography.bodyBold.copyWith(color: AppColors.navyBlue, fontSize: AppTypography.fontSize14),
          ),
        ),
      ),
      const SizedBox(height: AppDimensions.space8),
      AppButton(text: 'Đăng nhập', onPressed: _handleLogin, backgroundColor: AppColors.authButton),
    ];
  }

  List<Widget> _buildRegisterFields() {
    return [
      AppTextField(
        key: const ValueKey('register_email'),
        label: 'Địa chỉ email',
        hintText: 'name@email.com',
        controller: _registerEmailController,
        keyboardType: TextInputType.emailAddress,
        borderColor: AppColors.softBlueSurface,
      ),
      const SizedBox(height: AppDimensions.space16),
      AppTextField(
        key: const ValueKey('register_password'),
        label: 'Mật khẩu',
        hintText: 'Nhập mật khẩu của bạn',
        controller: _registerPasswordController,
        isPassword: true,
        borderColor: AppColors.softBlueSurface,
      ),
      const SizedBox(height: AppDimensions.space16),
      AppTextField(
        key: const ValueKey('register_confirm'),
        label: 'Xác nhận mật khẩu',
        hintText: 'Nhập lại mật khẩu của bạn',
        controller: _registerConfirmController,
        isPassword: true,
        textInputAction: TextInputAction.done,
        borderColor: AppColors.softBlueSurface,
      ),
      const SizedBox(height: AppDimensions.space24),
      AppButton(text: 'Đăng ký', onPressed: _noAction, backgroundColor: AppColors.authButton),
    ];
  }
}

/// Nơi giữ [ForgotPasswordUiState] và nối callback của Màn 21.
/// Chưa có backend: "Gửi liên kết đặt lại" chỉ gọi callback, chưa làm gì thêm.
class _ForgotPasswordRoute extends StatefulWidget {
  const _ForgotPasswordRoute();

  @override
  State<_ForgotPasswordRoute> createState() => _ForgotPasswordRouteState();
}

class _ForgotPasswordRouteState extends State<_ForgotPasswordRoute> {
  ForgotPasswordUiState _state = const ForgotPasswordUiState();

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordScreen(
      state: _state,
      onEmailChange: (email) => setState(() => _state = _state.copyWith(email: email)),
      onSendResetLinkClick: () {},
      onBackClick: () => Navigator.of(context).pop(),
    );
  }
}

/// Thanh chuyển Đăng nhập / Đăng ký (segmented control).
class AuthSegmentTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AuthSegmentTabs({super.key, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.buttonHeight,
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      child: Row(children: [_buildTab(0, 'Đăng nhập'), _buildTab(1, 'Đăng ký')]),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : null,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: isSelected
                  ? AppTypography.bodyBold.copyWith(color: AppColors.navyBlue)
                  : AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label, style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
        side: const BorderSide(color: AppColors.softBlueSurface),
        backgroundColor: AppColors.white,
      ),
    );
  }
}

/// Logo chữ "G" 4 màu của Google, vẽ bằng code (chưa có file icon).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: AppDimensions.iconSmall, height: AppDimensions.iconSmall, child: CustomPaint(painter: _GoogleLogoPainter()));
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static double _deg(double d) => d * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: (size.width - stroke) / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Góc tính theo chiều kim đồng hồ từ hướng 3 giờ; khe hở của chữ G ở −45°…0°.
    void arc(double start, double sweep, Color color) =>
        canvas.drawArc(rect, _deg(start), _deg(sweep), false, paint..color = color);
    arc(-160, 115, AppColors.googleRed);
    arc(135, 65, AppColors.googleYellow);
    arc(45, 90, AppColors.googleGreen);
    arc(0, 45, AppColors.googleBlue);

    // Thanh ngang màu xanh của chữ G
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy - stroke / 2, size.width, center.dy + stroke / 2),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
