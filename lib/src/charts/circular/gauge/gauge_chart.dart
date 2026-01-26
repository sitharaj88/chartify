import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_painter.dart';
import '../../../theme/chart_theme_data.dart';

/// A range segment for the gauge chart.
@immutable
class GaugeRange {
  const GaugeRange({
    required this.start,
    required this.end,
    required this.color,
    this.label,
  });

  /// Start value of this range.
  final double start;

  /// End value of this range.
  final double end;

  /// Color for this range.
  final Color color;

  /// Optional label for this range.
  final String? label;
}

/// Data configuration for gauge chart.
@immutable
class GaugeChartData {
  const GaugeChartData({
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.ranges,
    this.startAngle = 135,
    this.sweepAngle = 270,
    this.thickness = 20,
    this.showValue = true,
    this.valueFormatter,
    this.label,
    this.showTicks = true,
    this.majorTickCount = 5,
    this.minorTickCount = 4,
    this.needleColor,
    this.needleLength = 0.8,
    this.needleWidth = 3,
    this.showNeedleBase = true,
    this.needleBaseRadius = 10,
  });

  /// Current value to display.
  final double value;

  /// Minimum gauge value.
  final double minValue;

  /// Maximum gauge value.
  final double maxValue;

  /// Color ranges for the gauge arc.
  final List<GaugeRange>? ranges;

  /// Start angle in degrees (0 = right, 90 = bottom).
  final double startAngle;

  /// Sweep angle in degrees.
  final double sweepAngle;

  /// Thickness of the gauge arc.
  final double thickness;

  /// Whether to show the current value.
  final bool showValue;

  /// Custom value formatter.
  final String Function(double value)? valueFormatter;

  /// Optional label below the value.
  final String? label;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Number of major tick marks.
  final int majorTickCount;

  /// Number of minor ticks between major ticks.
  final int minorTickCount;

  /// Needle color (uses theme primary if null).
  final Color? needleColor;

  /// Needle length as a ratio of radius (0-1).
  final double needleLength;

  /// Needle width.
  final double needleWidth;

  /// Whether to show the circular needle base.
  final bool showNeedleBase;

  /// Radius of the needle base circle.
  final double needleBaseRadius;

  /// Get the normalized value (0-1).
  double get normalizedValue =>
      ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

  String get formattedValue =>
      valueFormatter?.call(value) ?? value.toStringAsFixed(0);
}

/// Gauge chart widget.
class GaugeChart extends StatefulWidget {
  const GaugeChart({
    super.key,
    required this.data,
    this.animation = const ChartAnimation(),
    this.centerWidget,
    this.padding = const EdgeInsets.all(20),
  });

  /// Chart data configuration.
  final GaugeChartData data;

  /// Animation configuration.
  final ChartAnimation animation;

  /// Optional widget to display at center.
  final Widget? centerWidget;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  State<GaugeChart> createState() => _GaugeChartState();
}

class _GaugeChartState extends State<GaugeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animation.duration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animation.curve,
    );
    if (widget.animation.animateOnLoad) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GaugeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _animationController.duration = widget.animation.duration;
    }
    if (widget.data.value != oldWidget.data.value &&
        widget.animation.animateOnDataChange) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _GaugeChartPainter(
                    data: widget.data,
                    theme: theme,
                    animationValue: _animation.value,
                    padding: widget.padding,
                  ),
                ),
                if (widget.centerWidget != null)
                  Positioned.fill(
                    child: Center(child: widget.centerWidget!),
                  ),
                if (widget.centerWidget == null && widget.data.showValue)
                  _buildDefaultCenterWidget(theme, size),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultCenterWidget(ChartThemeData theme, Size size) {
    // Position value BELOW the needle hub to avoid overlap
    final centerY = size.height / 2;
    final valueTop = centerY + widget.data.needleBaseRadius + 8;

    return Positioned(
      left: 0,
      right: 0,
      top: valueTop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.data.formattedValue,
            textAlign: TextAlign.center,
            style: theme.titleStyle.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.data.label != null)
            Text(
              widget.data.label!,
              textAlign: TextAlign.center,
              style: theme.labelStyle.copyWith(
                color: theme.labelStyle.color?.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// Painter for gauge chart.
class _GaugeChartPainter extends CircularChartPainter {
  _GaugeChartPainter({
    required this.data,
    required ChartThemeData theme,
    required this.padding,
    double animationValue = 1.0,
  }) : super(
          theme: theme,
          animationValue: animationValue,
          startAngle: data.startAngle,
        );

  final GaugeChartData data;
  final EdgeInsets padding;

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    final center = chartArea.center;
    final radius = chartArea.width / 2;
    final innerRadius = radius - data.thickness;

    // Draw background arc
    _drawBackgroundArc(canvas, center, radius, innerRadius);

    // Draw range segments or single arc
    if (data.ranges != null && data.ranges!.isNotEmpty) {
      _drawRanges(canvas, center, radius, innerRadius);
    }

    // Draw value arc
    _drawValueArc(canvas, center, radius, innerRadius);

    // Draw ticks
    if (data.showTicks) {
      _drawTicks(canvas, center, radius);
    }

    // Draw needle
    _drawNeedle(canvas, center, innerRadius);
  }

  void _drawBackgroundArc(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
  ) {
    final backgroundPaint = getPaint(
      color: theme.gridLineColor.withValues(alpha: 0.3),
      strokeWidth: data.thickness,
      strokeCap: StrokeCap.round,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - data.thickness / 2,
    );

    canvas.drawArc(
      rect,
      degreesToRadians(data.startAngle),
      degreesToRadians(data.sweepAngle),
      false,
      backgroundPaint,
    );
  }

  void _drawRanges(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
  ) {
    for (final range in data.ranges!) {
      final startNorm = ((range.start - data.minValue) /
              (data.maxValue - data.minValue))
          .clamp(0.0, 1.0);
      final endNorm =
          ((range.end - data.minValue) / (data.maxValue - data.minValue))
              .clamp(0.0, 1.0);

      final rangeStart = data.startAngle + data.sweepAngle * startNorm;
      final rangeSweep = data.sweepAngle * (endNorm - startNorm);

      final rangePaint = getPaint(
        color: range.color.withValues(alpha: 0.3),
        strokeWidth: data.thickness,
        strokeCap: StrokeCap.butt,
      );

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - data.thickness / 2,
      );

      canvas.drawArc(
        rect,
        degreesToRadians(rangeStart),
        degreesToRadians(rangeSweep),
        false,
        rangePaint,
      );
    }
  }

  void _drawValueArc(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
  ) {
    final animatedValue = data.normalizedValue * animationValue;
    if (animatedValue <= 0) return;

    final valueAngle = data.sweepAngle * animatedValue;

    // Determine color based on ranges
    Color valueColor = theme.getSeriesColor(0);
    if (data.ranges != null && data.ranges!.isNotEmpty) {
      final currentValue = data.value;
      for (final range in data.ranges!) {
        if (currentValue >= range.start && currentValue <= range.end) {
          valueColor = range.color;
          break;
        }
      }
    }

    final valuePaint = getPaint(
      color: valueColor,
      strokeWidth: data.thickness,
      strokeCap: StrokeCap.round,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - data.thickness / 2,
    );

    canvas.drawArc(
      rect,
      degreesToRadians(data.startAngle),
      degreesToRadians(valueAngle),
      false,
      valuePaint,
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickRadius = radius + 5;
    final majorTickLength = 10.0;
    final minorTickLength = 5.0;

    final majorTickPaint = getPaint(
      color: theme.axisLineColor,
      strokeWidth: 2,
    );

    final minorTickPaint = getPaint(
      color: theme.axisLineColor.withValues(alpha: 0.5),
      strokeWidth: 1,
    );

    final totalTicks =
        data.majorTickCount + (data.majorTickCount - 1) * data.minorTickCount;

    for (var i = 0; i <= totalTicks; i++) {
      final isMajor = i % (data.minorTickCount + 1) == 0;
      final angle = degreesToRadians(
          data.startAngle + data.sweepAngle * (i / totalTicks));
      final tickLength = isMajor ? majorTickLength : minorTickLength;

      final outerPoint = Offset(
        center.dx + tickRadius * math.cos(angle),
        center.dy + tickRadius * math.sin(angle),
      );

      final innerPoint = Offset(
        center.dx + (tickRadius + tickLength) * math.cos(angle),
        center.dy + (tickRadius + tickLength) * math.sin(angle),
      );

      canvas.drawLine(
        outerPoint,
        innerPoint,
        isMajor ? majorTickPaint : minorTickPaint,
      );

      // Draw major tick labels
      if (isMajor) {
        final tickValue = data.minValue +
            (data.maxValue - data.minValue) * (i / totalTicks);
        final labelRadius = tickRadius + tickLength + 15;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(angle),
          center.dy + labelRadius * math.sin(angle),
        );

        drawText(
          canvas,
          tickValue.toStringAsFixed(0),
          labelPos,
          style: theme.labelStyle.copyWith(fontSize: 10),
        );
      }
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double innerRadius) {
    final animatedValue = data.normalizedValue * animationValue;
    final needleAngle =
        degreesToRadians(data.startAngle + data.sweepAngle * animatedValue);

    final needleColor = data.needleColor ?? theme.getSeriesColor(0);
    final needleLength = innerRadius * data.needleLength;

    // Create tapered needle path for better visibility
    final needlePath = _createNeedlePath(center, needleAngle, needleLength);

    // Draw needle shadow
    canvas.save();
    canvas.translate(2, 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(needlePath, shadowPaint);
    canvas.restore();

    // Draw needle body
    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    // Draw needle base
    if (data.showNeedleBase) {
      // Shadow for base
      final baseShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(center.dx + 1, center.dy + 2),
        data.needleBaseRadius,
        baseShadowPaint,
      );

      // Base circle
      final basePaint = Paint()
        ..color = needleColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, data.needleBaseRadius, basePaint);

      // Highlight
      final baseHighlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(center.dx - data.needleBaseRadius * 0.25,
            center.dy - data.needleBaseRadius * 0.25),
        data.needleBaseRadius * 0.35,
        baseHighlightPaint,
      );
    }
  }

  Path _createNeedlePath(Offset center, double angle, double length) {
    final path = Path();
    final perpAngle = angle + math.pi / 2;

    // Needle base width (at center)
    const baseWidth = 8.0;

    // Base points perpendicular to needle direction
    final baseLeft = Offset(
      center.dx + (baseWidth / 2) * math.cos(perpAngle),
      center.dy + (baseWidth / 2) * math.sin(perpAngle),
    );
    final baseRight = Offset(
      center.dx - (baseWidth / 2) * math.cos(perpAngle),
      center.dy - (baseWidth / 2) * math.sin(perpAngle),
    );

    // Tip point
    final tipPoint = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );

    // Small tail behind center
    final tailLength = baseWidth * 0.5;
    final tailPoint = Offset(
      center.dx - tailLength * math.cos(angle),
      center.dy - tailLength * math.sin(angle),
    );

    path.moveTo(tailPoint.dx, tailPoint.dy);
    path.lineTo(baseLeft.dx, baseLeft.dy);
    path.lineTo(tipPoint.dx, tipPoint.dy);
    path.lineTo(baseRight.dx, baseRight.dy);
    path.close();

    return path;
  }

  @override
  Rect getChartArea(Size size) {
    final availableWidth = size.width - padding.horizontal;
    final availableHeight = size.height - padding.vertical;
    final minDimension = math.min(availableWidth, availableHeight);
    final radius = minDimension / 2 - 30; // Extra space for ticks
    final center = Offset(size.width / 2, size.height / 2);

    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldRepaint(covariant _GaugeChartPainter oldDelegate) {
    return super.shouldRepaint(oldDelegate) ||
        data != oldDelegate.data ||
        padding != oldDelegate.padding;
  }
}
