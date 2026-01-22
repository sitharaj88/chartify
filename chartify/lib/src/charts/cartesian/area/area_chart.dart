import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/data/data_point.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../line/line_chart_data.dart';

/// A data series for area charts.
class AreaSeries<X, Y extends num> {
  const AreaSeries({
    this.name,
    required this.data,
    this.color,
    this.visible = true,
    this.strokeWidth = 2.0,
    this.strokeColor,
    this.fillOpacity = 0.3,
    this.gradient,
    this.curved = true,
    this.showLine = true,
    this.showMarkers = false,
    this.markerSize = 4.0,
  });

  final String? name;
  final List<DataPoint<X, Y>> data;
  final Color? color;
  final bool visible;
  final double strokeWidth;
  final Color? strokeColor;
  final double fillOpacity;
  final Gradient? gradient;
  final bool curved;
  final bool showLine;
  final bool showMarkers;
  final double markerSize;

  bool get isEmpty => data.isEmpty;
  int get length => data.length;
}

/// Data configuration for an area chart.
class AreaChartData {
  const AreaChartData({
    required this.series,
    this.stacked = false,
    this.xAxis,
    this.yAxis,
    this.animation,
  });

  final List<AreaSeries> series;
  final bool stacked;
  final AxisConfig? xAxis;
  final AxisConfig? yAxis;
  final ChartAnimation? animation;
}

/// An area chart widget.
///
/// Displays data as filled areas under lines.
/// Supports stacked areas and gradients.
class AreaChart extends StatefulWidget {
  const AreaChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onDataPointTap,
    this.onDataPointHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final AreaChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DataPointInfo info)? onDataPointTap;
  final void Function(DataPointInfo? info)? onDataPointHover;
  final EdgeInsets padding;

  @override
  State<AreaChart> createState() => _AreaChartState();
}

class _AreaChartState extends State<AreaChart>
    with SingleTickerProviderStateMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;

  double _xMin = 0, _xMax = 1, _yMin = 0, _yMax = 1;
  bool _boundsValid = false;

  ChartAnimation get _animationConfig =>
      widget.animation ?? widget.data.animation ?? const ChartAnimation();

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
    if (_animationConfig.enabled && _animationConfig.animateOnLoad) {
      _animationController = AnimationController(
        vsync: this,
        duration: _animationConfig.duration,
      );

      _animation = CurvedAnimation(
        parent: _animationController!,
        curve: _animationConfig.curve,
      );

      _animationController!.addListener(() {
        if (mounted) setState(() {});
      });

      _animationController!.forward();
    }
  }

  @override
  void didUpdateWidget(AreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      _boundsValid = false;
      if (_animationConfig.enabled && _animationConfig.animateOnDataChange) {
        _animationController?.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _calculateBounds() {
    if (_boundsValid) return;

    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    bool hasData = false;

    if (widget.data.stacked) {
      // For stacked, calculate cumulative max
      int maxLength = 0;
      for (final series in widget.data.series) {
        if (!series.visible) continue;
        maxLength = math.max(maxLength, series.data.length);
      }

      for (var i = 0; i < maxLength; i++) {
        double stackSum = 0;
        for (final series in widget.data.series) {
          if (!series.visible || i >= series.data.length) continue;
          hasData = true;
          final point = series.data[i];
          final px = _toDouble(point.x);
          if (px < xMin) xMin = px;
          if (px > xMax) xMax = px;
          stackSum += point.y.toDouble();
        }
        if (stackSum > yMax) yMax = stackSum;
        if (stackSum < yMin) yMin = stackSum;
      }
    } else {
      for (final series in widget.data.series) {
        if (!series.visible) continue;
        for (final point in series.data) {
          hasData = true;
          final px = _toDouble(point.x);
          final py = point.y.toDouble();
          if (px < xMin) xMin = px;
          if (px > xMax) xMax = px;
          if (py < yMin) yMin = py;
          if (py > yMax) yMax = py;
        }
      }
    }

    if (!hasData) {
      _xMin = 0;
      _xMax = 1;
      _yMin = 0;
      _yMax = 1;
      _boundsValid = true;
      return;
    }

    _xMin = xMin;
    _xMax = xMax;
    _yMin = yMin;
    _yMax = yMax;

    if (widget.data.xAxis?.min != null) _xMin = widget.data.xAxis!.min!;
    if (widget.data.xAxis?.max != null) _xMax = widget.data.xAxis!.max!;
    if (widget.data.yAxis?.min != null) _yMin = widget.data.yAxis!.min!;
    if (widget.data.yAxis?.max != null) _yMax = widget.data.yAxis!.max!;

    final yRange = _yMax - _yMin;
    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else if (widget.data.yAxis?.min == null && _yMin > 0) {
      _yMin = 0;
    }

    final paddedYRange = _yMax - _yMin;
    _yMax += paddedYRange * 0.05;

    _boundsValid = true;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is DateTime) return value.millisecondsSinceEpoch.toDouble();
    return 0;
  }

  Offset _dataToScreen(dynamic x, num y) {
    if (_chartArea == Rect.zero) return Offset.zero;

    _calculateBounds();

    final xValue = _toDouble(x);
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;

    final screenX = xRange == 0
        ? _chartArea.center.dx
        : _chartArea.left + (xValue - _xMin) / xRange * _chartArea.width;

    final screenY = yRange == 0
        ? _chartArea.center.dy
        : _chartArea.bottom - (y.toDouble() - _yMin) / yRange * _chartArea.height;

    return Offset(screenX, screenY);
  }

  DataPointInfo? _findNearestPointOnX(Offset position) {
    if (widget.data.series.isEmpty) return null;
    if (!_chartArea.contains(position)) return null;

    DataPointInfo? nearest;
    double minDistance = double.infinity;

    for (var seriesIndex = 0; seriesIndex < widget.data.series.length; seriesIndex++) {
      final series = widget.data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
        final point = series.data[pointIndex];
        final screenPos = _dataToScreen(point.x, point.y);
        final distance = (screenPos.dx - position.dx).abs();

        if (distance < minDistance) {
          minDistance = distance;
          nearest = DataPointInfo(
            seriesIndex: seriesIndex,
            pointIndex: pointIndex,
            position: screenPos,
            xValue: point.x,
            yValue: point.y,
            seriesName: series.name,
          );
        }
      }
    }

    return nearest;
  }

  void _handleHover(PointerEvent event) {
    final nearestInfo = _findNearestPointOnX(event.localPosition);
    if (nearestInfo != null) {
      _controller.setHoveredPoint(nearestInfo);
      widget.onDataPointHover?.call(nearestInfo);
    } else {
      _controller.clearHoveredPoint();
      widget.onDataPointHover?.call(null);
    }
  }

  void _handleHoverExit(PointerExitEvent event) {
    _controller.clearHoveredPoint();
    widget.onDataPointHover?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        _chartArea = Rect.fromLTRB(
          widget.padding.left,
          widget.padding.top,
          constraints.maxWidth - widget.padding.right,
          constraints.maxHeight - widget.padding.bottom,
        );

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltip,
          theme: theme,
          chartArea: _chartArea,
          tooltipDataBuilder: (info) => _buildTooltipData(info, theme),
          child: ChartGestureDetector(
            controller: _controller,
            interactions: widget.interactions,
            hitTester: _hitTester,
            onTap: (details) {
              final hitInfo = _hitTester.hitTest(
                details.localPosition,
                radius: widget.interactions.hitTestRadius,
              );
              if (hitInfo != null && widget.onDataPointTap != null) {
                widget.onDataPointTap!(hitInfo);
              }
            },
            onHover: _handleHover,
            onExit: _handleHoverExit,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AreaChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: widget.padding,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }

  TooltipData _buildTooltipData(DataPointInfo info, ChartThemeData theme) {
    final series = widget.data.series[info.seriesIndex];

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: series.color ?? theme.getSeriesColor(info.seriesIndex),
          label: series.name ?? 'Series ${info.seriesIndex + 1}',
          value: info.yValue,
        ),
      ],
      xLabel: _formatXLabel(info.xValue),
    );
  }

  String _formatXLabel(dynamic value) {
    if (value is DateTime) {
      return '${value.month}/${value.day}/${value.year}';
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}

class _AreaChartPainter extends CartesianChartPainter {
  _AreaChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required EdgeInsets padding,
  }) : super(padding: padding, repaint: controller) {
    _calculateBounds();
  }

  final AreaChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;

  double _xMin = 0, _xMax = 1, _yMin = 0, _yMax = 1;
  bool _boundsCalculated = false;

  void _calculateBounds() {
    if (_boundsCalculated) return;

    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    bool hasData = false;

    for (final series in data.series) {
      if (!series.visible) continue;
      for (final point in series.data) {
        hasData = true;
        final px = _toDouble(point.x);
        final py = point.y.toDouble();
        if (px < xMin) xMin = px;
        if (px > xMax) xMax = px;
        if (py < yMin) yMin = py;
        if (py > yMax) yMax = py;
      }
    }

    if (!hasData) {
      _xMin = 0;
      _xMax = 1;
      _yMin = 0;
      _yMax = 1;
      _boundsCalculated = true;
      return;
    }

    _xMin = xMin;
    _xMax = xMax;
    _yMin = yMin;
    _yMax = yMax;

    if (data.xAxis?.min != null) _xMin = data.xAxis!.min!;
    if (data.xAxis?.max != null) _xMax = data.xAxis!.max!;
    if (data.yAxis?.min != null) _yMin = data.yAxis!.min!;
    if (data.yAxis?.max != null) _yMax = data.yAxis!.max!;

    final yRange = _yMax - _yMin;
    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else if (data.yAxis?.min == null && _yMin > 0) {
      _yMin = 0;
    }

    final paddedYRange = _yMax - _yMin;
    _yMax += paddedYRange * 0.05;

    _boundsCalculated = true;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is DateTime) return value.millisecondsSinceEpoch.toDouble();
    return 0;
  }

  Offset _dataToScreen(dynamic x, num y, Rect chartArea) {
    final xValue = _toDouble(x);
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;

    final screenX = xRange == 0
        ? chartArea.center.dx
        : chartArea.left + (xValue - _xMin) / xRange * chartArea.width;

    final screenY = yRange == 0
        ? chartArea.center.dy
        : chartArea.bottom - (y.toDouble() - _yMin) / yRange * chartArea.height;

    return Offset(screenX, screenY);
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.series.isEmpty) return;

    _calculateBounds();

    // Draw areas (bottom to top for proper layering)
    for (var i = data.series.length - 1; i >= 0; i--) {
      final series = data.series[i];
      if (!series.visible || series.isEmpty) continue;

      final color = series.color ?? theme.getSeriesColor(i);
      _drawArea(canvas, chartArea, series, color, i);

      if (series.showLine) {
        _drawLine(canvas, chartArea, series, color);
      }

      _registerHitTargets(chartArea, series, i);
    }

    // Draw markers on top
    for (var i = 0; i < data.series.length; i++) {
      final series = data.series[i];
      if (!series.visible || series.isEmpty || !series.showMarkers) continue;

      final color = series.color ?? theme.getSeriesColor(i);
      _drawMarkers(canvas, chartArea, series, color, i);
    }
  }

  void _drawArea(Canvas canvas, Rect chartArea, AreaSeries series, Color color, int seriesIndex) {
    if (series.data.length < 2) return;

    final points = <Offset>[];
    for (final point in series.data) {
      points.add(_dataToScreen(point.x, point.y, chartArea));
    }

    final path = Path();
    path.moveTo(points.first.dx, chartArea.bottom);
    path.lineTo(points.first.dx, points.first.dy);

    if (series.curved && points.length > 2) {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    } else {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    path.lineTo(points.last.dx, chartArea.bottom);
    path.close();

    final fillOpacity = series.fillOpacity * animationValue;

    if (series.gradient != null) {
      final paint = Paint()
        ..shader = series.gradient!.createShader(chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: fillOpacity),
          color.withValues(alpha: fillOpacity * 0.1),
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
  }

  void _drawLine(Canvas canvas, Rect chartArea, AreaSeries series, Color color) {
    if (series.data.length < 2) return;

    final points = <Offset>[];
    for (final point in series.data) {
      points.add(_dataToScreen(point.x, point.y, chartArea));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    if (series.curved && points.length > 2) {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    } else {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    final strokeColor = series.strokeColor ?? color;
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = series.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawMarkers(Canvas canvas, Rect chartArea, AreaSeries series, Color color, int seriesIndex) {
    for (var i = 0; i < series.data.length; i++) {
      final point = series.data[i];
      final pos = _dataToScreen(point.x, point.y, chartArea);

      final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
          controller.hoveredPoint?.pointIndex == i;

      if (isHovered) continue;

      final isDark = theme.brightness == Brightness.dark;
      final size = series.markerSize * animationValue;

      final markerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(pos, size / 2, markerPaint);
      canvas.drawCircle(pos, size / 2, borderPaint);
    }
  }

  void _registerHitTargets(Rect chartArea, AreaSeries series, int seriesIndex) {
    for (var i = 0; i < series.data.length; i++) {
      final point = series.data[i];
      final pos = _dataToScreen(point.x, point.y, chartArea);

      hitTester.addCircle(
        center: pos,
        radius: math.max(series.markerSize, 12),
        info: DataPointInfo(
          seriesIndex: seriesIndex,
          pointIndex: i,
          position: pos,
          xValue: point.x,
          yValue: point.y,
          seriesName: series.name,
        ),
      );
    }
  }

  @override
  void paintOverlay(Canvas canvas, Size size) {
    super.paintOverlay(canvas, size);

    final chartArea = getChartArea(size);
    final hoveredPoint = controller.hoveredPoint;

    if (hoveredPoint != null) {
      _drawHoverIndicator(canvas, hoveredPoint);
    }
  }

  void _drawHoverIndicator(Canvas canvas, DataPointInfo info) {
    final series = data.series[info.seriesIndex];
    final color = series.color ?? theme.getSeriesColor(info.seriesIndex);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 14, glowPaint);

    final isDark = theme.brightness == Brightness.dark;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF2D2D2D) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 7, borderPaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 5, dotPaint);
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    super.paintAxes(canvas, size);

    final chartArea = getChartArea(size);
    _drawYAxisLabels(canvas, chartArea);
    _drawXAxisLabels(canvas, chartArea);
  }

  void _drawYAxisLabels(Canvas canvas, Rect chartArea) {
    const labelCount = 5;
    final range = _yMax - _yMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _yMin + (range * i / labelCount);
      final y = chartArea.bottom - (chartArea.height * i / labelCount);

      final label = _formatNumber(value);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        chartArea.left - textPainter.width - 12,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect chartArea) {
    if (data.series.isEmpty) return;

    final firstSeries = data.series.first;
    if (firstSeries.isEmpty) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    final labelCount = math.min(6, firstSeries.length);
    final step = (firstSeries.length / labelCount).ceil();

    for (var i = 0; i < firstSeries.length; i += step) {
      final point = firstSeries.data[i];
      final screenPos = _dataToScreen(point.x, 0, chartArea);

      final label = _formatXValue(point.x);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        screenPos.dx - textPainter.width / 2,
        chartArea.bottom + 12,
      );
      textPainter.paint(canvas, offset);
    }
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatXValue(dynamic value) {
    if (value is DateTime) {
      return '${value.month}/${value.day}';
    }
    if (value is num) {
      return _formatNumber(value.toDouble());
    }
    return value.toString();
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices;
}
