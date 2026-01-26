import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'histogram_chart_data.dart';

export 'histogram_chart_data.dart';

/// A histogram chart widget.
///
/// Displays the distribution of numerical data by grouping
/// values into bins and showing frequency/density.
///
/// Example:
/// ```dart
/// HistogramChart(
///   data: HistogramChartData(
///     values: [1.2, 2.3, 2.5, 3.1, 3.3, 3.5, 4.0, 4.2, 5.1],
///     binningMethod: HistogramBinningMethod.sturges,
///   ),
/// )
/// ```
class HistogramChart extends StatefulWidget {
  const HistogramChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onBinTap,
    this.onBinHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final HistogramChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(HistogramBin bin, int index)? onBinTap;
  final void Function(HistogramBin? bin, int? index)? onBinHover;
  final EdgeInsets padding;

  @override
  State<HistogramChart> createState() => _HistogramChartState();
}

class _HistogramChartState extends State<HistogramChart>
    with SingleTickerProviderStateMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  Rect _chartArea = Rect.zero;
  late List<HistogramBin> _bins;

  ChartAnimation get _animationConfig =>
      widget.animation ?? widget.data.animation ?? const ChartAnimation();

  @override
  void initState() {
    super.initState();
    _bins = widget.data.calculateBins();
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
  void didUpdateWidget(HistogramChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      _bins = widget.data.calculateBins();
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
      radius: widget.interactions.hitTestRadius,
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      widget.onBinHover?.call(_bins[hitInfo.pointIndex], hitInfo.pointIndex);
    } else {
      _controller.clearHoveredPoint();
      widget.onBinHover?.call(null, null);
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
              if (hitInfo != null && widget.onBinTap != null) {
                widget.onBinTap!(_bins[hitInfo.pointIndex], hitInfo.pointIndex);
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onBinHover?.call(null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _HistogramChartPainter(
                  data: widget.data,
                  bins: _bins,
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
    final bin = _bins[info.pointIndex];
    final color = widget.data.color ?? theme.getSeriesColor(0);

    String valueLabel;
    switch (widget.data.mode) {
      case HistogramMode.frequency:
        valueLabel = 'Count: ${bin.count}';
      case HistogramMode.density:
        final totalCount = _bins.fold<int>(0, (sum, b) => sum + b.count);
        final density = totalCount > 0 ? bin.count / totalCount / bin.width : 0;
        valueLabel = 'Density: ${density.toStringAsFixed(4)}';
      case HistogramMode.cumulative:
        var cumulative = 0;
        for (var i = 0; i <= info.pointIndex; i++) {
          cumulative += _bins[i].count;
        }
        valueLabel = 'Cumulative: $cumulative';
      case HistogramMode.cumulativePercent:
        final totalCount = _bins.fold<int>(0, (sum, b) => sum + b.count);
        var cumulative = 0;
        for (var i = 0; i <= info.pointIndex; i++) {
          cumulative += _bins[i].count;
        }
        final percent = totalCount > 0 ? (cumulative / totalCount * 100) : 0;
        valueLabel = 'Cumulative: ${percent.toStringAsFixed(1)}%';
    }

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: valueLabel,
          value: bin.count.toDouble(),
        ),
      ],
      xLabel: '${bin.start.toStringAsFixed(2)} - ${bin.end.toStringAsFixed(2)}',
    );
  }
}

class _HistogramChartPainter extends CartesianChartPainter {
  _HistogramChartPainter({
    required this.data,
    required this.bins,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required super.padding,
  }) : super(repaint: controller) {
    _calculateBounds();
  }

  final HistogramChartData data;
  final List<HistogramBin> bins;
  final ChartController controller;
  final ChartHitTester hitTester;

  double _xMin = 0;
  double _xMax = 1;
  double _yMax = 1;

  void _calculateBounds() {
    if (bins.isEmpty) return;

    _xMin = bins.first.start;
    _xMax = bins.last.end;

    final totalCount = bins.fold<int>(0, (sum, b) => sum + b.count);

    switch (data.mode) {
      case HistogramMode.frequency:
        _yMax = bins.map((b) => b.count).reduce(math.max).toDouble();
      case HistogramMode.density:
        _yMax = bins.map((b) => totalCount > 0 ? b.count / totalCount / b.width : 0.0).reduce(math.max);
      case HistogramMode.cumulative:
        _yMax = totalCount.toDouble();
      case HistogramMode.cumulativePercent:
        _yMax = 100;
    }

    _yMax *= 1.1; // Add padding
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (bins.isEmpty) return;

    final color = data.color ?? theme.getSeriesColor(0);
    final totalCount = bins.fold<int>(0, (sum, b) => sum + b.count);

    var cumulativeCount = 0;

    for (var i = 0; i < bins.length; i++) {
      final bin = bins[i];
      cumulativeCount += bin.count;

      final isHovered = controller.hoveredPoint?.pointIndex == i;

      // Calculate bar position
      final left = _valueToX(bin.start, chartArea) + data.barSpacing / 2;
      final right = _valueToX(bin.end, chartArea) - data.barSpacing / 2;

      // Calculate bar height based on mode
      double value;
      switch (data.mode) {
        case HistogramMode.frequency:
          value = bin.count.toDouble();
        case HistogramMode.density:
          value = totalCount > 0 ? bin.count / totalCount / bin.width : 0;
        case HistogramMode.cumulative:
          value = cumulativeCount.toDouble();
        case HistogramMode.cumulativePercent:
          value = totalCount > 0 ? cumulativeCount / totalCount * 100 : 0;
      }

      final top = _valueToY(value * animationValue, chartArea);
      final bottom = chartArea.bottom;

      final barRect = Rect.fromLTRB(left, top, right, bottom);

      // Draw bar
      _drawBar(canvas, barRect, bin.color ?? color, isHovered);

      // Register hit target
      hitTester.addRect(
        rect: barRect,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(barRect.center.dx, top),
          xValue: bin.center,
          yValue: value,
        ),
      );
    }

    // Draw distribution curve if enabled
    if (data.showDistributionCurve && data.mode == HistogramMode.frequency) {
      _drawDistributionCurve(canvas, chartArea, totalCount);
    }
  }

  void _drawBar(Canvas canvas, Rect rect, Color color, bool isHovered) {
    var fillColor = color;
    if (isHovered) {
      fillColor = color.withValues(alpha: 1);
    }

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: isHovered ? 1.0 : 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);

    // Draw border
    if (data.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = data.borderColor ?? color.withValues(alpha: 1)
        ..strokeWidth = data.borderWidth
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, borderPaint);
    }

    // Hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, highlightPaint);
    }
  }

  void _drawDistributionCurve(Canvas canvas, Rect chartArea, int totalCount) {
    if (data.values.isEmpty || totalCount == 0) return;

    // Calculate mean and standard deviation
    final mean = data.values.reduce((a, b) => a + b) / data.values.length;
    final variance = data.values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / data.values.length;
    final std = math.sqrt(variance);

    if (std == 0) return;

    final curveColor = data.distributionCurveColor ?? theme.getSeriesColor(1);
    final paint = Paint()
      ..color = curveColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    var isFirst = true;

    // Draw normal distribution curve
    for (var x = _xMin; x <= _xMax; x += (_xMax - _xMin) / 100) {
      // Normal distribution formula
      final exponent = -math.pow(x - mean, 2) / (2 * variance);
      final pdf = (1 / (std * math.sqrt(2 * math.pi))) * math.exp(exponent);

      // Scale to match histogram
      final binWidth = bins.isNotEmpty ? bins.first.width : 1;
      final scaledPdf = pdf * totalCount * binWidth;

      final screenX = _valueToX(x, chartArea);
      final screenY = _valueToY(scaledPdf * animationValue, chartArea);

      if (isFirst) {
        path.moveTo(screenX, screenY);
        isFirst = false;
      } else {
        path.lineTo(screenX, screenY);
      }
    }

    canvas.drawPath(path, paint);
  }

  double _valueToX(double value, Rect chartArea) {
    final range = _xMax - _xMin;
    if (range == 0) return chartArea.center.dx;
    return chartArea.left + (value - _xMin) / range * chartArea.width;
  }

  double _valueToY(double value, Rect chartArea) {
    if (_yMax == 0) return chartArea.bottom;
    return chartArea.bottom - (value / _yMax) * chartArea.height;
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    super.paintAxes(canvas, size);

    final chartArea = getChartArea(size);
    _drawYAxisLabels(canvas, chartArea);
    _drawXAxisLabels(canvas, chartArea);
  }

  void _drawYAxisLabels(Canvas canvas, Rect chartArea) {
    const labelCount = 5;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _yMax * i / labelCount;
      final y = chartArea.bottom - (chartArea.height * i / labelCount);

      String label;
      switch (data.mode) {
        case HistogramMode.frequency:
        case HistogramMode.cumulative:
          label = value.toInt().toString();
        case HistogramMode.density:
          label = value.toStringAsFixed(3);
        case HistogramMode.cumulativePercent:
          label = '${value.toInt()}%';
      }

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        chartArea.left - textPainter.width - 12,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect chartArea) {
    const labelCount = 5;
    final range = _xMax - _xMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: 11,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _xMin + (range * i / labelCount);
      final x = chartArea.left + (chartArea.width * i / labelCount);

      final label = value.toStringAsFixed(1);

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
        chartArea.bottom + 12,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      bins != oldDelegate.bins ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
