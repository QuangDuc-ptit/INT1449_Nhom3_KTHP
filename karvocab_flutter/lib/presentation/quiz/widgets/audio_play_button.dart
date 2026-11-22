import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/speech_service.dart';

/// Nút loa lớn cho các chế độ "Nghe": hình tròn xanh trong một vòng sáng,
/// vòng sáng nhịp theo khi đang phát. Tự phát khi mở câu hỏi (nếu [autoPlay]).
class AudioPlayButton extends StatefulWidget {
  final String text;
  final bool autoPlay;

  const AudioPlayButton({
    super.key,
    required this.text,
    this.autoPlay = true,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppDurations.audioPulse);
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  Future<void> _play() async {
    if (_playing || !mounted) return;
    setState(() => _playing = true);
    _pulse.repeat(reverse: true);
    try {
      await SpeechService.instance.speak(widget.text);
    } finally {
      if (mounted) {
        _pulse
          ..stop()
          ..value = 0;
        setState(() => _playing = false);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppDimensions.quizAudioHaloSize,
          height: AppDimensions.quizAudioHaloSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1 + _pulse.value * AppDimensions.quizAudioPulseScale,
                  child: child,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.practiceSelectedFill,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: AppStrings.audioPlaySemantics,
                child: Material(
                  color: AppColors.practicePrimary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _play,
                    child: SizedBox(
                      width: AppDimensions.quizAudioButtonSize,
                      height: AppDimensions.quizAudioButtonSize,
                      child: Icon(
                        _playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                        color: AppColors.white,
                        size: AppDimensions.quizAudioButtonSize * AppDimensions.quizAudioIconFactor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          _playing ? AppStrings.audioPlaying : AppStrings.audioTapToReplay,
          style: AppTypography.quizCaption,
        ),
      ],
    );
  }
}
