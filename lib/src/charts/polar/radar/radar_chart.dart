import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';

/// A single data series for the radar chart.
@immutable
class RadarSeries {
  const RadarSeries({
    required this.values,
    this.name,
    this.color,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.showPoints = true,
    this.pointRadius = 4.0,
  });

  /// Values for each axis (must match number of axes).
  final List<double> values;

  /// Series name for legend/tooltip.
  final String? name;

  /// Line color (uses theme color if null).
  final Color? color;

  /// Fill color (uses line color with opacity if null).
  final Color? fillColor;

  /// Line stroke width.
  final double strokeWidth;

  /// Whether to show points at vertices.
  final bool showPoints;

  /// Radius of vertex points.
  final double pointRadius;
}

/// Data configuration for radar chart.
@immutable
class RadarChartData {
  const RadarChartData({
    required this.axes,
    required this.series,
    this.maxValue,
    this.tickCount = 5,
    this.showAxisLabels = true,
    this.showGridLines = true,
    this.gridType = RadarGridType.polygon,
  });

  /// Labels for each axis.
  final List<String> axes;

  /// Data series to display.
  final List<RadarSeries> series;

  /// Maximum value for scaling (auto-calculated if null).
  final double? maxValue;

  /// Number of grid rings.
  final int tickCount;

  /// Whether to show axis labels.
  final bool showAxisLabels;

  /// Whether to show grid lines.
  final bool showGridLines;

  /// Grid line type (polygon or circular).
  final RadarGridType gridType;
}

/// Grid line type for radar chart.
enum RadarGridType {
  /// Polygon grid (connects axis points).
  polygon,

  /// Circular grid (concentric circles).
  circular,
}

/// Radar/Spider chart widget.
class RadarChart extends StatefulWidget {
  const RadarChart({
    required this.data, super.key,
    this.controller,
    this.animation = const ChartAnimation(),
    this.tooltipConfig = const TooltipConfig(),
    this.padding = const EdgeInsets.all(40),
  });

  /// Chart data configuration.
  final RadarChartData data;

  /// Optional controller for external state management.
  final ChartController? controller;

  /// Animation configuration.
  final ChartAnimation animation;

  /// Tooltip configuration.
  final TooltipConfig tooltipConfig;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  State<RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initController();
    _initAnimation();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ChartController();
      _ownsController = true;
    }
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
  void didUpdateWidget(RadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    }
    if (widget.animation != oldWidget.animation) {
      _animationController.duration = widget.animation.duration;
      if (widget.animation.animateOnDataChange) {
        _animationController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

        final chartArea = Rect.fromLTWH(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.horizontal,
          constraints.maxHeight - responsivePadding.vertical,
        );

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltipConfig,
          theme: theme,
          chartArea: chartArea,
          child: ChartGestureDetector(
            controller: _controller,
            onHover: _handleHover,
            onExit: _handleHoverExit,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _RadarChartPainter(
                    data: widget.data,
                    theme: theme,
                    animationValue: _animation.value,
                    controller: _controller,
                    padding: responsivePadding,
                    labelFontSize: labelFontSize,
                    hitRadius: hitRadius,
                  ),
                ),
            ),
          ),
        );
      },
    );
  }

  void _handleHover(PointerHoverEvent event) {
    // Hit testing handled by painter
  }

  void _handleHoverExit(PointerExitEvent event) {
    _controller.setHoveredPoint(null);
  }
}

/// Painter for radar chart.
class _RadarChartPainter extends PolarChartPainter {
  _RadarChartPainter({
    required this.data,
    required super.theme,
    required this.controller,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
    super.animationValue,
  }) : super(
          axisCount: data.axes.length,
          tickCount: data.tickCount,
          repaint: controller,
        );

  final RadarChartData data;
  final ChartController controller;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;
  final ChartHitTester _hitTester = ChartHitTester();

  double get _maxValue {
    if (data.maxValue != null) return data.maxValue!;
    double max = 0;
    for (final series in data.series) {
      for (final value in series.values) {
        if (value > max) max = value;
      }
    }
    return max * 1.1; // Add 10% padding
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    _hitTester.clear();

    final center = chartArea.center;
    final radius = chartArea.width / 2;
    final maxValue = _maxValue;
    final axisCount = data.axes.length;

    // Draw each series
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      final points = <Offset>[];

      // Calculate points for this series
      for (var i = 0; i < axisCount; i++) {
        final value = series.values[i];
        final normalizedValue = (value / maxValue).clamp(0.0, 1.0);
        final animatedValue = normalizedValue * animationValue;
        final angle = degreesToRadians(-90 + (360 / axisCount) * i);
        final r = radius * animatedValue;

        final point = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        points.add(point);

        // Add hit target for each point
        _hitTester.addCircle(
          center: point,
          radius: hitRadius,
          info: DataPointInfo(
            seriesIndex: seriesIndex,
            pointIndex: i,
            xValue: data.axes[i],
            yValue: value,
            position: point,
            seriesName: series.name,
          ),
        );
      }

      if (points.isEmpty) continue;

      // Draw filled area
      final fillColor = series.fillColor ?? seriesColor.withValues(alpha: theme.areaFillOpacity);
      final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.close();

      // Draw subtle shadow beneath the filled area
      final shadowPaint = Paint()
        ..color = seriesColor.withValues(alpha: theme.shadowOpacity * 0.5)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.75);
      canvas.drawPath(fillPath, shadowPaint);

      final fillPaint = getPaint(
        color: fillColor,
        style: PaintingStyle.fill,
      );
      canvas.drawPath(fillPath, fillPaint);

      // Draw outline
      final linePaint = getPaint(
        color: seriesColor,
        strokeWidth: series.strokeWidth,
      );
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      linePath.close();
      canvas.drawPath(linePath, linePaint);

      // Draw points
      if (series.showPoints) {
        final pointPaint = getPaint(
          color: seriesColor,
          style: PaintingStyle.fill,
        );
        final pointBorderPaint = getPaint(
          color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
          strokeWidth: 2,
        );

        for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
          final point = points[pointIndex];
          final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
              controller.hoveredPoint?.pointIndex == pointIndex;

          if (isHovered) {
            // Draw larger highlight for hovered point
            final highlightPaint = getPaint(
              color: seriesColor.withAlpha(51),
              style: PaintingStyle.fill,
            );
            canvas.drawCircle(point, series.pointRadius * 2.5, highlightPaint);
            canvas.drawCircle(point, series.pointRadius + 3, pointBorderPaint);
            canvas.drawCircle(point, series.pointRadius + 2, pointPaint);
          } else {
            canvas.drawCircle(point, series.pointRadius + 1, pointBorderPaint);
            canvas.drawCircle(point, series.pointRadius, pointPaint);
          }
        }
      }
    }
  }

  /// Dash pattern for grid lines.
  List<double> get _gridDashPattern => theme.gridDashPattern ?? const [4, 3];

  /// Creates a dashed version of the given [source] path.
  Path _dashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var idx = 0;
      while (distance < metric.length) {
        final len = _gridDashPattern[idx % _gridDashPattern.length];
        final next = (distance + len).clamp(0.0, metric.length);
        if (draw) {
          result.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
        idx++;
      }
    }
    return result;
  }

  @override
  void paintGrid(Canvas canvas, Size size) {
    if (!data.showGridLines) return;

    final chartArea = getChartArea(size);
    final center = chartArea.center;
    final radius = chartArea.width / 2;
    final axisCount = data.axes.length;

    final gridPaint = getPaint(
      color: theme.gridLineColor,
      strokeWidth: theme.gridLineWidth,
    );

    // Draw grid rings (dashed)
    for (var i = 1; i <= tickCount; i++) {
      final r = radius * (i / tickCount);

      if (data.gridType == RadarGridType.circular) {
        // Build a full-circle path, then dash it
        final circlePath = Path()
          ..addOval(Rect.fromCircle(center: center, radius: r));
        canvas.drawPath(_dashedPath(circlePath), gridPaint);
      } else {
        // Polygon grid
        final path = Path();
        for (var j = 0; j < axisCount; j++) {
          final angle = degreesToRadians(-90 + (360 / axisCount) * j);
          final point = Offset(
            center.dx + r * math.cos(angle),
            center.dy + r * math.sin(angle),
          );
          if (j == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(_dashedPath(path), gridPaint);
      }
    }

    // Draw axis lines / spokes (dashed)
    for (var i = 0; i < axisCount; i++) {
      final angle = degreesToRadians(-90 + (360 / axisCount) * i);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      drawDashedLine(canvas, center, end, gridPaint, _gridDashPattern);
    }
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    if (!data.showAxisLabels) return;

    final chartArea = getChartArea(size);
    final center = chartArea.center;
    final radius = chartArea.width / 2;
    final axisCount = data.axes.length;
    const labelOffset = 20.0;

    for (var i = 0; i < axisCount; i++) {
      final angle = degreesToRadians(-90 + (360 / axisCount) * i);
      final labelPos = Offset(
        center.dx + (radius + labelOffset) * math.cos(angle),
        center.dy + (radius + labelOffset) * math.sin(angle),
      );

      drawText(
        canvas,
        data.axes[i],
        labelPos,
        style: theme.labelStyle.copyWith(fontSize: labelFontSize),
      );
    }
  }

  @override
  Rect getChartArea(Size size) {
    final availableWidth = size.width - padding.horizontal;
    final availableHeight = size.height - padding.vertical;
    final minDimension = math.min(availableWidth, availableHeight);
    final radius = minDimension / 2 - 20;
    final center = Offset(size.width / 2, size.height / 2);

    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => super.shouldRepaint(oldDelegate) ||
        data != oldDelegate.data ||
        padding != oldDelegate.padding ||
        labelFontSize != oldDelegate.labelFontSize ||
        hitRadius != oldDelegate.hitRadius;

  @override
  bool? hitTest(Offset position) {
    final hit = _hitTester.hitTest(position);
    if (hit != null) {
      controller.setHoveredPoint(hit);
    } else {
      controller.setHoveredPoint(null);
    }
    return hit != null;
  }
}
