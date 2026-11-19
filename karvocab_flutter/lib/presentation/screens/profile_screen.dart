import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_profile_model.dart';
import 'settings_screen.dart';

/// Màn 15 · Hồ sơ cá nhân (User Profile & Achievement Badges Screen)
/// Xem tiến độ học tập, huy hiệu thành tựu và truy cập cài đặt
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileModel _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfileModel.mockDefault();
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'local_fire_department_rounded':
        return Icons.local_fire_department_rounded;
      case 'explore_rounded':
        return Icons.explore_rounded;
      case 'military_tech_rounded':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Hồ sơ cá nhân', style: AppTypography.headingLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
            tooltip: 'Cài đặt tài khoản',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    profile: _profile,
                    onProfileUpdated: (updated) {
                      setState(() => _profile = updated);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ danh tính người học (Learner Identity Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar Axolotl
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.softBlueSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets_rounded, // Mascot Axolotl
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),

                  // Tên & Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile.fullName,
                          style: AppTypography.headingLarge.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _profile.email,
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppDimensions.space8),

                        // Pill mục tiêu ngày
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          ),
                          child: Text(
                            '🎯 Mục tiêu: ${_profile.dailyGoalWords} từ/ngày',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.navyBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // 2. Thống kê học tập (3 Thẻ ngang: Từ vựng, Streak, Học phần)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Từ đã học',
                    value: '${_profile.totalWordsLearned}',
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Chuỗi ngày',
                    value: '${_profile.currentStreak}',
                    unit: 'ngày',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Học phần',
                    value: '${_profile.totalCollections}',
                    icon: Icons.folder_special_rounded,
                    iconColor: AppColors.successGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space28),

            // 3. Hệ thống Huy hiệu vinh danh (Achievement Badges)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Huy hiệu thành tựu', style: AppTypography.headingMedium),
                Text(
                  '${_profile.badges.where((b) => b.isUnlocked).length}/${_profile.badges.length} đã đạt',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // Danh sách các huy hiệu
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _profile.badges.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
              itemBuilder: (context, index) {
                final badge = _profile.badges[index];
                return _buildBadgeCard(badge);
              },
            ),

            const SizedBox(height: AppDimensions.space28),

            // 4. Menu tiện ích nhanh
            Text('Tùy chọn khác', style: AppTypography.headingMedium),
            const SizedBox(height: AppDimensions.space12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
                    title: Text('Cài đặt tài khoản & Mục tiêu', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            profile: _profile,
                            onProfileUpdated: (updated) {
                              setState(() => _profile = updated);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue),
                    title: Text('Hướng dẫn & Trợ giúp (Rubric INT1449)', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hệ thống học từ vựng Spaced Repetition (SM-2) KarVocab.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }

  // Thẻ thống kê nhỏ
  Widget _buildStatCard({
    required String title,
    required String value,
    String? unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.headingLarge.copyWith(fontSize: 20),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.labelSmall.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Thẻ Huy hiệu thành tựu
  Widget _buildBadgeCard(BadgeModel badge) {
    final isLocked = !badge.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.white.withValues(alpha: 0.6) : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isLocked ? AppColors.borderLight : AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Huy hiệu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.borderLight.withValues(alpha: 0.5)
                  : AppColors.softBlueSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBadgeIcon(badge.iconName),
              color: isLocked ? AppColors.textMuted : AppColors.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),

          // Thông tin Huy hiệu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      badge.title,
                      style: AppTypography.bodyBold.copyWith(
                        color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Text(
                          '${badge.currentProgress}/${badge.maxProgress}',
                          style: AppTypography.labelSmall.copyWith(fontSize: 11),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: badge.currentProgress / badge.maxProgress,
                    backgroundColor: AppColors.secondaryBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 5,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
