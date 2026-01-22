import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'bar_chart_data.dart';
import 'bar_series.dart';

/// A bar chart widget.
///
/// Displays data as vertical or horizontal bars.
/// Supports grouped, stacked, and percent-stacked layouts.
///
/// Example:
/// ```dart
/// BarChart(
///   data: BarChartData(
///     series: [
///       BarSeries(
///         name: 'Sales',
///         data: [
///           DataPoint(x: 0, y: 100),
///           DataPoint(x: 1, y: 150),
///           DataPoint(x: 2, y: 120),
///         ],
///         color: Colors.blue,
///       ),
///     ],
///     xAxis: BarXAxisConfig(categories: ['Jan', 'Feb', 'Mar']),
///   ),
/// )
/// ```
class BarChart extends StatefulWidget {
  const BarChart({
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

  final BarChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DataPointInfo info)? onDataPointTap;
  final void Function(DataPointInfo? info)? onDataPointHover;
  final EdgeInsets padding;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart>
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
  void didUpdateWidget(BarChart oldWidget) {
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
      widget.onDataPointHover?.call(hitInfo);
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
                painter: _BarChartPainter(
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
    final category = widget.data.xAxis.categories != null &&
            info.pointIndex < widget.data.xAxis.categories!.length
        ? widget.data.xAxis.categories![info.pointIndex]
        : info.xValue.toString();

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: series.color ?? theme.getSeriesColor(info.seriesIndex),
          label: series.name ?? 'Series ${info.seriesIndex + 1}',
          value: info.yValue,
        ),
      ],
      xLabel: category,
    );
  }
}

class _BarChartPainter extends CartesianChartPainter {
  _BarChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required EdgeInsets padding,
  }) : super(padding: padding, repaint: controller) {
    _calculateBounds();
  }

  final BarChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;

  double _yMin = 0;
  double _yMax = 1;
  int _categoryCount = 0;

  void _calculateBounds() {
    double yMin = 0;
    double yMax = 0;
    int maxLength = 0;

    for (final series in data.series) {
      if (!series.visible) continue;
      maxLength = math.max(maxLength, series.data.length);

      if (data.grouping == BarGrouping.stacked ||
          data.grouping == BarGrouping.percentStacked) {
        // For stacked, we need cumulative values
        for (var i = 0; i < series.data.length; i++) {
          double stackSum = 0;
          for (final s in data.series) {
            if (!s.visible || i >= s.data.length) continue;
            stackSum += s.data[i].y.toDouble();
          }
          if (stackSum > yMax) yMax = stackSum;
          if (stackSum < yMin) yMin = stackSum;
        }
      } else {
        for (final point in series.data) {
          final y = point.y.toDouble();
          if (y > yMax) yMax = y;
          if (y < yMin) yMin = y;
        }
      }
    }

    _categoryCount = maxLength;

    // Apply axis config
    if (data.yAxis.min != null) yMin = data.yAxis.min!;
    if (data.yAxis.max != null) yMax = data.yAxis.max!;

    // Ensure we include zero for bar charts
    if (yMin > 0) yMin = 0;
    if (yMax < 0) yMax = 0;

    // Add padding
    final range = yMax - yMin;
    if (range == 0) {
      yMax = 1;
    } else {
      yMax += range * 0.1;
    }

    _yMin = yMin;
    _yMax = yMax;
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.series.isEmpty || _categoryCount == 0) return;

    final isVertical = data.direction == BarDirection.vertical;
    final visibleSeries = data.series.where((s) => s.visible).toList();
    final seriesCount = visibleSeries.length;

    if (seriesCount == 0) return;

    // Calculate bar dimensions
    final totalCategories = _categoryCount;
    final categorySize = isVertical
        ? chartArea.width / totalCategories
        : chartArea.height / totalCategories;

    final groupWidth = categorySize * (1 - data.groupSpacing);
    final barWidth = data.grouping == BarGrouping.grouped
        ? (groupWidth / seriesCount) * (1 - data.barSpacing)
        : groupWidth;

    for (var categoryIndex = 0; categoryIndex < totalCategories; categoryIndex++) {
      double stackOffset = 0;
      double negativeStackOffset = 0;

      for (var seriesIndex = 0; seriesIndex < visibleSeries.length; seriesIndex++) {
        final series = visibleSeries[seriesIndex];
        if (categoryIndex >= series.data.length) continue;

        final point = series.data[categoryIndex];
        final value = point.y.toDouble();
        final originalSeriesIndex = data.series.indexOf(series);

        // Calculate bar position
        double barStart, barEnd;
        final yRange = _yMax - _yMin;
        final normalizedValue = (value - _yMin) / yRange;
        final zeroPosition = -_yMin / yRange;

        if (data.grouping == BarGrouping.stacked ||
            data.grouping == BarGrouping.percentStacked) {
          if (value >= 0) {
            barStart = stackOffset;
            barEnd = stackOffset + normalizedValue * animationValue;
            stackOffset = barEnd;
          } else {
            barEnd = negativeStackOffset;
            barStart = negativeStackOffset + normalizedValue * animationValue;
            negativeStackOffset = barStart;
          }
        } else {
          barStart = zeroPosition;
          barEnd = normalizedValue * animationValue + zeroPosition * (1 - animationValue);
        }

        // Calculate rectangle
        Rect barRect;
        if (isVertical) {
          final categoryStart = chartArea.left + categoryIndex * categorySize;
          final groupStart = categoryStart + (categorySize - groupWidth) / 2;

          double barLeft;
          if (data.grouping == BarGrouping.grouped) {
            barLeft = groupStart + seriesIndex * (groupWidth / seriesCount) +
                (groupWidth / seriesCount - barWidth) / 2;
          } else {
            barLeft = groupStart;
          }

          final top = chartArea.bottom - barEnd * chartArea.height;
          final bottom = chartArea.bottom - barStart * chartArea.height;

          barRect = Rect.fromLTRB(
            barLeft,
            math.min(top, bottom),
            barLeft + barWidth,
            math.max(top, bottom),
          );
        } else {
          final categoryStart = chartArea.top + categoryIndex * categorySize;
          final groupStart = categoryStart + (categorySize - groupWidth) / 2;

          double barTop;
          if (data.grouping == BarGrouping.grouped) {
            barTop = groupStart + seriesIndex * (groupWidth / seriesCount) +
                (groupWidth / seriesCount - barWidth) / 2;
          } else {
            barTop = groupStart;
          }

          final left = chartArea.left + barStart * chartArea.width;
          final right = chartArea.left + barEnd * chartArea.width;

          barRect = Rect.fromLTRB(
            math.min(left, right),
            barTop,
            math.max(left, right),
            barTop + barWidth,
          );
        }

        // Draw the bar
        final color = series.color ?? theme.getSeriesColor(originalSeriesIndex);
        _drawBar(canvas, barRect, series, color, originalSeriesIndex, categoryIndex);

        // Register hit target
        hitTester.addRect(
          rect: barRect,
          info: DataPointInfo(
            seriesIndex: originalSeriesIndex,
            pointIndex: categoryIndex,
            position: barRect.center,
            xValue: point.x,
            yValue: point.y,
            seriesName: series.name,
          ),
        );
      }
    }
  }

  void _drawBar(
    Canvas canvas,
    Rect rect,
    BarSeries series,
    Color color,
    int seriesIndex,
    int pointIndex,
  ) {
    final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex &&
        controller.hoveredPoint?.pointIndex == pointIndex;
    final isSelected = controller.isPointSelected(seriesIndex, pointIndex);

    // Adjust color for hover/selection
    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 0.8);
    }
    if (isSelected) {
      fillColor = color.withValues(alpha: 1.0);
    }

    // Create rounded rectangle
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: series.borderRadius.topLeft,
      topRight: series.borderRadius.topRight,
      bottomLeft: series.borderRadius.bottomLeft,
      bottomRight: series.borderRadius.bottomRight,
    );

    // Draw fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    if (series.gradient != null) {
      fillPaint.shader = series.gradient!.createShader(rect);
    } else {
      fillPaint.color = fillColor;
    }

    canvas.drawRRect(rrect, fillPaint);

    // Draw border
    if (series.borderWidth > 0 && series.borderColor != null) {
      final borderPaint = Paint()
        ..color = series.borderColor!
        ..strokeWidth = series.borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw hover effect
    if (isHovered) {
      final hoverPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, hoverPaint);
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
    if (!data.yAxis.showLabels) return;

    final tickCount = data.yAxis.tickCount;
    final range = _yMax - _yMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= tickCount; i++) {
      final value = _yMin + (range * i / tickCount);
      final y = chartArea.bottom - (chartArea.height * i / tickCount);

      final label = data.yAxis.labelFormatter?.call(value) ??
          _formatNumber(value);

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
    if (!data.xAxis.showLabels || _categoryCount == 0) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    final categoryWidth = chartArea.width / _categoryCount;

    for (var i = 0; i < _categoryCount; i++) {
      final label = data.xAxis.categories != null && i < data.xAxis.categories!.length
          ? data.xAxis.categories![i]
          : i.toString();

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final x = chartArea.left + categoryWidth * i + categoryWidth / 2;
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
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices;
}
