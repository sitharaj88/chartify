import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A task in the Gantt chart.
@immutable
class GanttTask {
  const GanttTask({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    this.progress = 0.0,
    this.color,
    this.dependencies,
    this.isMilestone = false,
  });

  /// Unique identifier for this task.
  final String id;

  /// Display label for this task.
  final String label;

  /// Start date/time.
  final DateTime start;

  /// End date/time.
  final DateTime end;

  /// Progress (0.0 to 1.0).
  final double progress;

  /// Optional custom color.
  final Color? color;

  /// IDs of tasks this task depends on.
  final List<String>? dependencies;

  /// Whether this is a milestone (single point in time).
  final bool isMilestone;

  /// Duration of the task.
  Duration get duration => end.difference(start);
}

/// Data configuration for Gantt chart.
@immutable
class GanttChartData {
  const GanttChartData({
    required this.tasks,
    this.barHeight = 24.0,
    this.barSpacing = 8.0,
    this.barRadius = 4.0,
    this.showProgress = true,
    this.showDependencies = false,
    this.showLabels = true,
    this.showDates = true,
    this.labelWidth = 120.0,
    this.startDate,
    this.endDate,
    this.animation,
  });

  /// List of tasks.
  final List<GanttTask> tasks;

  /// Height of task bars.
  final double barHeight;

  /// Spacing between bars.
  final double barSpacing;

  /// Corner radius of bars.
  final double barRadius;

  /// Whether to show progress overlay.
  final bool showProgress;

  /// Whether to draw dependency lines.
  final bool showDependencies;

  /// Whether to show task labels.
  final bool showLabels;

  /// Whether to show date labels on axis.
  final bool showDates;

  /// Width for label column.
  final double labelWidth;

  /// Start date for the chart (auto-calculated if null).
  final DateTime? startDate;

  /// End date for the chart (auto-calculated if null).
  final DateTime? endDate;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get computed start date.
  DateTime get computedStartDate {
    if (startDate != null) return startDate!;
    if (tasks.isEmpty) return DateTime.now();
    return tasks.map((t) => t.start).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Get computed end date.
  DateTime get computedEndDate {
    if (endDate != null) return endDate!;
    if (tasks.isEmpty) return DateTime.now().add(const Duration(days: 30));
    return tasks.map((t) => t.end).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Total duration of the chart.
  Duration get totalDuration =>
      computedEndDate.difference(computedStartDate);
}
