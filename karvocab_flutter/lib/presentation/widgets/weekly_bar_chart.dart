import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Biểu đồ cột 7 ngày vẽ bằng Canvas (không dùng thư viện biểu đồ).
///
/// - Trục Y: giá trị lớn nhất làm tròn lên số đẹp, chia 4 khoảng đều.
/// - Ngày có giá trị `null` không vẽ cột.
/// - Cột của [todayIndex] tô màu đậm, nhãn ngày in đậm.
class WeeklyBarChart extends StatelessWidget {
  /// 7 giá trị theo thứ tự [dayLabels].
  final List<int?> values;
  final List<String> dayLabels;
  final int todayIndex;

  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.dayLabels,
    required this.todayIndex,
  }) : assert(values.length == dayLabels.length);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.chartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeeklyBarChartPainter(
          values: values,
          dayLabels: dayLabels,
          todayIndex: todayIndex,
        ),
      ),
    );
  }

  /// Số khoảng chia trên trục Y.
  static const int gridIntervals = 4;

  /// Giá trị đỉnh trục Y: bước = số đẹp (1, 2, 5 × 10ⁿ) ≥ max / 4, đỉnh = bước × 4.
  static int niceAxisMax(Iterable<int?> values) {
    final maxValue = values.whereType<int>().fold<int>(0, math.max);
    if (maxValue <= 0) return gridIntervals;
    final rawStep = maxValue / gridIntervals;
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final step = [1, 2, 5, 10]
        .map((m) => m * magnitude)
        .firstWhere((s) => s >= rawStep);
    return (math.max(1, step.round())) * gridIntervals;
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<int?> values;
  final List<String> dayLabels;
  final int todayIndex;

  _WeeklyBarChartPainter({
    required this.values,
    required this.dayLabels,
    required this.todayIndex,
  });

  static const double _labelGap = AppDimensions.space8;

  TextPainter _layout(String text, TextStyle style) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)
        ..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const intervals = WeeklyBarChart.gridIntervals;
    final axisMax = WeeklyBarChart.niceAxisMax(values);

    // Nhãn trục Y (từ 0 tới đỉnh) — đo trước để biết lề trái.
    final yLabels = [
      for (var i = 0; i <= intervals; i++)
        _layout('${axisMax * i ~/ intervals}', AppTypography.chartAxisLabel),
    ];
    final yLabelWidth = yLabels.map((p) => p.width).fold<double>(0, math.max);

    final dayStyleNormal = AppTypography.homeSmall;
    final dayStyleToday =
        AppTypography.homeSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.navyBlue);
    final dayPainters = [
      for (var i = 0; i < dayLabels.length; i++)
        _layout(dayLabels[i], i == todayIndex ? dayStyleToday : dayStyleNormal),
    ];
    final dayLabelHeight = dayPainters.map((p) => p.height).fold<double>(0, math.max);

    // Vùng vẽ cột; chừa nửa chiều cao nhãn trên cùng để nhãn đỉnh không bị cắt.
    final plotLeft = yLabelWidth + _labelGap;
    final plotTop = yLabels.last.height / 2;
    final plotBottom = size.height - dayLabelHeight - _labelGap;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = size.width - plotLeft;

    // Đường kẻ ngang + nhãn trục Y
    final gridPaint = Paint()
      ..color = AppColors.homeDivider
      ..strokeWidth = AppDimensions.chartGridLineWidth;
    for (var i = 0; i <= intervals; i++) {
      final y = plotBottom - plotHeight * i / intervals;
      canvas.drawLine(Offset(plotLeft, y), Offset(size.width, y), gridPaint);
      final label = yLabels[i];
      label.paint(canvas, Offset(yLabelWidth - label.width, y - label.height / 2));
    }

    // Cột + nhãn ngày
    final slotWidth = plotWidth / values.length;
    final barWidth = slotWidth * AppDimensions.chartBarWidthFactor;
    const barRadius = Radius.circular(AppDimensions.chartBarRadius);
    for (var i = 0; i < values.length; i++) {
      final centerX = plotLeft + slotWidth * (i + 0.5);
      final value = values[i];
      if (value != null && value > 0) {
        final barHeight = plotHeight * value / axisMax;
        final rect = Rect.fromLTRB(
          centerX - barWidth / 2,
          plotBottom - barHeight,
          centerX + barWidth / 2,
          plotBottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect, topLeft: barRadius, topRight: barRadius),
          Paint()..color = i == todayIndex ? AppColors.chartBarToday : AppColors.chartBar,
        );
      }
      final day = dayPainters[i];
      day.paint(canvas, Offset(centerX - day.width / 2, plotBottom + _labelGap));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter old) =>
      old.todayIndex != todayIndex || !_listEquals(old.values, values) ||
      !_listEquals(old.dayLabels, dayLabels);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
