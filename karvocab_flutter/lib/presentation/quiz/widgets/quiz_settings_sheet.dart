import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/quiz_models.dart';
import '../../../data/repositories/quiz_settings_store.dart';
import 'volume_control.dart';

/// Màn 10 · Bottom sheet chỉnh thời gian đếm ngược của từng trò chơi và âm lượng hiệu ứng.
/// Thay đổi được lưu ngay vào [settings], nút "Xong" chỉ đóng sheet.
class QuizSettingsSheet extends StatelessWidget {
  final QuizSettingsStore settings;

  /// Các trò chơi theo thứ tự hiển thị trên Màn 10: (chế độ, tên trò).
  final List<(QuizMode, String)> games;

  const QuizSettingsSheet({super.key, required this.settings, required this.games});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.space8),
            Center(
              child: Container(
                width: AppDimensions.practiceSheetHandleWidth,
                height: AppDimensions.space4,
                decoration: BoxDecoration(
                  color: AppColors.practiceBorder,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.practiceHorizontalPadding,
                AppDimensions.space16,
                AppDimensions.space8,
                AppDimensions.space4,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(AppStrings.practiceTimerLabel, style: AppTypography.practiceSectionTitle),
                  ),
                  TextButton(
                    key: const Key('quiz_settings_done'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                    ),
                    child: Text(
                      AppStrings.practiceSheetDone,
                      style: AppTypography.practiceOrderOption.copyWith(color: AppColors.practicePrimary),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.practiceHorizontalPadding),
                children: [
                  SwitchListTile(
                    key: const Key('quiz_timer_switch'),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.practicePrimary,
                    title: const Text(AppStrings.practiceTimerEnable, style: AppTypography.practiceLabel),
                    subtitle: const Text(AppStrings.practiceTimerHint, style: AppTypography.practiceHint),
                    value: settings.timerEnabled,
                    onChanged: settings.setTimerEnabled,
                  ),
                  for (final (mode, title) in games)
                    _SecondsRow(
                      key: Key('quiz_timer_${mode.name}'),
                      title: title,
                      seconds: settings.secondsFor(mode),
                      enabled: settings.timerEnabled,
                      onDecrease: settings.secondsFor(mode) > QuizSettingsStore.minSeconds
                          ? () => settings.decreaseSeconds(mode)
                          : null,
                      onIncrease: settings.secondsFor(mode) < QuizSettingsStore.maxSeconds
                          ? () => settings.increaseSeconds(mode)
                          : null,
                    ),
                  const SizedBox(height: AppDimensions.space8),
                  const Divider(
                    height: AppDimensions.borderThin,
                    thickness: AppDimensions.borderThin,
                    color: AppColors.practiceCardBorder,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  VolumeControl(settings: settings),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('quiz_settings_reset'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                        foregroundColor: AppColors.practiceTextSecondary,
                      ),
                      onPressed: settings.isDefault ? null : settings.resetDefaults,
                      icon: const Icon(Icons.restart_alt_rounded, size: AppDimensions.iconSmall),
                      label: const Text(AppStrings.practiceTimerReset),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một dòng "Tên trò · [−] 35s [+]".
class _SecondsRow extends StatelessWidget {
  final String title;
  final int seconds;
  final bool enabled;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _SecondsRow({
    super.key,
    required this.title,
    required this.seconds,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = BoxConstraints.tightFor(
      width: AppDimensions.minTouchTarget,
      height: AppDimensions.minTouchTarget,
    );
    return Opacity(
      opacity: enabled ? 1 : AppDimensions.quizDimmedOpacity,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.practiceFieldValue)),
          IconButton(
            tooltip: AppStrings.timerDecrease(title),
            constraints: buttonSize,
            color: AppColors.practicePrimary,
            onPressed: enabled ? onDecrease : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: AppDimensions.minTouchTarget,
            child: Text(
              AppStrings.secondsShort(seconds),
              textAlign: TextAlign.center,
              style: AppTypography.quizCounter,
            ),
          ),
          IconButton(
            tooltip: AppStrings.timerIncrease(title),
            constraints: buttonSize,
            color: AppColors.practicePrimary,
            onPressed: enabled ? onIncrease : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
