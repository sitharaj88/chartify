import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'bump_chart_data.dart';

export 'bump_chart_data.dart';

/// A bump chart widget.
///
/// Displays ranking changes over time with connected dots.
///
/// Example:
/// ```dart
/// BumpChart(
///   data: BumpChartData(
///     timeLabels: ['Q1', 'Q2', 'Q3', 'Q4'],
///     series: [
///       BumpSeries(label: 'Team A', rankings: [1, 2, 1, 1]),
///       BumpSeries(label: 'Team B', rankings: [2, 1, 3, 2]),
///       BumpSeries(label: 'Team C', rankings: [3, 3, 2, 3]),
///     ],
///   ),
/// )
/// ```
class BumpChart extends StatefulWidget {
  const BumpChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onSeriesTap,
    this.padding = const EdgeInsets.all(24),
  });

  final BumpChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int seriesIndex, BumpSeries series)? onSeriesTap;
  final EdgeInsets padding;

  @override
  State<BumpChart> createState() => _BumpChartState();
}

class _BumpChartState extends State<BumpChart>
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
  void didUpdateWidget(BumpChart oldWidget) {
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
              if (hitInfo != null && widget.onSeriesTap != null) {
                final idx = hitInfo.seriesIndex;
                if (idx >= 0 && idx < widget.data.series.length) {
                  widget.onSeriesTap!(idx, widget.data.series[idx]);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BumpChartPainter(
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

    if (seriesIdx < 0 || seriesIdx >= widget.data.series.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final series = widget.data.series[seriesIdx];
    final color = series.color ?? theme.getSeriesColor(seriesIdx);

    final entries = <TooltipEntry>[
      TooltipEntry(
        color: color,
        label: 'Rank',
        value: pointIdx < series.rankings.length
            ? series.rankings[pointIdx].toDouble()
            : 0,
        formattedValue: pointIdx < series.rankings.length
            ? '#${series.rankings[pointIdx]}'
            : '-',
      ),
    ];

    final timeLabel = widget.data.timeLabels != null &&
            pointIdx < widget.data.timeLabels!.length
        ? widget.data.timeLabels![pointIdx]
        : 'Point ${pointIdx + 1}';

    return TooltipData(
      position: info.position,
      entries: entries,
      xLabel: '${series.label} - $timeLabel',
    );
  }
}

class _BumpChartPainter extends ChartPainter {
  _BumpChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
    required this.hitRadius,
  }) : super(repaint: controller);

  final BumpChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;
  final double hitRadius;

  @override
  Rect getChartArea(Size size) {
    final labelWidth = data.showLabels ? 80.0 : 0.0;
    return Rect.fromLTRB(
      padding.left + labelWidth,
      padding.top + 20,
      size.width - padding.right - labelWidth,
      size.height - padding.bottom - 30,
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.series.isEmpty || data.timePointCount == 0) return;

    final timePointCount = data.timePointCount;
    final maxRank = data.maxRank;

    // Draw time labels
    _drawTimeLabels(canvas, chartArea, timePointCount);

    // Draw grid
    _drawGrid(canvas, chartArea, timePointCount, maxRank);

    // Draw each series
    for (var seriesIdx = 0; seriesIdx < data.series.length; seriesIdx++) {
      final series = data.series[seriesIdx];
      final isHovered = controller.hoveredPoint?.seriesIndex == seriesIdx;
      final color = series.color ?? theme.getSeriesColor(seriesIdx);

      // Calculate points
      final points = <Offset>[];
      for (var t = 0; t < series.rankings.length; t++) {
        final rank = series.rankings[t];
        final x = _getXPosition(t, timePointCount, chartArea);
        final y = _getYPosition(rank, maxRank, chartArea);
        points.add(Offset(x, y));
      }

      // Apply animation (reveal from left to right)
      final animatedPointCount =
          (points.length * animationValue).ceil().clamp(0, points.length);
      final animatedPoints = points.take(animatedPointCount).toList();

      if (animatedPoints.isEmpty) continue;

      // Draw connecting lines
      _drawLines(canvas, animatedPoints, color, isHovered);

      // Draw markers
      for (var t = 0; t < animatedPoints.length; t++) {
        final point = animatedPoints[t];
        final rank = series.rankings[t];
        final isPointHovered =
            isHovered && controller.hoveredPoint?.pointIndex == t;

        _drawMarker(canvas, point, rank, color, isPointHovered);

        // Register hit target
        hitTester.addCircle(
          center: point,
          radius: hitRadius,
          info: DataPointInfo(
            seriesIndex: seriesIdx,
            pointIndex: t,
            position: point,
            xValue: t,
            yValue: rank.toDouble(),
          ),
        );
      }

      // Draw series labels
      if (data.showLabels && animatedPoints.isNotEmpty) {
        _drawSeriesLabel(
          canvas,
          series,
          animatedPoints.first,
          animatedPoints.last,
          color,
          chartArea,
        );
      }
    }
  }

  double _getXPosition(int timeIndex, int timePointCount, Rect chartArea) {
    if (timePointCount <= 1) return chartArea.center.dx;
    return chartArea.left +
        (timeIndex / (timePointCount - 1)) * chartArea.width;
  }

  double _getYPosition(int rank, int maxRank, Rect chartArea) {
    if (maxRank <= 1) return chartArea.center.dy;
    // Rank 1 at top, higher ranks lower
    return chartArea.top + ((rank - 1) / (maxRank - 1)) * chartArea.height;
  }

  void _drawTimeLabels(Canvas canvas, Rect chartArea, int timePointCount) {
    if (data.timeLabels == null) return;

    for (var t = 0; t < timePointCount && t < data.timeLabels!.length; t++) {
      final x = _getXPosition(t, timePointCount, chartArea);
      final label = data.timeLabels![t];

      final textSpan = TextSpan(
        text: label,
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

  void _drawGrid(
      Canvas canvas, Rect chartArea, int timePointCount, int maxRank,) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = theme.gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontal lines for each rank
    for (var rank = 1; rank <= maxRank; rank++) {
      final y = _getYPosition(rank, maxRank, chartArea);
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );

      // Draw rank number
      final textSpan = TextSpan(
        text: '$rank',
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

    // Vertical lines for each time point
    for (var t = 0; t < timePointCount; t++) {
      final x = _getXPosition(t, timePointCount, chartArea);
      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        paint,
      );
    }
  }

  void _drawLines(
      Canvas canvas, List<Offset> points, Color color, bool isHovered,) {
    if (points.length < 2) return;

    final paint = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: isHovered ? 1.0 : 0.7)
      ..strokeWidth = isHovered ? data.lineWidth * 1.5 : data.lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (data.smoothLines) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (var i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final midX = (p0.dx + p1.dx) / 2;

        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }

      // Draw shadow
      final shadowPaint = Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: theme.shadowOpacity)
        ..strokeWidth = paint.strokeWidth + 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.4);
      canvas.drawPath(path, shadowPaint);

      canvas.drawPath(path, paint);
    } else {
      for (var i = 1; i < points.length; i++) {
        canvas.drawLine(points[i - 1], points[i], paint);
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset point, int rank, Color color,
      bool isHovered,) {
    final size = isHovered ? data.markerSize * 1.3 : data.markerSize;

    // Draw filled circle
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, size / 2, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..isAntiAlias = true
      ..color = isHovered ? Colors.white : theme.backgroundColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(point, size / 2, borderPaint);

    // Draw rank number
    if (data.showRankings) {
      final textSpan = TextSpan(
        text: '$rank',
        style: theme.labelStyle.copyWith(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2,
            point.dy - textPainter.height / 2,),
      );
    }
  }

  void _drawSeriesLabel(Canvas canvas, BumpSeries series, Offset firstPoint,
      Offset lastPoint, Color color, Rect chartArea,) {
    final textSpan = TextSpan(
      text: series.label,
      style: theme.labelStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
        fontSize: labelFontSize,
      ),
    );

    // Left label
    final leftPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout(maxWidth: 70);

    leftPainter.paint(
      canvas,
      Offset(
        chartArea.left - leftPainter.width - data.markerSize - 4,
        firstPoint.dy - leftPainter.height / 2,
      ),
    );

    // Right label
    final rightPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 70);

    rightPainter.paint(
      canvas,
      Offset(
        chartArea.right + data.markerSize + 4,
        lastPoint.dy - rightPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BumpChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      labelFontSize != oldDelegate.labelFontSize ||
      hitRadius != oldDelegate.hitRadius;
}
