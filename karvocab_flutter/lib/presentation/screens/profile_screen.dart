import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/account_plan.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/collection_store.dart';
import '../widgets/account_widgets.dart';
import 'settings_screen.dart';

/// Màn 15 · Hồ sơ cá nhân: ảnh đại diện, thông tin tài khoản (mã ID, email,
/// ngày sinh, loại tài khoản), quyền lợi gói đang dùng và thành tựu học tập.
/// Mã ID và email chỉ xem, không sửa được; ngày sinh sửa được.
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
      listenable: Listenable.merge([_auth, _store]),
      builder: (context, _) {
        final stored = _auth.currentUser ?? UserProfileModel.mockDefault();
        // Số học phần lấy trực tiếp từ Thư viện để luôn khớp với dữ liệu thật.
        final profile = stored.copyWith(totalCollections: _store.collections.length);
        return Scaffold(
          backgroundColor: AppColors.practiceBackground,
          appBar: AppBar(
            backgroundColor: AppColors.practiceBackground,
            surfaceTintColor: AppColors.practiceBackground,
            centerTitle: false,
            title: const Text(AppStrings.profileTitle, style: AppTypography.practiceTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.practicePrimary),
                tooltip: AppStrings.profileSettingsTooltip,
                onPressed: _openSettings,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, AppDimensions.space8, 0, AppDimensions.space32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppDimensions.profileMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.quizHorizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IdentityCard(profile: profile, plan: _auth.activePlan ?? profile.plan),
                      const SizedBox(height: AppDimensions.space24),
                      const _SectionTitle(AppStrings.profileAccountInfo),
                      _buildAccountInfo(profile),
                      const SizedBox(height: AppDimensions.space24),
                      const _SectionTitle(AppStrings.profilePlanBenefits),
                      _buildBenefits(),
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
        );
      },
    );
  }

  Widget _buildAccountInfo(UserProfileModel profile) {
    final memberId = profile.memberId;
    final birthDate = profile.birthDate;
    final plan = _auth.activePlan ?? profile.plan;
    final expires = profile.planExpiresAt;

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
            trailing: const _LockIcon(),
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
          const _RowDivider(),
          _InfoRow(
            key: const Key('profile_plan'),
            icon: Icons.workspace_premium_outlined,
            label: AppStrings.profilePlan,
            valueWidget: Align(alignment: Alignment.centerLeft, child: PlanChip(plan: plan)),
            // Chỉ gói dùng thử mới cần dòng phụ: ngày hết hạn.
            caption: plan == AccountPlan.plus && expires != null
                ? AppStrings.profilePlanExpires(formatDmy(expires), _daysLeft(expires))
                : null,
          ),
        ],
      ),
    );
  }

  int _daysLeft(DateTime expires) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expires.difference(today).inDays.clamp(0, 365);
  }

  Widget _buildBenefits() {
    final aiLimit = _auth.activePlan?.aiDailyLimit;
    final wordLimit = _auth.wordLimit;
    return _Card(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        children: [
          _UsageRow(
            icon: Icons.auto_awesome_rounded,
            label: AppStrings.profileAiToday,
            used: _auth.aiUsedToday,
            limit: aiLimit,
          ),
          const SizedBox(height: AppDimensions.space16),
          _UsageRow(
            icon: Icons.bookmark_outline_rounded,
            label: AppStrings.profileSavedWords,
            used: _store.totalWordCount,
            limit: wordLimit,
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

/// Ảnh đại diện + tên + loại tài khoản.
class _IdentityCard extends StatelessWidget {
  final UserProfileModel profile;
  final AccountPlan plan;

  const _IdentityCard({required this.profile, required this.plan});

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
              border: Border.all(color: plan.color, width: AppDimensions.profileAvatarBorder),
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
          const SizedBox(height: AppDimensions.space8),
          PlanChip(plan: plan),
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

class _LockIcon extends StatelessWidget {
  const _LockIcon();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppDimensions.space12),
        child: Icon(
          Icons.lock_outline_rounded,
          size: AppDimensions.iconSmall,
          color: AppColors.practiceTextSecondary,
          semanticLabel: AppStrings.profileLocked,
        ),
      );
}

/// Một dòng thông tin: icon, nhãn nhỏ, giá trị, chú thích và nút bên phải.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final TextStyle? valueStyle;
  final Widget? valueWidget;
  final String? caption;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticsHint;

  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueStyle,
    this.valueWidget,
    this.caption,
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
                      valueWidget ?? Text(value ?? '', style: valueStyle ?? AppTypography.quizOption),
                      if (caption != null) ...[
                        const SizedBox(height: AppDimensions.space4),
                        Text(caption!, style: AppTypography.quizCaption),
                      ],
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

/// Hạn mức đã dùng: "1/3" kèm thanh tiến độ, hoặc "Không giới hạn".
class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used;
  final int? limit;

  const _UsageRow({required this.icon, required this.label, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final max = limit;
    final full = max != null && used >= max;
    final color = full ? AppColors.errorRed : AppColors.practicePrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: AppDimensions.iconSmall, color: AppColors.practicePrimary),
            const SizedBox(width: AppDimensions.space8),
            Expanded(child: Text(label, style: AppTypography.quizOption)),
            Text(
              max == null ? AppStrings.profileUnlimited : AppStrings.profileUsage(used, max),
              style: AppTypography.quizChip.copyWith(color: max == null ? AppColors.successGreen : color),
            ),
          ],
        ),
        if (max != null) ...[
          const SizedBox(height: AppDimensions.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: max == 0 ? 1 : (used / max).clamp(0.0, 1.0),
              minHeight: AppDimensions.profileUsageBarHeight,
              backgroundColor: AppColors.practiceSelectedFill,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final String value;
  final String? unit;
  final String label;

  const _StatTile({
    required this.icon,
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
            child: Icon(icon, color: color, size: AppDimensions.iconSmall),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: value, style: AppTypography.quizStatValue),
              if (unit != null) TextSpan(text: ' $unit', style: AppTypography.quizCaption),
            ]),
          ),
          const SizedBox(height: AppDimensions.space2),
          Text(label, style: AppTypography.quizCaption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
