import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'calendar_heatmap_data.dart';

export 'calendar_heatmap_data.dart';

/// A calendar heatmap chart widget (GitHub contribution style).
///
/// Displays values over time in a calendar grid format.
///
/// Example:
/// ```dart
/// CalendarHeatmapChart(
///   data: CalendarHeatmapData(
///     data: [
///       CalendarDataPoint(date: DateTime(2024, 1, 1), value: 5),
///       CalendarDataPoint(date: DateTime(2024, 1, 2), value: 3),
///       // ... more data points
///     ],
///   ),
/// )
/// ```
class CalendarHeatmapChart extends StatefulWidget {
  const CalendarHeatmapChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onDayTap,
    this.padding = const EdgeInsets.all(16),
  });

  final CalendarHeatmapData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(DateTime date, double? value)? onDayTap;
  final EdgeInsets padding;

  @override
  State<CalendarHeatmapChart> createState() => _CalendarHeatmapChartState();
}

class _CalendarHeatmapChartState extends State<CalendarHeatmapChart>
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
  void didUpdateWidget(CalendarHeatmapChart oldWidget) {
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
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: 0);
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
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: 0);
              if (hitInfo != null && widget.onDayTap != null) {
                // Decode date from pointIndex
                final startDate = widget.data.computedStartDate;
                final date = startDate.add(Duration(days: hitInfo.pointIndex));
                final dataMap = widget.data.toDataMap();
                final key = _dateKey(date);
                widget.onDayTap!(date, dataMap[key]);
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CalendarHeatmapPainter(
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
    final startDate = widget.data.computedStartDate;
    final date = startDate.add(Duration(days: info.pointIndex));
    final dataMap = widget.data.toDataMap();
    final key = _dateKey(date);
    final value = dataMap[key];

    final colors =
        widget.data.colorStops ?? CalendarHeatmapData.defaultColorStops;
    final color = value != null && value > 0 ? colors.last : colors.first;

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: 'Value',
          value: value ?? 0,
          formattedValue: value?.toStringAsFixed(0) ?? 'No data',
        ),
      ],
      xLabel: _formatDate(date),
    );
  }

  String _formatDate(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _CalendarHeatmapPainter extends ChartPainter {
  _CalendarHeatmapPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final CalendarHeatmapData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;

  static const _dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', ''];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Rect getChartArea(Size size) {
    final dayLabelWidth = data.showDayLabels ? 30.0 : 0.0;
    final monthLabelHeight = data.showMonthLabels ? 20.0 : 0.0;

    return Rect.fromLTRB(
      padding.left + dayLabelWidth,
      padding.top + monthLabelHeight,
      size.width - padding.right,
      size.height - padding.bottom,
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    final startDate = data.computedStartDate;
    final endDate = data.computedEndDate;
    final dataMap = data.toDataMap();
    final (minValue, maxValue) = data.calculateRange();
    final colors = data.colorStops ?? CalendarHeatmapData.defaultColorStops;
    final emptyColor = data.emptyColor ?? colors.first;

    final cellTotal = data.cellSize + data.cellSpacing;

    // Find the first Sunday before or on startDate
    var current = startDate;
    while (current.weekday != DateTime.sunday) {
      current = current.subtract(const Duration(days: 1));
    }

    // Draw day labels
    if (data.showDayLabels) {
      _drawDayLabels(canvas, chartArea, cellTotal);
    }

    var week = 0;
    var lastMonth = -1;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final dayOfWeek = current.weekday % 7; // Sunday = 0, Monday = 1, etc.

      // Draw month label when month changes
      if (data.showMonthLabels && current.month != lastMonth && dayOfWeek == 0) {
        _drawMonthLabel(canvas, chartArea, week, current.month);
        lastMonth = current.month;
      }

      // Only draw if within date range
      if (!current.isBefore(startDate)) {
        final x = chartArea.left + week * cellTotal;
        final y = chartArea.top + dayOfWeek * cellTotal;

        final key = _dateKey(current);
        final value = dataMap[key];

        // Calculate color
        Color cellColor;
        if (value == null || value <= 0) {
          cellColor = emptyColor;
        } else {
          final ratio = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
          cellColor = _getColorForRatio(ratio, colors);
        }

        // Apply animation
        final animatedColor = Color.lerp(emptyColor, cellColor, animationValue)!;

        // Check if hovered
        final dayIndex = current.difference(startDate).inDays;
        final isHovered = controller.hoveredPoint?.pointIndex == dayIndex;

        // Draw cell
        final rect = Rect.fromLTWH(x, y, data.cellSize, data.cellSize);
        final paint = Paint()
          ..color = animatedColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final rRect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(data.cellRadius),
        );
        canvas.drawRRect(rRect, paint);

        // Draw hover border
        if (isHovered) {
          final borderPaint = Paint()
            ..color = theme.axisLineColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true;
          canvas.drawRRect(rRect, borderPaint);
        }

        // Register hit target
        hitTester.addRect(
          rect: rect,
          info: DataPointInfo(
            seriesIndex: 0,
            pointIndex: dayIndex,
            position: rect.center,
            xValue: dayIndex,
            yValue: value ?? 0,
          ),
        );
      }

      // Move to next day
      current = current.add(const Duration(days: 1));
      if (current.weekday == DateTime.sunday) {
        week++;
      }
    }
  }

  void _drawDayLabels(Canvas canvas, Rect chartArea, double cellTotal) {
    for (var day = 0; day < 7; day++) {
      final label = _dayLabels[day];
      if (label.isEmpty) continue;

      final y = chartArea.top + day * cellTotal + data.cellSize / 2;

      final textSpan = TextSpan(
        text: label,
        style: theme.labelStyle.copyWith(fontSize: labelFontSize * 0.82),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(chartArea.left - textPainter.width - 4,
            y - textPainter.height / 2,),
      );
    }
  }

  void _drawMonthLabel(Canvas canvas, Rect chartArea, int week, int month) {
    final x = chartArea.left + week * (data.cellSize + data.cellSpacing);

    final textSpan = TextSpan(
      text: _monthNames[month - 1],
      style: theme.labelStyle.copyWith(fontSize: labelFontSize * 0.91),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x, chartArea.top - textPainter.height - 4),
    );
  }

  Color _getColorForRatio(double ratio, List<Color> colors) {
    // Handle empty or single color array
    if (colors.isEmpty) return Colors.grey;
    if (colors.length == 1) return colors.first;

    // Clamp ratio to valid range to prevent out-of-bounds access
    final clampedRatio = ratio.clamp(0.0, 1.0);

    // Calculate index and local ratio for interpolation
    final scaledValue = clampedRatio * (colors.length - 1);
    final index = scaledValue.floor();
    final localRatio = scaledValue - index;

    // Handle edge case where ratio is exactly 1.0
    if (index >= colors.length - 1) return colors.last;

    return Color.lerp(colors[index], colors[index + 1], localRatio)!;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant _CalendarHeatmapPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
