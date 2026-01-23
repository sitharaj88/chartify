import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'gantt_chart_data.dart';

export 'gantt_chart_data.dart';

/// A Gantt chart widget.
///
/// Displays project timeline with tasks, progress, and dependencies.
///
/// Example:
/// ```dart
/// GanttChart(
///   data: GanttChartData(
///     tasks: [
///       GanttTask(
///         id: '1',
///         label: 'Task 1',
///         start: DateTime(2024, 1, 1),
///         end: DateTime(2024, 1, 15),
///         progress: 0.5,
///       ),
///       GanttTask(
///         id: '2',
///         label: 'Task 2',
///         start: DateTime(2024, 1, 10),
///         end: DateTime(2024, 1, 25),
///         dependencies: ['1'],
///       ),
///     ],
///   ),
/// )
/// ```
class GanttChart extends StatefulWidget {
  const GanttChart({
    super.key,
    required this.data,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onTaskTap,
    this.padding = const EdgeInsets.all(16),
  });

  final GanttChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, GanttTask task)? onTaskTap;
  final EdgeInsets padding;

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart>
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
  void didUpdateWidget(GanttChart oldWidget) {
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
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: 0);
              if (hitInfo != null && widget.onTaskTap != null) {
                final idx = hitInfo.pointIndex;
                if (idx >= 0 && idx < widget.data.tasks.length) {
                  widget.onTaskTap!(idx, widget.data.tasks[idx]);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GanttChartPainter(
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
    if (idx < 0 || idx >= widget.data.tasks.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final task = widget.data.tasks[idx];
    final color = task.color ?? theme.getSeriesColor(idx);

    final entries = <TooltipEntry>[
      TooltipEntry(
        color: color,
        label: 'Duration',
        value: task.duration.inDays.toDouble(),
        formattedValue: '${task.duration.inDays} days',
      ),
    ];

    if (widget.data.showProgress) {
      entries.add(TooltipEntry(
        color: color.withValues(alpha: 0.5),
        label: 'Progress',
        value: task.progress * 100,
        formattedValue: '${(task.progress * 100).toStringAsFixed(0)}%',
      ));
    }

    return TooltipData(
      position: info.position,
      entries: entries,
      xLabel: task.label,
    );
  }
}

class _GanttChartPainter extends ChartPainter {
  _GanttChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
  }) : super(repaint: controller);

  final GanttChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Rect getChartArea(Size size) {
    final labelWidth = data.showLabels ? data.labelWidth : 0.0;
    final dateHeight = data.showDates ? 30.0 : 0.0;

    return Rect.fromLTRB(
      padding.left + labelWidth,
      padding.top + dateHeight,
      size.width - padding.right,
      size.height - padding.bottom,
    );
  }

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.tasks.isEmpty) return;

    final startDate = data.computedStartDate;
    final endDate = data.computedEndDate;
    final totalDuration = data.totalDuration;

    if (totalDuration.inMilliseconds <= 0) return;

    // Draw date axis
    if (data.showDates) {
      _drawDateAxis(canvas, chartArea, startDate, endDate);
    }

    // Draw grid
    _drawGrid(canvas, chartArea, startDate, endDate);

    // Draw tasks
    final rowHeight = data.barHeight + data.barSpacing;

    for (var i = 0; i < data.tasks.length; i++) {
      final task = data.tasks[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      final color = task.color ?? theme.getSeriesColor(i);

      final y = chartArea.top + i * rowHeight;

      // Calculate x positions
      final startOffset = task.start.difference(startDate);
      final endOffset = task.end.difference(startDate);

      final startRatio =
          startOffset.inMilliseconds / totalDuration.inMilliseconds;
      final endRatio = endOffset.inMilliseconds / totalDuration.inMilliseconds;

      // Apply animation
      final animatedEndRatio =
          startRatio + (endRatio - startRatio) * animationValue;

      final startX = chartArea.left + startRatio * chartArea.width;
      final endX = chartArea.left + animatedEndRatio * chartArea.width;

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, task, y, chartArea);
      }

      if (task.isMilestone) {
        // Draw milestone (diamond)
        _drawMilestone(canvas, startX, y, color, isHovered);
      } else {
        // Draw task bar
        final barRect = Rect.fromLTWH(
          startX,
          y,
          endX - startX,
          data.barHeight,
        );

        _drawTaskBar(canvas, barRect, task, color, isHovered);
      }

      // Register hit target
      hitTester.addRect(
        rect: Rect.fromLTWH(startX, y, endX - startX, data.barHeight),
        info: DataPointInfo(
          seriesIndex: 0,
          pointIndex: i,
          position: Offset((startX + endX) / 2, y + data.barHeight / 2),
          xValue: i,
          yValue: task.progress,
        ),
      );
    }

    // Draw dependencies
    if (data.showDependencies) {
      _drawDependencies(canvas, chartArea, startDate, totalDuration, rowHeight);
    }
  }

  void _drawDateAxis(
      Canvas canvas, Rect chartArea, DateTime startDate, DateTime endDate) {
    final totalDays = endDate.difference(startDate).inDays;

    // Determine appropriate date interval
    int interval;
    if (totalDays <= 14) {
      interval = 1; // Daily
    } else if (totalDays <= 60) {
      interval = 7; // Weekly
    } else {
      interval = 30; // Monthly
    }

    var current = startDate;
    while (current.isBefore(endDate)) {
      final ratio = current.difference(startDate).inMilliseconds /
          endDate.difference(startDate).inMilliseconds;
      final x = chartArea.left + ratio * chartArea.width;

      String label;
      if (interval == 1) {
        label = '${current.day}';
      } else if (interval == 7) {
        label = '${_monthNames[current.month - 1]} ${current.day}';
      } else {
        label = _monthNames[current.month - 1];
      }

      final textSpan = TextSpan(
        text: label,
        style: theme.labelStyle.copyWith(fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartArea.top - textPainter.height - 8),
      );

      current = current.add(Duration(days: interval));
    }
  }

  void _drawGrid(
      Canvas canvas, Rect chartArea, DateTime startDate, DateTime endDate) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    final totalDays = endDate.difference(startDate).inDays;

    // Vertical grid lines
    int interval = totalDays <= 14 ? 1 : (totalDays <= 60 ? 7 : 30);
    var current = startDate;
    while (current.isBefore(endDate)) {
      final ratio = current.difference(startDate).inMilliseconds /
          endDate.difference(startDate).inMilliseconds;
      final x = chartArea.left + ratio * chartArea.width;

      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        paint,
      );

      current = current.add(Duration(days: interval));
    }

    // Horizontal grid lines
    final rowHeight = data.barHeight + data.barSpacing;
    for (var i = 0; i <= data.tasks.length; i++) {
      final y = chartArea.top + i * rowHeight - data.barSpacing / 2;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );
    }
  }

  void _drawLabel(Canvas canvas, GanttTask task, double y, Rect chartArea) {
    final textSpan = TextSpan(
      text: task.label,
      style: theme.labelStyle.copyWith(fontSize: 11),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: data.labelWidth - 8);

    textPainter.paint(
      canvas,
      Offset(
        chartArea.left - data.labelWidth,
        y + (data.barHeight - textPainter.height) / 2,
      ),
    );
  }

  void _drawTaskBar(Canvas canvas, Rect rect, GanttTask task, Color color,
      bool isHovered) {
    // Background bar
    final bgPaint = Paint()
      ..color = isHovered ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(data.barRadius),
    );
    canvas.drawRRect(rRect, bgPaint);

    // Progress bar
    if (data.showProgress && task.progress > 0) {
      final progressRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * task.progress * animationValue,
        rect.height,
      );

      final progressPaint = Paint()
        ..color = isHovered ? color : color.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      final progressRRect = RRect.fromRectAndRadius(
        progressRect,
        Radius.circular(data.barRadius),
      );
      canvas.drawRRect(progressRRect, progressPaint);
    }

    // Border
    if (isHovered) {
      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rRect, borderPaint);
    }
  }

  void _drawMilestone(
      Canvas canvas, double x, double y, Color color, bool isHovered) {
    final size = data.barHeight * 0.6;
    final centerY = y + data.barHeight / 2;

    final path = Path()
      ..moveTo(x, centerY - size / 2)
      ..lineTo(x + size / 2, centerY)
      ..lineTo(x, centerY + size / 2)
      ..lineTo(x - size / 2, centerY)
      ..close();

    final fillPaint = Paint()
      ..color = isHovered ? color : color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (isHovered) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawDependencies(Canvas canvas, Rect chartArea, DateTime startDate,
      Duration totalDuration, double rowHeight) {
    final taskMap = <String, int>{};
    for (var i = 0; i < data.tasks.length; i++) {
      taskMap[data.tasks[i].id] = i;
    }

    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < data.tasks.length; i++) {
      final task = data.tasks[i];
      if (task.dependencies == null) continue;

      for (final depId in task.dependencies!) {
        final depIndex = taskMap[depId];
        if (depIndex == null) continue;

        final depTask = data.tasks[depIndex];

        // Calculate positions
        final depEndRatio = depTask.end.difference(startDate).inMilliseconds /
            totalDuration.inMilliseconds;
        final taskStartRatio =
            task.start.difference(startDate).inMilliseconds /
                totalDuration.inMilliseconds;

        final startX = chartArea.left + depEndRatio * chartArea.width;
        final startY = chartArea.top + depIndex * rowHeight + data.barHeight / 2;
        final endX = chartArea.left + taskStartRatio * chartArea.width;
        final endY = chartArea.top + i * rowHeight + data.barHeight / 2;

        // Draw arrow
        final path = Path()
          ..moveTo(startX, startY)
          ..lineTo(startX + 10, startY)
          ..lineTo(startX + 10, endY)
          ..lineTo(endX, endY);

        canvas.drawPath(path, paint);

        // Arrowhead
        final arrowPath = Path()
          ..moveTo(endX, endY)
          ..lineTo(endX - 6, endY - 4)
          ..lineTo(endX - 6, endY + 4)
          ..close();

        final arrowPaint = Paint()
          ..color = theme.gridLineColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GanttChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
