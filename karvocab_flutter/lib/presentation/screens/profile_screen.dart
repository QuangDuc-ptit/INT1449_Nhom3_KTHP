import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../core/widgets/streak_flame.dart';
import '../widgets/birth_date_picker.dart';
import 'settings_screen.dart';
import '../widgets/tab_header.dart';

/// Màn 15 · Hồ sơ cá nhân: ảnh đại diện, thông tin tài khoản (mã ID, email,
/// ngày sinh) và thành tựu học tập.
/// Mã ID và email chỉ xem, không sửa được; ngày sinh sửa được.
class ProfileScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final CollectionStore? store;

  /// Tiến độ học (mặc định [DashboardStore.instance]) để tính "Từ đã học" và streak.
  final DashboardStore? dashboard;

  const ProfileScreen({super.key, this.authRepository, this.store, this.dashboard});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthRepository get _auth => widget.authRepository ?? AuthRepository.instance;
  CollectionStore get _store => widget.store ?? CollectionStore.instance;
  DashboardStore get _dashboard => widget.dashboard ?? DashboardStore.instance;

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SettingsScreen(authRepository: widget.authRepository)));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _copyMemberId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) _showMessage(AppStrings.profileIdCopied);
  }

  Future<void> _editBirthDate(DateTime? current) async {
    final picked = await pickBirthDate(context, initial: current);
    if (picked == null || !mounted) return;
    _auth.updateBirthDate(picked);
    _showMessage(AppStrings.profileBirthDateSaved);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_auth, _store, _dashboard]),
      builder: (context, _) {
        final stored = _auth.currentUser ?? UserProfileModel.mockDefault();
        // Thành tựu tính từ dữ liệu thật của Thư viện và tiến độ ôn tập, cùng luật
        // với Trang chủ, để hai màn không hiện hai con số khác nhau.
        final learned = _store.collections
            .expand((c) => _store.wordsOf(c.id))
            .where((w) => _dashboard.isLearned(w.id))
            .length;
        final profile = stored.copyWith(
          totalCollections: _store.collections.length,
          totalWordsLearned: learned,
          currentStreak: _dashboard.streak,
        );
        return Scaffold(
          backgroundColor: AppColors.practiceBackground,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, AppDimensions.space16, 0, AppDimensions.space32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppDimensions.profileMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.quizHorizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Lối vào Cài đặt nằm ở mục "Tùy chọn khác" bên dưới.
                        const TabHeader(title: AppStrings.profileTitle),
                        const SizedBox(height: AppDimensions.space16),
                        _IdentityCard(profile: profile),
                        const SizedBox(height: AppDimensions.space24),
                        const _SectionTitle(AppStrings.profileAccountInfo),
                        _buildAccountInfo(profile),
                        const SizedBox(height: AppDimensions.space24),
                        const _SectionTitle(AppStrings.profileAchievements),
                        _buildAchievements(profile),
                        const SizedBox(height: AppDimensions.space24),
                        const _SectionTitle(AppStrings.profileMore),
                        _buildMoreOptions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountInfo(UserProfileModel profile) {
    final memberId = profile.memberId;
    final birthDate = profile.birthDate;

    return _Card(
      child: Column(
        children: [
          _InfoRow(
            key: const Key('profile_member_id'),
            icon: Icons.badge_outlined,
            label: AppStrings.profileMemberId,
            value: memberId ?? AppStrings.profileNoMemberId,
            valueStyle: memberId == null ? AppTypography.quizCaption : AppTypography.profileMemberId,
            trailing: memberId == null
                ? null
                : IconButton(
                    tooltip: AppStrings.profileCopyId,
                    icon: const Icon(Icons.copy_rounded, size: AppDimensions.iconSmall),
                    color: AppColors.practicePrimary,
                    onPressed: () => _copyMemberId(memberId),
                  ),
            onTap: memberId == null ? () => _editBirthDate(birthDate) : null,
          ),
          const _RowDivider(),
          _InfoRow(
            key: const Key('profile_email'),
            icon: Icons.mail_outline_rounded,
            label: AppStrings.profileEmail,
            value: profile.email,
            // Ghi rõ bằng chữ thay cho icon ổ khoá dễ hiểu nhầm là "bảo mật".
          ),
          const _RowDivider(),
          _InfoRow(
            key: const Key('profile_birth_date'),
            icon: Icons.cake_outlined,
            label: AppStrings.profileBirthDate,
            value: birthDate == null ? AppStrings.profileNoBirthDate : formatDmy(birthDate),
            trailing: const Icon(Icons.edit_outlined, size: AppDimensions.iconSmall, color: AppColors.practicePrimary),
            onTap: () => _editBirthDate(birthDate),
            semanticsHint: AppStrings.profileEditBirthDate,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(UserProfileModel profile) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.menu_book_rounded,
              color: AppColors.practicePrimary,
              tint: AppColors.practiceSelectedFill,
              value: '${profile.totalWordsLearned}',
              label: AppStrings.profileWordsLearned,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: _StatTile(
              icon: Icons.local_fire_department_rounded,
              iconWidget: StreakFlame(size: AppDimensions.iconSmall, lit: profile.currentStreak > 0),
              color: AppColors.warningOrange,
              tint: AppColors.quizAlmostTint,
              value: '${profile.currentStreak}',
              unit: AppStrings.profileStreakUnit,
              label: AppStrings.profileStreak,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: _StatTile(
              icon: Icons.folder_special_rounded,
              color: AppColors.successGreen,
              tint: AppColors.quizCorrectTint,
              value: '${profile.totalCollections}',
              label: AppStrings.profileCollections,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptions() {
    // Material (thay vì Container có màu nền) để ListTile vẽ được hiệu ứng bấm.
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.quizCardRadius),
        side: const BorderSide(color: AppColors.practiceCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.practicePrimary),
            title: const Text(AppStrings.profileOpenSettings, style: AppTypography.quizOption),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.practiceTextSecondary),
            onTap: _openSettings,
          ),
          const _RowDivider(),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: AppColors.practicePrimary),
            title: const Text(AppStrings.profileHelp, style: AppTypography.quizOption),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.practiceTextSecondary),
            onTap: () => _showMessage(AppStrings.profileHelpMessage),
          ),
        ],
      ),
    );
  }
}

/// Ảnh đại diện + tên.
class _IdentityCard extends StatelessWidget {
  final UserProfileModel profile;

  const _IdentityCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.avatarUrl.isNotEmpty;
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space24, horizontal: AppDimensions.space16),
      child: Column(
        children: [
          Container(
            width: AppDimensions.profileAvatarSize,
            height: AppDimensions.profileAvatarSize,
            padding: const EdgeInsets.all(AppDimensions.profileAvatarBorder),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.practicePrimary, width: AppDimensions.profileAvatarBorder),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: AppColors.practiceSelectedFill,
                child: hasPhoto
                    ? Image.network(
                        profile.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(AppAssets.logo),
                      )
                    // Chưa có ảnh: dùng linh vật Axolotl làm ảnh đại diện mặc định.
                    : Image.asset(AppAssets.logo, excludeFromSemantics: true),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(profile.fullName, style: AppTypography.profileName, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.quizCardRadius),
        border: Border.all(color: AppColors.practiceCardBorder),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.space4, bottom: AppDimensions.space10),
      child: Semantics(header: true, child: Text(text, style: AppTypography.practiceSectionTitle)),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: AppDimensions.space16,
    endIndent: AppDimensions.space16,
    color: AppColors.practiceCardBorder,
  );
}

/// Một dòng thông tin: icon, nhãn nhỏ, giá trị và nút bên phải.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticsHint;

  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.trailing,
    this.onTap,
    this.semanticsHint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: semanticsHint,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimensions.profileRowMinHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space4,
              AppDimensions.space12,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.practicePrimary, size: AppDimensions.iconMedium),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.quizCaption),
                      const SizedBox(height: AppDimensions.space2),
                      Text(value, style: valueStyle ?? AppTypography.quizOption),
                    ],
                  ),
                ),
                if (trailing != null) trailing! else const SizedBox(width: AppDimensions.space12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final Color color;
  final Color tint;
  final String value;
  final String? unit;
  final String label;

  const _StatTile({
    required this.icon,
    this.iconWidget,
    required this.color,
    required this.tint,
    required this.value,
    required this.label,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16, horizontal: AppDimensions.space8),
      child: Column(
        children: [
          Container(
            width: AppDimensions.profileStatIconBox,
            height: AppDimensions.profileStatIconBox,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Center(child: iconWidget ?? Icon(icon, color: color, size: AppDimensions.iconSmall)),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: AppTypography.quizStatValue),
                if (unit != null) TextSpan(text: ' $unit', style: AppTypography.quizCaption),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space2),
          Text(label, style: AppTypography.quizCaption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
