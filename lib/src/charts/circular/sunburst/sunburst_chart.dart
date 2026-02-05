import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'sunburst_chart_data.dart';

export 'sunburst_chart_data.dart';

/// A sunburst chart widget.
///
/// Displays hierarchical data as concentric rings where
/// arc size represents value.
///
/// Example:
/// ```dart
/// SunburstChart(
///   data: SunburstChartData(
///     root: SunburstNode(
///       label: 'Root',
///       children: [
///         SunburstNode(label: 'A', value: 10),
///         SunburstNode(label: 'B', value: 20),
///         SunburstNode(label: 'C', value: 15),
///       ],
///     ),
///   ),
/// )
/// ```
class SunburstChart extends StatefulWidget {
  const SunburstChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onArcTap,
    this.onArcHover,
  });

  final SunburstChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(SunburstNode node, int depth)? onArcTap;
  final void Function(SunburstNode? node, int? depth)? onArcHover;

  @override
  State<SunburstChart> createState() => _SunburstChartState();
}

class _SunburstChartState extends State<SunburstChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  List<SunburstArc> _arcCache = [];

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
  void didUpdateWidget(SunburstChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      _arcCache = [];
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
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: 0);
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      final idx = hitInfo.pointIndex;
      if (idx >= 0 && idx < _arcCache.length) {
        final arc = _arcCache[idx];
        widget.onArcHover?.call(arc.node, arc.depth);
      }
    } else {
      _controller.clearHoveredPoint();
      widget.onArcHover?.call(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltip,
          theme: theme,
          chartArea: Rect.fromLTWH(
              0, 0, constraints.maxWidth, constraints.maxHeight,),
          tooltipDataBuilder: (info) => _buildTooltipData(info, theme),
          child: ChartGestureDetector(
            controller: _controller,
            interactions: widget.interactions,
            hitTester: _hitTester,
            onTap: (details) {
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: hitRadius);
              if (hitInfo != null && widget.onArcTap != null) {
                final idx = hitInfo.pointIndex;
                if (idx >= 0 && idx < _arcCache.length) {
                  final arc = _arcCache[idx];
                  widget.onArcTap!(arc.node, arc.depth);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onArcHover?.call(null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SunburstChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  labelFontSize: labelFontSize,
                  onLayoutComplete: (arcs, _) {
                    _arcCache = arcs;
                  },
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
    if (idx < 0 || idx >= _arcCache.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final arc = _arcCache[idx];
    final node = arc.node;
    final color = node.color ?? theme.getSeriesColor(arc.depth);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: node.label,
          value: node.computedValue,
          formattedValue: node.computedValue.toStringAsFixed(1),
        ),
      ],
      xLabel: 'Level: ${arc.depth}',
    );
  }
}

class _SunburstChartPainter extends ChartPainter {
  _SunburstChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.labelFontSize,
    required this.onLayoutComplete,
  }) : super(repaint: controller);

  final SunburstChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final double labelFontSize;
  final void Function(List<SunburstArc>, Offset) onLayoutComplete;

  @override
  Rect getChartArea(Size size) => Rect.fromLTWH(0, 0, size.width, size.height);

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.root.computedValue <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 8;

    // Compute layout
    final arcs = _computeLayout(center, maxRadius);
    onLayoutComplete(arcs, center);

    // Draw arcs (from outer to inner for proper layering)
    final sortedArcs = List<SunburstArc>.from(arcs)
      ..sort((a, b) => b.depth.compareTo(a.depth));

    for (var i = 0; i < sortedArcs.length; i++) {
      final arc = sortedArcs[i];
      final originalIndex = arcs.indexOf(arc);
      final isHovered = controller.hoveredPoint?.pointIndex == originalIndex;

      _drawArc(canvas, center, arc, originalIndex, isHovered);

      // Register hit target (using arc path)
      _registerHitTarget(center, arc, originalIndex);
    }

    // Draw center label
    if (data.showCenterLabel && data.innerRadius > 0) {
      _drawCenterLabel(canvas, center);
    }
  }

  List<SunburstArc> _computeLayout(Offset center, double maxRadius) {
    final result = <SunburstArc>[];
    final totalValue = data.root.computedValue;
    if (totalValue <= 0) return result;

    // Calculate max depth for radius distribution
    final maxDepth = data.maxDepth ?? data.root.depth;
    final availableRadius = maxRadius - data.innerRadius;
    final ringWidth = data.ringWidth > 0
        ? data.ringWidth
        : availableRadius / (maxDepth + 1);

    void layoutNode(
      SunburstNode node,
      double startAngle,
      double sweepAngle,
      int depth,
      SunburstArc? parent,
    ) {
      if (data.maxDepth != null && depth > data.maxDepth!) return;

      const ringGap = 2.0;
      final innerRadius = data.innerRadius + depth * ringWidth;
      final outerRadius = innerRadius + ringWidth - ringGap;

      if (outerRadius > maxRadius) return;

      final arc = SunburstArc(
        node: node,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        depth: depth,
        parent: parent,
      );

      result.add(arc);

      // Layout children
      if (!node.isLeaf && node.children != null) {
        final children = node.children!;
        final nodeValue = node.computedValue;
        var childStartAngle = startAngle;

        for (final child in children) {
          final childValue = child.computedValue;
          final childSweep = (childValue / nodeValue) * sweepAngle;

          // Apply gap
          final adjustedSweep = childSweep - data.gapRadians;
          if (adjustedSweep > 0) {
            layoutNode(
              child,
              childStartAngle + data.gapRadians / 2,
              adjustedSweep,
              depth + 1,
              arc,
            );
          }

          childStartAngle += childSweep;
        }
      }
    }

    // Start from root
    final rootSweep = 2 * math.pi - data.gapRadians;
    layoutNode(data.root, data.startAngle, rootSweep, 0, null);

    return result;
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    SunburstArc arc,
    int index,
    bool isHovered,
  ) {
    if (arc.sweepAngle <= 0) return;

    // Determine color
    Color color;
    if (arc.node.color != null) {
      color = arc.node.color!;
    } else if (data.colorByDepth) {
      color = theme.getSeriesColor(arc.depth);
    } else {
      color = theme.getSeriesColor(index % 10);
    }

    // Animate sweep angle
    final animatedSweep = arc.sweepAngle * animationValue;

    // Create arc path
    final path = _createArcPath(
      center,
      arc.innerRadius,
      arc.outerRadius,
      arc.startAngle,
      animatedSweep,
    );

    // Draw fill
    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1);
    }

    // Draw shadow on outer segments (leaf nodes or max depth)
    if (arc.node.isLeaf || (data.maxDepth != null && arc.depth == data.maxDepth)) {
      final shadowPaint = Paint()
        ..color = Colors.black.withAlpha((theme.shadowOpacity * 255 * 0.5).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.save();
      canvas.translate(1, 2);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = theme.backgroundColor.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(path, borderPaint);

    // Draw hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, highlightPaint);
    }

    // Draw label
    if (data.showLabels && data.labelPosition != SunburstLabelPosition.none) {
      if (animatedSweep >= data.minLabelAngle) {
        _drawLabel(canvas, center, arc, color);
      }
    }
  }

  Path _createArcPath(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    final path = Path();

    if (innerRadius <= 0) {
      // Draw as pie slice
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
    } else {
      // Draw as ring segment
      final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

      // Outer arc
      path.arcTo(outerRect, startAngle, sweepAngle, true);

      // Line to inner arc end
      final innerEndX = center.dx + innerRadius * math.cos(startAngle + sweepAngle);
      final innerEndY = center.dy + innerRadius * math.sin(startAngle + sweepAngle);
      path.lineTo(innerEndX, innerEndY);

      // Inner arc (reverse direction)
      path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);

      path.close();
    }

    return path;
  }

  void _registerHitTarget(Offset center, SunburstArc arc, int index) {
    // Create hit path
    final path = _createArcPath(
      center,
      arc.innerRadius,
      arc.outerRadius,
      arc.startAngle,
      arc.sweepAngle,
    );

    // Calculate center point of arc for tooltip position
    final midAngle = arc.midAngle;
    final midRadius = arc.midRadius;
    final position = Offset(
      center.dx + midRadius * math.cos(midAngle),
      center.dy + midRadius * math.sin(midAngle),
    );

    hitTester.addPath(
      path: path,
      info: DataPointInfo(
        seriesIndex: arc.depth,
        pointIndex: index,
        position: position,
        xValue: arc.depth,
        yValue: arc.node.computedValue,
      ),
    );
  }

  void _drawLabel(Canvas canvas, Offset center, SunburstArc arc, Color bgColor) {
    final midAngle = arc.midAngle;
    final midRadius = arc.midRadius;

    // Calculate label position
    final labelX = center.dx + midRadius * math.cos(midAngle);
    final labelY = center.dy + midRadius * math.sin(midAngle);

    // Determine text color based on background
    final textColor = _getContrastColor(bgColor);
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: textColor,
    );

    final textSpan = TextSpan(text: arc.node.label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '.',
    )..layout(maxWidth: arc.outerRadius - arc.innerRadius);

    // Check if text fits in arc
    final arcLength = arc.sweepAngle * midRadius;
    if (textPainter.width > arcLength * 0.8) return;

    canvas.save();
    canvas.translate(labelX, labelY);

    if (data.labelPosition == SunburstLabelPosition.tangential) {
      // Rotate text to follow arc
      var rotationAngle = midAngle + math.pi / 2;
      // Flip text if it would be upside down
      if (midAngle > math.pi / 2 && midAngle < 3 * math.pi / 2) {
        rotationAngle += math.pi;
      }
      canvas.rotate(rotationAngle);
    } else if (data.labelPosition == SunburstLabelPosition.radial) {
      // Point text outward
      var rotationAngle = midAngle;
      if (midAngle > math.pi / 2 && midAngle < 3 * math.pi / 2) {
        rotationAngle += math.pi;
      }
      canvas.rotate(rotationAngle);
    }

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  void _drawCenterLabel(Canvas canvas, Offset center) {
    final textStyle = data.centerLabelStyle ??
        theme.labelStyle.copyWith(
          fontSize: labelFontSize * 1.4,
          fontWeight: FontWeight.bold,
        );

    final textSpan = TextSpan(text: data.root.label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: data.innerRadius * 1.5);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _SunburstChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      labelFontSize != oldDelegate.labelFontSize ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
