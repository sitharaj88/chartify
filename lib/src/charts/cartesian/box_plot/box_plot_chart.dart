import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'box_plot_chart_data.dart';

export 'box_plot_chart_data.dart';

/// A box plot (box-and-whisker) chart widget.
///
/// Displays statistical data showing the distribution through
/// quartiles, with whiskers indicating variability.
///
/// Example:
/// ```dart
/// BoxPlotChart(
///   data: BoxPlotChartData(
///     items: [
///       BoxPlotItem(label: 'A', min: 5, q1: 10, median: 15, q3: 20, max: 25),
///       BoxPlotItem(label: 'B', min: 8, q1: 12, median: 18, q3: 22, max: 28),
///     ],
///   ),
/// )
/// ```
class BoxPlotChart extends StatefulWidget {
  const BoxPlotChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.onItemHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final BoxPlotChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(BoxPlotItem item, int index)? onItemTap;
  final void Function(BoxPlotItem? item, int? index)? onItemHover;
  final EdgeInsets padding;

  @override
  State<BoxPlotChart> createState() => _BoxPlotChartState();
}

class _BoxPlotChartState extends State<BoxPlotChart>
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
  void didUpdateWidget(BoxPlotChart oldWidget) {
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
                painter: _BoxPlotChartPainter(
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
    final item = widget.data.items[info.pointIndex];
    final color = item.color ?? theme.getSeriesColor(info.pointIndex);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(color: color, label: 'Max', value: item.max),
        TooltipEntry(color: color, label: 'Q3', value: item.q3),
        TooltipEntry(color: color, label: 'Median', value: item.median),
        TooltipEntry(color: color, label: 'Q1', value: item.q1),
        TooltipEntry(color: color, label: 'Min', value: item.min),
        if (item.mean != null)
          TooltipEntry(color: color, label: 'Mean', value: item.mean),
      ],
      xLabel: item.label,
    );
  }
}

class _BoxPlotChartPainter extends CartesianChartPainter {
  _BoxPlotChartPainter({
    required this.data,
    required ChartThemeData theme,
    required double animationValue,
    required this.controller,
    required this.hitTester,
    required EdgeInsets padding,
    this.labelFontSize = 11.0,
  }) : super(
          theme: theme,
          animationValue: animationValue,
          padding: padding,
          repaint: controller,
          gridDashPattern: theme.gridDashPattern,
        ) {
    _calculateBounds();
  }

  final BoxPlotChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final double labelFontSize;

  double _yMin = 0;
  double _yMax = 1;

  @override
  void paintGrid(Canvas canvas, Size size) {
    if (!showGrid) return;

    final chartArea = getChartArea(size);
    final gridPaint = getPaint(
      color: theme.gridLineColor,
      strokeWidth: theme.gridLineWidth,
    );

    // Paint horizontal lines only (no vertical lines)
    const horizontalCount = 5;
    for (var i = 0; i <= horizontalCount; i++) {
      final y = chartArea.top + (chartArea.height / horizontalCount) * i;
      final start = Offset(chartArea.left, y);
      final end = Offset(chartArea.right, y);

      if (gridDashPattern != null) {
        drawDashedLine(canvas, start, end, gridPaint, gridDashPattern!);
      } else {
        canvas.drawLine(start, end, gridPaint);
      }
    }
  }

  void _calculateBounds() {
    if (data.items.isEmpty) return;

    var minValue = double.infinity;
    var maxValue = double.negativeInfinity;

    for (final item in data.items) {
      minValue = math.min(minValue, item.min);
      maxValue = math.max(maxValue, item.max);

      // Include outliers
      if (item.outliers != null) {
        for (final outlier in item.outliers!) {
          minValue = math.min(minValue, outlier);
          maxValue = math.max(maxValue, outlier);
        }
      }
    }

    final range = maxValue - minValue;
    _yMin = minValue - range * 0.1;
    _yMax = maxValue + range * 0.1;
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.items.isEmpty) return;

    final isVertical = data.orientation == BoxPlotOrientation.vertical;
    final itemCount = data.items.length;
    final itemSpace = isVertical
        ? chartArea.width / itemCount
        : chartArea.height / itemCount;
    final boxSize = itemSpace * data.boxWidth;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = item.color ?? theme.getSeriesColor(i);

      if (isVertical) {
        _drawVerticalBoxPlot(canvas, chartArea, item, i, itemSpace, boxSize, color, isHovered);
      } else {
        _drawHorizontalBoxPlot(canvas, chartArea, item, i, itemSpace, boxSize, color, isHovered);
      }
    }
  }

  void _drawVerticalBoxPlot(
    Canvas canvas,
    Rect chartArea,
    BoxPlotItem item,
    int index,
    double itemSpace,
    double boxSize,
    Color color,
    bool isHovered,
  ) {
    final centerX = chartArea.left + itemSpace * index + itemSpace / 2;

    // Calculate Y positions
    final minY = _valueToY(item.min, chartArea);
    final q1Y = _valueToY(item.q1, chartArea);
    final medianY = _valueToY(item.median, chartArea);
    final q3Y = _valueToY(item.q3, chartArea);
    final maxY = _valueToY(item.max, chartArea);

    // Animate from median outward
    final animatedMinY = medianY + (minY - medianY) * animationValue;
    final animatedQ1Y = medianY + (q1Y - medianY) * animationValue;
    final animatedQ3Y = medianY + (q3Y - medianY) * animationValue;
    final animatedMaxY = medianY + (maxY - medianY) * animationValue;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = data.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isHovered ? data.fillOpacity + 0.2 : data.fillOpacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw whiskers
    final whiskerWidth = boxSize * data.whiskerWidth;

    // Upper whisker
    canvas.drawLine(
      Offset(centerX, animatedQ3Y),
      Offset(centerX, animatedMaxY),
      strokePaint,
    );
    canvas.drawLine(
      Offset(centerX - whiskerWidth / 2, animatedMaxY),
      Offset(centerX + whiskerWidth / 2, animatedMaxY),
      strokePaint,
    );

    // Lower whisker
    canvas.drawLine(
      Offset(centerX, animatedQ1Y),
      Offset(centerX, animatedMinY),
      strokePaint,
    );
    canvas.drawLine(
      Offset(centerX - whiskerWidth / 2, animatedMinY),
      Offset(centerX + whiskerWidth / 2, animatedMinY),
      strokePaint,
    );

    // Draw box
    final boxRect = Rect.fromLTRB(
      centerX - boxSize / 2,
      animatedQ3Y,
      centerX + boxSize / 2,
      animatedQ1Y,
    );
    final boxRRect = RRect.fromRectAndRadius(boxRect, Radius.circular(theme.barCornerRadius * 0.5));

    if (data.showNotch) {
      _drawNotchedBox(canvas, boxRect, medianY, data.notchWidth, fillPaint, strokePaint);
    } else {
      canvas.drawRRect(boxRRect, fillPaint);
      canvas.drawRRect(boxRRect, strokePaint);
    }

    // Draw median line
    canvas.drawLine(
      Offset(centerX - boxSize / 2, medianY),
      Offset(centerX + boxSize / 2, medianY),
      Paint()
        ..color = color
        ..strokeWidth = data.strokeWidth * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // Draw mean marker
    if (data.showMean && item.mean != null) {
      final meanY = _valueToY(item.mean!, chartArea);
      _drawMeanMarker(canvas, Offset(centerX, meanY), color);
    }

    // Draw outliers
    if (data.showOutliers && item.outliers != null) {
      for (final outlier in item.outliers!) {
        final outlierY = _valueToY(outlier, chartArea);
        _drawOutlier(canvas, Offset(centerX, outlierY), color);
      }
    }

    // Hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRect(
        Rect.fromLTRB(centerX - itemSpace / 2, chartArea.top, centerX + itemSpace / 2, chartArea.bottom),
        highlightPaint,
      );
    }

    // Register hit target
    hitTester.addRect(
      rect: Rect.fromLTRB(centerX - itemSpace / 2, animatedMaxY, centerX + itemSpace / 2, animatedMinY),
      info: DataPointInfo(
        seriesIndex: 0,
        pointIndex: index,
        position: Offset(centerX, medianY),
        xValue: item.label,
        yValue: item.median,
      ),
    );
  }

  void _drawHorizontalBoxPlot(
    Canvas canvas,
    Rect chartArea,
    BoxPlotItem item,
    int index,
    double itemSpace,
    double boxSize,
    Color color,
    bool isHovered,
  ) {
    final centerY = chartArea.top + itemSpace * index + itemSpace / 2;

    // Calculate X positions
    final minX = _valueToX(item.min, chartArea);
    final q1X = _valueToX(item.q1, chartArea);
    final medianX = _valueToX(item.median, chartArea);
    final q3X = _valueToX(item.q3, chartArea);
    final maxX = _valueToX(item.max, chartArea);

    // Animate from median outward
    final animatedMinX = medianX + (minX - medianX) * animationValue;
    final animatedQ1X = medianX + (q1X - medianX) * animationValue;
    final animatedQ3X = medianX + (q3X - medianX) * animationValue;
    final animatedMaxX = medianX + (maxX - medianX) * animationValue;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = data.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isHovered ? data.fillOpacity + 0.2 : data.fillOpacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw whiskers
    final whiskerSize = boxSize * data.whiskerWidth;

    // Right whisker
    canvas.drawLine(Offset(animatedQ3X, centerY), Offset(animatedMaxX, centerY), strokePaint);
    canvas.drawLine(Offset(animatedMaxX, centerY - whiskerSize / 2), Offset(animatedMaxX, centerY + whiskerSize / 2), strokePaint);

    // Left whisker
    canvas.drawLine(Offset(animatedQ1X, centerY), Offset(animatedMinX, centerY), strokePaint);
    canvas.drawLine(Offset(animatedMinX, centerY - whiskerSize / 2), Offset(animatedMinX, centerY + whiskerSize / 2), strokePaint);

    // Draw box
    final boxRect = Rect.fromLTRB(animatedQ1X, centerY - boxSize / 2, animatedQ3X, centerY + boxSize / 2);
    final boxRRect = RRect.fromRectAndRadius(boxRect, Radius.circular(theme.barCornerRadius * 0.5));
    canvas.drawRRect(boxRRect, fillPaint);
    canvas.drawRRect(boxRRect, strokePaint);

    // Draw median line
    canvas.drawLine(
      Offset(medianX, centerY - boxSize / 2),
      Offset(medianX, centerY + boxSize / 2),
      Paint()
        ..color = color
        ..strokeWidth = data.strokeWidth * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // Register hit target
    hitTester.addRect(
      rect: Rect.fromLTRB(animatedMinX, centerY - itemSpace / 2, animatedMaxX, centerY + itemSpace / 2),
      info: DataPointInfo(
        seriesIndex: 0,
        pointIndex: index,
        position: Offset(medianX, centerY),
        xValue: item.label,
        yValue: item.median,
      ),
    );
  }

  void _drawNotchedBox(
    Canvas canvas,
    Rect boxRect,
    double medianY,
    double notchRatio,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    final notchWidth = boxRect.width * notchRatio;
    final notchLeft = boxRect.center.dx - notchWidth / 2;
    final notchRight = boxRect.center.dx + notchWidth / 2;

    final path = Path()
      ..moveTo(boxRect.left, boxRect.top)
      ..lineTo(boxRect.right, boxRect.top)
      ..lineTo(boxRect.right, medianY)
      ..lineTo(notchRight, medianY)
      ..lineTo(notchLeft, medianY)
      ..lineTo(boxRect.left, medianY)
      ..lineTo(boxRect.left, boxRect.bottom)
      ..lineTo(boxRect.right, boxRect.bottom)
      ..lineTo(boxRect.right, medianY)
      ..lineTo(notchRight, medianY)
      ..lineTo(notchLeft, medianY)
      ..lineTo(boxRect.left, medianY)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawMeanMarker(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final size = data.meanMarkerSize / 2;
    canvas.drawLine(Offset(center.dx - size, center.dy - size), Offset(center.dx + size, center.dy + size), paint);
    canvas.drawLine(Offset(center.dx - size, center.dy + size), Offset(center.dx + size, center.dy - size), paint);
  }

  void _drawOutlier(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(center, data.outlierRadius, paint);
  }

  double _valueToY(double value, Rect chartArea) {
    final range = _yMax - _yMin;
    if (range == 0) return chartArea.center.dy;
    return chartArea.bottom - (value - _yMin) / range * chartArea.height;
  }

  double _valueToX(double value, Rect chartArea) {
    final range = _yMax - _yMin;
    if (range == 0) return chartArea.center.dx;
    return chartArea.left + (value - _yMin) / range * chartArea.width;
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    super.paintAxes(canvas, size);

    final chartArea = getChartArea(size);
    if (data.orientation == BoxPlotOrientation.vertical) {
      _drawYAxisLabels(canvas, chartArea);
      _drawXAxisLabels(canvas, chartArea);
    } else {
      _drawHorizontalAxisLabels(canvas, chartArea);
    }
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

      final label = _formatValue(value);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(chartArea.left - textPainter.width - 12, y - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect chartArea) {
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
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

      final offset = Offset(x - textPainter.width / 2, chartArea.bottom + 12);
      textPainter.paint(canvas, offset);
    }
  }

  void _drawHorizontalAxisLabels(Canvas canvas, Rect chartArea) {
    // Draw value axis at bottom
    const labelCount = 5;
    final range = _yMax - _yMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _yMin + (range * i / labelCount);
      final x = chartArea.left + (chartArea.width * i / labelCount);

      final label = _formatValue(value);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(x - textPainter.width / 2, chartArea.bottom + 12);
      textPainter.paint(canvas, offset);
    }

    // Draw category labels on left
    final itemCount = data.items.length;
    final itemSpace = chartArea.height / itemCount;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final y = chartArea.top + itemSpace * i + itemSpace / 2;

      final textSpan = TextSpan(text: item.label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(chartArea.left - textPainter.width - 12, y - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _BoxPlotChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
