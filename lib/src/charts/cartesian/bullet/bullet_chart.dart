import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'bullet_chart_data.dart';

export 'bullet_chart_data.dart';

/// A bullet chart widget.
///
/// Displays comparative metrics with ranges and targets,
/// commonly used for KPI dashboards.
///
/// Example:
/// ```dart
/// BulletChart(
///   data: BulletChartData(
///     items: [
///       BulletItem(
///         label: 'Revenue',
///         value: 270,
///         target: 250,
///         ranges: [150, 225, 300],
///       ),
///     ],
///   ),
/// )
/// ```
class BulletChart extends StatefulWidget {
  const BulletChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onItemTap,
    this.padding = const EdgeInsets.all(16),
  });

  final BulletChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, BulletItem item)? onItemTap;
  final EdgeInsets padding;

  @override
  State<BulletChart> createState() => _BulletChartState();
}

class _BulletChartState extends State<BulletChart>
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
  void didUpdateWidget(BulletChart oldWidget) {
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

  void _handleHover(PointerEvent event, double hitRadius) {
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: hitRadius);
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
    } else {
      _controller.clearHoveredPoint();
    }
  }

  void _handleTap(TapDownDetails details, double hitRadius) {
    final hitInfo = _hitTester.hitTest(details.localPosition, radius: hitRadius);
    if (hitInfo != null && widget.onItemTap != null) {
      final idx = hitInfo.pointIndex;
      if (idx >= 0 && idx < widget.data.items.length) {
        widget.onItemTap!(idx, widget.data.items[idx]);
      }
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
            onTap: (details) => _handleTap(details, hitRadius),
            onHover: (event) => _handleHover(event, hitRadius),
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BulletChartPainter(
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
    final idx = info.pointIndex;
    if (idx < 0 || idx >= widget.data.items.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final item = widget.data.items[idx];
    final color =
        item.color ?? widget.data.valueColor ?? theme.getSeriesColor(0);

    final entries = <TooltipEntry>[
      TooltipEntry(
        color: color,
        label: 'Value',
        value: item.value,
        formattedValue: item.value.toStringAsFixed(1),
      ),
    ];

    if (item.target != null) {
      entries.add(TooltipEntry(
        color: widget.data.targetColor ?? Colors.black,
        label: 'Target',
        value: item.target,
        formattedValue: item.target!.toStringAsFixed(1),
      ),);
    }

    return TooltipData(
      position: info.position,
      entries: entries,
      xLabel: item.label,
    );
  }
}

class _BulletChartPainter extends ChartPainter {
  _BulletChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final BulletChartData data;
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

    if (data.items.isEmpty) return;

    final isHorizontal = data.orientation == BulletOrientation.horizontal;
    final itemCount = data.items.length;

    // Calculate item dimensions
    double itemSize;
    if (isHorizontal) {
      itemSize =
          (chartArea.height - (itemCount - 1) * data.spacing) / itemCount;
    } else {
      itemSize = (chartArea.width - (itemCount - 1) * data.spacing) / itemCount;
    }

    for (var i = 0; i < itemCount; i++) {
      final item = data.items[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      Rect itemRect;
      if (isHorizontal) {
        final y = chartArea.top + i * (itemSize + data.spacing);
        itemRect = Rect.fromLTWH(
          chartArea.left + (data.showLabels ? data.labelWidth : 0),
          y,
          chartArea.width - (data.showLabels ? data.labelWidth : 0),
          itemSize,
        );
      } else {
        final x = chartArea.left + i * (itemSize + data.spacing);
        itemRect = Rect.fromLTWH(
          x,
          chartArea.top,
          itemSize,
          chartArea.height - (data.showLabels ? data.labelWidth : 0),
        );
      }

      _drawBullet(canvas, item, itemRect, i, isHovered, isHorizontal);

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, item, itemRect, itemSize, isHorizontal);
      }

      // Register hit target
      hitTester.addRect(
        rect: itemRect,
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: itemRect.center,
          xValue: i,
          yValue: item.value,
        ),
      );
    }
  }

  void _drawBullet(
    Canvas canvas,
    BulletItem item,
    Rect rect,
    int index,
    bool isHovered,
    bool isHorizontal,
  ) {
    final maxValue = item.computedMax;
    if (maxValue <= 0) return;

    // Get range colors
    final rangeColors = data.rangeColors ?? BulletChartData.defaultRangeColors;

    // Draw range bands (background)
    _drawRanges(canvas, item, rect, rangeColors, isHorizontal, maxValue);

    // Draw value bar
    _drawValueBar(canvas, item, rect, index, isHovered, isHorizontal, maxValue);

    // Draw target marker
    if (item.target != null) {
      _drawTarget(canvas, item, rect, isHorizontal, maxValue);
    }
  }

  void _drawRanges(
    Canvas canvas,
    BulletItem item,
    Rect rect,
    List<Color> colors,
    bool isHorizontal,
    double maxValue,
  ) {
    const rangeRadius = Radius.circular(4);

    if (item.ranges.isEmpty) {
      // Draw single background
      final paint = Paint()
        ..isAntiAlias = true
        ..color = colors.isNotEmpty
            ? colors.first.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, rangeRadius), paint);
      return;
    }

    for (var i = item.ranges.length - 1; i >= 0; i--) {
      final rangeValue = item.ranges[i];
      final color = i < colors.length ? colors[i] : colors.last;

      final ratio = (rangeValue / maxValue).clamp(0.0, 1.0);

      Rect rangeRect;
      if (isHorizontal) {
        rangeRect = Rect.fromLTWH(
          rect.left,
          rect.top,
          rect.width * ratio,
          rect.height,
        );
      } else {
        rangeRect = Rect.fromLTWH(
          rect.left,
          rect.bottom - rect.height * ratio,
          rect.width,
          rect.height * ratio,
        );
      }

      final paint = Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: animationValue * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(rangeRect, rangeRadius), paint);
    }
  }

  void _drawValueBar(
    Canvas canvas,
    BulletItem item,
    Rect rect,
    int index,
    bool isHovered,
    bool isHorizontal,
    double maxValue,
  ) {
    final ratio = ((item.value / maxValue) * animationValue).clamp(0.0, 1.0);
    final valueColor =
        item.color ?? data.valueColor ?? theme.getSeriesColor(index);

    final barHeight = rect.height * data.valueHeight;
    final barOffset = (rect.height - barHeight) / 2;

    Rect valueRect;
    if (isHorizontal) {
      valueRect = Rect.fromLTWH(
        rect.left,
        rect.top + barOffset,
        rect.width * ratio,
        barHeight,
      );
    } else {
      final barWidth = rect.width * data.valueHeight;
      final barXOffset = (rect.width - barWidth) / 2;
      valueRect = Rect.fromLTWH(
        rect.left + barXOffset,
        rect.bottom - rect.height * ratio,
        barWidth,
        rect.height * ratio,
      );
    }

    var fillColor = valueColor;
    if (isHovered) {
      fillColor = valueColor.withValues(alpha: 1);
    }

    final paint = Paint()
      ..isAntiAlias = true
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(valueRect, Radius.circular(theme.barCornerRadius * 0.67)),
      paint,
    );

    // Draw value text if enabled
    if (data.showValues && valueRect.width > 30) {
      final textStyle = theme.labelStyle.copyWith(
        fontSize: labelFontSize * 0.9,
        color: _getContrastColor(fillColor),
        fontWeight: FontWeight.bold,
      );

      final textSpan =
          TextSpan(text: item.value.toStringAsFixed(0), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      if (isHorizontal && textPainter.width < valueRect.width - 8) {
        textPainter.paint(
          canvas,
          Offset(
            valueRect.right - textPainter.width - 4,
            valueRect.center.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawTarget(
    Canvas canvas,
    BulletItem item,
    Rect rect,
    bool isHorizontal,
    double maxValue,
  ) {
    final targetRatio = (item.target! / maxValue).clamp(0.0, 1.0);
    final targetColor = data.targetColor ?? Colors.black87;

    final paint = Paint()
      ..isAntiAlias = true
      ..color = targetColor.withValues(alpha: animationValue)
      ..strokeWidth = data.targetWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isHorizontal) {
      final x = rect.left + rect.width * targetRatio;
      canvas.drawLine(
        Offset(x, rect.top + rect.height * 0.15),
        Offset(x, rect.bottom - rect.height * 0.15),
        paint,
      );
    } else {
      final y = rect.bottom - rect.height * targetRatio;
      canvas.drawLine(
        Offset(rect.left + rect.width * 0.15, y),
        Offset(rect.right - rect.width * 0.15, y),
        paint,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    BulletItem item,
    Rect bulletRect,
    double itemSize,
    bool isHorizontal,
  ) {
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: item.label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: isHorizontal ? TextAlign.right : TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: data.labelWidth - 8);

    if (isHorizontal) {
      textPainter.paint(
        canvas,
        Offset(
          bulletRect.left - textPainter.width - 8,
          bulletRect.center.dy - textPainter.height / 2,
        ),
      );
    } else {
      textPainter.paint(
        canvas,
        Offset(
          bulletRect.center.dx - textPainter.width / 2,
          bulletRect.bottom + 8,
        ),
      );
    }
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _BulletChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
