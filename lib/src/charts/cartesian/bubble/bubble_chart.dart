import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'bubble_chart_data.dart';

export 'bubble_chart_data.dart';

/// A bubble chart widget.
///
/// Displays data as circles in a 2D coordinate system where the
/// circle size represents a third dimension.
///
/// Example:
/// ```dart
/// BubbleChart(
///   data: BubbleChartData(
///     series: [
///       BubbleSeries(
///         name: 'Population',
///         data: [
///           BubbleDataPoint(x: 1, y: 100, size: 50),
///           BubbleDataPoint(x: 2, y: 150, size: 30),
///           BubbleDataPoint(x: 3, y: 120, size: 80),
///         ],
///       ),
///     ],
///   ),
/// )
/// ```
class BubbleChart extends StatefulWidget {
  const BubbleChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onDataPointTap,
    this.onDataPointHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final BubbleChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DataPointInfo info)? onDataPointTap;
  final void Function(DataPointInfo? info)? onDataPointHover;
  final EdgeInsets padding;

  @override
  State<BubbleChart> createState() => _BubbleChartState();
}

class _BubbleChartState extends State<BubbleChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
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
  void didUpdateWidget(BubbleChart oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

        _chartArea = Rect.fromLTRB(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.right,
          constraints.maxHeight - responsivePadding.bottom,
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
                radius: hitRadius,
              );
              if (hitInfo != null && widget.onDataPointTap != null) {
                widget.onDataPointTap!(hitInfo);
              }
            },
            onHover: (event) {
              final hitInfo = _hitTester.hitTest(
                event.localPosition,
                radius: hitRadius,
              );
              if (hitInfo != null) {
                _controller.setHoveredPoint(hitInfo);
                widget.onDataPointHover?.call(hitInfo);
              } else {
                _controller.clearHoveredPoint();
                widget.onDataPointHover?.call(null);
              }
            },
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onDataPointHover?.call(null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BubbleChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: responsivePadding,
                  labelFontSize: labelFontSize,
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
    final point = series.data[info.pointIndex];

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: point.color ?? series.color ?? theme.getSeriesColor(info.seriesIndex),
          label: series.name ?? 'Series ${info.seriesIndex + 1}',
          value: info.yValue,
          formattedValue: 'x: ${_formatValue(info.xValue)}, y: ${_formatValue(info.yValue)}, size: ${_formatValue(point.size)}',
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

class _BubbleChartPainter extends CartesianChartPainter {
  _BubbleChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required super.padding,
    this.labelFontSize = 11.0,
  }) : super(repaint: controller, gridDashPattern: theme.gridDashPattern) {
    _calculateBounds();
  }

  final BubbleChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final double labelFontSize;

  double _xMin = 0;
  double _xMax = 1;
  double _yMin = 0;
  double _yMax = 1;
  double _sizeMin = 0;
  double _sizeMax = 1;
  bool _boundsCalculated = false;

  void _calculateBounds() {
    if (_boundsCalculated) return;

    var xMin = double.infinity;
    var xMax = double.negativeInfinity;
    var yMin = double.infinity;
    var yMax = double.negativeInfinity;
    var sizeMin = double.infinity;
    var sizeMax = double.negativeInfinity;
    var hasData = false;

    for (final series in data.series) {
      if (!series.visible) continue;
      for (final point in series.data) {
        hasData = true;
        final px = _toDouble(point.x);
        final py = point.y.toDouble();
        final ps = point.size;

        if (px < xMin) xMin = px;
        if (px > xMax) xMax = px;
        if (py < yMin) yMin = py;
        if (py > yMax) yMax = py;
        if (ps < sizeMin) sizeMin = ps;
        if (ps > sizeMax) sizeMax = ps;
      }
    }

    if (!hasData) {
      _xMin = 0;
      _xMax = 1;
      _yMin = 0;
      _yMax = 1;
      _sizeMin = 0;
      _sizeMax = 1;
      _boundsCalculated = true;
      return;
    }

    _xMin = xMin;
    _xMax = xMax;
    _yMin = yMin;
    _yMax = yMax;
    _sizeMin = sizeMin;
    _sizeMax = sizeMax;

    // Apply axis config
    if (data.xAxis?.min != null) _xMin = data.xAxis!.min!;
    if (data.xAxis?.max != null) _xMax = data.xAxis!.max!;
    if (data.yAxis?.min != null) _yMin = data.yAxis!.min!;
    if (data.yAxis?.max != null) _yMax = data.yAxis!.max!;

    // Add padding to accommodate bubble sizes
    final xRange = _xMax - _xMin;
    final yRange = _yMax - _yMin;

    if (xRange == 0) {
      _xMin -= 1;
      _xMax += 1;
    } else {
      _xMin -= xRange * 0.1;
      _xMax += xRange * 0.1;
    }

    if (yRange == 0) {
      _yMin -= 1;
      _yMax += 1;
    } else {
      _yMin -= yRange * 0.1;
      _yMax += yRange * 0.1;
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

    // Collect all bubbles to sort by size (draw largest first)
    final bubbles = <_BubbleInfo>[];

    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (!series.visible || series.isEmpty) continue;

      final seriesColor = series.color ?? theme.getSeriesColor(seriesIndex);

      for (var pointIndex = 0; pointIndex < series.data.length; pointIndex++) {
        final point = series.data[pointIndex];
        final position = _dataToScreen(point.x, point.y, chartArea);

        final bubbleSize = data.sizeConfig.calculateSize(
          point.size,
          _sizeMin,
          _sizeMax,
        );

        bubbles.add(_BubbleInfo(
          position: position,
          size: bubbleSize,
          color: point.color ?? seriesColor,
          borderColor: series.borderColor,
          borderWidth: series.borderWidth,
          opacity: series.opacity,
          seriesIndex: seriesIndex,
          pointIndex: pointIndex,
          point: point,
          series: series,
        ),);
      }
    }

    // Sort by size descending (draw largest first, so smaller ones are on top)
    bubbles.sort((a, b) => b.size.compareTo(a.size));

    // Draw all bubbles
    for (final bubble in bubbles) {
      final isHovered = controller.hoveredPoint?.seriesIndex == bubble.seriesIndex &&
          controller.hoveredPoint?.pointIndex == bubble.pointIndex;
      final isSelected = controller.isPointSelected(bubble.seriesIndex, bubble.pointIndex);

      _drawBubble(canvas, bubble, isHovered, isSelected);

      // Register hit target
      hitTester.addCircle(
        center: bubble.position,
        radius: math.max(bubble.size / 2, 12),
        info: DataPointInfo(
          seriesIndex: bubble.seriesIndex,
          pointIndex: bubble.pointIndex,
          position: bubble.position,
          xValue: bubble.point.x,
          yValue: bubble.point.y,
          seriesName: bubble.series.name,
        ),
      );
    }
  }

  void _drawBubble(
    Canvas canvas,
    _BubbleInfo bubble,
    bool isHovered,
    bool isSelected,
  ) {
    final radius = (bubble.size / 2) * animationValue;
    if (radius <= 0) return;

    var fillColor = bubble.color.withValues(alpha: bubble.opacity);
    if (isHovered) {
      fillColor = bubble.color.withValues(alpha: math.min(1, bubble.opacity + 0.2));
    }
    if (isSelected) {
      fillColor = bubble.color;
    }

    // Draw shadow for hovered/selected
    if (isHovered || isSelected) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: theme.shadowOpacity * 1.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius)
        ..isAntiAlias = true;
      canvas.drawCircle(
        Offset(bubble.position.dx + 2, bubble.position.dy + 2),
        radius,
        shadowPaint,
      );
    }

    // Draw fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(bubble.position, radius, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = bubble.borderColor
      ..strokeWidth = bubble.borderWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawCircle(bubble.position, radius, borderPaint);

    // Draw label if enabled
    if (data.showLabels && bubble.point.label != null) {
      _drawLabel(canvas, bubble, radius);
    }

    // Draw hover ring
    if (isHovered) {
      final hoverPaint = Paint()
        ..color = bubble.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(bubble.position, radius + 4, hoverPaint);
    }
  }

  void _drawLabel(Canvas canvas, _BubbleInfo bubble, double radius) {
    final label = bubble.point.label!;
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: data.labelPosition == BubbleLabelPosition.inside
          ? Colors.white
          : theme.labelStyle.color,
    );

    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    Offset labelOffset;
    switch (data.labelPosition) {
      case BubbleLabelPosition.inside:
        labelOffset = Offset(
          bubble.position.dx - textPainter.width / 2,
          bubble.position.dy - textPainter.height / 2,
        );
      case BubbleLabelPosition.above:
        labelOffset = Offset(
          bubble.position.dx - textPainter.width / 2,
          bubble.position.dy - radius - textPainter.height - 4,
        );
      case BubbleLabelPosition.below:
        labelOffset = Offset(
          bubble.position.dx - textPainter.width / 2,
          bubble.position.dy + radius + 4,
        );
    }

    textPainter.paint(canvas, labelOffset);
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
      fontSize: labelFontSize,
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
      fontSize: labelFontSize,
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
  bool shouldRepaint(covariant _BubbleChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices;
}

/// Internal class to hold bubble rendering info.
class _BubbleInfo {
  _BubbleInfo({
    required this.position,
    required this.size,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.opacity,
    required this.seriesIndex,
    required this.pointIndex,
    required this.point,
    required this.series,
  });

  final Offset position;
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double opacity;
  final int seriesIndex;
  final int pointIndex;
  final BubbleDataPoint<dynamic, num> point;
  final BubbleSeries<dynamic, num> series;
}
