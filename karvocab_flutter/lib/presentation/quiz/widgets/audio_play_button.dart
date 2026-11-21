import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/speech_service.dart';

/// Nút loa lớn 96dp dùng cho các chế độ "Nghe". Tự phát khi mở câu hỏi (nếu [autoPlay]).
class AudioPlayButton extends StatefulWidget {
  final String text;
  final bool autoPlay;
  final double size;

  const AudioPlayButton({
    super.key,
    required this.text,
    this.autoPlay = true,
    this.size = 96,
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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
        _pulse.stop();
        _pulse.value = 0;
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
        Semantics(
          button: true,
          label: 'Phát âm thanh',
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = 1 + _pulse.value * 0.08;
              return Transform.scale(scale: scale, child: child);
            },
            child: Material(
              color: AppColors.primaryBlue,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _play,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Icon(
                    _playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                    color: AppColors.white,
                    size: widget.size * 0.45,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _playing ? 'Đang phát...' : 'Chạm để nghe lại',
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}
