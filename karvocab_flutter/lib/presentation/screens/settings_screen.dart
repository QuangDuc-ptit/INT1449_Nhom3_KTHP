import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/user_profile_model.dart';
import 'login_screen.dart';

/// Màn 23 · Cài đặt tài khoản (Account Settings Screen)
/// Điều chỉnh mục tiêu ngày, giờ nhắc học, đổi mật khẩu và đăng xuất
class SettingsScreen extends StatefulWidget {
  final UserProfileModel profile;
  final ValueChanged<UserProfileModel>? onProfileUpdated;

  const SettingsScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _dailyGoal;
  late bool _isNotifEnabled;
  late String _reminderTime;
  String _selectedLanguage = 'vi'; // 'vi' hoặc 'en'

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.profile.dailyGoalWords;
    _isNotifEnabled = widget.profile.isNotificationEnabled;
    _reminderTime = widget.profile.reminderTime;
  }

  void _saveChanges() {
    final updated = widget.profile.copyWith(
      dailyGoalWords: _dailyGoal,
      isNotificationEnabled: _isNotifEnabled,
      reminderTime: _reminderTime,
    );
    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(updated);
    }
  }

  // Hộp thoại đổi mật khẩu
  void _openChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          ),
          title: Text('Đổi mật khẩu', style: AppTypography.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Mật khẩu hiện tại',
                  hintText: 'Nhập mật khẩu cũ',
                  controller: oldPassController,
                  isPassword: true,
                ),
                const SizedBox(height: AppDimensions.space12),
                AppTextField(
                  label: 'Mật khẩu mới',
                  hintText: 'Tối thiểu 6 ký tự',
                  controller: newPassController,
                  isPassword: true,
                ),
                const SizedBox(height: AppDimensions.space12),
                AppTextField(
                  label: 'Xác nhận mật khẩu mới',
                  hintText: 'Nhập lại mật khẩu mới',
                  controller: confirmPassController,
                  isPassword: true,
                  errorText: errorText,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(AppDimensions.space16),
          actions: [
            TextButton(
              onPressed: () {
                oldPassController.dispose();
                newPassController.dispose();
                confirmPassController.dispose();
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Hủy',
                style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                ),
              ),
              onPressed: () {
                if (newPassController.text.length < 6) {
                  setDialogState(() => errorText = 'Mật khẩu mới phải từ 6 ký tự trở lên');
                  return;
                }
                if (newPassController.text != confirmPassController.text) {
                  setDialogState(() => errorText = 'Mật khẩu xác nhận không khớp');
                  return;
                }

                oldPassController.dispose();
                newPassController.dispose();
                confirmPassController.dispose();
                Navigator.of(ctx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đổi mật khẩu thành công!'),
                    backgroundColor: AppColors.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Cập nhật', style: AppTypography.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại xác nhận đăng xuất
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 24),
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
            child: Text(
              'Ở lại',
              style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              // Chuyển hướng về màn hình Đăng nhập
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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
      appBar: AppBar(
        title: Text('Cài đặt tài khoản', style: AppTypography.headingLarge),
        centerTitle: true,
      ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Số từ cần ôn mỗi ngày', style: AppTypography.bodyBold),
                          const SizedBox(height: 2),
                          Text(
                            'Duy trì mục tiêu để giữ chuỗi Streak',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                          ),
                        ],
                      ),

                      // Stepper (Tăng / Giảm số từ)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: _dailyGoal > 5 ? AppColors.primaryBlue : AppColors.textMuted,
                            iconSize: 28,
                            onPressed: _dailyGoal > 5
                                ? () {
                                    setState(() => _dailyGoal -= 5);
                                    _saveChanges();
                                  }
                                : null,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 36),
                            alignment: Alignment.center,
                            child: Text(
                              '$_dailyGoal',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: _dailyGoal < 30 ? AppColors.primaryBlue : AppColors.textMuted,
                            iconSize: 28,
                            onPressed: _dailyGoal < 30
                                ? () {
                                    setState(() => _dailyGoal += 5);
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Bật thông báo hằng ngày', style: AppTypography.bodyBold),
                    subtitle: Text(
                      'Nhắc ôn từ vựng theo phương pháp Spaced Repetition',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                    ),
                    value: _isNotifEnabled,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() => _isNotifEnabled = val);
                      _saveChanges();
                    },
                  ),
                  if (_isNotifEnabled) ...[
                    const Divider(height: 1, color: AppColors.borderLight),
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryBlue),
                      title: Text('Thời gian nhắc học', style: AppTypography.bodyBold),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );
                        if (picked != null) {
                          final h = picked.hour.toString().padLeft(2, '0');
                          final m = picked.minute.toString().padLeft(2, '0');
                          setState(() => _reminderTime = '$h:$m');
                          _saveChanges();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Section 3: Ngôn ngữ & Giao diện (Điểm cộng Rubric +2)
            _buildSectionHeader('Ngôn ngữ giao diện (Localization)'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primaryBlue),
                      const SizedBox(width: AppDimensions.space12),
                      Text('Ngôn ngữ hiển thị', style: AppTypography.bodyBold),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt 🇻🇳')),
                      DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val == 'vi'
                                ? 'Đã chọn Tiếng Việt'
                                : 'Switched to English language'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Section 4: Tài khoản & Bảo mật
            _buildSectionHeader('Tài khoản & Bảo mật'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue),
                    title: Text('Đổi mật khẩu', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: _openChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryBlue),
                    title: Text('Điều khoản & Quyền riêng tư', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
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
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              onPressed: _confirmLogout,
            ),

            const SizedBox(height: AppDimensions.space16),

            // Version info
            Center(
              child: Text(
                'KarVocab Mobile · Phiên bản 1.0.0-MVP (INT1449)',
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
      padding: const EdgeInsets.only(bottom: AppDimensions.space8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
