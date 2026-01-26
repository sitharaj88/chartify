import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'slope_chart_data.dart';

export 'slope_chart_data.dart';

/// A slope chart widget.
///
/// Displays lines connecting values at two time points,
/// useful for showing changes or comparisons between two periods.
///
/// Example:
/// ```dart
/// SlopeChart(
///   data: SlopeChartData(
///     startLabel: '2020',
///     endLabel: '2023',
///     items: [
///       SlopeItem(label: 'Product A', startValue: 100, endValue: 150),
///       SlopeItem(label: 'Product B', startValue: 80, endValue: 60),
///       SlopeItem(label: 'Product C', startValue: 50, endValue: 90),
///     ],
///   ),
/// )
/// ```
class SlopeChart extends StatefulWidget {
  const SlopeChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.padding = const EdgeInsets.all(24),
  });

  final SlopeChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, SlopeItem item)? onItemTap;
  final EdgeInsets padding;

  @override
  State<SlopeChart> createState() => _SlopeChartState();
}

class _SlopeChartState extends State<SlopeChart>
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
  void didUpdateWidget(SlopeChart oldWidget) {
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
                painter: _SlopeChartPainter(
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

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: widget.data.startLabel,
          value: item.startValue,
          formattedValue: item.startValue.toStringAsFixed(1),
        ),
        TooltipEntry(
          color: color,
          label: widget.data.endLabel,
          value: item.endValue,
          formattedValue: item.endValue.toStringAsFixed(1),
        ),
        TooltipEntry(
          color: item.isPositive ? Colors.green : Colors.red,
          label: 'Change',
          value: item.change,
          formattedValue:
              '${item.isPositive ? '+' : ''}${item.change.toStringAsFixed(1)} (${item.percentChange.toStringAsFixed(1)}%)',
        ),
      ],
      xLabel: item.label,
    );
  }
}

class _SlopeChartPainter extends ChartPainter {
  _SlopeChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
  }) : super(repaint: controller);

  final SlopeChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;

  @override
  Rect getChartArea(Size size) => Rect.fromLTRB(
      padding.left + data.labelWidth,
      padding.top + 30, // Space for column headers
      size.width - padding.right - data.labelWidth,
      size.height - padding.bottom,
    );

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.items.isEmpty) return;

    final (minValue, maxValue) = data.calculateRange();

    // Draw column headers
    _drawColumnHeaders(canvas, chartArea);

    // Draw axes (vertical lines)
    _drawAxes(canvas, chartArea);

    // Draw each slope line
    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = item.color ?? theme.getSeriesColor(i);

      // Calculate Y positions
      final startRatio =
          ((item.startValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
      final endRatio =
          ((item.endValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

      // Apply animation (slide in from left)
      final animatedEndRatio =
          startRatio + (endRatio - startRatio) * animationValue;

      final startY = chartArea.bottom - startRatio * chartArea.height;
      final endY = chartArea.bottom - animatedEndRatio * chartArea.height;

      final startPoint = Offset(chartArea.left, startY);
      final endPoint = Offset(chartArea.right, endY);

      // Draw line
      final lineWidth = isHovered ? data.lineWidth * 2 : data.lineWidth;
      final linePaint = Paint()
        ..color = color.withValues(alpha: isHovered ? 1.0 : 0.8)
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, linePaint);

      // Draw markers
      final markerSize = isHovered ? data.markerSize * 1.3 : data.markerSize;

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isHovered ? Colors.white : theme.backgroundColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(startPoint, markerSize / 2, fillPaint);
      canvas.drawCircle(startPoint, markerSize / 2, borderPaint);

      canvas.drawCircle(endPoint, markerSize / 2, fillPaint);
      canvas.drawCircle(endPoint, markerSize / 2, borderPaint);

      // Draw labels
      if (data.showLabels) {
        _drawItemLabels(canvas, item, startPoint, endPoint, color, chartArea);
      }

      // Draw values
      if (data.showValues) {
        _drawValues(canvas, item, startPoint, endPoint, chartArea);
      }

      // Register hit target
      hitTester.addPath(
        path: Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(endPoint.dx, endPoint.dy),
        strokeWidth: data.lineWidth * 4,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(
            (startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2,
          ),
          xValue: i,
          yValue: item.endValue,
        ),
      );
    }
  }

  void _drawColumnHeaders(Canvas canvas, Rect chartArea) {
    // Start label
    final startSpan = TextSpan(
      text: data.startLabel,
      style: theme.titleStyle.copyWith(fontSize: 14),
    );
    final startPainter = TextPainter(
      text: startSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    startPainter.paint(
      canvas,
      Offset(
        chartArea.left - startPainter.width / 2,
        chartArea.top - startPainter.height - 8,
      ),
    );

    // End label
    final endSpan = TextSpan(
      text: data.endLabel,
      style: theme.titleStyle.copyWith(fontSize: 14),
    );
    final endPainter = TextPainter(
      text: endSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    endPainter.paint(
      canvas,
      Offset(
        chartArea.right - endPainter.width / 2,
        chartArea.top - endPainter.height - 8,
      ),
    );
  }

  void _drawAxes(Canvas canvas, Rect chartArea) {
    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1;

    // Start axis
    canvas.drawLine(
      Offset(chartArea.left, chartArea.top),
      Offset(chartArea.left, chartArea.bottom),
      paint,
    );

    // End axis
    canvas.drawLine(
      Offset(chartArea.right, chartArea.top),
      Offset(chartArea.right, chartArea.bottom),
      paint,
    );
  }

  void _drawItemLabels(Canvas canvas, SlopeItem item, Offset startPoint,
      Offset endPoint, Color color, Rect chartArea,) {
    // Start label (left side)
    final startSpan = TextSpan(
      text: item.label,
      style: theme.labelStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
    final startPainter = TextPainter(
      text: startSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout(maxWidth: data.labelWidth - 8);

    startPainter.paint(
      canvas,
      Offset(
        chartArea.left - startPainter.width - 8,
        startPoint.dy - startPainter.height / 2,
      ),
    );

    // End label (right side) - only show label if different or for clarity
    final endSpan = TextSpan(
      text: item.label,
      style: theme.labelStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
    final endPainter = TextPainter(
      text: endSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: data.labelWidth - 8);

    endPainter.paint(
      canvas,
      Offset(
        chartArea.right + 8,
        endPoint.dy - endPainter.height / 2,
      ),
    );
  }

  void _drawValues(Canvas canvas, SlopeItem item, Offset startPoint,
      Offset endPoint, Rect chartArea,) {
    // Start value
    final startValueSpan = TextSpan(
      text: item.startValue.toStringAsFixed(0),
      style: theme.labelStyle.copyWith(fontSize: 10),
    );
    final startValuePainter = TextPainter(
      text: startValueSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    startValuePainter.paint(
      canvas,
      Offset(
        startPoint.dx - startValuePainter.width - data.markerSize,
        startPoint.dy - startValuePainter.height / 2,
      ),
    );

    // End value
    final endValueSpan = TextSpan(
      text: item.endValue.toStringAsFixed(0),
      style: theme.labelStyle.copyWith(fontSize: 10),
    );
    final endValuePainter = TextPainter(
      text: endValueSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    endValuePainter.paint(
      canvas,
      Offset(
        endPoint.dx + data.markerSize,
        endPoint.dy - endValuePainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SlopeChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
