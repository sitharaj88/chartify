import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'lollipop_chart_data.dart';

export 'lollipop_chart_data.dart';

/// A lollipop chart widget.
///
/// Displays data as thin lines with circles at the end,
/// similar to a bar chart but more minimal.
///
/// Example:
/// ```dart
/// LollipopChart(
///   data: LollipopChartData(
///     items: [
///       LollipopItem(label: 'A', value: 30),
///       LollipopItem(label: 'B', value: 50),
///       LollipopItem(label: 'C', value: 20),
///     ],
///   ),
/// )
/// ```
class LollipopChart extends StatefulWidget {
  const LollipopChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.padding = const EdgeInsets.all(24),
  });

  final LollipopChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, LollipopItem item)? onItemTap;
  final EdgeInsets padding;

  @override
  State<LollipopChart> createState() => _LollipopChartState();
}

class _LollipopChartState extends State<LollipopChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
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
  void didUpdateWidget(LollipopChart oldWidget) {
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
    final hitInfo = _hitTester.hitTest(event.localPosition);
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
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

        final chartArea = Rect.fromLTRB(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.right,
          constraints.maxHeight - responsivePadding.bottom,
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
              final hitInfo = _hitTester.hitTest(details.localPosition);
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
                painter: _LollipopChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: responsivePadding,
                  labelFontSize: labelFontSize,
                  hitRadius: hitRadius,
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

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: item.label,
          value: item.value,
          formattedValue: item.value.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class _LollipopChartPainter extends ChartPainter {
  _LollipopChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
  }) : super(repaint: controller);

  final LollipopChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;

  @override
  Rect getChartArea(Size size) {
    final labelSpace = data.showLabels ? 40.0 : 0.0;
    final isHorizontal = data.orientation == LollipopOrientation.horizontal;

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
    final isHorizontal = data.orientation == LollipopOrientation.horizontal;

    // Draw grid and axis
    _drawGrid(canvas, chartArea, minValue, maxValue, isHorizontal);
    _drawAxis(canvas, chartArea, minValue, maxValue, isHorizontal);

    // Calculate baseline position
    final baselineRatio =
        ((data.baselineValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    final itemCount = data.items.length;
    final availableSpace = isHorizontal ? chartArea.height : chartArea.width;
    final itemSpace = availableSpace / itemCount;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = item.color ?? theme.getSeriesColor(i);
      final shape = item.markerShape ?? data.markerShape;

      // Calculate position
      final itemCenter = itemSpace * (i + 0.5);

      // Calculate value position
      final valueRatio =
          ((item.value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

      // Apply animation
      final animatedRatio =
          baselineRatio + (valueRatio - baselineRatio) * animationValue;

      Offset basePoint;
      Offset markerPoint;

      if (isHorizontal) {
        final baseX = chartArea.left + baselineRatio * chartArea.width;
        final valueX = chartArea.left + animatedRatio * chartArea.width;
        final y = chartArea.top + itemCenter;

        basePoint = Offset(baseX, y);
        markerPoint = Offset(valueX, y);
      } else {
        final baseY = chartArea.bottom - baselineRatio * chartArea.height;
        final valueY = chartArea.bottom - animatedRatio * chartArea.height;
        final x = chartArea.left + itemCenter;

        basePoint = Offset(x, baseY);
        markerPoint = Offset(x, valueY);
      }

      // Draw stem
      final stemPaint = Paint()
        ..color = color
        ..strokeWidth = data.stemWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawLine(basePoint, markerPoint, stemPaint);

      // Draw marker
      final markerSize = isHovered ? data.markerSize * 1.3 : data.markerSize;

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Draw shadow
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: theme.shadowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      _drawMarker(canvas, markerPoint, markerSize + 2, shape, shadowPaint);

      _drawMarker(canvas, markerPoint, markerSize, shape, fillPaint);
      _drawMarker(canvas, markerPoint, markerSize, shape, borderPaint);

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, item, chartArea, itemCenter, isHorizontal);
      }

      // Draw value
      if (data.showValues) {
        _drawValue(canvas, item, markerPoint, isHorizontal);
      }

      // Register hit target
      hitTester.addCircle(
        center: markerPoint,
        radius: hitRadius,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: markerPoint,
          xValue: i,
          yValue: item.value,
        ),
      );
    }
  }

  void _drawMarker(Canvas canvas, Offset center, double size,
      LollipopMarkerShape shape, Paint paint,) {
    final half = size / 2;

    switch (shape) {
      case LollipopMarkerShape.circle:
        canvas.drawCircle(center, half, paint);
      case LollipopMarkerShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: size, height: size),
          paint,
        );
      case LollipopMarkerShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      case LollipopMarkerShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy + half * 0.5)
          ..lineTo(center.dx - half, center.dy + half * 0.5)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  void _drawGrid(Canvas canvas, Rect chartArea, double minValue,
      double maxValue, bool isHorizontal,) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

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
      double maxValue, bool isHorizontal,) {
    final paint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    if (isHorizontal) {
      canvas.drawLine(
        Offset(chartArea.left, chartArea.bottom),
        Offset(chartArea.right, chartArea.bottom),
        paint,
      );

      const labelCount = 5;
      for (var i = 0; i <= labelCount; i++) {
        final value = minValue + (i / labelCount) * (maxValue - minValue);
        final x = chartArea.left + (i / labelCount) * chartArea.width;

        final textSpan = TextSpan(
          text: value.toStringAsFixed(0),
          style: theme.labelStyle.copyWith(fontSize: labelFontSize),
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

      const labelCount = 5;
      for (var i = 0; i <= labelCount; i++) {
        final value = maxValue - (i / labelCount) * (maxValue - minValue);
        final y = chartArea.top + (i / labelCount) * chartArea.height;

        final textSpan = TextSpan(
          text: value.toStringAsFixed(0),
          style: theme.labelStyle.copyWith(fontSize: labelFontSize),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(chartArea.left - textPainter.width - 8,
              y - textPainter.height / 2,),
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, LollipopItem item, Rect chartArea,
      double itemCenter, bool isHorizontal,) {
    final textSpan = TextSpan(
      text: item.label,
      style: theme.labelStyle.copyWith(fontSize: labelFontSize),
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
          chartArea.top + itemCenter - textPainter.height / 2,
        ),
      );
    } else {
      textPainter.paint(
        canvas,
        Offset(
          chartArea.left + itemCenter - textPainter.width / 2,
          chartArea.bottom + 8,
        ),
      );
    }
  }

  void _drawValue(
      Canvas canvas, LollipopItem item, Offset markerPoint, bool isHorizontal,) {
    final textSpan = TextSpan(
      text: item.value.toStringAsFixed(0),
      style: theme.labelStyle.copyWith(
        fontSize: labelFontSize,
        fontWeight: FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = data.markerSize + 4;

    if (isHorizontal) {
      textPainter.paint(
        canvas,
        Offset(
          markerPoint.dx + offset,
          markerPoint.dy - textPainter.height / 2,
        ),
      );
    } else {
      textPainter.paint(
        canvas,
        Offset(
          markerPoint.dx - textPainter.width / 2,
          markerPoint.dy - offset - textPainter.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LollipopChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
