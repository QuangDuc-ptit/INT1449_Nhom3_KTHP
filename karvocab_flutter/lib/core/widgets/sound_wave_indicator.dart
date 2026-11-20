import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Hiệu ứng sóng âm nhỏ hiển thị khi đang phát phát âm (DEV1-S2-04).
/// Khi [isActive] = false, các cột đứng yên ở độ cao thấp nhất.
class SoundWaveIndicator extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double height;
  final int barCount;

  const SoundWaveIndicator({
    super.key,
    required this.isActive,
    this.color = AppColors.primaryBlue,
    this.height = 18,
    this.barCount = 4,
  });

  @override
  State<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SoundWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = (_controller.value * 2 * math.pi) + i * 0.9;
              final factor = widget.isActive ? 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase)) : 0.3;
              return Container(
                width: 3,
                height: widget.height * factor,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
