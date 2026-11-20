import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/badge_rules.dart';
import '../../data/repositories/collection_store.dart';
import 'settings_screen.dart';

/// Màn 15 · Hồ sơ cá nhân (User Profile & Achievement Badges Screen)
/// Xem tiến độ học tập, huy hiệu thành tựu và truy cập cài đặt
class ProfileScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final CollectionStore? store;

  const ProfileScreen({super.key, this.authRepository, this.store});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;
  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(authRepository: widget.authRepository)),
    );
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
    return ListenableBuilder(
      listenable: Listenable.merge([_auth, _store]),
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final storedProfile = _auth.currentUser ?? UserProfileModel.mockDefault();
    // Số học phần lấy trực tiếp từ Thư viện để luôn khớp với dữ liệu thật.
    final profile = storedProfile.copyWith(totalCollections: _store.collections.length);
    final badges = BadgeRules.evaluate(
      currentStreak: profile.currentStreak,
      wordsLearned: profile.totalWordsLearned,
      collectionCount: profile.totalCollections,
    );

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Hồ sơ cá nhân', style: AppTypography.headingLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
            tooltip: 'Cài đặt tài khoản',
            onPressed: _openSettings,
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
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  // Avatar Axolotl
                  Container(
                    width: AppDimensions.avatarSize,
                    height: AppDimensions.avatarSize,
                    decoration: BoxDecoration(
                      color: AppColors.softBlueSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: AppDimensions.borderThick),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets_rounded, // Mascot Axolotl
                        size: AppDimensions.iconState,
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
                          profile.fullName,
                          style: AppTypography.headingLarge.copyWith(fontSize: AppTypography.fontSize20),
                        ),
                        const SizedBox(height: AppDimensions.space2),
                        Text(
                          profile.email,
                          style: AppTypography.bodyMedium.copyWith(fontSize: AppTypography.fontSize13),
                        ),
                        const SizedBox(height: AppDimensions.space8),

                        // Pill mục tiêu ngày
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.chipPaddingH, vertical: AppDimensions.chipPaddingV),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          ),
                          child: Text(
                            '🎯 Mục tiêu: ${profile.dailyGoalWords} từ/ngày',
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
                    value: '${profile.totalWordsLearned}',
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Chuỗi ngày',
                    value: '${profile.currentStreak}',
                    unit: 'ngày',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Học phần',
                    value: '${profile.totalCollections}',
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
                  '${badges.where((b) => b.isUnlocked).length}/${badges.length} đã đạt',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // Danh sách các huy hiệu
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(badge);
              },
            ),

            const SizedBox(height: AppDimensions.space28),

            // 4. Menu tiện ích nhanh
            Text('Tùy chọn khác', style: AppTypography.headingMedium),
            const SizedBox(height: AppDimensions.space12),

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
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
                    title: Text('Cài đặt tài khoản & Mục tiêu', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: AppDimensions.iconXSmall, color: AppColors.textMuted),
                    onTap: _openSettings,
                  ),
                  const Divider(height: AppDimensions.dividerThickness, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue),
                    title: Text('Hướng dẫn & Trợ giúp (Rubric INT1449)', style: AppTypography.bodyBold),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: AppDimensions.iconXSmall, color: AppColors.textMuted),
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
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16, horizontal: AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: AppDimensions.tintOpacity),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: AppDimensions.iconSocial),
          ),
          const SizedBox(height: AppDimensions.space8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.headingLarge.copyWith(fontSize: AppTypography.fontSize20),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.labelSmall.copyWith(fontSize: AppTypography.fontSize11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space2),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: AppTypography.fontSize11,
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

    final card = Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.white.withValues(alpha: AppDimensions.lockedSurfaceOpacity) : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isLocked ? AppColors.borderLight : AppColors.primaryBlue.withValues(alpha: AppDimensions.accentBorderOpacity),
        ),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          // Icon Huy hiệu
          Container(
            width: AppDimensions.badgeIconBoxSize,
            height: AppDimensions.badgeIconBoxSize,
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.borderLight.withValues(alpha: AppDimensions.halfOpacity)
                  : AppColors.softBlueSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBadgeIcon(badge.iconName),
              color: isLocked ? AppColors.textMuted : AppColors.primaryBlue,
              size: AppDimensions.iconFeature,
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
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space2),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Text(
                          '${badge.currentProgress}/${badge.maxProgress}',
                          style: AppTypography.labelSmall.copyWith(fontSize: AppTypography.fontSize11),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: AppDimensions.iconSmall),
                  ],
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  badge.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: AppTypography.fontSize13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: AppDimensions.space8),
                  LinearProgressIndicator(
                    value: badge.currentProgress / badge.maxProgress,
                    backgroundColor: AppColors.secondaryBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXSmall),
                    minHeight: AppDimensions.badgeProgressHeight,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!isLocked) return card;
    // Huy hiệu chưa mở khoá hiển thị dạng xám (grayscale) theo đặc tả Màn 15.
    return Semantics(
      label: 'Huy hiệu ${badge.title} chưa mở khoá, tiến độ ${badge.currentProgress}/${badge.maxProgress}',
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: card,
      ),
    );
  }
}
