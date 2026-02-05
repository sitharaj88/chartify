import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'sparkline_chart_data.dart';

export 'sparkline_chart_data.dart';

/// A compact sparkline chart widget.
///
/// Sparklines are small, word-sized graphics that show data trends
/// without the overhead of axes, labels, or legends.
///
/// Example:
/// ```dart
/// SparklineChart(
///   data: SparklineChartData(
///     values: [10, 25, 15, 30, 20, 35],
///     type: SparklineType.line,
///     showLastMarker: true,
///   ),
/// )
/// ```
class SparklineChart extends StatefulWidget {
  const SparklineChart({
    required this.data, super.key,
    this.animation = const ChartAnimation(),
    this.padding = EdgeInsets.zero,
  });

  /// Chart data configuration.
  final SparklineChartData data;

  /// Animation configuration.
  final ChartAnimation animation;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  State<SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<SparklineChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
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
  void didUpdateWidget(SparklineChart oldWidget) {
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
        final responsivePadding = getResponsivePadding(
          context,
          constraints,
          override: widget.padding,
        );
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => CustomPaint(
            painter: _SparklinePainter(
              data: widget.data,
              theme: theme,
              animationValue: _animation.value,
              padding: responsivePadding,
              labelFontSize: labelFontSize,
              hitRadius: hitRadius,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.theme,
    required this.animationValue,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
  });

  final SparklineChartData data;
  final ChartThemeData theme;
  final double animationValue;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.values.isEmpty) return;

    final chartArea = Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );

    if (chartArea.width <= 0 || chartArea.height <= 0) return;

    // Draw reference line first (behind everything)
    _drawReferenceLine(canvas, chartArea);

    // Draw based on type
    switch (data.type) {
      case SparklineType.line:
        _drawLine(canvas, chartArea);
      case SparklineType.area:
        _drawArea(canvas, chartArea);
      case SparklineType.bar:
        _drawBars(canvas, chartArea);
      case SparklineType.winLoss:
        _drawWinLoss(canvas, chartArea);
    }

    // Draw markers
    _drawMarkers(canvas, chartArea);
  }

  List<Offset> _calculatePoints(Rect chartArea) {
    final points = <Offset>[];
    final count = data.values.length;
    if (count == 0) return points;

    final minVal = data.minValue;
    final maxVal = data.maxValue;
    final range = maxVal - minVal;

    for (var i = 0; i < count; i++) {
      final x = count == 1
          ? chartArea.center.dx
          : chartArea.left + (chartArea.width * i / (count - 1));

      final normalizedY = range == 0 ? 0.5 : (data.values[i] - minVal) / range;
      final y = chartArea.bottom - (chartArea.height * normalizedY);

      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawLine(Canvas canvas, Rect chartArea) {
    final points = _calculatePoints(chartArea);
    if (points.length < 2) return;

    final color = data.color ?? theme.getSeriesColor(0);
    final path = _createPath(points, data.curved);
    final animatedPath = _getAnimatedPath(path, animationValue);

    // Draw subtle shadow beneath the line
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: theme.shadowOpacity * 1.3)
      ..strokeWidth = data.lineWidth + 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
      ..isAntiAlias = true;
    canvas.drawPath(animatedPath, shadowPaint);

    // Draw the main line
    final paint = Paint()
      ..color = color
      ..strokeWidth = data.lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(animatedPath, paint);
  }

  void _drawArea(Canvas canvas, Rect chartArea) {
    final points = _calculatePoints(chartArea);
    if (points.length < 2) return;

    final color = data.color ?? theme.getSeriesColor(0);

    // Create line path
    final linePath = _createPath(points, data.curved);

    // Create area path
    final areaPath = Path()..addPath(linePath, Offset.zero);

    // Close the path for filling
    final baseline = data.clipToZero && data.minValue < 0 && data.maxValue > 0
        ? _valueToY(0, chartArea)
        : chartArea.bottom;

    areaPath
      ..lineTo(points.last.dx, baseline)
      ..lineTo(points.first.dx, baseline)
      ..close();

    // Draw area fill with gradient (top with alpha -> bottom transparent)
    final animatedAreaPath = _getAnimatedAreaPath(areaPath, points, chartArea, animationValue);

    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: data.areaOpacity * animationValue),
        color.withValues(alpha: 0.0),
      ],
    );

    final areaPaint = Paint()
      ..shader = areaGradient.createShader(chartArea)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(animatedAreaPath, areaPaint);

    // Draw subtle shadow beneath the line
    final animatedLinePath = _getAnimatedPath(linePath, animationValue);

    final shadowPaint2 = Paint()
      ..color = color.withValues(alpha: theme.shadowOpacity * 1.3)
      ..strokeWidth = data.lineWidth + 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
      ..isAntiAlias = true;
    canvas.drawPath(animatedLinePath, shadowPaint2);

    // Draw line on top
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = data.lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(animatedLinePath, linePaint);
  }

  void _drawBars(Canvas canvas, Rect chartArea) {
    final count = data.values.length;
    if (count == 0) return;

    final minVal = data.minValue;
    final maxVal = data.maxValue;
    final range = maxVal - minVal;

    final barWidth = data.barWidth ??
        (chartArea.width - (count - 1) * data.barSpacing) / count;
    final totalBarSpace = barWidth + data.barSpacing;

    final color = data.color ?? theme.getSeriesColor(0);
    final negColor = data.negativeColor ?? Colors.red;

    // Determine baseline
    final hasNegative = minVal < 0;
    final baseline = hasNegative && maxVal > 0
        ? _valueToY(0, chartArea)
        : (minVal >= 0 ? chartArea.bottom : chartArea.top);

    for (var i = 0; i < count; i++) {
      final value = data.values[i];
      final x = chartArea.left + totalBarSpace * i;

      final normalizedY = range == 0 ? 0.5 : (value - minVal) / range;
      final y = chartArea.bottom - (chartArea.height * normalizedY);

      // Animate height
      final animatedY = baseline + (y - baseline) * animationValue;

      final barRect = Rect.fromLTRB(
        x,
        math.min(baseline, animatedY),
        x + barWidth,
        math.max(baseline, animatedY),
      );

      final paint = Paint()
        ..color = value >= 0 ? color : negColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawRect(barRect, paint);
    }
  }

  void _drawWinLoss(Canvas canvas, Rect chartArea) {
    final count = data.values.length;
    if (count == 0) return;

    final barWidth = data.barWidth ??
        (chartArea.width - (count - 1) * data.barSpacing) / count;
    final totalBarSpace = barWidth + data.barSpacing;
    final barHeight = (chartArea.height - 4) / 2; // Leave gap in middle

    final color = data.color ?? theme.getSeriesColor(0);
    final negColor = data.negativeColor ?? Colors.red;

    final midY = chartArea.center.dy;

    for (var i = 0; i < count; i++) {
      final value = data.values[i];
      final x = chartArea.left + totalBarSpace * i;

      // Animate height
      final animatedHeight = barHeight * animationValue;

      Rect barRect;
      if (value >= 0) {
        barRect = Rect.fromLTRB(x, midY - animatedHeight - 1, x + barWidth, midY - 1);
      } else {
        barRect = Rect.fromLTRB(x, midY + 1, x + barWidth, midY + animatedHeight + 1);
      }

      final paint = Paint()
        ..color = value >= 0 ? color : negColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(1)),
        paint,
      );
    }
  }

  void _drawReferenceLine(Canvas canvas, Rect chartArea) {
    final refValue = data.referenceValue;
    if (refValue == null) return;

    final y = _valueToY(refValue, chartArea);
    if (y < chartArea.top || y > chartArea.bottom) return;

    final color = data.referenceLineColor ?? theme.gridLineColor;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * animationValue)
      ..strokeWidth = data.referenceLineWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Draw dashed line
    _drawDashedLine(
      canvas,
      Offset(chartArea.left, y),
      Offset(chartArea.right, y),
      paint,
      data.referenceLineDash,
    );
  }

  void _drawMarkers(Canvas canvas, Rect chartArea) {
    final points = _calculatePoints(chartArea);
    if (points.isEmpty) return;

    final color = data.color ?? theme.getSeriesColor(0);

    // First marker
    if (data.showFirstMarker && points.isNotEmpty) {
      _drawMarker(canvas, points.first, data.firstMarker, color);
    }

    // Last marker
    if (data.showLastMarker && points.isNotEmpty) {
      _drawMarker(canvas, points.last, data.lastMarker, color);
    }

    // Min marker
    if (data.showMinMarker) {
      final minIdx = data.minIndex;
      if (minIdx >= 0 && minIdx < points.length) {
        _drawMarker(canvas, points[minIdx], data.minMarker, color);
      }
    }

    // Max marker
    if (data.showMaxMarker) {
      final maxIdx = data.maxIndex;
      if (maxIdx >= 0 && maxIdx < points.length) {
        _drawMarker(canvas, points[maxIdx], data.maxMarker, color);
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset center, SparklineMarker marker, Color defaultColor) {
    if (!marker.show) return;

    final fillColor = marker.color ?? defaultColor;
    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: fillColor.a * animationValue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, marker.radius, fillPaint);

    if (marker.borderWidth > 0) {
      final borderColor = marker.borderColor ?? Colors.white;
      final borderPaint = Paint()
        ..color = borderColor.withValues(alpha: borderColor.a * animationValue)
        ..strokeWidth = marker.borderWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawCircle(center, marker.radius, borderPaint);
    }
  }

  double _valueToY(double value, Rect chartArea) {
    final minVal = data.minValue;
    final maxVal = data.maxValue;
    final range = maxVal - minVal;

    if (range == 0) return chartArea.center.dy;

    final normalized = (value - minVal) / range;
    return chartArea.bottom - (chartArea.height * normalized);
  }

  Path _createPath(List<Offset> points, bool curved) {
    if (points.isEmpty) return Path();

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    if (!curved || points.length < 3) {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      // Monotone cubic interpolation
      for (var i = 1; i < points.length; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = i < points.length - 1 ? points[i + 1] : points[i];

        final controlPoint1 = Offset(
          p0.dx + (p1.dx - p0.dx) / 3,
          p0.dy + (p1.dy - p0.dy) / 3,
        );
        final controlPoint2 = Offset(
          p1.dx - (p2.dx - p0.dx) / 6,
          p1.dy - (p2.dy - p0.dy) / 6,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }
    }

    return path;
  }

  Path _getAnimatedPath(Path path, double progress) {
    if (progress >= 1.0) return path;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return Path();

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * progress;

    final result = Path();
    var currentLength = 0.0;

    for (final metric in metrics) {
      if (currentLength + metric.length <= targetLength) {
        result.addPath(metric.extractPath(0, metric.length), Offset.zero);
        currentLength += metric.length;
      } else {
        final remaining = targetLength - currentLength;
        if (remaining > 0) {
          result.addPath(metric.extractPath(0, remaining), Offset.zero);
        }
        break;
      }
    }

    return result;
  }

  Path _getAnimatedAreaPath(
    Path fullPath,
    List<Offset> points,
    Rect chartArea,
    double progress,
  ) {
    if (progress >= 1.0) return fullPath;

    // For area, animate from bottom up
    final animatedPoints = points.map((p) {
      final targetY = p.dy;
      final startY = chartArea.bottom;
      return Offset(p.dx, startY + (targetY - startY) * progress);
    }).toList();

    final linePath = _createPath(animatedPoints, data.curved);
    final areaPath = Path()..addPath(linePath, Offset.zero);

    final baseline = data.clipToZero && data.minValue < 0 && data.maxValue > 0
        ? _valueToY(0, chartArea)
        : chartArea.bottom;

    areaPath
      ..lineTo(animatedPoints.last.dx, baseline)
      ..lineTo(animatedPoints.first.dx, baseline)
      ..close();

    return areaPath;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashPattern,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      var drawDash = true;
      var dashIndex = 0;

      while (distance < metric.length) {
        final dashLength = dashPattern[dashIndex % dashPattern.length];
        final nextDistance = distance + dashLength;

        if (drawDash) {
          final extractPath = metric.extractPath(
            distance,
            nextDistance.clamp(0, metric.length),
          );
          canvas.drawPath(extractPath, paint);
        }

        distance = nextDistance;
        drawDash = !drawDash;
        dashIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      data != oldDelegate.data ||
      animationValue != oldDelegate.animationValue ||
      theme != oldDelegate.theme ||
      padding != oldDelegate.padding ||
      labelFontSize != oldDelegate.labelFontSize ||
      hitRadius != oldDelegate.hitRadius;
}
