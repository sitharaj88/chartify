import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/data/data_point.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';

/// A data point for scatter charts with optional size.
class ScatterDataPoint<X, Y extends num> extends DataPoint<X, Y> {
  const ScatterDataPoint({
    required super.x,
    required super.y,
    super.metadata,
    this.size,
    this.color,
  });

  /// Custom size for this point (uses series default if null).
  final double? size;

  /// Custom color for this point (uses series color if null).
  final Color? color;
}

/// A data series for scatter charts.
class ScatterSeries<X, Y extends num> {
  const ScatterSeries({
    required this.data, this.name,
    this.color,
    this.visible = true,
    this.pointSize = 8.0,
    this.pointShape = ScatterPointShape.circle,
    this.borderColor,
    this.borderWidth = 0,
    this.opacity = 1.0,
  });

  final String? name;
  final List<ScatterDataPoint<X, Y>> data;
  final Color? color;
  final bool visible;
  final double pointSize;
  final ScatterPointShape pointShape;
  final Color? borderColor;
  final double borderWidth;
  final double opacity;

  bool get isEmpty => data.isEmpty;
  int get length => data.length;
}

/// Shape of scatter chart points.
enum ScatterPointShape {
  circle,
  square,
  diamond,
  triangle,
  cross,
}

/// Data configuration for a scatter chart.
class ScatterChartData {
  const ScatterChartData({
    required this.series,
    this.xAxis,
    this.yAxis,
    this.animation,
  });

  final List<ScatterSeries> series;
  final AxisConfig? xAxis;
  final AxisConfig? yAxis;
  final ChartAnimation? animation;
}

/// A scatter chart widget.
///
/// Displays data as points in a 2D coordinate system.
class ScatterChart extends StatefulWidget {
  const ScatterChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onDataPointTap,
    this.onDataPointHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final ScatterChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DataPointInfo info)? onDataPointTap;
  final void Function(DataPointInfo? info)? onDataPointHover;
  final EdgeInsets padding;

  @override
  State<ScatterChart> createState() => _ScatterChartState();
}

class _ScatterChartState extends State<ScatterChart>
    with SingleTickerProviderStateMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;

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
  void didUpdateWidget(ScatterChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
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

  void _handleHover(PointerEvent event) {
    final hitInfo = _hitTester.hitTest(
      event.localPosition,
      radius: widget.interactions.hitTestRadius,
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      widget.onDataPointHover?.call(hitInfo);
    } else {
      _controller.clearHoveredPoint();
      widget.onDataPointHover?.call(null);
    }
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
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onDataPointHover?.call(null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ScatterChartPainter(
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
          formattedValue: 'x: ${_formatValue(info.xValue)}, y: ${_formatValue(info.yValue)}',
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}

class _ScatterChartPainter extends CartesianChartPainter {
  _ScatterChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required super.padding,
  }) : super(repaint: controller) {
    _calculateBounds();
  }

  final ScatterChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;

  double _xMin = 0;
  double _xMax = 1;
  double _yMin = 0;
  double _yMax = 1;
  bool _boundsCalculated = false;

  void _calculateBounds() {
    if (_boundsCalculated) return;

    var xMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMin = double.infinity;
    var yMax = double.negativeInfinity;
    var hasData = false;

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

    // Add padding
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;

    if (xRange == 0) {
      _xMin -= 1;
      _xMax += 1;
    } else {
      _xMin -= xRange * 0.05;
      _xMax += xRange * 0.05;
    }

    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else {
      _yMin -= yRange * 0.05;
      _yMax += yRange * 0.05;
    }

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

    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
        final point = series.data[pointIndex];
        final position = _dataToScreen(point.x, point.y, chartArea);

        final pointSize = (point.size ?? series.pointSize) * animationValue;
        final pointColor = point.color ?? seriesColor;

        final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
            controller.hoveredPoint?.pointIndex == pointIndex;
        final isSelected = controller.isPointSelected(seriesIndex, pointIndex);

        _drawPoint(
          canvas,
          position,
          pointSize,
          series.pointShape,
          pointColor,
          series,
          isHovered,
          isSelected,
        );

        // Register hit target
        hitTester.addCircle(
          center: position,
          radius: math.max(pointSize, 12),
          info: DataPointInfo(
            seriesIndex: seriesIndex,
            pointIndex: pointIndex,
            position: position,
            xValue: point.x,
            yValue: point.y,
            seriesName: series.name,
          ),
        );
      }
    }
  }

  void _drawPoint(
    Canvas canvas,
    Offset center,
    double size,
    ScatterPointShape shape,
    Color color,
    ScatterSeries series,
    bool isHovered,
    bool isSelected,
  ) {
    var fillColor = color.withValues(alpha: series.opacity);
    if (isHovered) {
      fillColor = color;
    }
    if (isSelected) {
      fillColor = color;
      size *= 1.3;
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = series.borderWidth > 0
        ? (Paint()
          ..color = series.borderColor ?? Colors.white
          ..strokeWidth = series.borderWidth
          ..style = PaintingStyle.stroke)
        : null;

    switch (shape) {
      case ScatterPointShape.circle:
        canvas.drawCircle(center, size / 2, fillPaint);
        if (borderPaint != null) {
          canvas.drawCircle(center, size / 2, borderPaint);
        }

      case ScatterPointShape.square:
        final rect = Rect.fromCenter(center: center, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        if (borderPaint != null) {
          canvas.drawRect(rect, borderPaint);
        }

      case ScatterPointShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy)
          ..lineTo(center.dx, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (borderPaint != null) {
          canvas.drawPath(path, borderPaint);
        }

      case ScatterPointShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy + size / 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (borderPaint != null) {
          canvas.drawPath(path, borderPaint);
        }

      case ScatterPointShape.cross:
        final halfSize = size / 2;
        final crossPaint = Paint()
          ..color = fillColor
          ..strokeWidth = size / 4
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
    }

    // Draw hover glow
    if (isHovered) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, size / 2 + 6, glowPaint);
    }
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
    const labelCount = 5;
    final range = _xMax - _xMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _xMin + (range * i / labelCount);
      final x = chartArea.left + (chartArea.width * i / labelCount);

      final label = _formatNumber(value);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
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

  @override
  bool shouldRepaint(covariant _ScatterChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices;
}
