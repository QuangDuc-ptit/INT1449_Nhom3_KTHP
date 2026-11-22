import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';

/// Vòng tròn tiến độ của thẻ học phần (Màn 05): nền Divider, phần đã đạt
/// BrandLight, giữa là "{phần trăm}%".
class CourseProgressRing extends StatelessWidget {
  /// 0 … 100.
  final int percent;

  const CourseProgressRing({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppDimensions.progressRingSize,
      child: CustomPaint(
        painter: _RingPainter(percent.clamp(0, 100) / 100),
        child: Center(
          child: Text(AppStrings.libraryProgressPercent(percent), style: AppTypography.progressPercent),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppDimensions.progressRingStroke;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = AppColors.divider);
    if (progress > 0) {
      // Bắt đầu từ hướng 12 giờ, chạy theo chiều kim đồng hồ.
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint
          ..color = AppColors.primaryBlue
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
