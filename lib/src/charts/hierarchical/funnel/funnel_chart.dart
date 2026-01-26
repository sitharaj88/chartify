import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'funnel_chart_data.dart';

export 'funnel_chart_data.dart';

/// A funnel chart widget.
///
/// Displays data as a funnel shape, commonly used for
/// showing conversion rates in sales or marketing pipelines.
///
/// Example:
/// ```dart
/// FunnelChart(
///   data: FunnelChartData(
///     sections: [
///       FunnelSection(label: 'Visitors', value: 1000),
///       FunnelSection(label: 'Leads', value: 400),
///       FunnelSection(label: 'Prospects', value: 200),
///       FunnelSection(label: 'Sales', value: 50),
///     ],
///   ),
/// )
/// ```
class FunnelChart extends StatefulWidget {
  const FunnelChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onSectionTap,
    this.onSectionHover,
    this.padding = const EdgeInsets.all(24),
  });

  final FunnelChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(FunnelSection section, int index)? onSectionTap;
  final void Function(FunnelSection? section, int? index)? onSectionHover;
  final EdgeInsets padding;

  @override
  State<FunnelChart> createState() => _FunnelChartState();
}

class _FunnelChartState extends State<FunnelChart>
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
  void didUpdateWidget(FunnelChart oldWidget) {
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
                painter: _FunnelChartPainter(
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
    final section = widget.data.sections[info.pointIndex];
    final color = section.color ?? theme.getSeriesColor(info.pointIndex);

    final entries = <TooltipEntry>[
      TooltipEntry(
        color: color,
        label: 'Value',
        value: section.value,
        formattedValue: _formatValue(section.value),
      ),
    ];

    // Add conversion rate if not first section
    if (widget.data.showConversionRate && info.pointIndex > 0) {
      final rate = widget.data.conversionRate(0, info.pointIndex);
      entries.add(TooltipEntry(
        color: color,
        label: 'Overall Rate',
        value: rate,
        formattedValue: '${rate.toStringAsFixed(1)}%',
      ));
    }

    return TooltipData(
      position: info.position,
      entries: entries,
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

class _FunnelChartPainter extends ChartPainter {
  _FunnelChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
  }) : super(repaint: controller);

  final FunnelChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;

  @override
  Rect getChartArea(Size size) {
    return Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.sections.isEmpty) return;

    final isVertical = data.orientation == FunnelOrientation.vertical;

    if (isVertical) {
      _paintVerticalFunnel(canvas, chartArea);
    } else {
      _paintHorizontalFunnel(canvas, chartArea);
    }
  }

  void _paintVerticalFunnel(Canvas canvas, Rect chartArea) {
    final sectionCount = data.sections.length;
    final totalGap = data.gap * (sectionCount - 1);
    final availableHeight = chartArea.height - totalGap;

    // Calculate section heights
    List<double> sectionHeights;
    if (data.mode == FunnelMode.equalHeight) {
      final equalHeight = availableHeight / sectionCount;
      sectionHeights = List.filled(sectionCount, equalHeight);
    } else {
      final totalValue = data.totalValue;
      sectionHeights = data.sections.map((s) {
        return totalValue > 0 ? (s.value / totalValue) * availableHeight : availableHeight / sectionCount;
      }).toList();
    }

    // Calculate widths based on values
    final maxValue = data.sections.map((s) => s.value).reduce(math.max);
    final centerX = chartArea.center.dx;
    final maxHalfWidth = chartArea.width / 2 * 0.8; // Leave space for labels

    var currentY = chartArea.top;

    for (var i = 0; i < sectionCount; i++) {
      final section = data.sections[i];
      final sectionHeight = sectionHeights[i] * animationValue;
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      // Calculate widths at top and bottom of section
      final topWidthRatio = maxValue > 0 ? section.value / maxValue : 1;
      final bottomWidthRatio = i < sectionCount - 1
          ? (maxValue > 0 ? data.sections[i + 1].value / maxValue : 1)
          : data.neckWidth;

      final topHalfWidth = maxHalfWidth * topWidthRatio;
      final bottomHalfWidth = maxHalfWidth * bottomWidthRatio;

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
        _drawVerticalLabel(
          canvas,
          section,
          i,
          centerX,
          currentY + sectionHeight / 2,
          maxHalfWidth,
          topHalfWidth,
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

  void _paintHorizontalFunnel(Canvas canvas, Rect chartArea) {
    final sectionCount = data.sections.length;
    final totalGap = data.gap * (sectionCount - 1);
    final availableWidth = chartArea.width - totalGap;

    // Calculate section widths
    List<double> sectionWidths;
    if (data.mode == FunnelMode.equalHeight) {
      final equalWidth = availableWidth / sectionCount;
      sectionWidths = List.filled(sectionCount, equalWidth);
    } else {
      final totalValue = data.totalValue;
      sectionWidths = data.sections.map((s) {
        return totalValue > 0 ? (s.value / totalValue) * availableWidth : availableWidth / sectionCount;
      }).toList();
    }

    // Calculate heights based on values
    final maxValue = data.sections.map((s) => s.value).reduce(math.max);
    final centerY = chartArea.center.dy;
    final maxHalfHeight = chartArea.height / 2 * 0.7;

    var currentX = chartArea.left;

    for (var i = 0; i < sectionCount; i++) {
      final section = data.sections[i];
      final sectionWidth = sectionWidths[i] * animationValue;
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      // Calculate heights at left and right of section
      final leftHeightRatio = maxValue > 0 ? section.value / maxValue : 1;
      final rightHeightRatio = i < sectionCount - 1
          ? (maxValue > 0 ? data.sections[i + 1].value / maxValue : 1)
          : data.neckWidth;

      final leftHalfHeight = maxHalfHeight * leftHeightRatio;
      final rightHalfHeight = maxHalfHeight * rightHeightRatio;

      // Create trapezoid path
      final path = Path()
        ..moveTo(currentX, centerY - leftHalfHeight)
        ..lineTo(currentX + sectionWidth, centerY - rightHalfHeight)
        ..lineTo(currentX + sectionWidth, centerY + rightHalfHeight)
        ..lineTo(currentX, centerY + leftHalfHeight)
        ..close();

      // Draw section
      final color = section.color ?? theme.getSeriesColor(i);
      _drawSection(canvas, path, color, isHovered);

      // Register hit target
      hitTester.addPath(
        path: path,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(currentX + sectionWidth / 2, centerY),
          xValue: section.label,
          yValue: section.value,
        ),
      );

      currentX += sectionWidth + data.gap;
    }
  }

  void _drawSection(Canvas canvas, Path path, Color color, bool isHovered) {
    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1.0);
    }

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: isHovered ? 0.9 : 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, borderPaint);

    // Hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, highlightPaint);
    }
  }

  void _drawVerticalLabel(
    Canvas canvas,
    FunnelSection section,
    int index,
    double centerX,
    double y,
    double maxHalfWidth,
    double sectionHalfWidth,
  ) {
    final labelText = data.showValues
        ? '${section.label}: ${_formatValue(section.value)}'
        : section.label;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 12,
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
      case FunnelLabelPosition.left:
        offset = Offset(
          centerX - maxHalfWidth - textPainter.width - 16,
          y - textPainter.height / 2,
        );
      case FunnelLabelPosition.right:
        offset = Offset(
          centerX + maxHalfWidth + 16,
          y - textPainter.height / 2,
        );
      case FunnelLabelPosition.inside:
        offset = Offset(
          centerX - textPainter.width / 2,
          y - textPainter.height / 2,
        );
    }

    textPainter.paint(canvas, offset);

    // Draw conversion rate
    if (data.showConversionRate && index > 0) {
      final rate = data.conversionRate(index - 1, index);
      final rateText = '${rate.toStringAsFixed(1)}%';
      final rateStyle = theme.labelStyle.copyWith(
        fontSize: 10,
        color: theme.labelStyle.color?.withValues(alpha: 0.7),
      );

      final rateSpan = TextSpan(text: rateText, style: rateStyle);
      final ratePainter = TextPainter(
        text: rateSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      )..layout();

      final rateOffset = Offset(
        offset.dx,
        offset.dy + textPainter.height + 2,
      );
      ratePainter.paint(canvas, rateOffset);
    }
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
  bool shouldRepaint(covariant _FunnelChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
