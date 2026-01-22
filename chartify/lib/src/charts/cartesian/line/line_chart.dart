import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'line_chart_data.dart';
import 'line_series.dart';

/// A line chart widget.
///
/// Displays data as a series of points connected by lines.
/// Supports multiple series, curved lines, area fills, markers,
/// tooltips, crosshairs, and interactive features.
///
/// Example:
/// ```dart
/// LineChart(
///   data: LineChartData(
///     series: [
///       LineSeries(
///         name: 'Revenue',
///         data: [
///           DataPoint(x: 0, y: 10),
///           DataPoint(x: 1, y: 25),
///           DataPoint(x: 2, y: 15),
///           DataPoint(x: 3, y: 30),
///         ],
///         color: Colors.blue,
///         curved: true,
///         fillArea: true,
///       ),
///     ],
///   ),
///   tooltip: TooltipConfig(enabled: true),
///   showCrosshair: true,
/// )
/// ```
class LineChart extends StatefulWidget {
  /// Creates a line chart.
  const LineChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.showCrosshair = true,
    this.crosshairColor,
    this.onDataPointTap,
    this.onDataPointHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  /// The chart data.
  final LineChartData data;

  /// Optional controller for managing chart state.
  final ChartController? controller;

  /// Animation configuration (overrides data.animation).
  final ChartAnimation? animation;

  /// Interaction configuration.
  final ChartInteractions interactions;

  /// Tooltip configuration.
  final TooltipConfig tooltip;

  /// Whether to show crosshair on hover.
  final bool showCrosshair;

  /// Custom crosshair color (uses theme color if null).
  final Color? crosshairColor;

  /// Called when a data point is tapped.
  final void Function(DataPointInfo info)? onDataPointTap;

  /// Called when a data point is hovered.
  final void Function(DataPointInfo? info)? onDataPointHover;

  /// Padding around the chart area.
  final EdgeInsets padding;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;

  // Cached bounds for consistent position calculations
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
    // Note: Don't add listener here - painter handles repaint via shouldRepaint
    // and tooltip overlay has its own listener
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
  void didUpdateWidget(LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    // Handle data changes - invalidate cached bounds
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

  void _handleHover(PointerEvent event) {
    // Find nearest point on X axis for smooth tracking
    // Don't call setState - the tooltip overlay handles its own state
    final nearestInfo = _findNearestPointOnX(event.localPosition);
    if (nearestInfo != null) {
      _controller.setHoveredPoint(nearestInfo);
      widget.onDataPointHover?.call(nearestInfo);
    } else {
      _controller.clearHoveredPoint();
      widget.onDataPointHover?.call(null);
    }
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

  void _calculateBounds() {
    if (_boundsValid) return;

    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    bool hasData = false;

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

    // Apply axis config overrides
    if (widget.data.xAxis?.min != null) _xMin = widget.data.xAxis!.min!;
    if (widget.data.xAxis?.max != null) _xMax = widget.data.xAxis!.max!;
    if (widget.data.yAxis?.min != null) _yMin = widget.data.yAxis!.min!;
    if (widget.data.yAxis?.max != null) _yMax = widget.data.yAxis!.max!;

    // Add padding to y-axis (must match painter!)
    final yRange = _yMax - _yMin;
    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else if (widget.data.yAxis?.min == null && _yMin > 0) {
      _yMin = 0;
    }

    // Add 5% padding to top of y-axis (must match painter!)
    final paddedYRange = _yMax - _yMin;
    _yMax += paddedYRange * 0.05;

    _boundsValid = true;
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is DateTime) return value.millisecondsSinceEpoch.toDouble();
    return 0;
  }

  void _handleHoverExit(PointerExitEvent event) {
    // Don't call setState - the tooltip overlay handles its own state
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
              if (widget.onDataPointTap != null) {
                final hitInfo = _hitTester.hitTest(
                  details.localPosition,
                  radius: widget.interactions.hitTestRadius,
                );
                if (hitInfo != null) {
                  widget.onDataPointTap!(hitInfo);
                }
              }
            },
            onHover: _handleHover,
            onExit: _handleHoverExit,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LineChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: widget.padding,
                  showCrosshair: widget.showCrosshair,
                  crosshairColor: widget.crosshairColor,
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
    final entries = <TooltipEntry>[];

    // Add entry for the hovered series
    entries.add(TooltipEntry(
      color: widget.data.series[info.seriesIndex].color ??
          theme.getSeriesColor(info.seriesIndex),
      label: info.seriesName ?? 'Series ${info.seriesIndex + 1}',
      value: info.yValue,
    ));

    // Optionally add entries for other series at the same x value
    for (var i = 0; i < widget.data.series.length; i++) {
      if (i == info.seriesIndex) continue;
      final series = widget.data.series[i];
      if (!series.visible || series.isEmpty) continue;

      // Find matching point
      for (final point in series.data) {
        if (_toDouble(point.x) == _toDouble(info.xValue)) {
          entries.add(TooltipEntry(
            color: series.color ?? theme.getSeriesColor(i),
            label: series.name ?? 'Series ${i + 1}',
            value: point.y,
          ));
          break;
        }
      }
    }

    return TooltipData(
      position: info.position,
      entries: entries,
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

class _LineChartPainter extends CartesianChartPainter {
  _LineChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required EdgeInsets padding,
    this.showCrosshair = true,
    this.crosshairColor,
  }) : super(padding: padding, repaint: controller) {
    _calculateBounds();
  }

  final LineChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final bool showCrosshair;
  final Color? crosshairColor;

  // Cached calculations
  double _xMin = 0;
  double _xMax = 1;
  double _yMin = 0;
  double _yMax = 1;
  bool _boundsCalculated = false;

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.series.isEmpty) return;

    _calculateBounds();

    // Draw each series
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      // Draw area fill first (behind the line)
      if (series.fillArea) {
        _drawAreaFill(canvas, chartArea, series, seriesColor);
      }

      // Draw the line
      _drawLine(canvas, chartArea, series, seriesColor);

      // Register hit targets for all points
      _registerHitTargets(chartArea, series, seriesIndex);
    }

    // Draw markers after all lines (so they appear on top)
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      if (series.showMarkers) {
        _drawMarkers(canvas, chartArea, series, seriesColor, seriesIndex);
      }
    }
  }

  void _registerHitTargets(
    Rect chartArea,
    LineSeries<dynamic, num> series,
    int seriesIndex,
  ) {
    for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
      final dataPoint = series.data[pointIndex];
      final position = _dataToScreen(dataPoint.x, dataPoint.y, chartArea);

      hitTester.addCircle(
        center: position,
        radius: math.max(series.markerSize, 12),
        info: DataPointInfo(
          seriesIndex: seriesIndex,
          pointIndex: pointIndex,
          position: position,
          xValue: dataPoint.x,
          yValue: dataPoint.y,
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

    // Draw crosshair
    if (showCrosshair && hoveredPoint != null) {
      _drawCrosshair(canvas, chartArea, hoveredPoint);
    }

    // Draw hover indicator on hovered point
    if (hoveredPoint != null) {
      _drawHoverIndicator(canvas, hoveredPoint);
    }
  }

  void _drawCrosshair(Canvas canvas, Rect chartArea, DataPointInfo info) {
    final isDark = theme.brightness == Brightness.dark;
    final color = crosshairColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.15));

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical line
    _drawDashedLine(
      canvas,
      Offset(info.position.dx, chartArea.top),
      Offset(info.position.dx, chartArea.bottom),
      paint,
      [4, 4],
    );

    // Draw horizontal line
    _drawDashedLine(
      canvas,
      Offset(chartArea.left, info.position.dy),
      Offset(chartArea.right, info.position.dy),
      paint,
      [4, 4],
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> pattern,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    var drawn = 0.0;
    var drawDash = true;
    var patternIndex = 0;

    while (drawn < distance) {
      final dashLength = pattern[patternIndex % pattern.length];
      final nextDrawn = math.min(drawn + dashLength, distance);

      if (drawDash) {
        canvas.drawLine(
          Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
          Offset(start.dx + unitX * nextDrawn, start.dy + unitY * nextDrawn),
          paint,
        );
      }

      drawn = nextDrawn;
      drawDash = !drawDash;
      patternIndex++;
    }
  }

  void _drawHoverIndicator(Canvas canvas, DataPointInfo info) {
    final seriesColor = data.series[info.seriesIndex].color ??
        theme.getSeriesColor(info.seriesIndex);

    // Outer glow
    final glowPaint = Paint()
      ..color = seriesColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 14, glowPaint);

    // White border
    final isDark = theme.brightness == Brightness.dark;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF2D2D2D) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 7, borderPaint);

    // Colored center
    final dotPaint = Paint()
      ..color = seriesColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(info.position, 5, dotPaint);
  }

  void _calculateBounds() {
    if (_boundsCalculated) return;

    bool hasData = false;
    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;

    for (final series in data.series) {
      if (!series.visible) continue;

      for (final point in series.data) {
        hasData = true;
        final x = _toDouble(point.x);
        final y = point.y.toDouble();

        if (x < xMin) xMin = x;
        if (x > xMax) xMax = x;
        if (y < yMin) yMin = y;
        if (y > yMax) yMax = y;
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

    // Apply axis config overrides
    if (data.xAxis?.min != null) _xMin = data.xAxis!.min!;
    if (data.xAxis?.max != null) _xMax = data.xAxis!.max!;
    if (data.yAxis?.min != null) _yMin = data.yAxis!.min!;
    if (data.yAxis?.max != null) _yMax = data.yAxis!.max!;

    // Add padding to y-axis
    final yRange = _yMax - _yMin;
    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else if (data.yAxis?.min == null && _yMin > 0) {
      _yMin = 0;
    }

    // Add 10% padding to top of y-axis for visual breathing room
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

  void _drawLine(
    Canvas canvas,
    Rect chartArea,
    LineSeries<dynamic, num> series,
    Color color,
  ) {
    if (series.data.length < 2) return;

    final paint = getPaint(
      color: color,
      strokeWidth: series.strokeWidth,
      strokeCap: series.strokeCap,
      strokeJoin: series.strokeJoin,
    );

    final path = _createLinePath(chartArea, series);

    if (animationValue < 1.0) {
      final animatedPath = _animatePath(path, animationValue);
      if (series.dashPattern != null) {
        final dashedPath = _createDashedPath(animatedPath, series.dashPattern!);
        canvas.drawPath(dashedPath, paint);
      } else {
        canvas.drawPath(animatedPath, paint);
      }
    } else {
      if (series.dashPattern != null) {
        final dashedPath = _createDashedPath(path, series.dashPattern!);
        canvas.drawPath(dashedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _createLinePath(Rect chartArea, LineSeries<dynamic, num> series) {
    final path = Path();
    final points = <Offset>[];

    for (final dataPoint in series.data) {
      points.add(_dataToScreen(dataPoint.x, dataPoint.y, chartArea));
    }

    if (points.isEmpty) return path;

    if (series.curved) {
      return _createCurvedPath(points, series.curveType, series.tension);
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  Path _createCurvedPath(
    List<Offset> points,
    CurveType curveType,
    double tension,
  ) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    if (points.length < 3) {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    switch (curveType) {
      case CurveType.monotone:
        return _createMonotonePath(points);
      case CurveType.bezier:
        return _createBezierPath(points, tension);
      case CurveType.stepBefore:
        return _createStepPath(points, StepType.before);
      case CurveType.stepAfter:
        return _createStepPath(points, StepType.after);
      case CurveType.stepMiddle:
        return _createStepPath(points, StepType.middle);
      case CurveType.catmullRom:
      case CurveType.cardinal:
      case CurveType.natural:
        return _createMonotonePath(points);
    }
  }

  Path _createMonotonePath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

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

    return path;
  }

  Path _createBezierPath(List<Offset> points, double tension) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final midX = (p1.dx + p2.dx) / 2;

      final cp1x = p1.dx + (midX - p1.dx) * tension;
      final cp2x = p2.dx - (p2.dx - midX) * tension;

      path.cubicTo(cp1x, p1.dy, cp2x, p2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  Path _createStepPath(List<Offset> points, StepType type) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];

      switch (type) {
        case StepType.before:
          path.lineTo(p2.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
        case StepType.after:
          path.lineTo(p1.dx, p2.dy);
          path.lineTo(p2.dx, p2.dy);
        case StepType.middle:
          final midX = (p1.dx + p2.dx) / 2;
          path.lineTo(midX, p1.dy);
          path.lineTo(midX, p2.dy);
          path.lineTo(p2.dx, p2.dy);
      }
    }

    return path;
  }

  void _addCurvedSegmentsToPath(
    Path path,
    List<Offset> points,
    CurveType curveType,
    double tension,
  ) {
    if (points.length < 2) return;

    if (points.length < 3) {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return;
    }

    switch (curveType) {
      case CurveType.monotone:
        _addMonotoneSegments(path, points);
      case CurveType.bezier:
        _addBezierSegments(path, points, tension);
      case CurveType.stepBefore:
        _addStepSegments(path, points, StepType.before);
      case CurveType.stepAfter:
        _addStepSegments(path, points, StepType.after);
      case CurveType.stepMiddle:
        _addStepSegments(path, points, StepType.middle);
      case CurveType.catmullRom:
      case CurveType.cardinal:
      case CurveType.natural:
        _addMonotoneSegments(path, points);
    }
  }

  void _addMonotoneSegments(Path path, List<Offset> points) {
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
  }

  void _addBezierSegments(Path path, List<Offset> points, double tension) {
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final midX = (p1.dx + p2.dx) / 2;

      final cp1x = p1.dx + (midX - p1.dx) * tension;
      final cp2x = p2.dx - (p2.dx - midX) * tension;

      path.cubicTo(cp1x, p1.dy, cp2x, p2.dy, p2.dx, p2.dy);
    }
  }

  void _addStepSegments(Path path, List<Offset> points, StepType type) {
    for (var i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];

      switch (type) {
        case StepType.before:
          path.lineTo(p2.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
        case StepType.after:
          path.lineTo(p1.dx, p2.dy);
          path.lineTo(p2.dx, p2.dy);
        case StepType.middle:
          final midX = (p1.dx + p2.dx) / 2;
          path.lineTo(midX, p1.dy);
          path.lineTo(midX, p2.dy);
          path.lineTo(p2.dx, p2.dy);
      }
    }
  }

  Path _animatePath(Path originalPath, double progress) {
    final metrics = originalPath.computeMetrics().toList();
    if (metrics.isEmpty) return Path();

    final animatedPath = Path();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * progress;

    var accumulatedLength = 0.0;
    for (final metric in metrics) {
      if (accumulatedLength + metric.length <= targetLength) {
        animatedPath.addPath(
          metric.extractPath(0, metric.length),
          Offset.zero,
        );
        accumulatedLength += metric.length;
      } else {
        final remainingLength = targetLength - accumulatedLength;
        if (remainingLength > 0) {
          animatedPath.addPath(
            metric.extractPath(0, remainingLength),
            Offset.zero,
          );
        }
        break;
      }
    }

    return animatedPath;
  }

  Path _createDashedPath(Path source, List<double> dashPattern) {
    final result = Path();
    final metrics = source.computeMetrics();

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
            math.min(nextDistance, metric.length),
          );
          result.addPath(extractPath, Offset.zero);
        }

        distance = nextDistance;
        drawDash = !drawDash;
        dashIndex++;
      }
    }

    return result;
  }

  void _drawAreaFill(
    Canvas canvas,
    Rect chartArea,
    LineSeries<dynamic, num> series,
    Color color,
  ) {
    if (series.data.length < 2) return;

    final points = <Offset>[];
    for (final dataPoint in series.data) {
      points.add(_dataToScreen(dataPoint.x, dataPoint.y, chartArea));
    }

    final areaPath = Path();

    // Start from bottom-left, then up to first point
    areaPath.moveTo(points.first.dx, chartArea.bottom);
    areaPath.lineTo(points.first.dx, points.first.dy);

    // Add the line points
    if (series.curved) {
      _addCurvedSegmentsToPath(areaPath, points, series.curveType, series.tension);
    } else {
      for (var i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Close the path back to the bottom
    areaPath.lineTo(points.last.dx, chartArea.bottom);
    areaPath.close();

    // Apply animation
    final animatedOpacity = series.areaOpacity * animationValue;

    if (series.areaGradient != null) {
      final gradientPaint = Paint()
        ..shader = series.areaGradient!.createShader(chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, gradientPaint);
    } else {
      // Create a nice gradient for the area
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: animatedOpacity),
          color.withValues(alpha: animatedOpacity * 0.1),
        ],
      );
      final areaPaint = Paint()
        ..shader = gradient.createShader(chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);
    }
  }

  void _drawMarkers(
    Canvas canvas,
    Rect chartArea,
    LineSeries<dynamic, num> series,
    Color color,
    int seriesIndex,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
      final dataPoint = series.data[pointIndex];
      final position = _dataToScreen(dataPoint.x, dataPoint.y, chartArea);

      final isSelected = controller.isPointSelected(seriesIndex, pointIndex);
      final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
          controller.hoveredPoint?.pointIndex == pointIndex;

      // Skip drawing marker if this point is being hovered (we draw a special indicator)
      if (isHovered) continue;

      final size = isSelected ? series.markerSize * 1.5 : series.markerSize;
      final animatedSize = size * animationValue;

      final markerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      _drawMarkerShape(
        canvas,
        position,
        animatedSize,
        series.markerShape,
        markerPaint,
        borderPaint,
      );
    }
  }

  void _drawMarkerShape(
    Canvas canvas,
    Offset center,
    double size,
    MarkerShape shape,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    switch (shape) {
      case MarkerShape.circle:
        canvas.drawCircle(center, size / 2, fillPaint);
        canvas.drawCircle(center, size / 2, borderPaint);

      case MarkerShape.square:
        final rect = Rect.fromCenter(center: center, width: size, height: size);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);

      case MarkerShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy)
          ..lineTo(center.dx, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);

      case MarkerShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy + size / 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);

      case MarkerShape.triangleDown:
        final path = Path()
          ..moveTo(center.dx, center.dy + size / 2)
          ..lineTo(center.dx + size / 2, center.dy - size / 2)
          ..lineTo(center.dx - size / 2, center.dy - size / 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);

      case MarkerShape.cross:
        final halfSize = size / 2;
        final crossPaint = Paint()
          ..color = fillPaint.color
          ..strokeWidth = size / 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - halfSize, center.dy),
          Offset(center.dx + halfSize, center.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - halfSize),
          Offset(center.dx, center.dy + halfSize),
          crossPaint,
        );

      case MarkerShape.x:
        final halfSize = size / 2 * 0.7;
        final xPaint = Paint()
          ..color = fillPaint.color
          ..strokeWidth = size / 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - halfSize, center.dy - halfSize),
          Offset(center.dx + halfSize, center.dy + halfSize),
          xPaint,
        );
        canvas.drawLine(
          Offset(center.dx + halfSize, center.dy - halfSize),
          Offset(center.dx - halfSize, center.dy + halfSize),
          xPaint,
        );

      case MarkerShape.star:
        final path = _createStarPath(center, size / 2, size / 4, 5);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
    }
  }

  Path _createStarPath(
    Offset center,
    double outerRadius,
    double innerRadius,
    int points,
  ) {
    final path = Path();
    final angleStep = math.pi / points;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    super.paintAxes(canvas, size);

    _calculateBounds();

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

      final label = data.yAxis?.labelFormatter?.call(value) ??
          _formatNumber(value);

      // Create text painter to measure text width
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw right-aligned to the left of the chart area
      final offset = Offset(
        chartArea.left - textPainter.width - 12,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);

      // Draw small tick mark
      final tickPaint = Paint()
        ..color = theme.axisLineColor.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(chartArea.left - 4, y),
        Offset(chartArea.left, y),
        tickPaint,
      );
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
      final dataPoint = firstSeries.data[i];
      final screenPos = _dataToScreen(dataPoint.x, 0, chartArea);

      final label = data.xAxis?.labelFormatter?.call(_toDouble(dataPoint.x)) ??
          _formatXValue(dataPoint.x);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      // Center the label under the data point
      final offset = Offset(
        screenPos.dx - textPainter.width / 2,
        chartArea.bottom + 12,
      );
      textPainter.paint(canvas, offset);

      // Draw small tick mark
      final tickPaint = Paint()
        ..color = theme.axisLineColor.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(screenPos.dx, chartArea.bottom),
        Offset(screenPos.dx, chartArea.bottom + 4),
        tickPaint,
      );
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
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.viewport != oldDelegate.controller.viewport ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}

enum StepType { before, after, middle }
