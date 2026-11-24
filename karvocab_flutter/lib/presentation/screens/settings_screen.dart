import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/reminder_service.dart';
import 'login_screen.dart';

/// Màn 23 · Cài đặt tài khoản (Account Settings Screen)
/// Điều chỉnh mục tiêu ngày, giờ nhắc học, đổi mật khẩu và đăng xuất.
/// Mọi thay đổi được lưu ngay vào [AuthRepository] nên Màn 15 cập nhật theo.
class SettingsScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final ReminderService? reminderService;

  const SettingsScreen({super.key, this.authRepository, this.reminderService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int minDailyGoal = 5;

  /// BE và `DashboardStore` (FE2) chỉ nhận mục tiêu 5–30 từ/ngày (FE-BE-ALIGNMENT).
  static const int maxDailyGoal = 30;
  static const int dailyGoalStep = 5;

  late int _dailyGoal;
  late bool _isNotifEnabled;
  late String _reminderTime;

  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;
  ReminderService get _reminders => widget.reminderService ?? ReminderService.instance;
  UserProfileModel get _profile => _auth.currentUser ?? UserProfileModel.initial();

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _dailyGoal = profile.dailyGoalWords;
    _isNotifEnabled = profile.isNotificationEnabled;
    _reminderTime = profile.reminderTime;
  }

  void _saveChanges() {
    if (!_auth.isLoggedIn) return;
    _auth.updateProfile(
      _profile.copyWith(
        dailyGoalWords: _dailyGoal,
        isNotificationEnabled: _isNotifEnabled,
        reminderTime: _reminderTime,
      ),
    );
  }

  Future<void> _applyReminder() async {
    if (_isNotifEnabled) {
      await _reminders.scheduleDaily(_reminderTime);
    } else {
      await _reminders.cancel();
    }
  }

  // Hộp thoại đổi mật khẩu
  Future<void> _openChangePasswordDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ChangePasswordDialog(authRepository: _auth),
    );
    if (changed == true && mounted) {
      AppToast.success(context, 'Đổi mật khẩu thành công!');
    }
  }

  // Hộp thoại xác nhận đăng xuất
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusCard)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: AppDimensions.iconMedium),
            const SizedBox(width: AppDimensions.space8),
            Text('Đăng xuất tài khoản?', style: AppTypography.headingMedium),
          ],
        ),
        content: Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục đồng bộ quá trình học từ vựng.',
          style: AppTypography.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.all(AppDimensions.space16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Ở lại', style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              // Xoá phiên + lịch nhắc rồi chuyển hướng về màn hình Đăng nhập
              _auth.logout();
              _reminders.cancel();
              Navigator.of(context)
                  .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: Text('Đăng xuất', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(title: Text('Cài đặt tài khoản', style: AppTypography.headingMedium)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Mục tiêu học tập
            _buildSectionHeader('Mục tiêu học tập hằng ngày'),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(AppStrings.settingsDailyGoalLabel, style: AppTypography.bodyBold)],
                        ),
                      ),

                      // Stepper (Tăng / Giảm số từ)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            tooltip: 'Giảm mục tiêu',
                            color: _dailyGoal > minDailyGoal ? AppColors.primaryBlue : AppColors.textMuted,
                            iconSize: 28,
                            onPressed: _dailyGoal > minDailyGoal
                                ? () {
                                    setState(() => _dailyGoal -= dailyGoalStep);
                                    _saveChanges();
                                  }
                                : null,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: AppDimensions.dailyGoalValueMinWidth),
                            alignment: Alignment.center,
                            child: Text(
                              '$_dailyGoal',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: AppTypography.fontSize20,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            tooltip: 'Tăng mục tiêu',
                            color: _dailyGoal < maxDailyGoal ? AppColors.primaryBlue : AppColors.textMuted,
                            iconSize: 28,
                            onPressed: _dailyGoal < maxDailyGoal
                                ? () {
                                    setState(() => _dailyGoal += dailyGoalStep);
                                    _saveChanges();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Section 2: Nhắc nhở thông báo
            _buildSectionHeader('Nhắc nhở ôn tập'),
            // Material (thay vì Container có màu nền) để ListTile vẽ được hiệu ứng bấm
            Material(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Bật thông báo hằng ngày', style: AppTypography.bodyBold),
                    value: _isNotifEnabled,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() => _isNotifEnabled = val);
                      _saveChanges();
                      _applyReminder();
                      AppToast.info(
                        context,
                        val ? 'Sẽ nhắc bạn ôn tập lúc $_reminderTime mỗi ngày' : 'Đã tắt nhắc nhở hằng ngày',
                      );
                    },
                  ),
                  if (_isNotifEnabled) ...[
                    const Divider(height: AppDimensions.dividerThickness, color: AppColors.borderLight),
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryBlue),
                      title: Text('Thời gian nhắc học', style: AppTypography.bodyBold),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBlueSurface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Text(
                          _reminderTime,
                          style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue),
                        ),
                      ),
                      onTap: () async {
                        final parts = _reminderTime.split(':');
                        final initialTime = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 20,
                          minute: int.tryParse(parts[1]) ?? 0,
                        );
                        final picked = await showTimePicker(context: context, initialTime: initialTime);
                        if (picked != null && mounted) {
                          final h = picked.hour.toString().padLeft(2, '0');
                          final m = picked.minute.toString().padLeft(2, '0');
                          setState(() => _reminderTime = '$h:$m');
                          _saveChanges();
                          await _applyReminder();
                          if (!context.mounted) return;
                          AppToast.info(context, 'Đã đặt giờ nhắc học: $_reminderTime');
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Section 3: Tài khoản & Bảo mật
            _buildSectionHeader('Tài khoản & Bảo mật'),
            // Material (thay vì Container có màu nền) để ListTile vẽ được hiệu ứng bấm
            Material(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Ngày sinh chỉ sửa ở Hồ sơ (Màn 15) để không có hai nơi cùng sửa một thông tin.
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue),
                    title: Text('Đổi mật khẩu', style: AppTypography.bodyBold),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppDimensions.iconXSmall,
                      color: AppColors.textMuted,
                    ),
                    onTap: _openChangePasswordDialog,
                  ),
                  const Divider(height: AppDimensions.dividerThickness, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryBlue),
                    title: Text('Điều khoản & Quyền riêng tư', style: AppTypography.bodyBold),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppDimensions.iconXSmall,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('KarVocab tuân thủ tiêu chí Bảo mật theo Rubric INT1449.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space32),

            // Section 5: Nút Đăng xuất
            AppButton(
              text: 'Đăng xuất tài khoản',
              variant: AppButtonVariant.outline,
              foregroundColor: AppColors.errorRed,
              borderColor: AppColors.errorRed,
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              onPressed: _confirmLogout,
            ),

            const SizedBox(height: AppDimensions.space16),

            // Version info
            Center(
              child: Text(
                'KarVocab · Phiên bản 1.0.0',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ),

            const SizedBox(height: AppDimensions.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8, left: AppDimensions.space4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: AppTypography.sectionHeaderLetterSpacing,
        ),
      ),
    );
  }
}

/// Hộp thoại đổi mật khẩu (Màn 23).
/// Tách thành StatefulWidget riêng để controller được dispose đúng vòng đời
/// (tránh lỗi dùng controller đã dispose khi dialog đang chạy hiệu ứng đóng).
/// `pop(true)` khi đổi thành công.
class ChangePasswordDialog extends StatefulWidget {
  final AuthRepository authRepository;

  const ChangePasswordDialog({super.key, required this.authRepository});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _currentError = Validators.required(_currentController.text, 'Vui lòng nhập mật khẩu hiện tại');
      _newError = Validators.strongPassword(_newController.text);
      _confirmError = Validators.confirmPassword(_confirmController.text, _newController.text);
    });
    if (_currentError != null || _newError != null || _confirmError != null) return;

    setState(() => _isLoading = true);
    try {
      await widget.authRepository.changePassword(_currentController.text, _newController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusCard)),
      title: Text('Đổi mật khẩu', style: AppTypography.headingMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Mật khẩu hiện tại',
              hintText: 'Nhập mật khẩu cũ',
              controller: _currentController,
              isPassword: true,
              errorText: _currentError,
            ),
            const SizedBox(height: AppDimensions.space12),
            AppTextField(
              label: 'Mật khẩu mới',
              hintText: '≥ 8 ký tự, 1 chữ hoa, 1 chữ số',
              controller: _newController,
              isPassword: true,
              errorText: _newError,
            ),
            const SizedBox(height: AppDimensions.space12),
            AppTextField(
              label: 'Xác nhận mật khẩu mới',
              hintText: 'Nhập lại mật khẩu mới',
              controller: _confirmController,
              isPassword: true,
              textInputAction: TextInputAction.done,
              errorText: _confirmError,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(AppDimensions.space16),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
          ),
          child: Text(AppStrings.cancel, style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary)),
        ),
        SizedBox(
          width: AppDimensions.dialogActionWidth,
          child: AppButton(
            text: AppStrings.update,
            onPressed: _submit,
            isLoading: _isLoading,
            height: AppDimensions.minTouchTarget,
          ),
        ),
      ],
    );
  }
}
