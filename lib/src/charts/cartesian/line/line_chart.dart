import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../core/gestures/spatial_index.dart';
import '../../../core/math/geometry/bounds_calculator.dart';
import '../../../core/math/geometry/coordinate_transform.dart';
import '../../../core/math/scales/scale.dart';
import '../../../rendering/renderers/axis_renderer.dart';
import '../../../rendering/renderers/grid_renderer.dart';
import '../../../rendering/renderers/renderer.dart';
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
    required this.data, super.key,
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

  // Spatial index for O(log n) hit testing
  QuadTree<DataPointInfo>? _spatialIndex;

  // Cached bounds
  Bounds? _xBounds;
  Bounds? _yBounds;

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
  void didUpdateWidget(LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      _xBounds = null;
      _yBounds = null;
      _spatialIndex = null;
      if (_animationConfig.enabled && _animationConfig.animateOnDataChange) {
        _animationController?.forward(from: 0);
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
    if (_xBounds != null && _yBounds != null) return;

    final points = <({double x, double y})>[];
    for (final series in widget.data.series) {
      if (!series.visible) continue;
      for (final point in series.data) {
        points.add((x: _toDouble(point.x), y: point.y.toDouble()));
      }
    }

    if (points.isEmpty) {
      _xBounds = const Bounds(min: 0, max: 1);
      _yBounds = const Bounds(min: 0, max: 1);
      return;
    }

    final (xBounds, yBounds) = BoundsCalculator.calculateFromPoints(points);

    // Apply axis config overrides
    _xBounds = xBounds.withOverrides(
      minOverride: widget.data.xAxis?.min,
      maxOverride: widget.data.xAxis?.max,
    );

    var effectiveYBounds = yBounds;
    // Include zero if min > 0
    if (widget.data.yAxis?.min == null && effectiveYBounds.min > 0) {
      effectiveYBounds = Bounds(min: 0, max: effectiveYBounds.max);
    }
    effectiveYBounds = effectiveYBounds.withOverrides(
      minOverride: widget.data.yAxis?.min,
      maxOverride: widget.data.yAxis?.max,
    );
    // Add 5% padding to top
    _yBounds = Bounds(
      min: effectiveYBounds.min,
      max: effectiveYBounds.max + (effectiveYBounds.max - effectiveYBounds.min) * 0.05,
    );
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
    final xRange = _xBounds!.max - _xBounds!.min;
    final yRange = _yBounds!.max - _yBounds!.min;

    final screenX = xRange == 0
        ? _chartArea.center.dx
        : _chartArea.left + (xValue - _xBounds!.min) / xRange * _chartArea.width;

    final screenY = yRange == 0
        ? _chartArea.center.dy
        : _chartArea.bottom - (y.toDouble() - _yBounds!.min) / yRange * _chartArea.height;

    return Offset(screenX, screenY);
  }

  void _buildSpatialIndex() {
    if (_spatialIndex != null) return;
    _spatialIndex = QuadTree<DataPointInfo>(bounds: _chartArea);

    for (var seriesIndex = 0; seriesIndex < widget.data.series.length; seriesIndex++) {
      final series = widget.data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
        final point = series.data[pointIndex];
        final screenPos = _dataToScreen(point.x, point.y);

        final info = DataPointInfo(
          seriesIndex: seriesIndex,
          pointIndex: pointIndex,
          position: screenPos,
          xValue: point.x,
          yValue: point.y,
          seriesName: series.name,
        );

        _spatialIndex!.insert(
          info,
          Rect.fromCenter(center: screenPos, width: 30, height: 30),
        );
      }
    }
  }

  void _handleHover(PointerEvent event) {
    _buildSpatialIndex();
    final nearestInfo = _spatialIndex?.findNearest(event.localPosition, maxDistance: 50);

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

        // Reset spatial index when layout changes
        _spatialIndex = null;

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
                _buildSpatialIndex();
                final hitInfo = _spatialIndex?.findNearest(
                  details.localPosition,
                  maxDistance: widget.interactions.hitTestRadius,
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
                  xBounds: _xBounds,
                  yBounds: _yBounds,
                  onBoundsCalculated: (x, y) {
                    _xBounds = x;
                    _yBounds = y;
                  },
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

    entries.add(TooltipEntry(
      color: widget.data.series[info.seriesIndex].color ??
          theme.getSeriesColor(info.seriesIndex),
      label: info.seriesName ?? 'Series ${info.seriesIndex + 1}',
      value: info.yValue,
    ),);

    for (var i = 0; i < widget.data.series.length; i++) {
      if (i == info.seriesIndex) continue;
      final series = widget.data.series[i];
      if (!series.visible || series.isEmpty) continue;

      for (final point in series.data) {
        if (_toDouble(point.x) == _toDouble(info.xValue)) {
          entries.add(TooltipEntry(
            color: series.color ?? theme.getSeriesColor(i),
            label: series.name ?? 'Series ${i + 1}',
            value: point.y,
          ),);
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

/// Painter for line charts using the new rendering infrastructure.
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.theme,
    required this.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    this.showCrosshair = true,
    this.crosshairColor,
    this.xBounds,
    this.yBounds,
    this.onBoundsCalculated,
  }) : super(repaint: controller);

  final LineChartData data;
  final ChartThemeData theme;
  final double animationValue;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final bool showCrosshair;
  final Color? crosshairColor;
  Bounds? xBounds;
  Bounds? yBounds;
  final void Function(Bounds x, Bounds y)? onBoundsCalculated;

  // Renderers (lazily initialized)
  AxisRenderer<double>? _yAxisRenderer;
  GridRenderer<double, double>? _gridRenderer;

  late Rect _chartArea;
  late LinearScale _xScale;
  late LinearScale _yScale;
  late CoordinateTransform _transform;

  @override
  void paint(Canvas canvas, Size size) {
    hitTester.clear();

    _chartArea = Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );

    if (data.series.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Calculate bounds
    _calculateBounds();

    // Create scales
    _xScale = LinearScale(
      domain: (xBounds!.min, xBounds!.max),
      range: (_chartArea.left, _chartArea.right),
    );

    _yScale = LinearScale(
      domain: (yBounds!.min, yBounds!.max),
      range: (_chartArea.bottom, _chartArea.top),
    );

    // Create transform
    _transform = CoordinateTransform(
      chartArea: _chartArea,
      xBounds: xBounds!,
      yBounds: yBounds!,
    );

    // Draw layers
    _drawGrid(canvas, size);
    _drawSeries(canvas);
    _drawAxes(canvas, size);
    _drawOverlay(canvas);
  }

  void _calculateBounds() {
    if (xBounds != null && yBounds != null) return;

    final points = <({double x, double y})>[];
    for (final series in data.series) {
      if (!series.visible) continue;
      for (final point in series.data) {
        points.add((x: _toDouble(point.x), y: point.y.toDouble()));
      }
    }

    if (points.isEmpty) {
      xBounds = const Bounds(min: 0, max: 1);
      yBounds = const Bounds(min: 0, max: 1);
      return;
    }

    final (calculatedXBounds, calculatedYBounds) =
        BoundsCalculator.calculateFromPoints(points);

    xBounds = calculatedXBounds.withOverrides(
      minOverride: data.xAxis?.min,
      maxOverride: data.xAxis?.max,
    );

    var effectiveYBounds = calculatedYBounds;
    if (data.yAxis?.min == null && effectiveYBounds.min > 0) {
      effectiveYBounds = Bounds(min: 0, max: effectiveYBounds.max);
    }
    effectiveYBounds = effectiveYBounds.withOverrides(
      minOverride: data.yAxis?.min,
      maxOverride: data.yAxis?.max,
    );
    yBounds = Bounds(
      min: effectiveYBounds.min,
      max: effectiveYBounds.max + (effectiveYBounds.max - effectiveYBounds.min) * 0.05,
    );

    onBoundsCalculated?.call(xBounds!, yBounds!);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is DateTime) return value.millisecondsSinceEpoch.toDouble();
    return 0;
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padding.left, size.height - padding.bottom),
      Offset(size.width - padding.right, size.height - padding.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(padding.left, padding.top),
      Offset(padding.left, size.height - padding.bottom),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    _gridRenderer ??= GridRenderer<double, double>(
      config: GridConfig(
        lineColor: theme.gridLineColor,
        lineWidth: theme.gridLineWidth,
      ),
      xScale: _xScale,
      yScale: _yScale,
    );

    _gridRenderer!.render(canvas, size, _chartArea);
  }

  void _drawAxes(Canvas canvas, Size size) {
    // Y-axis labels
    _yAxisRenderer ??= AxisRenderer<double>(
      config: AxisConfig(
        position: ChartPosition.left,
        labelStyle: theme.labelStyle.copyWith(
          fontSize: 11,
          color: theme.labelStyle.color?.withAlpha(180),
        ),
        lineColor: theme.axisLineColor,
        tickColor: theme.axisLineColor.withAlpha(128),
      ),
      scale: _yScale,
    );

    final yTicks = _yScale.ticks(count: 5);
    for (final tick in yTicks) {
      final y = _yScale.scale(tick);
      final label = data.yAxis?.labelFormatter?.call(tick) ?? _formatNumber(tick);

      final textSpan = TextSpan(
        text: label,
        style: theme.labelStyle.copyWith(
          fontSize: 11,
          color: theme.labelStyle.color?.withAlpha(180),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        _chartArea.left - textPainter.width - 12,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);

      // Tick mark
      final tickPaint = Paint()
        ..color = theme.axisLineColor.withAlpha(128)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(_chartArea.left - 4, y),
        Offset(_chartArea.left, y),
        tickPaint,
      );
    }

    // X-axis labels
    if (data.series.isEmpty) return;
    final firstSeries = data.series.first;
    if (firstSeries.isEmpty) return;

    final labelCount = math.min(6, firstSeries.length);
    final step = (firstSeries.length / labelCount).ceil();

    for (var i = 0; i < firstSeries.length; i += step) {
      final dataPoint = firstSeries.data[i];
      final x = _xScale.scale(_toDouble(dataPoint.x));

      final label = data.xAxis?.labelFormatter?.call(_toDouble(dataPoint.x)) ??
          _formatXValue(dataPoint.x);

      final textSpan = TextSpan(
        text: label,
        style: theme.labelStyle.copyWith(
          fontSize: 11,
          color: theme.labelStyle.color?.withAlpha(180),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
        _chartArea.bottom + 12,
      );
      textPainter.paint(canvas, offset);

      // Tick mark
      final tickPaint = Paint()
        ..color = theme.axisLineColor.withAlpha(128)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, _chartArea.bottom),
        Offset(x, _chartArea.bottom + 4),
        tickPaint,
      );
    }

    // Axis lines
    final axisPaint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = theme.axisLineWidth;

    canvas.drawLine(
      Offset(_chartArea.left, _chartArea.bottom),
      Offset(_chartArea.right, _chartArea.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(_chartArea.left, _chartArea.top),
      Offset(_chartArea.left, _chartArea.bottom),
      axisPaint,
    );
  }

  void _drawSeries(Canvas canvas) {
    // Draw each series
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      // Convert data to screen coordinates
      final positions = <Offset>[];
      for (final point in series.data) {
        positions.add(_transform.dataToScreen(_toDouble(point.x), point.y.toDouble()));
      }

      // Draw area fill first
      if (series.fillArea && positions.length >= 2) {
        _drawAreaFill(canvas, positions, series, seriesColor);
      }

      // Draw the line
      if (positions.length >= 2) {
        _drawLine(canvas, positions, series, seriesColor);
      }

      // Register hit targets
      _registerHitTargets(positions, series, seriesIndex);
    }

    // Draw markers on top
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty || !series.showMarkers) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);
      final positions = <Offset>[];
      for (final point in series.data) {
        positions.add(_transform.dataToScreen(_toDouble(point.x), point.y.toDouble()));
      }

      _drawMarkers(canvas, positions, series, seriesColor, seriesIndex);
    }
  }

  void _drawLine(
    Canvas canvas,
    List<Offset> positions,
    LineSeries<dynamic, num> series,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = series.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = series.strokeCap
      ..strokeJoin = series.strokeJoin;

    final path = _createLinePath(positions, series);

    if (animationValue < 1.0) {
      final animatedPath = _animatePath(path, animationValue);
      if (series.dashPattern != null) {
        _drawDashedPath(canvas, animatedPath, paint, series.dashPattern!);
      } else {
        canvas.drawPath(animatedPath, paint);
      }
    } else {
      if (series.dashPattern != null) {
        _drawDashedPath(canvas, path, paint, series.dashPattern!);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _createLinePath(List<Offset> positions, LineSeries<dynamic, num> series) {
    final path = Path();
    if (positions.isEmpty) return path;

    path.moveTo(positions.first.dx, positions.first.dy);

    if (!series.curved || positions.length < 3) {
      for (var i = 1; i < positions.length; i++) {
        path.lineTo(positions[i].dx, positions[i].dy);
      }
      return path;
    }

    // Monotone cubic interpolation
    for (var i = 0; i < positions.length - 1; i++) {
      final p0 = i > 0 ? positions[i - 1] : positions[i];
      final p1 = positions[i];
      final p2 = positions[i + 1];
      final p3 = i < positions.length - 2 ? positions[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
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
        animatedPath.addPath(metric.extractPath(0, metric.length), Offset.zero);
        accumulatedLength += metric.length;
      } else {
        final remainingLength = targetLength - accumulatedLength;
        if (remainingLength > 0) {
          animatedPath.addPath(metric.extractPath(0, remainingLength), Offset.zero);
        }
        break;
      }
    }

    return animatedPath;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dashPattern) {
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
            math.min(nextDistance, metric.length),
          );
          canvas.drawPath(extractPath, paint);
        }

        distance = nextDistance;
        drawDash = !drawDash;
        dashIndex++;
      }
    }
  }

  void _drawAreaFill(
    Canvas canvas,
    List<Offset> positions,
    LineSeries<dynamic, num> series,
    Color color,
  ) {
    final areaPath = Path();
    areaPath.moveTo(positions.first.dx, _chartArea.bottom);
    areaPath.lineTo(positions.first.dx, positions.first.dy);

    if (series.curved && positions.length >= 3) {
      for (var i = 0; i < positions.length - 1; i++) {
        final p0 = i > 0 ? positions[i - 1] : positions[i];
        final p1 = positions[i];
        final p2 = positions[i + 1];
        final p3 = i < positions.length - 2 ? positions[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        areaPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    } else {
      for (var i = 1; i < positions.length; i++) {
        areaPath.lineTo(positions[i].dx, positions[i].dy);
      }
    }

    areaPath.lineTo(positions.last.dx, _chartArea.bottom);
    areaPath.close();

    final animatedOpacity = series.areaOpacity * animationValue;

    if (series.areaGradient != null) {
      final gradientPaint = Paint()
        ..shader = series.areaGradient!.createShader(_chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, gradientPaint);
    } else {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha((animatedOpacity * 255).round()),
          color.withAlpha((animatedOpacity * 0.1 * 255).round()),
        ],
      );
      final areaPaint = Paint()
        ..shader = gradient.createShader(_chartArea)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);
    }
  }

  void _registerHitTargets(
    List<Offset> positions,
    LineSeries<dynamic, num> series,
    int seriesIndex,
  ) {
    for (var pointIndex = 0; pointIndex < positions.length; pointIndex++) {
      final position = positions[pointIndex];
      final dataPoint = series.data[pointIndex];

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

  void _drawMarkers(
    Canvas canvas,
    List<Offset> positions,
    LineSeries<dynamic, num> series,
    Color color,
    int seriesIndex,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    for (var pointIndex = 0; pointIndex < positions.length; pointIndex++) {
      final position = positions[pointIndex];

      final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
          controller.hoveredPoint?.pointIndex == pointIndex;

      if (isHovered) continue;

      final isSelected = controller.isPointSelected(seriesIndex, pointIndex);
      final size = isSelected ? series.markerSize * 1.5 : series.markerSize;
      final animatedSize = size * animationValue;

      final markerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      _drawMarkerShape(canvas, position, animatedSize, series.markerShape, markerPaint, borderPaint);
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

  Path _createStarPath(Offset center, double outerRadius, double innerRadius, int points) {
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

  void _drawOverlay(Canvas canvas) {
    final hoveredPoint = controller.hoveredPoint;

    if (hoveredPoint != null) {
      // Find all points at the same x-coordinate across all series
      final allPointsAtX = _findAllPointsAtX(hoveredPoint.xValue);

      if (showCrosshair) {
        _drawCrosshair(canvas, hoveredPoint, allPointsAtX);
      }

      // Draw hover indicators for ALL series at this x-position
      for (final pointInfo in allPointsAtX) {
        _drawHoverIndicator(canvas, pointInfo);
      }
    }
  }

  /// Find all data points across all series at the given x-value.
  List<DataPointInfo> _findAllPointsAtX(dynamic xValue) {
    final result = <DataPointInfo>[];
    final targetX = _toDouble(xValue);

    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
        final point = series.data[pointIndex];
        if (_toDouble(point.x) == targetX) {
          final screenPos = _transform.dataToScreen(targetX, point.y.toDouble());
          result.add(DataPointInfo(
            seriesIndex: seriesIndex,
            pointIndex: pointIndex,
            position: screenPos,
            xValue: point.x,
            yValue: point.y,
            seriesName: series.name,
          ),);
          break;
        }
      }
    }

    return result;
  }

  void _drawCrosshair(Canvas canvas, DataPointInfo info, List<DataPointInfo> allPoints) {
    final isDark = theme.brightness == Brightness.dark;
    final color = crosshairColor ??
        (isDark
            ? Colors.white.withAlpha(77)
            : Colors.black.withAlpha(38));

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical line through all points at this x-position
    _drawDashedLine(
      canvas,
      Offset(info.position.dx, _chartArea.top),
      Offset(info.position.dx, _chartArea.bottom),
      paint,
      [4, 4],
    );

    // Draw connecting line between points if multiple series
    if (allPoints.length > 1) {
      // Sort points by Y position
      final sortedPoints = List<DataPointInfo>.from(allPoints)
        ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

      // Draw solid vertical line connecting all the points
      final connectPaint = Paint()
        ..color = color.withAlpha(isDark ? 100 : 60)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(info.position.dx, sortedPoints.first.position.dy),
        Offset(info.position.dx, sortedPoints.last.position.dy),
        connectPaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, List<double> pattern) {
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
      ..color = seriesColor.withAlpha(77)
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
      data != oldDelegate.data ||
      animationValue != oldDelegate.animationValue ||
      controller.viewport != oldDelegate.controller.viewport ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
