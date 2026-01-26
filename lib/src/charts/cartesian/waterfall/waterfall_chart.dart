import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'waterfall_chart_data.dart';

export 'waterfall_chart_data.dart';

/// A waterfall chart widget.
///
/// Shows how an initial value is affected by a series of
/// positive or negative values, leading to a final value.
///
/// Example:
/// ```dart
/// WaterfallChart(
///   data: WaterfallChartData(
///     items: [
///       WaterfallItem(label: 'Start', value: 100, type: WaterfallItemType.total),
///       WaterfallItem(label: 'Sales', value: 50),
///       WaterfallItem(label: 'Costs', value: -30),
///       WaterfallItem(label: 'End', value: 120, type: WaterfallItemType.total),
///     ],
///   ),
/// )
/// ```
class WaterfallChart extends StatefulWidget {
  const WaterfallChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.onItemHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final WaterfallChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(WaterfallItem item, int index)? onItemTap;
  final void Function(WaterfallItem? item, int? index)? onItemHover;
  final EdgeInsets padding;

  @override
  State<WaterfallChart> createState() => _WaterfallChartState();
}

class _WaterfallChartState extends State<WaterfallChart>
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
  void didUpdateWidget(WaterfallChart oldWidget) {
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
    final hitInfo = _hitTester.hitTest(
      event.localPosition,
      radius: widget.interactions.hitTestRadius,
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      widget.onItemHover?.call(widget.data.items[hitInfo.pointIndex], hitInfo.pointIndex);
    } else {
      _controller.clearHoveredPoint();
      widget.onItemHover?.call(null, null);
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
              if (hitInfo != null && widget.onItemTap != null) {
                widget.onItemTap!(widget.data.items[hitInfo.pointIndex], hitInfo.pointIndex);
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onItemHover?.call(null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WaterfallChartPainter(
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
    final item = widget.data.items[info.pointIndex];
    final color = widget.data.getItemColor(item);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: item.effectiveType.name,
          value: item.value,
          formattedValue: _formatValue(item.value),
        ),
      ],
      xLabel: item.label,
    );
  }

  String _formatValue(double value) {
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
}

class _WaterfallChartPainter extends CartesianChartPainter {
  _WaterfallChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required EdgeInsets padding,
  }) : super(padding: padding, repaint: controller) {
    _calculateBounds();
  }

  final WaterfallChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;

  double _yMin = 0;
  double _yMax = 1;
  final List<_WaterfallBarInfo> _barInfos = [];

  void _calculateBounds() {
    if (data.items.isEmpty) return;

    _barInfos.clear();

    var runningTotal = data.startValue;
    var minValue = runningTotal;
    var maxValue = runningTotal;

    for (final item in data.items) {
      double barStart;
      double barEnd;

      switch (item.effectiveType) {
        case WaterfallItemType.total:
          barStart = 0;
          barEnd = item.value;
          runningTotal = item.value;
        case WaterfallItemType.subtotal:
          barStart = 0;
          barEnd = runningTotal;
        case WaterfallItemType.increase:
        case WaterfallItemType.decrease:
          barStart = runningTotal;
          barEnd = runningTotal + item.value;
          runningTotal = barEnd;
      }

      _barInfos.add(_WaterfallBarInfo(
        start: barStart,
        end: barEnd,
        runningTotal: runningTotal,
      ));

      minValue = math.min(minValue, math.min(barStart, barEnd));
      maxValue = math.max(maxValue, math.max(barStart, barEnd));
    }

    final range = maxValue - minValue;
    _yMin = minValue - range * 0.1;
    _yMax = maxValue + range * 0.1;

    // Ensure zero is included if values span across it
    if (_yMin > 0) _yMin = 0;
    if (_yMax < 0) _yMax = 0;
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.items.isEmpty || _barInfos.isEmpty) return;

    final itemCount = data.items.length;
    final itemSpace = chartArea.width / itemCount;
    final barWidth = itemSpace * data.barWidth;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final barInfo = _barInfos[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      final x = chartArea.left + itemSpace * i + itemSpace / 2;

      // Draw connector from previous bar
      if (data.showConnectors && i > 0) {
        final prevBarInfo = _barInfos[i - 1];
        _drawConnector(canvas, chartArea, i, itemSpace, barWidth, prevBarInfo, barInfo);
      }

      // Calculate bar rect with animation
      final startY = _valueToY(barInfo.start, chartArea);
      final endY = _valueToY(barInfo.end, chartArea);

      final animatedStartY = chartArea.bottom + (startY - chartArea.bottom) * animationValue;
      final animatedEndY = chartArea.bottom + (endY - chartArea.bottom) * animationValue;

      final barRect = Rect.fromLTRB(
        x - barWidth / 2,
        math.min(animatedStartY, animatedEndY),
        x + barWidth / 2,
        math.max(animatedStartY, animatedEndY),
      );

      // Draw bar
      final color = data.getItemColor(item);
      _drawBar(canvas, barRect, color, isHovered);

      // Draw value label
      if (data.showValues) {
        _drawValueLabel(canvas, barRect, item, barInfo);
      }

      // Register hit target
      hitTester.addRect(
        rect: barRect,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(x, math.min(animatedStartY, animatedEndY)),
          xValue: item.label,
          yValue: item.value,
        ),
      );
    }
  }

  void _drawConnector(
    Canvas canvas,
    Rect chartArea,
    int index,
    double itemSpace,
    double barWidth,
    _WaterfallBarInfo prevBarInfo,
    _WaterfallBarInfo currentBarInfo,
  ) {
    final prevX = chartArea.left + itemSpace * (index - 1) + itemSpace / 2 + barWidth / 2;
    final currentX = chartArea.left + itemSpace * index + itemSpace / 2 - barWidth / 2;

    // Connect from end of previous bar to start of current bar
    final y = _valueToY(prevBarInfo.runningTotal, chartArea);
    final animatedY = chartArea.bottom + (y - chartArea.bottom) * animationValue;

    final connectorColor = data.connectorColor ?? theme.gridLineColor;
    final paint = Paint()
      ..color = connectorColor
      ..strokeWidth = data.connectorWidth
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    _drawDashedLine(
      canvas,
      Offset(prevX, animatedY),
      Offset(currentX, animatedY),
      paint,
      data.connectorDash,
    );
  }

  void _drawBar(Canvas canvas, Rect rect, Color color, bool isHovered) {
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(data.borderRadius),
    );

    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1.0);
    }

    final paint = Paint()
      ..color = fillColor.withValues(alpha: isHovered ? 1.0 : 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, highlightPaint);
    }
  }

  void _drawValueLabel(
    Canvas canvas,
    Rect barRect,
    WaterfallItem item,
    _WaterfallBarInfo barInfo,
  ) {
    final label = _formatValue(item.value);
    final textStyle = theme.labelStyle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    Offset offset;
    switch (data.valuePosition) {
      case WaterfallValuePosition.above:
        offset = Offset(
          barRect.center.dx - textPainter.width / 2,
          barRect.top - textPainter.height - 4,
        );
      case WaterfallValuePosition.inside:
        offset = Offset(
          barRect.center.dx - textPainter.width / 2,
          barRect.center.dy - textPainter.height / 2,
        );
      case WaterfallValuePosition.below:
        offset = Offset(
          barRect.center.dx - textPainter.width / 2,
          barRect.bottom + 4,
        );
    }

    textPainter.paint(canvas, offset);
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    final prefix = value > 0 ? '+' : '';
    if (value == value.roundToDouble()) {
      return '$prefix${value.toInt()}';
    }
    return '$prefix${value.toStringAsFixed(1)}';
  }

  double _valueToY(double value, Rect chartArea) {
    final range = _yMax - _yMin;
    if (range == 0) return chartArea.center.dy;
    return chartArea.bottom - (value - _yMin) / range * chartArea.height;
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
  void paintAxes(Canvas canvas, Size size) {
    super.paintAxes(canvas, size);

    final chartArea = getChartArea(size);
    _drawYAxisLabels(canvas, chartArea);
    _drawXAxisLabels(canvas, chartArea);

    // Draw zero line if applicable
    if (_yMin < 0 && _yMax > 0) {
      _drawZeroLine(canvas, chartArea);
    }
  }

  void _drawZeroLine(Canvas canvas, Rect chartArea) {
    final y = _valueToY(0, chartArea);
    final paint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(chartArea.left, y),
      Offset(chartArea.right, y),
      paint,
    );
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

      final label = _formatAxisValue(value);

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
    if (data.items.isEmpty) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    final itemCount = data.items.length;
    final itemSpace = chartArea.width / itemCount;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final x = chartArea.left + itemSpace * i + itemSpace / 2;

      final textSpan = TextSpan(text: item.label, style: textStyle);
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

  String _formatAxisValue(double value) {
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
  bool shouldRepaint(covariant _WaterfallChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}

/// Internal class for waterfall bar calculation.
class _WaterfallBarInfo {
  _WaterfallBarInfo({
    required this.start,
    required this.end,
    required this.runningTotal,
  });

  final double start;
  final double end;
  final double runningTotal;
}
