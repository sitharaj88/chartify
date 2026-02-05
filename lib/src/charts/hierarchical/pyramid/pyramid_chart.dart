import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'pyramid_chart_data.dart';

export 'pyramid_chart_data.dart';

/// A pyramid chart widget.
///
/// Displays data as a pyramid shape with sections stacked
/// from smallest (top) to largest (bottom).
///
/// Example:
/// ```dart
/// PyramidChart(
///   data: PyramidChartData(
///     sections: [
///       PyramidSection(label: 'Top', value: 10),
///       PyramidSection(label: 'Middle', value: 30),
///       PyramidSection(label: 'Bottom', value: 60),
///     ],
///   ),
/// )
/// ```
class PyramidChart extends StatefulWidget {
  const PyramidChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onSectionTap,
    this.onSectionHover,
    this.padding = const EdgeInsets.all(24),
  });

  final PyramidChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(PyramidSection section, int index)? onSectionTap;
  final void Function(PyramidSection? section, int? index)? onSectionHover;
  final EdgeInsets padding;

  @override
  State<PyramidChart> createState() => _PyramidChartState();
}

class _PyramidChartState extends State<PyramidChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;
  double _hitRadius = 8.0;

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
  void didUpdateWidget(PyramidChart oldWidget) {
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
      radius: _hitRadius,
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      widget.onSectionHover?.call(widget.data.sections[hitInfo.pointIndex], hitInfo.pointIndex);
    } else {
      _controller.clearHoveredPoint();
      widget.onSectionHover?.call(null, null);
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
        _hitRadius = hitRadius;

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
              if (hitInfo != null && widget.onSectionTap != null) {
                widget.onSectionTap!(widget.data.sections[hitInfo.pointIndex], hitInfo.pointIndex);
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onSectionHover?.call(null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PyramidChartPainter(
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
    final section = widget.data.sections[info.pointIndex];
    final color = section.color ?? theme.getSeriesColor(info.pointIndex);
    final percentage = widget.data.totalValue > 0
        ? (section.value / widget.data.totalValue * 100)
        : 0.0;

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: 'Value',
          value: section.value,
          formattedValue: '${_formatValue(section.value)} (${percentage.toStringAsFixed(1)}%)',
        ),
      ],
      xLabel: section.label,
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _PyramidChartPainter extends ChartPainter {
  _PyramidChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final PyramidChartData data;
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

    if (data.sections.isEmpty) return;

    final sectionCount = data.sections.length;
    final totalGap = data.gap * (sectionCount - 1);
    final availableHeight = chartArea.height - totalGap;

    // Calculate section heights
    List<double> sectionHeights;
    if (data.mode == PyramidMode.equalHeight) {
      final equalHeight = availableHeight / sectionCount;
      sectionHeights = List.filled(sectionCount, equalHeight);
    } else {
      final totalValue = data.totalValue;
      sectionHeights = data.sections.map((s) => totalValue > 0 ? (s.value / totalValue) * availableHeight : availableHeight / sectionCount).toList();
    }

    final centerX = chartArea.center.dx;
    final maxHalfWidth = chartArea.width / 2 * 0.8;

    // Calculate cumulative heights for width calculation
    final totalHeight = sectionHeights.reduce((a, b) => a + b);
    var cumulativeHeight = 0.0;
    var currentY = chartArea.top;

    for (var i = 0; i < sectionCount; i++) {
      final section = data.sections[i];
      final sectionHeight = sectionHeights[i] * animationValue;
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      // Calculate widths based on position in pyramid
      // Top is narrow, bottom is wide
      final topRatio = totalHeight > 0 ? cumulativeHeight / totalHeight : 0.0;
      cumulativeHeight += sectionHeights[i];
      final bottomRatio = totalHeight > 0 ? cumulativeHeight / totalHeight : 1.0;

      final topHalfWidth = maxHalfWidth * topRatio;
      final bottomHalfWidth = maxHalfWidth * bottomRatio;

      // Create trapezoid path
      final path = Path()
        ..moveTo(centerX - topHalfWidth, currentY)
        ..lineTo(centerX + topHalfWidth, currentY)
        ..lineTo(centerX + bottomHalfWidth, currentY + sectionHeight)
        ..lineTo(centerX - bottomHalfWidth, currentY + sectionHeight)
        ..close();

      // Draw section
      final color = section.color ?? theme.getSeriesColor(i);
      _drawSection(canvas, path, color, isHovered);

      // Draw label
      if (data.showLabels) {
        _drawLabel(
          canvas,
          section,
          centerX,
          currentY + sectionHeight / 2,
          maxHalfWidth,
          math.max(topHalfWidth, bottomHalfWidth),
        );
      }

      // Register hit target
      hitTester.addPath(
        path: path,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(centerX, currentY + sectionHeight / 2),
          xValue: section.label,
          yValue: section.value,
        ),
      );

      currentY += sectionHeight + data.gap;
    }
  }

  void _drawSection(Canvas canvas, Path path, Color color, bool isHovered) {
    // Draw shadow behind segment
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((theme.shadowOpacity * 255 * 0.5).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.5)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, shadowPaint);

    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1);
    }

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: isHovered ? 0.9 : 0.8)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(path, borderPaint);

    // Hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, highlightPaint);
    }
  }

  void _drawLabel(
    Canvas canvas,
    PyramidSection section,
    double centerX,
    double y,
    double maxHalfWidth,
    double sectionHalfWidth,
  ) {
    final labelText = data.showValues
        ? '${section.label}: ${_formatValue(section.value)}'
        : section.label;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: labelText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();

    Offset offset;
    switch (data.labelPosition) {
      case PyramidLabelPosition.left:
        offset = Offset(
          centerX - maxHalfWidth - textPainter.width - 16,
          y - textPainter.height / 2,
        );
      case PyramidLabelPosition.right:
        offset = Offset(
          centerX + maxHalfWidth + 16,
          y - textPainter.height / 2,
        );
      case PyramidLabelPosition.inside:
        offset = Offset(
          centerX - textPainter.width / 2,
          y - textPainter.height / 2,
        );
    }

    textPainter.paint(canvas, offset);
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _PyramidChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      labelFontSize != oldDelegate.labelFontSize ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
