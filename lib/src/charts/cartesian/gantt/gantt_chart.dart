import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import 'gantt_chart_data.dart';
import 'gantt_scheduler.dart';

export 'gantt_chart_data.dart';
export 'gantt_scheduler.dart';
export 'gantt_validator.dart';

/// A Gantt chart widget.
///
/// Displays project timeline with tasks, progress, and dependencies.
/// Supports enterprise features like baseline tracking, critical path,
/// hierarchy, and resource swimlanes.
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
///     showTodayLine: true,
///     showBaseline: true,
///     highlightCriticalPath: true,
///   ),
/// )
/// ```
class GanttChart extends StatefulWidget {
  const GanttChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onTaskTap,
    this.onTaskDoubleTap,
    this.onGroupToggle,
    this.padding = const EdgeInsets.all(16),
  });

  final GanttChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(int index, GanttTask task)? onTaskTap;
  final void Function(int index, GanttTask task)? onTaskDoubleTap;
  final void Function(String groupId, bool isExpanded)? onGroupToggle;
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
  GanttScheduleResult? _scheduleResult;

  ChartAnimation get _animationConfig =>
      widget.animation ?? widget.data.animation ?? const ChartAnimation();

  @override
  void initState() {
    super.initState();
    _initController();
    _initAnimation();
    _calculateSchedule();
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

  void _calculateSchedule() {
    if (widget.data.highlightCriticalPath) {
      _scheduleResult = GanttScheduler.calculateSchedule(
        widget.data.tasks,
        dependencies: widget.data.dependencies,
      );
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
      _calculateSchedule();
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
                final visibleTasks = widget.data.visibleTasks;
                if (idx >= 0 && idx < visibleTasks.length) {
                  widget.onTaskTap!(idx, visibleTasks[idx]);
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
                  scheduleResult: _scheduleResult,
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
    final visibleTasks = widget.data.visibleTasks;
    if (idx < 0 || idx >= visibleTasks.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final task = visibleTasks[idx];
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
        color: color.withValues(alpha:0.5),
        label: 'Progress',
        value: task.progress * 100,
        formattedValue: '${(task.progress * 100).toStringAsFixed(0)}%',
      ),);
    }

    // Show variance if baseline is available
    if (task.hasBaseline && widget.data.showBaseline) {
      final variance = task.endVarianceDays ?? 0;
      final varianceColor = variance > 0
          ? Colors.red
          : (variance < 0 ? Colors.green : Colors.grey);
      entries.add(TooltipEntry(
        color: varianceColor,
        label: 'Variance',
        value: variance.toDouble(),
        formattedValue: '${variance > 0 ? "+" : ""}$variance days',
      ),);
    }

    // Show if critical
    if (widget.data.highlightCriticalPath &&
        (_scheduleResult?.isTaskCritical(task.id) ?? false)) {
      entries.add(TooltipEntry(
        color: widget.data.criticalPathColor ?? Colors.red,
        label: 'Critical',
        value: 1,
        formattedValue: 'Yes',
      ),);
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
    this.scheduleResult,
  }) : super(repaint: controller);

  final GanttChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final GanttScheduleResult? scheduleResult;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

    final visibleTasks = data.visibleTasks;
    if (visibleTasks.isEmpty) return;

    final startDate = data.computedStartDate;
    final endDate = data.computedEndDate;
    final totalDuration = data.totalDuration;

    if (totalDuration.inMilliseconds <= 0) return;

    // Draw date axis
    if (data.showDates) {
      _drawDateAxis(canvas, chartArea, startDate, endDate);
    }

    // Draw grid
    _drawGrid(canvas, chartArea, startDate, endDate, visibleTasks.length);

    // Draw today line (before tasks so it's behind)
    if (data.showTodayLine) {
      _drawTodayLine(canvas, chartArea, startDate, endDate);
    }

    // Draw tasks
    final rowHeight = data.barHeight + data.barSpacing;

    for (var i = 0; i < visibleTasks.length; i++) {
      final task = visibleTasks[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;
      var color = task.color ?? theme.getSeriesColor(i);

      // Apply critical path color
      if (data.highlightCriticalPath &&
          (scheduleResult?.isTaskCritical(task.id) ?? false)) {
        color = data.criticalPathColor ?? Colors.red;
      }

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

      // Draw baseline bar first (underneath)
      if (data.showBaseline && task.hasBaseline) {
        _drawBaselineBar(canvas, chartArea, task, y, startDate, totalDuration);
      }

      // Draw label with hierarchy indentation
      if (data.showLabels) {
        _drawLabel(canvas, task, y, chartArea);
      }

      if (task.isMilestoneType) {
        // Draw milestone (diamond)
        _drawMilestone(canvas, startX, y, color, isHovered);
      } else if (task.isSummaryType) {
        // Draw summary bar (bracket style)
        _drawSummaryBar(canvas, startX, endX, y, color, isHovered);
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
      _drawDependencies(
        canvas,
        chartArea,
        startDate,
        totalDuration,
        rowHeight,
        visibleTasks,
      );
    }
  }

  void _drawTodayLine(
    Canvas canvas,
    Rect chartArea,
    DateTime startDate,
    DateTime endDate,
  ) {
    final today = DateTime.now();
    if (today.isBefore(startDate) || today.isAfter(endDate)) return;

    final ratio = today.difference(startDate).inMilliseconds /
        endDate.difference(startDate).inMilliseconds;
    final x = chartArea.left + ratio * chartArea.width;

    final paint = Paint()
      ..color = data.todayLineColor ?? Colors.red.withValues(alpha:0.7)
      ..strokeWidth = 2;

    // Draw dashed line
    const dashHeight = 6.0;
    const gapHeight = 4.0;
    var currentY = chartArea.top;

    while (currentY < chartArea.bottom) {
      final nextY = (currentY + dashHeight).clamp(0.0, chartArea.bottom);
      canvas.drawLine(
        Offset(x, currentY),
        Offset(x, nextY),
        paint,
      );
      currentY = nextY + gapHeight;
    }

    // Draw "Today" label
    final textSpan = TextSpan(
      text: 'Today',
      style: theme.labelStyle.copyWith(
        fontSize: 9,
        color: data.todayLineColor ?? Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, chartArea.top - textPainter.height - 2),
    );
  }

  void _drawBaselineBar(
    Canvas canvas,
    Rect chartArea,
    GanttTask task,
    double y,
    DateTime startDate,
    Duration totalDuration,
  ) {
    final baselineStartOffset = task.baselineStart!.difference(startDate);
    final baselineEndOffset = task.baselineEnd!.difference(startDate);

    final startRatio =
        baselineStartOffset.inMilliseconds / totalDuration.inMilliseconds;
    final endRatio =
        baselineEndOffset.inMilliseconds / totalDuration.inMilliseconds;

    final startX = chartArea.left + startRatio * chartArea.width;
    final endX = chartArea.left + endRatio * chartArea.width;

    // Draw baseline as a thin bar below the main bar
    final baselineY = y + data.barHeight - 4;
    final baselineRect = Rect.fromLTWH(
      startX,
      baselineY,
      endX - startX,
      3,
    );

    final paint = Paint()
      ..color = data.baselineColor ?? Colors.grey.withValues(alpha:0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(baselineRect, paint);
  }

  void _drawSummaryBar(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    Color color,
    bool isHovered,
  ) {
    final barHeight = data.barHeight * 0.4;
    final centerY = y + data.barHeight / 2;
    final topY = centerY - barHeight / 2;

    // Draw main bar
    final paint = Paint()
      ..color = isHovered ? color : color.withValues(alpha:0.8)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(startX, topY, endX - startX, barHeight);
    canvas.drawRect(rect, paint);

    // Draw bracket ends (downward triangles)
    final triangleSize = barHeight * 1.2;

    // Left bracket
    final leftPath = Path()
      ..moveTo(startX, topY)
      ..lineTo(startX, topY + barHeight + triangleSize)
      ..lineTo(startX + triangleSize / 2, topY + barHeight)
      ..close();
    canvas.drawPath(leftPath, paint);

    // Right bracket
    final rightPath = Path()
      ..moveTo(endX, topY)
      ..lineTo(endX, topY + barHeight + triangleSize)
      ..lineTo(endX - triangleSize / 2, topY + barHeight)
      ..close();
    canvas.drawPath(rightPath, paint);
  }

  void _drawDateAxis(
    Canvas canvas,
    Rect chartArea,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalDays = endDate.difference(startDate).inDays;

    // Determine interval based on view mode
    int interval;
    switch (data.viewMode) {
      case GanttViewMode.day:
        interval = totalDays <= 14 ? 1 : (totalDays <= 60 ? 7 : 30);
      case GanttViewMode.week:
        interval = 7;
      case GanttViewMode.month:
        interval = 30;
      case GanttViewMode.quarter:
        interval = 90;
      case GanttViewMode.year:
        interval = 365;
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
      } else if (interval <= 30) {
        label = _monthNames[current.month - 1];
      } else if (interval <= 90) {
        label = 'Q${((current.month - 1) ~/ 3) + 1} ${current.year}';
      } else {
        label = '${current.year}';
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
        Offset(
          x - textPainter.width / 2,
          chartArea.top - textPainter.height - 8,
        ),
      );

      current = current.add(Duration(days: interval));
    }
  }

  void _drawGrid(
    Canvas canvas,
    Rect chartArea,
    DateTime startDate,
    DateTime endDate,
    int taskCount,
  ) {
    final paint = Paint()
      ..color = theme.gridLineColor.withValues(alpha:0.2)
      ..strokeWidth = 1;

    final totalDays = endDate.difference(startDate).inDays;

    // Vertical grid lines
    final interval = totalDays <= 14 ? 1 : (totalDays <= 60 ? 7 : 30);
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
    for (var i = 0; i <= taskCount; i++) {
      final y = chartArea.top + i * rowHeight - data.barSpacing / 2;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );
    }
  }

  void _drawLabel(Canvas canvas, GanttTask task, double y, Rect chartArea) {
    // Calculate indentation based on hierarchy level
    final indent = data.showHierarchy ? task.level * 16.0 : 0.0;
    final availableWidth = data.labelWidth - 8 - indent;

    // Draw expand/collapse icon for groups
    if (data.showHierarchy && task.isGroup) {
      final iconX = chartArea.left - data.labelWidth + indent;
      final iconY = y + data.barHeight / 2;
      const iconSize = 10.0;

      final iconPaint = Paint()
        ..color = theme.labelStyle.color ?? Colors.black
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw +/- icon
      final isCollapsed = data.collapsedGroupIds.contains(task.id);

      // Horizontal line (always)
      canvas.drawLine(
        Offset(iconX, iconY),
        Offset(iconX + iconSize, iconY),
        iconPaint,
      );

      // Vertical line (only if collapsed, showing +)
      if (isCollapsed) {
        canvas.drawLine(
          Offset(iconX + iconSize / 2, iconY - iconSize / 2),
          Offset(iconX + iconSize / 2, iconY + iconSize / 2),
          iconPaint,
        );
      }
    }

    final textX = chartArea.left - data.labelWidth + indent +
        (data.showHierarchy && task.isGroup ? 16.0 : 0.0);

    final textSpan = TextSpan(
      text: task.label,
      style: theme.labelStyle.copyWith(
        fontSize: 11,
        fontWeight: task.isGroup ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: availableWidth > 0 ? availableWidth : 50);

    textPainter.paint(
      canvas,
      Offset(
        textX,
        y + (data.barHeight - textPainter.height) / 2,
      ),
    );
  }

  void _drawTaskBar(
    Canvas canvas,
    Rect rect,
    GanttTask task,
    Color color,
    bool isHovered,
  ) {
    // Background bar
    final bgPaint = Paint()
      ..color = isHovered ? color.withValues(alpha:0.4) : color.withValues(alpha:0.3)
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
        ..color = isHovered ? color : color.withValues(alpha:0.9)
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
    Canvas canvas,
    double x,
    double y,
    Color color,
    bool isHovered,
  ) {
    final size = data.barHeight * 0.6;
    final centerY = y + data.barHeight / 2;

    final path = Path()
      ..moveTo(x, centerY - size / 2)
      ..lineTo(x + size / 2, centerY)
      ..lineTo(x, centerY + size / 2)
      ..lineTo(x - size / 2, centerY)
      ..close();

    final fillPaint = Paint()
      ..color = isHovered ? color : color.withValues(alpha:0.8)
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

  void _drawDependencies(
    Canvas canvas,
    Rect chartArea,
    DateTime startDate,
    Duration totalDuration,
    double rowHeight,
    List<GanttTask> visibleTasks,
  ) {
    final taskMap = <String, int>{};
    for (var i = 0; i < visibleTasks.length; i++) {
      taskMap[visibleTasks[i].id] = i;
    }

    final paint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw explicit dependencies with type support
    for (final dep in data.dependencies) {
      final fromIndex = taskMap[dep.fromTaskId];
      final toIndex = taskMap[dep.toTaskId];
      if (fromIndex == null || toIndex == null) continue;

      final fromTask = visibleTasks[fromIndex];
      final toTask = visibleTasks[toIndex];

      _drawDependencyArrow(
        canvas,
        chartArea,
        startDate,
        totalDuration,
        rowHeight,
        fromTask,
        toTask,
        fromIndex,
        toIndex,
        dep.type,
        paint,
      );
    }

    // Draw simple dependencies (FS type)
    for (var i = 0; i < visibleTasks.length; i++) {
      final task = visibleTasks[i];
      if (task.dependencies == null) continue;

      for (final depId in task.dependencies!) {
        // Skip if already drawn as explicit dependency
        final alreadyDrawn = data.dependencies.any(
          (d) => d.fromTaskId == depId && d.toTaskId == task.id,
        );
        if (alreadyDrawn) continue;

        final depIndex = taskMap[depId];
        if (depIndex == null) continue;

        final depTask = visibleTasks[depIndex];

        _drawDependencyArrow(
          canvas,
          chartArea,
          startDate,
          totalDuration,
          rowHeight,
          depTask,
          task,
          depIndex,
          i,
          DependencyType.finishToStart,
          paint,
        );
      }
    }
  }

  void _drawDependencyArrow(
    Canvas canvas,
    Rect chartArea,
    DateTime startDate,
    Duration totalDuration,
    double rowHeight,
    GanttTask fromTask,
    GanttTask toTask,
    int fromIndex,
    int toIndex,
    DependencyType type,
    Paint paint,
  ) {
    // Calculate start point based on dependency type
    double fromX;
    switch (type) {
      case DependencyType.finishToStart:
      case DependencyType.finishToFinish:
        final ratio = fromTask.end.difference(startDate).inMilliseconds /
            totalDuration.inMilliseconds;
        fromX = chartArea.left + ratio * chartArea.width;
      case DependencyType.startToStart:
      case DependencyType.startToFinish:
        final ratio = fromTask.start.difference(startDate).inMilliseconds /
            totalDuration.inMilliseconds;
        fromX = chartArea.left + ratio * chartArea.width;
    }

    // Calculate end point based on dependency type
    double toX;
    switch (type) {
      case DependencyType.finishToStart:
      case DependencyType.startToStart:
        final ratio = toTask.start.difference(startDate).inMilliseconds /
            totalDuration.inMilliseconds;
        toX = chartArea.left + ratio * chartArea.width;
      case DependencyType.finishToFinish:
      case DependencyType.startToFinish:
        final ratio = toTask.end.difference(startDate).inMilliseconds /
            totalDuration.inMilliseconds;
        toX = chartArea.left + ratio * chartArea.width;
    }

    final fromY = chartArea.top + fromIndex * rowHeight + data.barHeight / 2;
    final toY = chartArea.top + toIndex * rowHeight + data.barHeight / 2;

    // Draw connector line
    const offset = 12.0;
    final path = Path();

    if (type == DependencyType.finishToStart ||
        type == DependencyType.finishToFinish) {
      path.moveTo(fromX, fromY);
      path.lineTo(fromX + offset, fromY);
      path.lineTo(fromX + offset, toY);
      path.lineTo(toX, toY);
    } else {
      path.moveTo(fromX, fromY);
      path.lineTo(fromX - offset, fromY);
      path.lineTo(fromX - offset, toY);
      path.lineTo(toX, toY);
    }

    canvas.drawPath(path, paint);

    // Draw arrowhead
    const arrowSize = 6.0;
    final arrowPath = Path();

    if (type == DependencyType.finishToStart ||
        type == DependencyType.startToStart) {
      // Arrow pointing right (to start)
      arrowPath
        ..moveTo(toX, toY)
        ..lineTo(toX - arrowSize, toY - arrowSize / 1.5)
        ..lineTo(toX - arrowSize, toY + arrowSize / 1.5)
        ..close();
    } else {
      // Arrow pointing left (to finish)
      arrowPath
        ..moveTo(toX, toY)
        ..lineTo(toX + arrowSize, toY - arrowSize / 1.5)
        ..lineTo(toX + arrowSize, toY + arrowSize / 1.5)
        ..close();
    }

    final arrowPaint = Paint()
      ..color = theme.gridLineColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _GanttChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint ||
      scheduleResult != oldDelegate.scheduleResult;
}
