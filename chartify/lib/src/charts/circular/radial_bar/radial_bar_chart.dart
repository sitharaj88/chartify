import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_painter.dart';
import '../../../theme/chart_theme_data.dart';
import 'radial_bar_chart_data.dart';

export 'radial_bar_chart_data.dart';

/// A radial bar chart widget.
///
/// Displays data as circular progress bars, useful for showing
/// progress, completion rates, or comparing multiple values.
///
/// Example:
/// ```dart
/// RadialBarChart(
///   data: RadialBarChartData(
///     bars: [
///       RadialBarItem(value: 75, label: 'Progress', color: Colors.blue),
///       RadialBarItem(value: 50, label: 'Tasks', color: Colors.green),
///       RadialBarItem(value: 90, label: 'Goals', color: Colors.orange),
///     ],
///   ),
/// )
/// ```
class RadialBarChart extends StatefulWidget {
  const RadialBarChart({
    super.key,
    required this.data,
    this.animation = const ChartAnimation(),
    this.centerWidget,
    this.padding = const EdgeInsets.all(20),
  });

  /// Chart data configuration.
  final RadialBarChartData data;

  /// Animation configuration.
  final ChartAnimation animation;

  /// Optional widget to display at the center.
  final Widget? centerWidget;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  State<RadialBarChart> createState() => _RadialBarChartState();
}

class _RadialBarChartState extends State<RadialBarChart>
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
  void didUpdateWidget(RadialBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _animationController.duration = widget.animation.duration;
    }
    if (widget.data != oldWidget.data && widget.animation.animateOnDataChange) {
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
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _RadialBarChartPainter(
                    data: widget.data,
                    theme: theme,
                    animationValue: _animation.value,
                    padding: widget.padding,
                  ),
                ),
                if (widget.centerWidget != null) widget.centerWidget!,
              ],
            );
          },
        );
      },
    );
  }
}

class _RadialBarChartPainter extends CircularChartPainter {
  _RadialBarChartPainter({
    required this.data,
    required ChartThemeData theme,
    required this.padding,
    double animationValue = 1.0,
  }) : super(
          theme: theme,
          animationValue: animationValue,
          startAngle: data.startAngle,
        );

  final RadialBarChartData data;
  final EdgeInsets padding;

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    final center = chartArea.center;
    final maxRadius = chartArea.width / 2;
    final barCount = data.bars.length;

    if (barCount == 0) return;

    // Calculate total space needed for all bars
    final totalBarSpace = barCount * data.thickness + (barCount - 1) * data.trackGap;
    final availableSpace = maxRadius * (1 - data.innerRadius);
    final scale = totalBarSpace > availableSpace ? availableSpace / totalBarSpace : 1.0;

    final scaledThickness = data.thickness * scale;
    final scaledGap = data.trackGap * scale;

    // Draw bars from outside to inside
    for (var i = 0; i < barCount; i++) {
      final bar = data.bars[i];
      final barThickness = (bar.thickness ?? data.thickness) * scale;

      // Calculate radius for this bar (outer bars first)
      final radius = maxRadius - (i * (scaledThickness + scaledGap)) - barThickness / 2;

      if (radius <= 0) continue;

      final color = bar.color ?? theme.getSeriesColor(i);

      // Draw track
      if (data.showTrack) {
        _drawTrack(canvas, center, radius, barThickness, bar, color);
      }

      // Draw progress bar
      _drawProgressBar(canvas, center, radius, barThickness, bar, color, i);

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, center, radius, barThickness, bar, i);
      }
    }
  }

  void _drawTrack(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
    RadialBarItem bar,
    Color barColor,
  ) {
    final trackColor = bar.trackColor ?? barColor.withValues(alpha: data.trackOpacity);
    final trackPaint = getPaint(
      color: trackColor,
      strokeWidth: thickness,
      strokeCap: data.strokeCap,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      degreesToRadians(data.startAngle),
      degreesToRadians(data.maxAngle),
      false,
      trackPaint,
    );
  }

  void _drawProgressBar(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
    RadialBarItem bar,
    Color color,
    int index,
  ) {
    final animatedValue = bar.normalizedValue * animationValue;
    if (animatedValue <= 0) return;

    final sweepAngle = data.maxAngle * animatedValue;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = data.strokeCap;

    if (bar.gradient != null) {
      // Create gradient shader
      final gradientRect = Rect.fromCircle(center: center, radius: radius + thickness / 2);
      paint.shader = bar.gradient!.createShader(gradientRect);
    } else {
      paint.color = color;
    }

    canvas.drawArc(
      rect,
      degreesToRadians(data.startAngle),
      degreesToRadians(sweepAngle),
      false,
      paint,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
    RadialBarItem bar,
    int index,
  ) {
    final label = bar.label ?? bar.percentageText;
    final animatedValue = bar.normalizedValue * animationValue;
    final sweepAngle = data.maxAngle * animatedValue;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    Offset labelPosition;

    switch (data.labelPosition) {
      case RadialBarLabelPosition.end:
        // Position at the end of the bar arc
        final endAngle = degreesToRadians(data.startAngle + sweepAngle);
        labelPosition = Offset(
          center.dx + (radius + thickness / 2 + 8) * math.cos(endAngle),
          center.dy + (radius + thickness / 2 + 8) * math.sin(endAngle),
        );

      case RadialBarLabelPosition.center:
        // Position in the center (useful for single bar)
        labelPosition = center;

      case RadialBarLabelPosition.outside:
        // Position outside at the start of the bar
        final startAngle = degreesToRadians(data.startAngle);
        labelPosition = Offset(
          center.dx + (radius + thickness / 2 + 15) * math.cos(startAngle),
          center.dy + (radius + thickness / 2 + 15) * math.sin(startAngle),
        );
    }

    drawText(canvas, label, labelPosition, style: textStyle);
  }

  @override
  Rect getChartArea(Size size) {
    final availableWidth = size.width - padding.horizontal;
    final availableHeight = size.height - padding.vertical;
    final minDimension = math.min(availableWidth, availableHeight);
    final radius = minDimension / 2;
    final center = Offset(size.width / 2, size.height / 2);

    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldRepaint(covariant _RadialBarChartPainter oldDelegate) {
    return super.shouldRepaint(oldDelegate) ||
        data != oldDelegate.data ||
        padding != oldDelegate.padding;
  }
}
