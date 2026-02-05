import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'dumbbell_chart_data.dart';

export 'dumbbell_chart_data.dart';

/// A dumbbell chart widget.
///
/// Displays two connected points per category, useful for showing
/// before/after comparisons or changes between two values.
///
/// Example:
/// ```dart
/// DumbbellChart(
///   data: DumbbellChartData(
///     items: [
///       DumbbellItem(label: '2020', startValue: 30, endValue: 50),
///       DumbbellItem(label: '2021', startValue: 40, endValue: 65),
///       DumbbellItem(label: '2022', startValue: 35, endValue: 70),
///     ],
///   ),
/// )
/// ```
class DumbbellChart extends StatefulWidget {
  const DumbbellChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.padding = const EdgeInsets.all(24),
  });

  final DumbbellChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, DumbbellItem item)? onItemTap;
  final EdgeInsets padding;

  @override
  State<DumbbellChart> createState() => _DumbbellChartState();
}

class _DumbbellChartState extends State<DumbbellChart>
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
  void didUpdateWidget(DumbbellChart oldWidget) {
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
                painter: _DumbbellChartPainter(
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
    final startColor = item.startColor ??
        widget.data.startColor ??
        theme.getSeriesColor(0);
    final endColor =
        item.endColor ?? widget.data.endColor ?? theme.getSeriesColor(1);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: startColor,
          label: item.startLabel ?? 'Start',
          value: item.startValue,
          formattedValue: item.startValue.toStringAsFixed(1),
        ),
        TooltipEntry(
          color: endColor,
          label: item.endLabel ?? 'End',
          value: item.endValue,
          formattedValue: item.endValue.toStringAsFixed(1),
        ),
        TooltipEntry(
          color: item.isPositive
              ? (widget.data.positiveColor ?? Colors.green)
              : (widget.data.negativeColor ?? Colors.red),
          label: 'Change',
          value: item.difference,
          formattedValue:
              '${item.isPositive ? '+' : ''}${item.difference.toStringAsFixed(1)}',
        ),
      ],
      xLabel: item.label,
    );
  }
}

class _DumbbellChartPainter extends ChartPainter {
  _DumbbellChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
  }) : super(repaint: controller);

  final DumbbellChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;

  @override
  Rect getChartArea(Size size) {
    final labelSpace = data.showLabels ? 60.0 : 0.0;
    final isHorizontal = data.orientation == DumbbellOrientation.horizontal;

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
    final isHorizontal = data.orientation == DumbbellOrientation.horizontal;

    // Draw grid and axis
    _drawGrid(canvas, chartArea, minValue, maxValue, isHorizontal);
    _drawAxis(canvas, chartArea, minValue, maxValue, isHorizontal);

    final itemCount = data.items.length;
    final availableSpace = isHorizontal ? chartArea.height : chartArea.width;
    final itemSpace = availableSpace / itemCount;

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      // Colors
      final startColor = item.startColor ??
          data.startColor ??
          theme.getSeriesColor(0);
      final endColor =
          item.endColor ?? data.endColor ?? theme.getSeriesColor(1);
      final connectorColor = item.connectorColor ??
          (item.isPositive
              ? (data.positiveColor ?? Colors.green)
              : (data.negativeColor ?? Colors.red));

      // Calculate position
      final itemCenter = itemSpace * (i + 0.5);

      // Calculate value positions
      final startRatio =
          ((item.startValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
      final endRatio =
          ((item.endValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

      // Apply animation
      final animatedStartRatio = startRatio * animationValue;
      final animatedEndRatio = endRatio * animationValue;

      Offset startPoint;
      Offset endPoint;

      if (isHorizontal) {
        final startX = chartArea.left + animatedStartRatio * chartArea.width;
        final endX = chartArea.left + animatedEndRatio * chartArea.width;
        final y = chartArea.top + itemCenter;

        startPoint = Offset(startX, y);
        endPoint = Offset(endX, y);
      } else {
        final startY = chartArea.bottom - animatedStartRatio * chartArea.height;
        final endY = chartArea.bottom - animatedEndRatio * chartArea.height;
        final x = chartArea.left + itemCenter;

        startPoint = Offset(x, startY);
        endPoint = Offset(x, endY);
      }

      // Draw connector line
      final connectorPaint = Paint()
        ..isAntiAlias = true
        ..color = connectorColor.withValues(alpha: isHovered ? 1.0 : 0.6)
        ..strokeWidth = data.connectorWidth.clamp(2.0, 3.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, connectorPaint);

      // Draw start marker
      final markerSize = isHovered ? data.markerSize * 1.3 : data.markerSize;

      // Draw shadow for start marker
      final startShadowPaint = Paint()
        ..isAntiAlias = true
        ..color = startColor.withValues(alpha: theme.shadowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startPoint.dx, startPoint.dy + 1), markerSize / 2, startShadowPaint);

      final startFillPaint = Paint()
        ..isAntiAlias = true
        ..color = startColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPoint, markerSize / 2, startFillPaint);

      final startBorderPaint = Paint()
        ..isAntiAlias = true
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(startPoint, markerSize / 2, startBorderPaint);

      // Draw shadow for end marker
      final endShadowPaint = Paint()
        ..isAntiAlias = true
        ..color = endColor.withValues(alpha: theme.shadowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endPoint.dx, endPoint.dy + 1), markerSize / 2, endShadowPaint);

      // Draw end marker
      final endFillPaint = Paint()
        ..isAntiAlias = true
        ..color = endColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPoint, markerSize / 2, endFillPaint);

      final endBorderPaint = Paint()
        ..isAntiAlias = true
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(endPoint, markerSize / 2, endBorderPaint);

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, item, chartArea, itemCenter, isHorizontal);
      }

      // Draw difference
      if (data.showDifference) {
        _drawDifference(canvas, item, startPoint, endPoint, isHorizontal, connectorColor);
      }

      // Register hit target (use center of connector)
      final center = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        (startPoint.dy + endPoint.dy) / 2,
      );

      hitTester.addRect(
        rect: Rect.fromCenter(
          center: center,
          width: isHorizontal
              ? (endPoint.dx - startPoint.dx).abs() + data.markerSize
              : data.markerSize * 2,
          height: isHorizontal
              ? data.markerSize * 2
              : (endPoint.dy - startPoint.dy).abs() + data.markerSize,
        ),
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: center,
          xValue: i,
          yValue: item.endValue,
        ),
      );
    }
  }

  void _drawGrid(Canvas canvas, Rect chartArea, double minValue,
      double maxValue, bool isHorizontal,) {
    final paint = Paint()
      ..isAntiAlias = true
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
      double maxValue, bool isHorizontal,) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = theme.axisLineColor
      ..strokeWidth = 1;

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
          style: theme.labelStyle.copyWith(fontSize: labelFontSize * 0.9),
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
          style: theme.labelStyle.copyWith(fontSize: labelFontSize * 0.9),
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

  void _drawLabel(Canvas canvas, DumbbellItem item, Rect chartArea,
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

  void _drawDifference(Canvas canvas, DumbbellItem item, Offset startPoint,
      Offset endPoint, bool isHorizontal, Color color,) {
    final sign = item.isPositive ? '+' : '';
    final textSpan = TextSpan(
      text: '$sign${item.difference.toStringAsFixed(0)}',
      style: theme.labelStyle.copyWith(
        fontSize: labelFontSize * 0.82,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final midPoint = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );

    if (isHorizontal) {
      textPainter.paint(
        canvas,
        Offset(
          midPoint.dx - textPainter.width / 2,
          midPoint.dy - textPainter.height - 4,
        ),
      );
    } else {
      textPainter.paint(
        canvas,
        Offset(
          midPoint.dx + 4,
          midPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DumbbellChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      labelFontSize != oldDelegate.labelFontSize ||
      hitRadius != oldDelegate.hitRadius;
}
