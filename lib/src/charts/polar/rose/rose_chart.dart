import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'rose_chart_data.dart';

export 'rose_chart_data.dart';

/// A rose/polar chart widget.
///
/// Displays data as segments radiating from a center point,
/// with segment length proportional to value.
///
/// Example:
/// ```dart
/// RoseChart(
///   data: RoseChartData(
///     segments: [
///       RoseSegment(label: 'N', value: 30),
///       RoseSegment(label: 'NE', value: 50),
///       RoseSegment(label: 'E', value: 20),
///       RoseSegment(label: 'SE', value: 40),
///       RoseSegment(label: 'S', value: 60),
///       RoseSegment(label: 'SW', value: 25),
///       RoseSegment(label: 'W', value: 35),
///       RoseSegment(label: 'NW', value: 45),
///     ],
///   ),
/// )
/// ```
class RoseChart extends StatefulWidget {
  const RoseChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onSegmentTap,
    this.padding = const EdgeInsets.all(24),
  });

  final RoseChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, RoseSegment segment)? onSegmentTap;
  final EdgeInsets padding;

  @override
  State<RoseChart> createState() => _RoseChartState();
}

class _RoseChartState extends State<RoseChart>
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
  void didUpdateWidget(RoseChart oldWidget) {
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
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: hitRadius);
              if (hitInfo != null && widget.onSegmentTap != null) {
                final idx = hitInfo.pointIndex;
                if (idx >= 0 && idx < widget.data.segments.length) {
                  widget.onSegmentTap!(idx, widget.data.segments[idx]);
                }
              }
            },
            onHover: (event) {
              final hitInfo = _hitTester.hitTest(event.localPosition, radius: hitRadius);
              if (hitInfo != null) {
                _controller.setHoveredPoint(hitInfo);
              } else {
                _controller.clearHoveredPoint();
              }
            },
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _RoseChartPainter(
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
    final idx = info.pointIndex;
    if (idx < 0 || idx >= widget.data.segments.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final segment = widget.data.segments[idx];
    final color = segment.color ?? theme.getSeriesColor(idx);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: segment.label,
          value: segment.value,
          formattedValue: segment.value.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class _RoseChartPainter extends ChartPainter {
  _RoseChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final RoseChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;

  @override
  Rect getChartArea(Size size) => Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.segments.isEmpty) return;

    final center = chartArea.center;
    final maxRadius = math.min(chartArea.width, chartArea.height) / 2 -
        (data.showLabels ? 30 : 0);
    final maxValue = data.computedMaxValue;

    final segmentCount = data.segments.length;
    final sweepAngle = (2 * math.pi - segmentCount * data.gapRadians) / segmentCount;

    // Draw grid circles
    _drawGrid(canvas, center, maxRadius);

    var currentAngle = data.startAngle;

    for (var i = 0; i < segmentCount; i++) {
      final segment = data.segments[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = segment.color ?? theme.getSeriesColor(i);

      // Calculate radius based on value
      final valueRatio = (segment.value / maxValue).clamp(0.0, 1.0);
      final outerRadius =
          data.innerRadius + (maxRadius - data.innerRadius) * valueRatio * animationValue;

      // Draw segment
      _drawSegment(
        canvas,
        center,
        data.innerRadius,
        outerRadius,
        currentAngle,
        sweepAngle,
        color,
        isHovered,
      );

      // Draw label
      if (data.showLabels) {
        _drawLabel(
          canvas,
          segment,
          center,
          maxRadius + 15,
          currentAngle + sweepAngle / 2,
        );
      }

      // Draw value
      if (data.showValues && outerRadius > data.innerRadius + 20) {
        _drawValue(
          canvas,
          segment,
          center,
          (data.innerRadius + outerRadius) / 2,
          currentAngle + sweepAngle / 2,
        );
      }

      // Register hit target
      hitTester.addArc(
        center: center,
        innerRadius: data.innerRadius,
        outerRadius: maxRadius,
        startAngle: currentAngle,
        sweepAngle: sweepAngle,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(
            center.dx + (data.innerRadius + outerRadius) / 2 * math.cos(currentAngle + sweepAngle / 2),
            center.dy + (data.innerRadius + outerRadius) / 2 * math.sin(currentAngle + sweepAngle / 2),
          ),
          xValue: i,
          yValue: segment.value,
        ),
      );

      currentAngle += sweepAngle + data.gapRadians;
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double maxRadius) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    const circles = 4;
    for (var i = 1; i <= circles; i++) {
      final radius = maxRadius * i / circles;
      canvas.drawCircle(center, radius, paint);
    }

    // Draw radial lines
    final segmentCount = data.segments.length;
    final angleStep = 2 * math.pi / segmentCount;
    var angle = data.startAngle;

    for (var i = 0; i < segmentCount; i++) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + maxRadius * math.cos(angle),
          center.dy + maxRadius * math.sin(angle),
        ),
        paint,
      );
      angle += angleStep;
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    bool isHovered,
  ) {
    final path = Path();

    if (innerRadius > 0) {
      // Draw arc with inner radius (donut style)
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();
    } else {
      // Draw pie slice
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
    }

    // Fill
    final fillPaint = Paint()
      ..color = isHovered ? color : color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..strokeWidth = isHovered ? 2 : 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  void _drawLabel(
    Canvas canvas,
    RoseSegment segment,
    Offset center,
    double radius,
    double angle,
  ) {
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    final textSpan = TextSpan(
      text: segment.label,
      style: theme.labelStyle.copyWith(fontSize: labelFontSize),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  void _drawValue(
    Canvas canvas,
    RoseSegment segment,
    Offset center,
    double radius,
    double angle,
  ) {
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    final textSpan = TextSpan(
      text: segment.value.toStringAsFixed(0),
      style: theme.labelStyle.copyWith(
        fontSize: labelFontSize * 10 / 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RoseChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
