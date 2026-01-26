import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'range_chart_data.dart';

export 'range_chart_data.dart';

/// A range chart widget.
///
/// Displays min/max ranges as filled bars, useful for showing
/// data ranges, temperature variations, or price ranges.
///
/// Example:
/// ```dart
/// RangeChart(
///   data: RangeChartData(
///     items: [
///       RangeItem(label: 'Jan', min: 5, max: 15),
///       RangeItem(label: 'Feb', min: 8, max: 18),
///       RangeItem(label: 'Mar', min: 12, max: 22),
///     ],
///   ),
/// )
/// ```
class RangeChart extends StatefulWidget {
  const RangeChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.padding = const EdgeInsets.all(24),
  });

  final RangeChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, RangeItem item)? onItemTap;
  final EdgeInsets padding;

  @override
  State<RangeChart> createState() => _RangeChartState();
}

class _RangeChartState extends State<RangeChart>
    with SingleTickerProviderStateMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();

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
  void didUpdateWidget(RangeChart oldWidget) {
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
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: 0);
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
    } else {
      _controller.clearHoveredPoint();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartArea = Rect.fromLTRB(
          widget.padding.left,
          widget.padding.top,
          constraints.maxWidth - widget.padding.right,
          constraints.maxHeight - widget.padding.bottom,
        );

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltip,
          theme: theme,
          chartArea: chartArea,
          tooltipDataBuilder: (info) => _buildTooltipData(info, theme),
          child: ChartGestureDetector(
            controller: _controller,
            interactions: widget.interactions,
            hitTester: _hitTester,
            onTap: (details) {
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: 0);
              if (hitInfo != null && widget.onItemTap != null) {
                final idx = hitInfo.pointIndex;
                if (idx >= 0 && idx < widget.data.items.length) {
                  widget.onItemTap!(idx, widget.data.items[idx]);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _RangeChartPainter(
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
    final idx = info.pointIndex;
    if (idx < 0 || idx >= widget.data.items.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final item = widget.data.items[idx];
    final color = item.color ?? theme.getSeriesColor(idx);

    final entries = <TooltipEntry>[
      TooltipEntry(
        color: color,
        label: 'Min',
        value: item.min,
        formattedValue: item.min.toStringAsFixed(1),
      ),
      TooltipEntry(
        color: color,
        label: 'Max',
        value: item.max,
        formattedValue: item.max.toStringAsFixed(1),
      ),
    ];

    if (item.mid != null) {
      entries.add(TooltipEntry(
        color: color.withValues(alpha: 0.7),
        label: 'Mid',
        value: item.mid!,
        formattedValue: item.mid!.toStringAsFixed(1),
      ));
    }

    return TooltipData(
      position: info.position,
      entries: entries,
      xLabel: item.label,
    );
  }
}

class _RangeChartPainter extends ChartPainter {
  _RangeChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
  }) : super(repaint: controller);

  final RangeChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;

  @override
  Rect getChartArea(Size size) {
    final labelSpace = data.showLabels ? 40.0 : 0.0;
    final isHorizontal = data.orientation == RangeOrientation.horizontal;

    return Rect.fromLTRB(
      padding.left + (isHorizontal ? labelSpace : 40),
      padding.top,
      size.width - padding.right - (isHorizontal ? 40 : 0),
      size.height - padding.bottom - (isHorizontal ? 0 : labelSpace + 20),
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.items.isEmpty) return;

    final (minValue, maxValue) = data.calculateRange();
    final isHorizontal = data.orientation == RangeOrientation.horizontal;

    // Draw grid and axis
    _drawGrid(canvas, chartArea, minValue, maxValue, isHorizontal);
    _drawAxis(canvas, chartArea, minValue, maxValue, isHorizontal);

    final itemCount = data.items.length;
    final availableSpace =
        isHorizontal ? chartArea.height : chartArea.width;
    final itemSpace = availableSpace / itemCount;
    final barSize = itemSpace * data.barWidth;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = item.color ?? theme.getSeriesColor(i);

      // Calculate bar position
      final itemCenter = itemSpace * (i + 0.5);

      // Calculate value positions
      final minRatio =
          ((item.min - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
      final maxRatio =
          ((item.max - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

      // Apply animation
      final animatedMinRatio = minRatio * animationValue;
      final animatedMaxRatio = maxRatio * animationValue;

      Rect barRect;
      if (isHorizontal) {
        final minX = chartArea.left + animatedMinRatio * chartArea.width;
        final maxX = chartArea.left + animatedMaxRatio * chartArea.width;
        barRect = Rect.fromLTWH(
          minX,
          chartArea.top + itemCenter - barSize / 2,
          maxX - minX,
          barSize,
        );
      } else {
        final minY = chartArea.bottom - animatedMinRatio * chartArea.height;
        final maxY = chartArea.bottom - animatedMaxRatio * chartArea.height;
        barRect = Rect.fromLTWH(
          chartArea.left + itemCenter - barSize / 2,
          maxY,
          barSize,
          minY - maxY,
        );
      }

      // Draw bar
      final fillColor = isHovered
          ? color.withValues(alpha: 1.0)
          : color.withValues(alpha: 0.7);

      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final rRect = RRect.fromRectAndRadius(
        barRect,
        Radius.circular(data.cornerRadius),
      );
      canvas.drawRRect(rRect, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rRect, borderPaint);

      // Draw midpoint marker
      if (data.showMidMarker && item.mid != null) {
        final midRatio = ((item.mid! - minValue) / (maxValue - minValue))
                .clamp(0.0, 1.0) *
            animationValue;

        Offset midPoint;
        if (isHorizontal) {
          midPoint = Offset(
            chartArea.left + midRatio * chartArea.width,
            barRect.center.dy,
          );
        } else {
          midPoint = Offset(
            barRect.center.dx,
            chartArea.bottom - midRatio * chartArea.height,
          );
        }

        final markerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(midPoint, data.midMarkerSize / 2, markerPaint);

        final markerBorderPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(midPoint, data.midMarkerSize / 2, markerBorderPaint);
      }

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, item, barRect, isHorizontal, chartArea);
      }

      // Register hit target
      hitTester.addRect(
        rect: barRect,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: barRect.center,
          xValue: i,
          yValue: item.max,
        ),
      );
    }
  }

  void _drawGrid(Canvas canvas, Rect chartArea, double minValue,
      double maxValue, bool isHorizontal) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const gridLines = 5;
    for (var i = 0; i <= gridLines; i++) {
      if (isHorizontal) {
        final x = chartArea.left + (i / gridLines) * chartArea.width;
        canvas.drawLine(
          Offset(x, chartArea.top),
          Offset(x, chartArea.bottom),
          paint,
        );
      } else {
        final y = chartArea.top + (i / gridLines) * chartArea.height;
        canvas.drawLine(
          Offset(chartArea.left, y),
          Offset(chartArea.right, y),
          paint,
        );
      }
    }
  }

  void _drawAxis(Canvas canvas, Rect chartArea, double minValue,
      double maxValue, bool isHorizontal) {
    final paint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = 1;

    if (isHorizontal) {
      canvas.drawLine(
        Offset(chartArea.left, chartArea.bottom),
        Offset(chartArea.right, chartArea.bottom),
        paint,
      );

      // Draw value labels
      const labelCount = 5;
      for (var i = 0; i <= labelCount; i++) {
        final value = minValue + (i / labelCount) * (maxValue - minValue);
        final x = chartArea.left + (i / labelCount) * chartArea.width;

        final textSpan = TextSpan(
          text: value.toStringAsFixed(0),
          style: theme.labelStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartArea.bottom + 8),
        );
      }
    } else {
      canvas.drawLine(
        Offset(chartArea.left, chartArea.top),
        Offset(chartArea.left, chartArea.bottom),
        paint,
      );

      // Draw value labels
      const labelCount = 5;
      for (var i = 0; i <= labelCount; i++) {
        final value = maxValue - (i / labelCount) * (maxValue - minValue);
        final y = chartArea.top + (i / labelCount) * chartArea.height;

        final textSpan = TextSpan(
          text: value.toStringAsFixed(0),
          style: theme.labelStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(chartArea.left - textPainter.width - 8,
              y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, RangeItem item, Rect barRect,
      bool isHorizontal, Rect chartArea) {
    final textSpan = TextSpan(
      text: item.label,
      style: theme.labelStyle.copyWith(fontSize: 11),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    if (isHorizontal) {
      textPainter.paint(
        canvas,
        Offset(
          chartArea.left - textPainter.width - 8,
          barRect.center.dy - textPainter.height / 2,
        ),
      );
    } else {
      textPainter.paint(
        canvas,
        Offset(
          barRect.center.dx - textPainter.width / 2,
          chartArea.bottom + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RangeChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
