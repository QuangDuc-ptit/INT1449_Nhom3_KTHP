import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/quiz_settings_store.dart';
import '../../../data/services/feedback_service.dart';

/// Chỉnh âm lượng hiệu ứng: nút −, thanh trượt (bước 10%), nút +, và "Nghe thử".
/// Dùng ở Màn 10 (cài đặt luyện tập) và trong lúc làm bài (nút loa trên đầu màn).
class VolumeControl extends StatelessWidget {
  final QuizSettingsStore settings;
  final FeedbackService? feedback;

  const VolumeControl({super.key, required this.settings, this.feedback});

  IconData _icon(double volume) {
    if (volume <= 0) return Icons.volume_off_rounded;
    if (volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  void _preview() {
    final f = feedback ?? FeedbackService.instance;
    f.volume = settings.volume;
    f.playTick();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final volume = settings.volume;
        final muted = volume <= 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_icon(volume), size: AppDimensions.iconSmall, color: AppColors.practicePrimary),
                const SizedBox(width: AppDimensions.space8),
                const Expanded(child: Text(AppStrings.volumeLabel, style: AppTypography.practiceLabel)),
                Text(
                  muted ? AppStrings.volumeMuted : AppStrings.volumePercent(settings.volumePercent),
                  key: const Key('volume_value'),
                  style: AppTypography.quizCounter,
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('volume_decrease'),
                  tooltip: AppStrings.volumeDecrease,
                  constraints: const BoxConstraints.tightFor(
                    width: AppDimensions.minTouchTarget,
                    height: AppDimensions.minTouchTarget,
                  ),
                  color: AppColors.practicePrimary,
                  onPressed: muted ? null : settings.decreaseVolume,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Slider(
                    key: const Key('volume_slider'),
                    value: volume,
                    divisions: 10,
                    activeColor: AppColors.practicePrimary,
                    inactiveColor: AppColors.practiceSelectedFill,
                    label: AppStrings.volumePercent(settings.volumePercent),
                    semanticFormatterCallback: (v) => AppStrings.volumePercent((v * 100).round()),
                    onChanged: settings.setVolume,
                    // Thả tay thì phát thử để người dùng nghe được mức vừa chọn
                    onChangeEnd: (_) => _preview(),
                  ),
                ),
                IconButton(
                  key: const Key('volume_increase'),
                  tooltip: AppStrings.volumeIncrease,
                  constraints: const BoxConstraints.tightFor(
                    width: AppDimensions.minTouchTarget,
                    height: AppDimensions.minTouchTarget,
                  ),
                  color: AppColors.practicePrimary,
                  onPressed: volume >= 1 ? null : settings.increaseVolume,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('volume_preview'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                  foregroundColor: AppColors.practicePrimary,
                ),
                onPressed: muted ? null : _preview,
                icon: const Icon(Icons.play_arrow_rounded, size: AppDimensions.iconSmall),
                label: const Text(AppStrings.volumePreview),
              ),
            ),
          ],
        );
      },
    );
  }
}
