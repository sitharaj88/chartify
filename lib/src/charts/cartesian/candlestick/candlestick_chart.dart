import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'candlestick_chart_data.dart';

export 'candlestick_chart_data.dart';

/// A candlestick chart widget for financial data.
///
/// Displays OHLC (Open, High, Low, Close) data commonly used
/// for stock and cryptocurrency trading charts.
///
/// Example:
/// ```dart
/// CandlestickChart(
///   data: CandlestickChartData(
///     data: [
///       CandlestickDataPoint(
///         date: DateTime(2024, 1, 1),
///         open: 100, high: 110, low: 95, close: 105,
///       ),
///       // ... more data points
///     ],
///   ),
/// )
/// ```
class CandlestickChart extends StatefulWidget {
  const CandlestickChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onDataPointTap,
    this.onDataPointHover,
    this.padding = const EdgeInsets.fromLTRB(56, 24, 24, 48),
  });

  final CandlestickChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DataPointInfo info)? onDataPointTap;
  final void Function(DataPointInfo? info)? onDataPointHover;
  final EdgeInsets padding;

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart>
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
  void didUpdateWidget(CandlestickChart oldWidget) {
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
      radius: widget.interactions.hitTestRadius,
    );
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
      widget.onDataPointHover?.call(hitInfo);
    } else {
      _controller.clearHoveredPoint();
      widget.onDataPointHover?.call(null);
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

        final volumeHeight = widget.data.showVolume
            ? constraints.maxHeight * widget.data.volumeHeightRatio
            : 0.0;

        _chartArea = Rect.fromLTRB(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.right,
          constraints.maxHeight - responsivePadding.bottom - volumeHeight,
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
              if (hitInfo != null && widget.onDataPointTap != null) {
                widget.onDataPointTap!(hitInfo);
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onDataPointHover?.call(null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CandlestickChartPainter(
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
    final candle = widget.data.data[info.pointIndex];
    final color = candle.isBullish
        ? widget.data.bullishColor
        : widget.data.bearishColor;

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: 'O: ${_formatPrice(candle.open)}',
          value: candle.open,
        ),
        TooltipEntry(
          color: color,
          label: 'H: ${_formatPrice(candle.high)}',
          value: candle.high,
        ),
        TooltipEntry(
          color: color,
          label: 'L: ${_formatPrice(candle.low)}',
          value: candle.low,
        ),
        TooltipEntry(
          color: color,
          label: 'C: ${_formatPrice(candle.close)}',
          value: candle.close,
        ),
        if (candle.volume != null)
          TooltipEntry(
            color: color,
            label: 'Vol: ${_formatVolume(candle.volume!)}',
            value: candle.volume,
          ),
      ],
      xLabel: _formatDate(candle.date),
    );
  }

  String _formatPrice(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatVolume(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _CandlestickChartPainter extends CartesianChartPainter {
  _CandlestickChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required super.padding,
    required this.labelFontSize,
  }) : super(repaint: controller, showGrid: data.showGrid) {
    _calculateBounds();
  }

  final CandlestickChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final double labelFontSize;

  double _priceMin = 0;
  double _priceMax = 1;
  double _volumeMax = 1;

  void _calculateBounds() {
    if (data.data.isEmpty) return;

    var priceMin = double.infinity;
    var priceMax = double.negativeInfinity;
    double volumeMax = 0;

    for (final candle in data.data) {
      if (candle.low < priceMin) priceMin = candle.low;
      if (candle.high > priceMax) priceMax = candle.high;
      if (candle.volume != null && candle.volume! > volumeMax) {
        volumeMax = candle.volume!;
      }
    }

    // Add padding
    final priceRange = priceMax - priceMin;
    _priceMin = priceMin - priceRange * 0.05;
    _priceMax = priceMax + priceRange * 0.05;
    _volumeMax = volumeMax * 1.1;
  }

  @override
  Rect getChartArea(Size size) {
    final volumeHeight = data.showVolume
        ? size.height * data.volumeHeightRatio
        : 0.0;

    return Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom - volumeHeight,
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.data.isEmpty) return;

    final candleCount = data.data.length;
    final candleSpace = chartArea.width / candleCount;
    final candleWidth = candleSpace * data.candleWidth;

    for (var i = 0; i < candleCount; i++) {
      final candle = data.data[i];
      final x = chartArea.left + candleSpace * i + candleSpace / 2;

      final isHovered = controller.hoveredPoint?.pointIndex == i;

      _drawCandle(canvas, chartArea, candle, x, candleWidth, isHovered);

      // Register hit target
      final centerY = _priceToY(
        (candle.high + candle.low) / 2,
        chartArea,
      );

      hitTester.addRect(
        rect: Rect.fromCenter(
          center: Offset(x, centerY),
          width: candleSpace,
          height: _priceToY(candle.low, chartArea) - _priceToY(candle.high, chartArea),
        ),
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset(x, _priceToY(candle.close, chartArea)),
          xValue: candle.date,
          yValue: candle.close,
        ),
      );
    }

    // Draw volume bars if enabled
    if (data.showVolume) {
      _drawVolumeBars(canvas, size, candleSpace);
    }
  }

  void _drawCandle(
    Canvas canvas,
    Rect chartArea,
    CandlestickDataPoint candle,
    double x,
    double candleWidth,
    bool isHovered,
  ) {
    final color = candle.isBullish ? data.bullishColor : data.bearishColor;
    var displayColor = color;
    if (isHovered) {
      displayColor = color.withValues(alpha: 1);
    }

    final highY = _priceToY(candle.high, chartArea);
    final lowY = _priceToY(candle.low, chartArea);
    final openY = _priceToY(candle.open, chartArea);
    final closeY = _priceToY(candle.close, chartArea);

    // Animate from middle
    final animatedHighY = chartArea.center.dy + (highY - chartArea.center.dy) * animationValue;
    final animatedLowY = chartArea.center.dy + (lowY - chartArea.center.dy) * animationValue;
    final animatedOpenY = chartArea.center.dy + (openY - chartArea.center.dy) * animationValue;
    final animatedCloseY = chartArea.center.dy + (closeY - chartArea.center.dy) * animationValue;

    // Draw wick
    final wickPaint = Paint()
      ..color = displayColor
      ..strokeWidth = data.wickWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, animatedHighY),
      Offset(x, animatedLowY),
      wickPaint,
    );

    // Draw body based on style
    switch (data.style) {
      case CandlestickStyle.filled:
        _drawFilledBody(canvas, x, candleWidth, animatedOpenY, animatedCloseY, displayColor, candle.isBullish);

      case CandlestickStyle.hollow:
        _drawHollowBody(canvas, x, candleWidth, animatedOpenY, animatedCloseY, displayColor, candle.isBullish);

      case CandlestickStyle.ohlc:
        _drawOHLCBody(canvas, x, candleWidth, animatedOpenY, animatedCloseY, displayColor);
    }

    // Draw hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(
          x - candleWidth / 2 - 2,
          chartArea.top,
          x + candleWidth / 2 + 2,
          chartArea.bottom,
        ),
        highlightPaint,
      );
    }
  }

  void _drawFilledBody(
    Canvas canvas,
    double x,
    double width,
    double openY,
    double closeY,
    Color color,
    bool isBullish,
  ) {
    final bodyRect = Rect.fromLTRB(
      x - width / 2,
      math.min(openY, closeY),
      x + width / 2,
      math.max(openY, closeY),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(bodyRect, paint);
  }

  void _drawHollowBody(
    Canvas canvas,
    double x,
    double width,
    double openY,
    double closeY,
    Color color,
    bool isBullish,
  ) {
    final bodyRect = Rect.fromLTRB(
      x - width / 2,
      math.min(openY, closeY),
      x + width / 2,
      math.max(openY, closeY),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = isBullish ? PaintingStyle.stroke : PaintingStyle.fill;

    canvas.drawRect(bodyRect, paint);
  }

  void _drawOHLCBody(
    Canvas canvas,
    double x,
    double width,
    double openY,
    double closeY,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left tick (open)
    canvas.drawLine(
      Offset(x - width / 2, openY),
      Offset(x, openY),
      paint,
    );

    // Right tick (close)
    canvas.drawLine(
      Offset(x, closeY),
      Offset(x + width / 2, closeY),
      paint,
    );
  }

  void _drawVolumeBars(Canvas canvas, Size size, double candleSpace) {
    final volumeArea = Rect.fromLTRB(
      padding.left,
      size.height - padding.bottom - size.height * data.volumeHeightRatio,
      size.width - padding.right,
      size.height - padding.bottom,
    );

    // Draw separator line
    final separatorPaint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(volumeArea.left, volumeArea.top),
      Offset(volumeArea.right, volumeArea.top),
      separatorPaint,
    );

    final barWidth = candleSpace * data.candleWidth * 0.8;

    for (var i = 0; i < data.data.length; i++) {
      final candle = data.data[i];
      if (candle.volume == null) continue;

      final x = volumeArea.left + candleSpace * i + candleSpace / 2;
      final volumeRatio = candle.volume! / _volumeMax;
      final barHeight = volumeArea.height * volumeRatio * animationValue;

      final color = data.volumeColor ??
          (candle.isBullish ? data.bullishColor : data.bearishColor);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(
          x - barWidth / 2,
          volumeArea.bottom - barHeight,
          x + barWidth / 2,
          volumeArea.bottom,
        ),
        paint,
      );
    }
  }

  double _priceToY(double price, Rect chartArea) {
    final range = _priceMax - _priceMin;
    if (range == 0) return chartArea.center.dy;

    final normalized = (price - _priceMin) / range;
    return chartArea.bottom - (chartArea.height * normalized);
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
    final range = _priceMax - _priceMin;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    for (var i = 0; i <= labelCount; i++) {
      final value = _priceMin + (range * i / labelCount);
      final y = chartArea.bottom - (chartArea.height * i / labelCount);

      final label = _formatPrice(value);

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
    if (data.data.isEmpty) return;

    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: theme.labelStyle.color?.withValues(alpha: 0.7),
    );

    // Show labels at intervals
    final candleCount = data.data.length;
    final labelInterval = (candleCount / 5).ceil().clamp(1, candleCount);
    final candleSpace = chartArea.width / candleCount;

    for (var i = 0; i < candleCount; i += labelInterval) {
      final candle = data.data[i];
      final x = chartArea.left + candleSpace * i + candleSpace / 2;

      final label = '${candle.date.month}/${candle.date.day}';

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

  String _formatPrice(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant _CandlestickChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
