import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import 'gantt_dependency.dart';

export 'gantt_dependency.dart';
export 'gantt_validator.dart';

/// Task constraint types for scheduling.
enum TaskConstraint {
  /// As Soon As Possible - default scheduling.
  asap,

  /// As Late As Possible - schedule at the last possible moment.
  alap,

  /// Must Start On - task must start on the constraint date.
  mustStartOn,

  /// Must Finish On - task must finish on the constraint date.
  mustFinishOn,

  /// Start No Earlier Than - task cannot start before the constraint date.
  startNoEarlierThan,

  /// Start No Later Than - task cannot start after the constraint date.
  startNoLaterThan,

  /// Finish No Earlier Than - task cannot finish before the constraint date.
  finishNoEarlierThan,

  /// Finish No Later Than - task cannot finish after the constraint date.
  finishNoLaterThan,
}

/// Task type for rendering and behavior.
enum TaskType {
  /// Regular task with start and end dates.
  task,

  /// Milestone - a single point in time.
  milestone,

  /// Summary/group task - aggregates child tasks.
  summary,
}

/// View mode for the Gantt chart time scale.
enum GanttViewMode {
  /// Day view - shows individual days.
  day,

  /// Week view - shows weeks.
  week,

  /// Month view - shows months.
  month,

  /// Quarter view - shows quarters.
  quarter,

  /// Year view - shows years.
  year,
}

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
    // Enterprise features
    this.type = TaskType.task,
    this.resourceId,
    this.resourceName,
    this.baselineStart,
    this.baselineEnd,
    this.parentId,
    this.level = 0,
    this.isGroup = false,
    this.isExpanded = true,
    this.constraint = TaskConstraint.asap,
    this.constraintDate,
    this.notes,
    this.priority,
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

  /// IDs of tasks this task depends on (simple FS dependencies).
  ///
  /// For more complex dependency types, use [GanttChartData.dependencies].
  final List<String>? dependencies;

  /// Whether this is a milestone (single point in time).
  ///
  /// Deprecated: Use [type] == [TaskType.milestone] instead.
  final bool isMilestone;

  /// The type of task (task, milestone, or summary).
  final TaskType type;

  /// Resource ID assigned to this task.
  final String? resourceId;

  /// Resource name for display.
  final String? resourceName;

  /// Baseline start date for variance tracking.
  ///
  /// Compare with [start] to show schedule variance.
  final DateTime? baselineStart;

  /// Baseline end date for variance tracking.
  ///
  /// Compare with [end] to show schedule variance.
  final DateTime? baselineEnd;

  /// Parent task ID for hierarchy (WBS structure).
  final String? parentId;

  /// Hierarchy level (0 = root, 1 = child of root, etc.).
  final int level;

  /// Whether this is a group/summary task.
  ///
  /// Group tasks typically show aggregated dates/progress from children.
  final bool isGroup;

  /// Whether this group is expanded (children visible).
  final bool isExpanded;

  /// Scheduling constraint type.
  final TaskConstraint constraint;

  /// Date for the constraint (required for some constraint types).
  final DateTime? constraintDate;

  /// Optional notes/description.
  final String? notes;

  /// Task priority (higher = more important).
  final int? priority;

  /// Duration of the task.
  Duration get duration => end.difference(start);

  /// Whether this task is effectively a milestone.
  bool get isMilestoneType => isMilestone || type == TaskType.milestone;

  /// Whether this task is a summary/group task.
  bool get isSummaryType => isGroup || type == TaskType.summary;

  /// Whether this task has baseline dates for comparison.
  bool get hasBaseline => baselineStart != null && baselineEnd != null;

  /// Baseline duration (if baseline dates are set).
  Duration? get baselineDuration =>
      hasBaseline ? baselineEnd!.difference(baselineStart!) : null;

  /// Start variance in days (positive = delayed, negative = ahead).
  int? get startVarianceDays => hasBaseline
      ? start.difference(baselineStart!).inDays
      : null;

  /// End variance in days (positive = delayed, negative = ahead).
  int? get endVarianceDays => hasBaseline
      ? end.difference(baselineEnd!).inDays
      : null;

  /// Creates a copy with updated values.
  GanttTask copyWith({
    String? id,
    String? label,
    DateTime? start,
    DateTime? end,
    double? progress,
    Color? color,
    List<String>? dependencies,
    bool? isMilestone,
    TaskType? type,
    String? resourceId,
    String? resourceName,
    DateTime? baselineStart,
    DateTime? baselineEnd,
    String? parentId,
    int? level,
    bool? isGroup,
    bool? isExpanded,
    TaskConstraint? constraint,
    DateTime? constraintDate,
    String? notes,
    int? priority,
  }) => GanttTask(
      id: id ?? this.id,
      label: label ?? this.label,
      start: start ?? this.start,
      end: end ?? this.end,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      dependencies: dependencies ?? this.dependencies,
      isMilestone: isMilestone ?? this.isMilestone,
      type: type ?? this.type,
      resourceId: resourceId ?? this.resourceId,
      resourceName: resourceName ?? this.resourceName,
      baselineStart: baselineStart ?? this.baselineStart,
      baselineEnd: baselineEnd ?? this.baselineEnd,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      isGroup: isGroup ?? this.isGroup,
      isExpanded: isExpanded ?? this.isExpanded,
      constraint: constraint ?? this.constraint,
      constraintDate: constraintDate ?? this.constraintDate,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
}

/// Resource definition for resource-based views.
@immutable
class GanttResource {
  const GanttResource({
    required this.id,
    required this.name,
    this.color,
    this.capacity = 1.0,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional color for the resource's tasks.
  final Color? color;

  /// Capacity (1.0 = full-time, 0.5 = half-time).
  final double capacity;
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
    // Enterprise features
    this.dependencies = const [],
    this.resources = const [],
    this.showBaseline = false,
    this.showTodayLine = true,
    this.highlightCriticalPath = false,
    this.criticalPathColor,
    this.showHierarchy = false,
    this.viewMode = GanttViewMode.day,
    this.showResourceSwimlanes = false,
    this.todayLineColor,
    this.baselineColor,
    this.collapsedGroupIds = const {},
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

  // === Enterprise Features ===

  /// Explicit dependency definitions with types and lag.
  ///
  /// These are used in addition to the simple [GanttTask.dependencies].
  final List<GanttDependency> dependencies;

  /// Resource definitions for resource views.
  final List<GanttResource> resources;

  /// Whether to show baseline comparison bars.
  final bool showBaseline;

  /// Whether to show the today line.
  final bool showTodayLine;

  /// Whether to highlight the critical path.
  final bool highlightCriticalPath;

  /// Color for critical path tasks (defaults to red).
  final Color? criticalPathColor;

  /// Whether to show hierarchy indentation.
  final bool showHierarchy;

  /// Time scale view mode.
  final GanttViewMode viewMode;

  /// Whether to group tasks by resource in swimlanes.
  final bool showResourceSwimlanes;

  /// Color for the today line.
  final Color? todayLineColor;

  /// Color for baseline bars.
  final Color? baselineColor;

  /// Set of collapsed group task IDs.
  final Set<String> collapsedGroupIds;

  /// Get computed start date.
  DateTime get computedStartDate {
    if (startDate != null) return startDate!;
    if (tasks.isEmpty) return DateTime.now();

    var earliest = tasks.first.start;
    for (final task in tasks) {
      if (task.start.isBefore(earliest)) earliest = task.start;
      if (task.baselineStart != null &&
          task.baselineStart!.isBefore(earliest)) {
        earliest = task.baselineStart!;
      }
    }
    return earliest;
  }

  /// Get computed end date.
  DateTime get computedEndDate {
    if (endDate != null) return endDate!;
    if (tasks.isEmpty) return DateTime.now().add(const Duration(days: 30));

    var latest = tasks.first.end;
    for (final task in tasks) {
      if (task.end.isAfter(latest)) latest = task.end;
      if (task.baselineEnd != null && task.baselineEnd!.isAfter(latest)) {
        latest = task.baselineEnd!;
      }
    }
    return latest;
  }

  /// Total duration of the chart.
  Duration get totalDuration => computedEndDate.difference(computedStartDate);

  /// Gets visible tasks (excluding collapsed children).
  List<GanttTask> get visibleTasks {
    if (!showHierarchy || collapsedGroupIds.isEmpty) {
      return tasks;
    }

    final result = <GanttTask>[];

    for (final task in tasks) {
      // Check if any ancestor is collapsed
      var isHidden = false;
      var currentParentId = task.parentId;

      while (currentParentId != null) {
        if (collapsedGroupIds.contains(currentParentId)) {
          isHidden = true;
          break;
        }
        // Find parent's parent
        final parent = tasks.firstWhere(
          (t) => t.id == currentParentId,
          orElse: () => GanttTask(
            id: '',
            label: '',
            start: DateTime.now(),
            end: DateTime.now(),
          ),
        );
        currentParentId = parent.id.isEmpty ? null : parent.parentId;
      }

      if (!isHidden) {
        result.add(task);
      }
    }

    return result;
  }

  /// Gets tasks grouped by resource ID.
  Map<String?, List<GanttTask>> get tasksByResource {
    final result = <String?, List<GanttTask>>{};
    for (final task in tasks) {
      result.putIfAbsent(task.resourceId, () => []).add(task);
    }
    return result;
  }

  /// Creates a copy with updated values.
  GanttChartData copyWith({
    List<GanttTask>? tasks,
    double? barHeight,
    double? barSpacing,
    double? barRadius,
    bool? showProgress,
    bool? showDependencies,
    bool? showLabels,
    bool? showDates,
    double? labelWidth,
    DateTime? startDate,
    DateTime? endDate,
    ChartAnimation? animation,
    List<GanttDependency>? dependencies,
    List<GanttResource>? resources,
    bool? showBaseline,
    bool? showTodayLine,
    bool? highlightCriticalPath,
    Color? criticalPathColor,
    bool? showHierarchy,
    GanttViewMode? viewMode,
    bool? showResourceSwimlanes,
    Color? todayLineColor,
    Color? baselineColor,
    Set<String>? collapsedGroupIds,
  }) => GanttChartData(
      tasks: tasks ?? this.tasks,
      barHeight: barHeight ?? this.barHeight,
      barSpacing: barSpacing ?? this.barSpacing,
      barRadius: barRadius ?? this.barRadius,
      showProgress: showProgress ?? this.showProgress,
      showDependencies: showDependencies ?? this.showDependencies,
      showLabels: showLabels ?? this.showLabels,
      showDates: showDates ?? this.showDates,
      labelWidth: labelWidth ?? this.labelWidth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      animation: animation ?? this.animation,
      dependencies: dependencies ?? this.dependencies,
      resources: resources ?? this.resources,
      showBaseline: showBaseline ?? this.showBaseline,
      showTodayLine: showTodayLine ?? this.showTodayLine,
      highlightCriticalPath: highlightCriticalPath ?? this.highlightCriticalPath,
      criticalPathColor: criticalPathColor ?? this.criticalPathColor,
      showHierarchy: showHierarchy ?? this.showHierarchy,
      viewMode: viewMode ?? this.viewMode,
      showResourceSwimlanes: showResourceSwimlanes ?? this.showResourceSwimlanes,
      todayLineColor: todayLineColor ?? this.todayLineColor,
      baselineColor: baselineColor ?? this.baselineColor,
      collapsedGroupIds: collapsedGroupIds ?? this.collapsedGroupIds,
    );
}
