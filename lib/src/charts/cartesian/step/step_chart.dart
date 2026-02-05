import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/data/data_point.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'step_chart_data.dart';

export 'step_chart_data.dart';

/// A step chart widget.
///
/// Displays data as a step-wise line, useful for showing
/// discrete changes in values over time.
///
/// Example:
/// ```dart
/// StepChart(
///   data: StepChartData(
///     series: [
///       StepSeries(data: [
///         DataPoint(x: 0, y: 10),
///         DataPoint(x: 1, y: 25),
///         DataPoint(x: 2, y: 15),
///       ]),
///     ],
///     stepType: StepType.after,
///   ),
/// )
/// ```
class StepChart<X, Y extends num> extends StatefulWidget {
  const StepChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onPointTap,
    this.padding = const EdgeInsets.all(24),
  });

  final StepChartData<X, Y> data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int seriesIndex, int pointIndex, DataPoint<X, Y> point)?
      onPointTap;
  final EdgeInsets padding;

  @override
  State<StepChart<X, Y>> createState() => _StepChartState<X, Y>();
}

class _StepChartState<X, Y extends num> extends State<StepChart<X, Y>>
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
  void didUpdateWidget(StepChart<X, Y> oldWidget) {
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
              if (hitInfo != null && widget.onPointTap != null) {
                final seriesIdx = hitInfo.seriesIndex;
                final pointIdx = hitInfo.pointIndex;
                if (seriesIdx >= 0 &&
                    seriesIdx < widget.data.series.length &&
                    pointIdx >= 0 &&
                    pointIdx < widget.data.series[seriesIdx].data.length) {
                  widget.onPointTap!(
                    seriesIdx,
                    pointIdx,
                    widget.data.series[seriesIdx].data[pointIdx],
                  );
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _StepChartPainter<X, Y>(
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
    final seriesIdx = info.seriesIndex;
    final pointIdx = info.pointIndex;

    if (seriesIdx < 0 ||
        seriesIdx >= widget.data.series.length ||
        pointIdx < 0 ||
        pointIdx >= widget.data.series[seriesIdx].data.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final series = widget.data.series[seriesIdx];
    final point = series.data[pointIdx];
    final color = series.color ?? theme.getSeriesColor(seriesIdx);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: series.name ?? 'Series ${seriesIdx + 1}',
          value: point.y.toDouble(),
          formattedValue: point.y.toStringAsFixed(1),
        ),
      ],
      xLabel: point.x.toString(),
    );
  }
}

class _StepChartPainter<X, Y extends num> extends ChartPainter {
  _StepChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
  }) : super(repaint: controller);

  final StepChartData<X, Y> data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;

  @override
  Rect getChartArea(Size size) => Rect.fromLTRB(
      padding.left + 40, // Space for Y axis
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom - 30, // Space for X axis
    );

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.series.isEmpty) return;

    final (minY, maxY) = data.calculateYRange();

    // Draw grid
    if (data.showGrid) {
      _drawGrid(canvas, chartArea, minY, maxY);
    }

    // Draw axes
    if (data.showYAxis) {
      _drawYAxis(canvas, chartArea, minY, maxY);
    }
    if (data.showXAxis) {
      _drawXAxis(canvas, chartArea);
    }

    // Draw each series
    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final series = data.series[seriesIndex];
      if (series.data.isEmpty) continue;

      final color = series.color ?? theme.getSeriesColor(seriesIndex);

      // Calculate point positions
      final points = <Offset>[];
      for (var i = 0; i < series.data.length; i++) {
        final point = series.data[i];
        final x = _getXPosition(i, series.data.length, chartArea);
        final y = _getYPosition(point.y.toDouble(), minY, maxY, chartArea);
        points.add(Offset(x, y));
      }

      // Apply animation
      final animatedPoints = points.map((p) {
        final baseY = chartArea.bottom;
        return Offset(p.dx, baseY + (p.dy - baseY) * animationValue);
      }).toList();

      // Draw fill area if enabled
      if (series.fillArea) {
        _drawFillArea(canvas, animatedPoints, chartArea, series, color);
      }

      // Draw step lines
      _drawStepLines(canvas, animatedPoints, series, color);

      // Draw markers
      if (series.showMarkers) {
        _drawMarkers(
            canvas, animatedPoints, seriesIndex, series, color, chartArea,);
      }

      // Register hit targets
      for (var i = 0; i < animatedPoints.length; i++) {
        hitTester.addCircle(
          center: animatedPoints[i],
          radius: hitRadius,
          info: DataPointInfo(
            seriesIndex: seriesIndex,
            pointIndex: i,
            position: animatedPoints[i],
            xValue: i,
            yValue: series.data[i].y.toDouble(),
          ),
        );
      }
    }
  }

  double _getXPosition(int index, int total, Rect chartArea) {
    if (total <= 1) return chartArea.center.dx;
    return chartArea.left + (index / (total - 1)) * chartArea.width;
  }

  double _getYPosition(double value, double minY, double maxY, Rect chartArea) {
    final ratio = (value - minY) / (maxY - minY);
    return chartArea.bottom - ratio * chartArea.height;
  }

  void _drawGrid(Canvas canvas, Rect chartArea, double minY, double maxY) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    // Horizontal grid lines
    const gridLines = 5;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartArea.top + (i / gridLines) * chartArea.height;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );
    }
  }

  void _drawYAxis(Canvas canvas, Rect chartArea, double minY, double maxY) {
    final paint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(chartArea.left, chartArea.top),
      Offset(chartArea.left, chartArea.bottom),
      paint,
    );

    // Draw Y axis labels
    const labelCount = 5;
    for (var i = 0; i <= labelCount; i++) {
      final value = maxY - (i / labelCount) * (maxY - minY);
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
        Offset(chartArea.left - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }

  void _drawXAxis(Canvas canvas, Rect chartArea) {
    final paint = Paint()
      ..color = theme.axisLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(chartArea.left, chartArea.bottom),
      Offset(chartArea.right, chartArea.bottom),
      paint,
    );

    // Draw X axis labels
    if (data.series.isNotEmpty && data.series.first.data.isNotEmpty) {
      final series = data.series.first;
      for (var i = 0; i < series.data.length; i++) {
        final x = _getXPosition(i, series.data.length, chartArea);
        final point = series.data[i];

        final textSpan = TextSpan(
          text: point.x.toString(),
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
    }
  }

  void _drawStepLines(
    Canvas canvas,
    List<Offset> points,
    StepSeries<X, Y> series,
    Color color,
  ) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = series.lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      switch (data.stepType) {
        case StepType.before:
          // Horizontal first, then vertical
          path.lineTo(curr.dx, prev.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepType.after:
          // Vertical first, then horizontal
          path.lineTo(prev.dx, curr.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepType.middle:
          // Step at midpoint
          final midX = (prev.dx + curr.dx) / 2;
          path.lineTo(midX, prev.dy);
          path.lineTo(midX, curr.dy);
          path.lineTo(curr.dx, curr.dy);
      }
    }

    // Draw subtle shadow behind the step line
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: theme.shadowOpacity * 1.2)
      ..strokeWidth = series.lineWidth + 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.5)
      ..isAntiAlias = true;
    canvas.drawPath(path, shadowPaint);

    canvas.drawPath(path, paint);
  }

  void _drawFillArea(
    Canvas canvas,
    List<Offset> points,
    Rect chartArea,
    StepSeries<X, Y> series,
    Color color,
  ) {
    if (points.length < 2) return;

    final fillColor =
        (series.fillColor ?? color).withValues(alpha: series.fillOpacity * animationValue);

    final path = Path();
    path.moveTo(points.first.dx, chartArea.bottom);
    path.lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      switch (data.stepType) {
        case StepType.before:
          path.lineTo(curr.dx, prev.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepType.after:
          path.lineTo(prev.dx, curr.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepType.middle:
          final midX = (prev.dx + curr.dx) / 2;
          path.lineTo(midX, prev.dy);
          path.lineTo(midX, curr.dy);
          path.lineTo(curr.dx, curr.dy);
      }
    }

    path.lineTo(points.last.dx, chartArea.bottom);
    path.close();

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  void _drawMarkers(
    Canvas canvas,
    List<Offset> points,
    int seriesIndex,
    StepSeries<X, Y> series,
    Color color,
    Rect chartArea,
  ) {
    final isHovered = controller.hoveredPoint?.seriesIndex == seriesIndex;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isPointHovered =
          isHovered && controller.hoveredPoint?.pointIndex == i;

      final radius =
          isPointHovered ? series.markerRadius * 1.5 : series.markerRadius;

      // Draw outer circle (border)
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true;

      canvas.drawCircle(point, radius, borderPaint);

      // Draw inner circle (fill)
      final fillPaint = Paint()
        ..color = isPointHovered ? color : theme.backgroundColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawCircle(point, radius - 1, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepChartPainter<X, Y> oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      labelFontSize != oldDelegate.labelFontSize ||
      hitRadius != oldDelegate.hitRadius;
}
