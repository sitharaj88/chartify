import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'pie_chart_data.dart';

/// A pie chart widget.
///
/// Displays data as proportional slices of a circle.
/// Set holeRadius > 0 for a donut chart.
///
/// Example:
/// ```dart
/// PieChart(
///   data: PieChartData(
///     sections: [
///       PieSection(value: 40, label: 'Mobile', color: Colors.blue),
///       PieSection(value: 30, label: 'Desktop', color: Colors.green),
///       PieSection(value: 30, label: 'Tablet', color: Colors.orange),
///     ],
///   ),
/// )
/// ```
class PieChart extends StatefulWidget {
  const PieChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.tooltip = const TooltipConfig(),
    this.onSectionTap,
    this.onSectionHover,
    this.centerWidget,
  });

  final PieChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final TooltipConfig tooltip;
  final void Function(int sectionIndex, PieSection section)? onSectionTap;
  final void Function(int? sectionIndex, PieSection? section)? onSectionHover;
  final Widget? centerWidget;

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart>
    with TickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;

  // Hover animation
  AnimationController? _hoverController;
  Animation<double>? _hoverAnimation;
  int? _hoveredIndex;
  double _hoverScale = 0;

  ChartAnimation get _animationConfig =>
      widget.animation ?? widget.data.animation ?? const ChartAnimation();

  @override
  void initState() {
    super.initState();
    _initController();
    _initAnimation();
    _initHoverAnimation();
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

  void _initHoverAnimation() {
    _hoverController = AnimationController(
      vsync: this,
      duration: widget.data.hoverDuration,
    );

    _hoverAnimation = CurvedAnimation(
      parent: _hoverController!,
      curve: Curves.easeOutCubic,
    );

    _hoverController!.addListener(() {
      if (mounted) {
        setState(() {
          _hoverScale = _hoverAnimation!.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(PieChart oldWidget) {
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

    if (widget.data.hoverDuration != oldWidget.data.hoverDuration) {
      _hoverController?.duration = widget.data.hoverDuration;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _hoverController?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(TapDownDetails details, double hitRadius) {
    final hitInfo = _hitTester.hitTest(details.localPosition, radius: hitRadius);
    if (hitInfo != null && widget.onSectionTap != null) {
      widget.onSectionTap!(hitInfo.pointIndex, widget.data.sections[hitInfo.pointIndex]);
    }
  }

  void _handleHover(PointerEvent event, double hitRadius) {
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: hitRadius);
    if (hitInfo != null) {
      if (_hoveredIndex != hitInfo.pointIndex) {
        _hoveredIndex = hitInfo.pointIndex;
        _hoverController?.forward(from: 0);
      }
      _controller.setHoveredPoint(hitInfo);
      widget.onSectionHover?.call(hitInfo.pointIndex, widget.data.sections[hitInfo.pointIndex]);
    } else {
      if (_hoveredIndex != null) {
        _hoveredIndex = null;
        _hoverController?.reverse();
      }
      _controller.clearHoveredPoint();
      widget.onSectionHover?.call(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelFontSize = getScaledFontSize(context, 12.0);
        final hitRadius = getHitTestRadius(context, constraints);

        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final minDimension = math.min(size.width, size.height);
        final center = Offset(size.width / 2, size.height / 2);
        final radius = minDimension / 2 - 40;

        _chartArea = Rect.fromCircle(center: center, radius: radius);

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltip,
          theme: theme,
          chartArea: _chartArea,
          tooltipDataBuilder: (info) => _buildTooltipData(info, theme),
          child: MouseRegion(
            onHover: (event) => _handleHover(event, hitRadius),
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onSectionHover?.call(null, null);
            },
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details, hitRadius),
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        data: widget.data,
                        theme: theme,
                        animationValue: _animation?.value ?? 1.0,
                        controller: _controller,
                        hitTester: _hitTester,
                        hoverScale: _hoverScale,
                        labelFontSize: labelFontSize,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  if (widget.centerWidget != null && widget.data.holeRadius > 0)
                    Positioned.fill(
                      child: Center(child: widget.centerWidget),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TooltipData _buildTooltipData(DataPointInfo info, ChartThemeData theme) {
    final section = widget.data.sections[info.pointIndex];
    final percentage = (section.value / widget.data.total * 100).toStringAsFixed(1);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: section.color ?? theme.getSeriesColor(info.pointIndex),
          label: section.label ?? 'Section ${info.pointIndex + 1}',
          value: section.value,
          formattedValue: '${section.value.toStringAsFixed(0)} ($percentage%)',
        ),
      ],
    );
  }
}

class _PieChartPainter extends CircularChartPainter {
  _PieChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.hoverScale,
    this.labelFontSize = 12.0,
  }) : super(innerRadiusRatio: 0, startAngle: data.startAngle);

  final PieChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final double hoverScale;
  final double labelFontSize;

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.sections.isEmpty) return;

    final center = chartArea.center;
    final outerRadius = chartArea.width / 2;
    // holeRadius: if <= 1, treat as ratio; if > 1, treat as pixels
    final innerRadius = data.holeRadius <= 1
        ? outerRadius * data.holeRadius
        : data.holeRadius.clamp(0.0, outerRadius - 10);

    final total = data.total;
    if (total <= 0) return;

    // Calculate gap in radians
    final gapRadians = data.segmentGap / outerRadius;

    var currentAngle = degreesToRadians(startAngle);

    // First pass: draw shadows
    if (data.enableShadows) {
      var shadowAngle = currentAngle;
      for (var i = 0; i < data.sections.length; i++) {
        final section = data.sections[i];
        final baseSweepAngle = (section.value / total) * 2 * math.pi * animationValue;
        final sweepAngle = baseSweepAngle - gapRadians;
        final adjustedStart = shadowAngle + (gapRadians / 2);

        final isHovered = controller.hoveredPoint?.pointIndex == i;
        // Smooth hover animation for explode offset
        final targetOffset = isHovered ? 10.0 : section.explodeOffset;
        final explodeOffset = isHovered ? targetOffset * hoverScale : targetOffset;

        final midAngle = shadowAngle + baseSweepAngle / 2;
        final explodeX = explodeOffset * math.cos(midAngle);
        final explodeY = explodeOffset * math.sin(midAngle);
        final sectionCenter = Offset(center.dx + explodeX, center.dy + explodeY);

        final path = _buildSectionPath(sectionCenter, innerRadius, outerRadius, adjustedStart, sweepAngle);
        _drawSectionShadow(canvas, path, section.shadowElevation);

        shadowAngle += baseSweepAngle;
      }
    }

    // Second pass: draw sections
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final baseSweepAngle = (section.value / total) * 2 * math.pi * animationValue;
      final sweepAngle = baseSweepAngle - gapRadians;
      final adjustedStart = currentAngle + (gapRadians / 2);

      final isHovered = controller.hoveredPoint?.pointIndex == i;
      // Smooth hover animation for explode offset
      final targetOffset = isHovered ? 10.0 : section.explodeOffset;
      final explodeOffset = isHovered ? targetOffset * hoverScale : targetOffset;

      // Calculate explode offset
      final midAngle = currentAngle + baseSweepAngle / 2;
      final explodeX = explodeOffset * math.cos(midAngle);
      final explodeY = explodeOffset * math.sin(midAngle);
      final sectionCenter = Offset(center.dx + explodeX, center.dy + explodeY);

      // Draw section
      final color = section.color ?? theme.getSeriesColor(i);
      _drawSection(
        canvas,
        sectionCenter,
        innerRadius,
        outerRadius,
        adjustedStart,
        sweepAngle,
        color,
        section,
        isHovered,
      );

      // Register hit target using arc-based hit testing (optimal for circular charts)
      _registerHitTarget(
        center,
        innerRadius,
        outerRadius,
        currentAngle,
        baseSweepAngle,
        i,
        section,
      );

      currentAngle += baseSweepAngle;
    }

    // Draw stroke between sections (only if no segment gaps)
    if (data.strokeWidth > 0 && data.segmentGap <= 0) {
      _drawStrokes(canvas, center, innerRadius, outerRadius);
    }

    // Draw labels
    if (data.showLabels && data.labelPosition != PieLabelPosition.none) {
      _drawLabels(canvas, center, outerRadius);
    }
  }

  void _drawSectionShadow(Canvas canvas, Path path, double elevation) {
    if (elevation <= 0) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation * 1.5);

    canvas.save();
    canvas.translate(elevation * 0.3, elevation * 0.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
  }

  Path _buildSectionPath(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    final path = Path();

    if (innerRadius > 0) {
      // Donut
      path.moveTo(
        center.dx + innerRadius * math.cos(startAngle),
        center.dy + innerRadius * math.sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.lineTo(
        center.dx + outerRadius * math.cos(startAngle + sweepAngle),
        center.dy + outerRadius * math.sin(startAngle + sweepAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();
    } else {
      // Full pie
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + outerRadius * math.cos(startAngle),
        center.dy + outerRadius * math.sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
    }

    return path;
  }

  void _drawSection(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    PieSection section,
    bool isHovered,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Apply gradient if available, otherwise use solid color
    if (section.gradient != null) {
      final rect = Rect.fromCircle(center: center, radius: outerRadius);
      paint.shader = section.gradient!.createShader(rect);
    } else {
      paint.color = isHovered ? color.withValues(alpha: 0.85) : color;
    }

    final path = _buildSectionPath(center, innerRadius, outerRadius, startAngle, sweepAngle);

    canvas.drawPath(path, paint);

    // Draw border
    if (section.borderWidth > 0 && section.borderColor != null) {
      final borderPaint = Paint()
        ..color = section.borderColor!
        ..strokeWidth = section.borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  void _registerHitTarget(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    int index,
    PieSection section,
  ) {
    // Calculate center point of the section for tooltip positioning
    final midAngle = startAngle + sweepAngle / 2;
    final midRadius = (innerRadius + outerRadius) / 2;
    final hitPoint = Offset(
      center.dx + midRadius * math.cos(midAngle),
      center.dy + midRadius * math.sin(midAngle),
    );

    // Use arc-based hit testing (ChartHitTester.addArc) which is optimal
    // for circular charts - tests angle ranges rather than bounding boxes
    hitTester.addArc(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      info: DataPointInfo(
        seriesIndex: 0,
        pointIndex: index,
        position: hitPoint,
        xValue: section.label,
        yValue: section.value,
        seriesName: section.label,
      ),
    );
  }

  void _drawStrokes(Canvas canvas, Offset center, double innerRadius, double outerRadius) {
    final total = data.total;
    if (total <= 0) return;

    final strokePaint = Paint()
      ..color = data.strokeColor ?? Colors.white
      ..strokeWidth = data.strokeWidth
      ..style = PaintingStyle.stroke;

    var currentAngle = degreesToRadians(startAngle);

    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final sweepAngle = (section.value / total) * 2 * math.pi * animationValue;

      // Draw line from inner to outer at start of section
      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(currentAngle),
        center.dy + innerRadius * math.sin(currentAngle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(currentAngle),
        center.dy + outerRadius * math.sin(currentAngle),
      );
      canvas.drawLine(innerPoint, outerPoint, strokePaint);

      currentAngle += sweepAngle;
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double outerRadius) {
    final total = data.total;
    if (total <= 0) return;

    // Minimum percentage threshold for showing labels (2%)
    const minLabelThreshold = 0.02;

    final textStyle = data.labelStyle ?? theme.labelStyle.copyWith(fontSize: labelFontSize);

    // First pass: calculate all label positions and bounds
    final labelInfos = <_LabelInfo>[];
    var currentAngle = degreesToRadians(startAngle);

    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final sweepAngle = (section.value / total) * 2 * math.pi * animationValue;
      final midAngle = currentAngle + sweepAngle / 2;
      final percentage = section.value / total;

      // Skip labels for sections below threshold or without labels
      if (section.label == null || percentage < minLabelThreshold) {
        currentAngle += sweepAngle;
        continue;
      }

      final percentageStr = (percentage * 100).toStringAsFixed(1);
      final labelText = '${section.label!}\n$percentageStr%';

      // Calculate label size
      final textSpan = TextSpan(text: labelText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      Offset labelPos;
      var isRightSide = true;

      if (data.labelPosition == PieLabelPosition.inside) {
        final labelRadius = outerRadius * 0.7;
        labelPos = Offset(
          center.dx + labelRadius * math.cos(midAngle),
          center.dy + labelRadius * math.sin(midAngle),
        );
      } else {
        // Outside label position
        const elbowLength = 20.0;
        const horizontalLength = 15.0;
        isRightSide = midAngle > -math.pi / 2 && midAngle < math.pi / 2;

        final elbowPoint = Offset(
          center.dx + (outerRadius + elbowLength) * math.cos(midAngle),
          center.dy + (outerRadius + elbowLength) * math.sin(midAngle),
        );
        labelPos = Offset(
          elbowPoint.dx + (isRightSide ? horizontalLength + 4 : -horizontalLength - textPainter.width - 4),
          elbowPoint.dy,
        );
      }

      final bounds = Rect.fromCenter(
        center: labelPos,
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      );

      labelInfos.add(_LabelInfo(
        index: i,
        section: section,
        midAngle: midAngle,
        labelText: labelText,
        position: labelPos,
        bounds: bounds,
        textPainter: textPainter,
        isRightSide: isRightSide,
        visible: true,
      ),);

      currentAngle += sweepAngle;
    }

    // Second pass: detect and resolve collisions for outside labels
    if (data.labelPosition != PieLabelPosition.inside) {
      _resolveCollisions(labelInfos, center, outerRadius);
    }

    // Third pass: draw visible labels
    for (final info in labelInfos) {
      if (!info.visible) continue;

      if (data.labelPosition == PieLabelPosition.inside) {
        _drawText(canvas, info.labelText, info.position, textStyle);
      } else {
        _drawLabelWithConnector(
          canvas,
          center,
          outerRadius,
          info,
          textStyle,
        );
      }
    }
  }

  /// Resolves label collisions by adjusting vertical positions.
  void _resolveCollisions(List<_LabelInfo> labels, Offset center, double outerRadius) {
    // Separate left and right side labels
    final rightLabels = labels.where((l) => l.isRightSide).toList();
    final leftLabels = labels.where((l) => !l.isRightSide).toList();

    // Sort by Y position
    rightLabels.sort((a, b) => a.position.dy.compareTo(b.position.dy));
    leftLabels.sort((a, b) => a.position.dy.compareTo(b.position.dy));

    // Resolve collisions on each side
    _resolveOneSide(rightLabels, center, outerRadius, isRight: true);
    _resolveOneSide(leftLabels, center, outerRadius, isRight: false);
  }

  void _resolveOneSide(List<_LabelInfo> labels, Offset center, double outerRadius, {required bool isRight}) {
    if (labels.isEmpty) return;

    const minSpacing = 4.0;
    const maxIterations = 10;

    for (var iter = 0; iter < maxIterations; iter++) {
      var hasCollision = false;

      for (var i = 0; i < labels.length - 1; i++) {
        final current = labels[i];
        final next = labels[i + 1];

        if (!current.visible || !next.visible) continue;

        final overlap = (current.bounds.bottom + minSpacing) - next.bounds.top;
        if (overlap > 0) {
          hasCollision = true;
          // Push labels apart
          final adjustment = overlap / 2;
          current.position = Offset(current.position.dx, current.position.dy - adjustment);
          next.position = Offset(next.position.dx, next.position.dy + adjustment);

          // Update bounds
          current.bounds = Rect.fromCenter(
            center: current.position,
            width: current.bounds.width,
            height: current.bounds.height,
          );
          next.bounds = Rect.fromCenter(
            center: next.position,
            width: next.bounds.width,
            height: next.bounds.height,
          );
        }
      }

      if (!hasCollision) break;
    }

    // Hide labels that would go too far outside the chart area
    final maxDistance = outerRadius * 2;
    for (final label in labels) {
      if ((label.position.dy - center.dy).abs() > maxDistance) {
        label.visible = false;
      }
    }
  }

  void _drawLabelWithConnector(
    Canvas canvas,
    Offset center,
    double outerRadius,
    _LabelInfo info,
    TextStyle style,
  ) {
    // Start point on pie edge
    final startPoint = Offset(
      center.dx + outerRadius * math.cos(info.midAngle),
      center.dy + outerRadius * math.sin(info.midAngle),
    );

    // Elbow point
    const elbowLength = 20.0;
    final elbowPoint = Offset(
      center.dx + (outerRadius + elbowLength) * math.cos(info.midAngle),
      center.dy + (outerRadius + elbowLength) * math.sin(info.midAngle),
    );

    // End point (adjusted Y for collision resolution)
    const horizontalLength = 15.0;
    final labelPoint = Offset(
      elbowPoint.dx + (info.isRightSide ? horizontalLength : -horizontalLength),
      info.position.dy,
    );

    // Draw connector lines
    final linePaint = Paint()
      ..color = style.color ?? Colors.grey
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(startPoint, elbowPoint, linePaint);
    canvas.drawLine(elbowPoint, labelPoint, linePaint);

    // Draw label
    final textOffset = Offset(
      info.isRightSide ? labelPoint.dx + 4 : labelPoint.dx - info.textPainter.width - 4,
      labelPoint.dy - info.textPainter.height / 2,
    );
    info.textPainter.paint(canvas, textOffset);
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      hoverScale != oldDelegate.hoverScale ||
      labelFontSize != oldDelegate.labelFontSize;
}

/// Helper class for label collision detection.
class _LabelInfo {
  _LabelInfo({
    required this.index,
    required this.section,
    required this.midAngle,
    required this.labelText,
    required this.position,
    required this.bounds,
    required this.textPainter,
    required this.isRightSide,
    required this.visible,
  });

  final int index;
  final PieSection section;
  final double midAngle;
  final String labelText;
  Offset position;
  Rect bounds;
  final TextPainter textPainter;
  final bool isRightSide;
  bool visible;
}

/// A donut chart widget (pie chart with a hole in the center).
///
/// This is a convenience widget that creates a PieChart with holeRadius > 0.
///
/// Example:
/// ```dart
/// DonutChart(
///   data: PieChartData(
///     sections: [
///       PieSection(value: 40, label: 'Mobile'),
///       PieSection(value: 30, label: 'Desktop'),
///       PieSection(value: 30, label: 'Tablet'),
///     ],
///     holeRadius: 0.6,
///   ),
///   centerWidget: Text('Total\n100'),
/// )
/// ```
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.tooltip = const TooltipConfig(),
    this.onSectionTap,
    this.onSectionHover,
    this.centerWidget,
  });

  final PieChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final TooltipConfig tooltip;
  final void Function(int sectionIndex, PieSection section)? onSectionTap;
  final void Function(int? sectionIndex, PieSection? section)? onSectionHover;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    // Ensure holeRadius is set for donut effect
    final donutData = data.holeRadius > 0
        ? data
        : data.copyWith(holeRadius: 0.5);

    return PieChart(
      data: donutData,
      controller: controller,
      animation: animation,
      tooltip: tooltip,
      onSectionTap: onSectionTap,
      onSectionHover: onSectionHover,
      centerWidget: centerWidget,
    );
  }
}
