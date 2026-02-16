import 'package:flutter/material.dart';

import '../../_base/chart_responsive_mixin.dart';
import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'heatmap_chart_data.dart';

export 'heatmap_chart_data.dart';

/// A heatmap chart widget.
///
/// Displays data as a grid of colored cells where
/// color intensity represents the value.
///
/// Example:
/// ```dart
/// HeatmapChart(
///   data: HeatmapChartData(
///     data: [
///       [1.0, 2.0, 3.0],
///       [4.0, 5.0, 6.0],
///       [7.0, 8.0, 9.0],
///     ],
///     rowLabels: ['A', 'B', 'C'],
///     columnLabels: ['X', 'Y', 'Z'],
///   ),
/// )
/// ```
class HeatmapChart extends StatefulWidget {
  const HeatmapChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onCellTap,
    this.onCellHover,
    this.padding = const EdgeInsets.fromLTRB(60, 24, 24, 48),
  });

  final HeatmapChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int row, int col, double value)? onCellTap;
  final void Function(int? row, int? col, double? value)? onCellHover;
  final EdgeInsets padding;

  @override
  State<HeatmapChart> createState() => _HeatmapChartState();
}

class _HeatmapChartState extends State<HeatmapChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
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
  void didUpdateWidget(HeatmapChart oldWidget) {
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
      radius: 0, // Exact hit for cells
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      final row = hitInfo.seriesIndex;
      final col = hitInfo.pointIndex;
      final value = widget.data.getValue(row, col);
      widget.onCellHover?.call(row, col, value);
    } else {
      _controller.clearHoveredPoint();
      widget.onCellHover?.call(null, null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);

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
              final hitInfo = _hitTester.hitTest(details.localPosition, radius: 0);
              if (hitInfo != null && widget.onCellTap != null) {
                final row = hitInfo.seriesIndex;
                final col = hitInfo.pointIndex;
                final value = widget.data.getValue(row, col);
                if (value != null) {
                  widget.onCellTap!(row, col, value);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onCellHover?.call(null, null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _HeatmapChartPainter(
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
    final row = info.seriesIndex;
    final col = info.pointIndex;
    final value = widget.data.getValue(row, col) ?? 0;

    final minVal = widget.data.computedMinValue;
    final maxVal = widget.data.computedMaxValue;
    final range = maxVal - minVal;
    final normalized = range > 0 ? (value - minVal) / range : 0.5;
    final color = widget.data.colorScale.getColor(normalized);

    final rowLabel = widget.data.rowLabels != null && row < widget.data.rowLabels!.length
        ? widget.data.rowLabels![row]
        : 'Row $row';
    final colLabel = widget.data.columnLabels != null && col < widget.data.columnLabels!.length
        ? widget.data.columnLabels![col]
        : 'Col $col';

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: 'Value',
          value: value,
          formattedValue: value.toStringAsFixed(2),
        ),
      ],
      xLabel: '$rowLabel, $colLabel',
    );
  }
}

class _HeatmapChartPainter extends ChartPainter {
  _HeatmapChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final HeatmapChartData data;
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

    if (data.rowCount == 0 || data.columnCount == 0) return;

    final cellWidth = chartArea.width / data.columnCount;
    final cellHeight = chartArea.height / data.rowCount;

    final minVal = data.computedMinValue;
    final maxVal = data.computedMaxValue;
    final range = maxVal - minVal;

    for (var row = 0; row < data.rowCount; row++) {
      for (var col = 0; col < data.columnCount; col++) {
        final value = data.getValue(row, col);
        if (value == null) continue;

        final isHovered = controller.hoveredPoint?.seriesIndex == row &&
            controller.hoveredPoint?.pointIndex == col;

        final normalized = range > 0 ? (value - minVal) / range : 0.5;
        final color = data.colorScale.getColor(normalized);

        final cellRect = Rect.fromLTWH(
          chartArea.left + col * cellWidth + data.cellPadding,
          chartArea.top + row * cellHeight + data.cellPadding,
          cellWidth - data.cellPadding * 2,
          cellHeight - data.cellPadding * 2,
        );

        _drawCell(canvas, cellRect, color, value, isHovered);

        // Register hit target
        hitTester.addRect(
          rect: cellRect,
          info: DataPointInfo(
            seriesIndex: row,
            pointIndex: col,
            position: cellRect.center,
            xValue: col,
            yValue: value,
          ),
        );
      }
    }

    // Draw labels
    _drawRowLabels(canvas, chartArea, cellHeight);
    _drawColumnLabels(canvas, chartArea, cellWidth);

    // Draw color legend
    if (data.showColorLegend) {
      _drawColorLegend(canvas, size, chartArea);
    }
  }

  void _drawCell(Canvas canvas, Rect rect, Color color, double value, bool isHovered) {
    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1);
    }

    // Animate opacity
    final opacity = animationValue;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(data.cellBorderRadius));

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: fillColor.a * opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, fillPaint);

    // Draw border on hover
    if (isHovered) {
      final borderPaint = Paint()
        ..color = theme.labelStyle.color ?? Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw value text if enabled
    if (data.showValues && rect.width > 20 && rect.height > 16) {
      final textStyle = theme.labelStyle.copyWith(
        fontSize: 10,
        color: _getContrastColor(fillColor),
      );

      final textSpan = TextSpan(text: value.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      if (textPainter.width < rect.width - 4) {
        final offset = Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _drawRowLabels(Canvas canvas, Rect chartArea, double cellHeight) {
    if (data.rowLabels == null) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i < data.rowLabels!.length && i < data.rowCount; i++) {
      final label = data.rowLabels![i];
      final y = chartArea.top + cellHeight * i + cellHeight / 2;

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        chartArea.left - textPainter.width - 8,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void _drawColumnLabels(Canvas canvas, Rect chartArea, double cellWidth) {
    if (data.columnLabels == null) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i < data.columnLabels!.length && i < data.columnCount; i++) {
      final label = data.columnLabels![i];
      final x = chartArea.left + cellWidth * i + cellWidth / 2;

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
        chartArea.bottom + 8,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void _drawColorLegend(Canvas canvas, Size size, Rect chartArea) {
    const legendWidth = 20.0;
    const legendHeight = 100.0;

    final legendRect = Rect.fromLTWH(
      size.width - padding.right + 8,
      chartArea.center.dy - legendHeight / 2,
      legendWidth,
      legendHeight,
    );

    // Draw gradient
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: data.colorScale.colors,
      stops: data.colorScale.stops,
    );

    final paint = Paint()
      ..shader = gradient.createShader(legendRect)
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(legendRect, const Radius.circular(4)),
      paint,
    );

    // Draw min/max labels
    final textStyle = theme.labelStyle.copyWith(fontSize: 9);

    final minSpan = TextSpan(text: data.computedMinValue.toStringAsFixed(1), style: textStyle);
    final minPainter = TextPainter(text: minSpan, textDirection: TextDirection.ltr)..layout();
    minPainter.paint(canvas, Offset(legendRect.left, legendRect.bottom + 4));

    final maxSpan = TextSpan(text: data.computedMaxValue.toStringAsFixed(1), style: textStyle);
    final maxPainter = TextPainter(text: maxSpan, textDirection: TextDirection.ltr)..layout();
    maxPainter.paint(canvas, Offset(legendRect.left, legendRect.top - maxPainter.height - 4));
  }

  @override
  bool shouldRepaint(covariant _HeatmapChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
