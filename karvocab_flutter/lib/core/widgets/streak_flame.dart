import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Ngọn lửa chuỗi ngày học, vẽ bằng [CustomPainter] thay cho icon Material.
///
/// Lửa ngoài có lưỡi lửa phụ bên trái, đổ màu đỏ cam → cam vàng; lõi vàng sáng ở giữa.
/// [lit] = `false` (chuỗi 0 ngày) thì lửa tắt, chuyển xám.
class StreakFlame extends StatelessWidget {
  final double size;
  final bool lit;

  const StreakFlame({super.key, required this.size, this.lit = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('streak_flame'),
      width: size,
      height: size,
      child: CustomPaint(painter: _FlamePainter(lit: lit)),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final bool lit;
  const _FlamePainter({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    // Lửa cao hơn rộng: vẽ trong khung tỉ lệ 0.82 × 1, căn giữa.
    final h = size.height;
    final w = h * 0.82;
    final dx = (size.width - w) / 2;

    /// Dựng đường cong khép kín từ điểm đầu + các đoạn Bézier bậc ba (toạ độ 0–1 trong khung lửa).
    Path shape(List<double> start, List<List<double>> curves) {
      final path = Path()..moveTo(dx + start[0] * w, start[1] * h);
      for (final c in curves) {
        path.cubicTo(dx + c[0] * w, c[1] * h, dx + c[2] * w, c[3] * h, dx + c[4] * w, c[5] * h);
      }
      return path..close();
    }

    // Lửa ngoài: đỉnh hơi lệch phải, lưỡi lửa phụ bên trái.
    final outer = shape([0.52, 0], [
      [0.66, 0.2, 0.96, 0.38, 0.94, 0.66],
      [0.92, 0.88, 0.72, 1, 0.5, 1],
      [0.27, 1, 0.06, 0.87, 0.06, 0.63],
      [0.06, 0.47, 0.15, 0.36, 0.25, 0.27],
      [0.27, 0.39, 0.33, 0.46, 0.41, 0.49],
      [0.36, 0.3, 0.42, 0.13, 0.52, 0],
    ]);
    // Lõi lửa: giọt nước ở nửa dưới.
    final core = shape([0.52, 0.46], [
      [0.64, 0.58, 0.76, 0.68, 0.74, 0.81],
      [0.72, 0.93, 0.62, 0.97, 0.5, 0.97],
      [0.38, 0.97, 0.27, 0.91, 0.28, 0.79],
      [0.29, 0.67, 0.42, 0.58, 0.52, 0.46],
    ]);

    final bounds = Offset(dx, 0) & Size(w, h);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lit
              ? const [AppColors.streakFlameTop, AppColors.streakFlameBottom]
              : const [AppColors.streakOffOuter, AppColors.streakOffOuter],
        ).createShader(bounds),
    );
    canvas.drawPath(
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lit
              ? const [AppColors.streakCoreTop, AppColors.streakCoreBottom]
              : const [AppColors.streakOffCore, AppColors.streakOffCore],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.lit != lit;
}
