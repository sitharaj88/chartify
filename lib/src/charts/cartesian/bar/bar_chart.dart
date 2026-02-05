import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerExitEvent;
import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../core/gestures/spatial_index.dart';
import '../../../core/math/geometry/bounds_calculator.dart';
import '../../../core/math/scales/scale.dart';
import '../../../rendering/renderers/grid_renderer.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
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
    required this.data, super.key,
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
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;

  // Spatial index for O(log n) hit testing
  QuadTree<DataPointInfo>? _spatialIndex;

  // Cached bounds
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

  void _handleHover(PointerEvent event) {
    final nearestInfo = _spatialIndex?.findNearest(
      event.localPosition,
      maxDistance: widget.interactions.hitTestRadius * 2,
    );

    if (nearestInfo != null) {
      _controller.setHoveredPoint(nearestInfo);
      widget.onDataPointHover?.call(nearestInfo);
    } else {
      // Fallback to rect-based hit testing
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
        // Get responsive padding based on screen size
        final responsivePadding = getResponsivePadding(
          context,
          constraints,
          override: widget.padding,
        );

        // Get responsive font size for labels
        final labelFontSize = getScaledFontSize(context, 11.0);

        // Get WCAG-compliant hit test radius
        final hitRadius = getHitTestRadius(context, constraints);

        _chartArea = Rect.fromLTRB(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.right,
          constraints.maxHeight - responsivePadding.bottom,
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
              final hitInfo = _hitTester.hitTest(
                details.localPosition,
                radius: hitRadius,
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
                  padding: responsivePadding,
                  yBounds: _yBounds,
                  onBoundsCalculated: (y) => _yBounds = y,
                  onSpatialIndexBuilt: (index) => _spatialIndex = index,
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

/// Painter for bar charts using the new rendering infrastructure.
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.theme,
    required this.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    this.yBounds,
    this.onBoundsCalculated,
    this.onSpatialIndexBuilt,
    this.labelFontSize = 11.0,
  }) : super(repaint: controller);

  final BarChartData data;
  final ChartThemeData theme;
  final double animationValue;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  Bounds? yBounds;
  final void Function(Bounds y)? onBoundsCalculated;
  final void Function(QuadTree<DataPointInfo> index)? onSpatialIndexBuilt;

  /// Font size for axis labels (responsive).
  final double labelFontSize;

  // Renderers
  GridRenderer<double, double>? _gridRenderer;

  late Rect _chartArea;
  late LinearScale _yScale;
  int _categoryCount = 0;

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
    _yScale = LinearScale(
      domain: (yBounds!.min, yBounds!.max),
      range: (_chartArea.bottom, _chartArea.top),
    );

    // Draw layers
    _drawGrid(canvas, size);
    _drawBars(canvas);
    _drawAxes(canvas, size);
  }

  void _calculateBounds() {
    if (yBounds != null) {
      _categoryCount = _calculateCategoryCount();
      return;
    }

    double yMin = 0;
    double yMax = 0;
    var maxLength = 0;

    for (final series in data.series) {
      if (!series.visible) continue;
      maxLength = math.max(maxLength, series.data.length);

      if (data.grouping == BarGrouping.stacked) {
        // For regular stacked, sum all values per category
        for (var i = 0; i < series.data.length; i++) {
          double positiveSum = 0;
          double negativeSum = 0;
          for (final s in data.series) {
            if (!s.visible || i >= s.data.length) continue;
            final val = s.data[i].y.toDouble();
            if (val >= 0) {
              positiveSum += val;
            } else {
              negativeSum += val;
            }
          }
          if (positiveSum > yMax) yMax = positiveSum;
          if (negativeSum < yMin) yMin = negativeSum;
        }
      } else if (data.grouping == BarGrouping.percentStacked) {
        // For percent-stacked, y-axis is always 0-100%
        // We'll set the bounds after the loop
      } else {
        for (final point in series.data) {
          final y = point.y.toDouble();
          if (y > yMax) yMax = y;
          if (y < yMin) yMin = y;
        }
      }
    }

    _categoryCount = maxLength;

    // For percent-stacked, use 0-1 range (representing 0-100%)
    if (data.grouping == BarGrouping.percentStacked) {
      yMin = 0;
      yMax = 1;
      yBounds = Bounds(min: yMin, max: yMax);
      onBoundsCalculated?.call(yBounds!);
      return;
    }

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

    yBounds = Bounds(min: yMin, max: yMax);
    onBoundsCalculated?.call(yBounds!);
  }

  int _calculateCategoryCount() {
    var maxLength = 0;
    for (final series in data.series) {
      if (!series.visible) continue;
      maxLength = math.max(maxLength, series.data.length);
    }
    return maxLength;
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
    final xScale = LinearScale(
      domain: (0, _categoryCount.toDouble()),
      range: (_chartArea.left, _chartArea.right),
    );

    _gridRenderer ??= GridRenderer<double, double>(
      config: GridConfig(
        lineColor: theme.gridLineColor,
        lineWidth: theme.gridLineWidth,
        dashPattern: theme.gridDashPattern,
        verticalLines: false,
      ),
      xScale: xScale,
      yScale: _yScale,
    );

    _gridRenderer!.render(canvas, size, _chartArea);
  }

  void _drawBars(Canvas canvas) {
    if (_categoryCount == 0) return;

    final isVertical = data.direction == BarDirection.vertical;
    final visibleSeries = data.series.where((s) => s.visible).toList();
    final seriesCount = visibleSeries.length;

    if (seriesCount == 0) return;

    // Build spatial index for hit testing
    final spatialIndex = QuadTree<DataPointInfo>(bounds: _chartArea);

    // Calculate bar dimensions
    final categorySize = isVertical
        ? _chartArea.width / _categoryCount
        : _chartArea.height / _categoryCount;

    final groupWidth = categorySize * (1 - data.groupSpacing);
    final barWidth = data.grouping == BarGrouping.grouped
        ? (groupWidth / seriesCount) * (1 - data.barSpacing)
        : groupWidth;

    // Pre-calculate category totals for percent-stacked mode
    final categoryTotals = <int, double>{};
    if (data.grouping == BarGrouping.percentStacked) {
      for (var categoryIndex = 0; categoryIndex < _categoryCount; categoryIndex++) {
        double total = 0;
        for (final series in visibleSeries) {
          if (categoryIndex < series.data.length) {
            total += series.data[categoryIndex].y.toDouble().abs();
          }
        }
        categoryTotals[categoryIndex] = total;
      }
    }

    for (var categoryIndex = 0; categoryIndex < _categoryCount; categoryIndex++) {
      double stackOffset = 0;
      double negativeStackOffset = 0;

      for (var seriesIndex = 0; seriesIndex < visibleSeries.length; seriesIndex++) {
        final series = visibleSeries[seriesIndex];
        if (categoryIndex >= series.data.length) continue;

        final point = series.data[categoryIndex];
        final rawValue = point.y.toDouble();
        final originalSeriesIndex = data.series.indexOf(series);

        // Calculate the value to use for bar height
        double value;
        if (data.grouping == BarGrouping.percentStacked) {
          // Convert to percentage (0-1 range)
          final total = categoryTotals[categoryIndex] ?? 1;
          value = total > 0 ? rawValue.abs() / total : 0;
          // Preserve sign for proper stacking
          if (rawValue < 0) value = -value;
        } else {
          value = rawValue;
        }

        // Calculate bar position
        double barStart;
        double barEnd;
        final yRange = yBounds!.max - yBounds!.min;
        final normalizedValue = (value - yBounds!.min) / yRange;
        final zeroPosition = -yBounds!.min / yRange;

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
          final categoryStart = _chartArea.left + categoryIndex * categorySize;
          final groupStart = categoryStart + (categorySize - groupWidth) / 2;

          double barLeft;
          if (data.grouping == BarGrouping.grouped) {
            barLeft = groupStart + seriesIndex * (groupWidth / seriesCount) +
                (groupWidth / seriesCount - barWidth) / 2;
          } else {
            barLeft = groupStart;
          }

          final top = _chartArea.bottom - barEnd * _chartArea.height;
          final bottom = _chartArea.bottom - barStart * _chartArea.height;

          barRect = Rect.fromLTRB(
            barLeft,
            math.min(top, bottom),
            barLeft + barWidth,
            math.max(top, bottom),
          );
        } else {
          final categoryStart = _chartArea.top + categoryIndex * categorySize;
          final groupStart = categoryStart + (categorySize - groupWidth) / 2;

          double barTop;
          if (data.grouping == BarGrouping.grouped) {
            barTop = groupStart + seriesIndex * (groupWidth / seriesCount) +
                (groupWidth / seriesCount - barWidth) / 2;
          } else {
            barTop = groupStart;
          }

          final left = _chartArea.left + barStart * _chartArea.width;
          final right = _chartArea.left + barEnd * _chartArea.width;

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

        // Create hit info
        final info = DataPointInfo(
          seriesIndex: originalSeriesIndex,
          pointIndex: categoryIndex,
          position: barRect.center,
          xValue: point.x,
          yValue: point.y,
          seriesName: series.name,
        );

        // Register hit target
        hitTester.addRect(rect: barRect, info: info);

        // Add to spatial index
        spatialIndex.insert(info, barRect);
      }
    }

    onSpatialIndexBuilt?.call(spatialIndex);
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
      fillColor = color.withAlpha(204);
    }
    if (isSelected) {
      fillColor = color.withAlpha(255);
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
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (series.gradient != null) {
      fillPaint.shader = series.gradient!.createShader(rect);
    } else {
      // Subtle vertical gradient for modern look
      final hslColor = HSLColor.fromColor(fillColor);
      final lighterColor = hslColor.withLightness((hslColor.lightness + 0.08).clamp(0.0, 1.0)).toColor();
      fillPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighterColor, fillColor],
      ).createShader(rect);
    }

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((theme.shadowOpacity * 255 * 0.5).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(rrect.shift(Offset(0, theme.shadowBlurRadius * 0.15)), shadowPaint);

    canvas.drawRRect(rrect, fillPaint);

    // Draw border
    if (series.borderWidth > 0 && series.borderColor != null) {
      final borderPaint = Paint()
        ..color = series.borderColor!
        ..strokeWidth = series.borderWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw hover effect
    if (isHovered) {
      final hoverPaint = Paint()
        ..color = Colors.white.withAlpha(51)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRRect(rrect, hoverPaint);
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    // Y-axis labels
    if (data.yAxis.showLabels) {
      _drawYAxisLabels(canvas);
    }

    // X-axis labels
    if (data.xAxis.showLabels && _categoryCount > 0) {
      _drawXAxisLabels(canvas);
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

  void _drawYAxisLabels(Canvas canvas) {
    final tickCount = data.yAxis.tickCount;
    final yTicks = _yScale.ticks(count: tickCount);

    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: theme.labelStyle.color?.withAlpha(180),
    );

    for (final tick in yTicks) {
      final y = _yScale.scale(tick);
      String label;
      if (data.yAxis.labelFormatter != null) {
        label = data.yAxis.labelFormatter!.call(tick);
      } else if (data.grouping == BarGrouping.percentStacked) {
        // Format as percentage for percent-stacked mode
        label = '${(tick * 100).round()}%';
      } else {
        label = _formatNumber(tick);
      }

      final textSpan = TextSpan(text: label, style: textStyle);
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
  }

  void _drawXAxisLabels(Canvas canvas) {
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: theme.labelStyle.color?.withAlpha(180),
    );

    final categoryWidth = _chartArea.width / _categoryCount;

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

      final x = _chartArea.left + categoryWidth * i + categoryWidth / 2;
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
      data != oldDelegate.data ||
      animationValue != oldDelegate.animationValue ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      controller.selectedIndices != oldDelegate.controller.selectedIndices;
}
