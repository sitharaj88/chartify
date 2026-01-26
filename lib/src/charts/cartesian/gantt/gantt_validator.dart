import 'gantt_chart_data.dart';

/// Result of Gantt chart data validation.
class GanttValidationResult {
  const GanttValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  /// Critical errors that prevent chart rendering.
  final List<GanttValidationError> errors;

  /// Non-critical warnings (chart will still render).
  final List<GanttValidationWarning> warnings;

  /// Whether the data is valid (no errors).
  bool get isValid => errors.isEmpty;

  /// Whether there are any issues (errors or warnings).
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;
}

/// A validation error.
class GanttValidationError {
  const GanttValidationError({
    required this.code,
    required this.message,
    this.taskId,
  });

  final GanttErrorCode code;
  final String message;
  final String? taskId;

  @override
  String toString() => taskId != null
      ? 'GanttError[$code] Task "$taskId": $message'
      : 'GanttError[$code]: $message';
}

/// A validation warning.
class GanttValidationWarning {
  const GanttValidationWarning({
    required this.code,
    required this.message,
    this.taskId,
  });

  final GanttWarningCode code;
  final String message;
  final String? taskId;

  @override
  String toString() => taskId != null
      ? 'GanttWarning[$code] Task "$taskId": $message'
      : 'GanttWarning[$code]: $message';
}

/// Error codes for Gantt validation.
enum GanttErrorCode {
  /// Task end date is before start date.
  invalidDateRange,

  /// Task progress is not in 0-1 range.
  invalidProgress,

  /// Circular dependency detected.
  circularDependency,

  /// Dependency references non-existent task.
  missingDependency,

  /// Duplicate task IDs.
  duplicateTaskId,

  /// Empty task ID.
  emptyTaskId,
}

/// Warning codes for Gantt validation.
enum GanttWarningCode {
  /// Task has zero duration (start == end) but is not a milestone.
  zeroDuration,

  /// Task progress is 100% but dates are in the future.
  completedFutureTask,

  /// Dependency may cause scheduling conflict.
  dependencyConflict,

  /// Task has no label.
  emptyLabel,
}

/// Validates Gantt chart data and detects issues.
class GanttValidator {
  const GanttValidator._();

  /// Validates the given Gantt chart data.
  static GanttValidationResult validate(GanttChartData data) {
    final errors = <GanttValidationError>[];
    final warnings = <GanttValidationWarning>[];
    final taskIds = <String>{};

    // Build task map for dependency validation
    final taskMap = <String, GanttTask>{};
    for (final task in data.tasks) {
      taskMap[task.id] = task;
    }

    for (final task in data.tasks) {
      // Check for empty task ID
      if (task.id.isEmpty) {
        errors.add(const GanttValidationError(
          code: GanttErrorCode.emptyTaskId,
          message: 'Task ID cannot be empty',
        ),);
        continue;
      }

      // Check for duplicate task IDs
      if (taskIds.contains(task.id)) {
        errors.add(GanttValidationError(
          code: GanttErrorCode.duplicateTaskId,
          message: 'Duplicate task ID found',
          taskId: task.id,
        ),);
      } else {
        taskIds.add(task.id);
      }

      // Validate date range (skip for milestones)
      if (!task.isMilestone && task.end.isBefore(task.start)) {
        errors.add(GanttValidationError(
          code: GanttErrorCode.invalidDateRange,
          message:
              'End date (${task.end}) is before start date (${task.start})',
          taskId: task.id,
        ),);
      }

      // Check for zero duration non-milestones
      if (!task.isMilestone && task.start == task.end) {
        warnings.add(GanttValidationWarning(
          code: GanttWarningCode.zeroDuration,
          message: 'Task has zero duration but is not marked as milestone',
          taskId: task.id,
        ),);
      }

      // Validate progress range
      if (task.progress < 0 || task.progress > 1) {
        errors.add(GanttValidationError(
          code: GanttErrorCode.invalidProgress,
          message:
              'Progress (${task.progress}) must be between 0.0 and 1.0',
          taskId: task.id,
        ),);
      }

      // Check for completed future tasks
      if (task.progress >= 1.0 && task.end.isAfter(DateTime.now())) {
        warnings.add(GanttValidationWarning(
          code: GanttWarningCode.completedFutureTask,
          message: 'Task is marked as complete but end date is in the future',
          taskId: task.id,
        ),);
      }

      // Check for empty label
      if (task.label.isEmpty) {
        warnings.add(GanttValidationWarning(
          code: GanttWarningCode.emptyLabel,
          message: 'Task has no label',
          taskId: task.id,
        ),);
      }

      // Validate dependencies exist
      if (task.dependencies != null) {
        for (final depId in task.dependencies!) {
          if (!taskMap.containsKey(depId)) {
            errors.add(GanttValidationError(
              code: GanttErrorCode.missingDependency,
              message: 'Dependency "$depId" does not exist',
              taskId: task.id,
            ),);
          }
        }
      }
    }

    // Check for circular dependencies
    final cycles = _detectCycles(data.tasks);
    for (final cycle in cycles) {
      errors.add(GanttValidationError(
        code: GanttErrorCode.circularDependency,
        message: 'Circular dependency detected: ${cycle.join(" → ")}',
        taskId: cycle.first,
      ),);
    }

    return GanttValidationResult(errors: errors, warnings: warnings);
  }

  /// Detects circular dependencies using DFS.
  ///
  /// Returns a list of cycles, where each cycle is a list of task IDs.
  static List<List<String>> _detectCycles(List<GanttTask> tasks) {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    // Build adjacency list
    final adjacency = <String, List<String>>{};
    for (final task in tasks) {
      adjacency[task.id] = task.dependencies ?? [];
    }

    void dfs(String taskId) {
      if (recursionStack.contains(taskId)) {
        // Found a cycle - extract it from path
        final cycleStart = path.indexOf(taskId);
        if (cycleStart != -1) {
          final cycle = path.sublist(cycleStart)..add(taskId);
          cycles.add(cycle);
        }
        return;
      }

      if (visited.contains(taskId)) return;

      visited.add(taskId);
      recursionStack.add(taskId);
      path.add(taskId);

      final dependencies = adjacency[taskId] ?? [];
      for (final depId in dependencies) {
        dfs(depId);
      }

      path.removeLast();
      recursionStack.remove(taskId);
    }

    for (final task in tasks) {
      if (!visited.contains(task.id)) {
        dfs(task.id);
      }
    }

    return cycles;
  }

  /// Validates a single task and returns errors.
  static List<GanttValidationError> validateTask(GanttTask task) {
    final errors = <GanttValidationError>[];

    if (task.id.isEmpty) {
      errors.add(const GanttValidationError(
        code: GanttErrorCode.emptyTaskId,
        message: 'Task ID cannot be empty',
      ),);
    }

    if (!task.isMilestone && task.end.isBefore(task.start)) {
      errors.add(GanttValidationError(
        code: GanttErrorCode.invalidDateRange,
        message: 'End date must be after start date',
        taskId: task.id,
      ),);
    }

    if (task.progress < 0 || task.progress > 1) {
      errors.add(GanttValidationError(
        code: GanttErrorCode.invalidProgress,
        message: 'Progress must be between 0.0 and 1.0',
        taskId: task.id,
      ),);
    }

    return errors;
  }

  /// Checks if a dependency would create a cycle.
  ///
  /// Use this before adding a new dependency to ensure it won't create
  /// a circular reference.
  static bool wouldCreateCycle(
    List<GanttTask> tasks,
    String fromTaskId,
    String toTaskId,
  ) {
    // Check if toTaskId can reach fromTaskId through existing dependencies
    final visited = <String>{};

    bool canReach(String current, String target) {
      if (current == target) return true;
      if (visited.contains(current)) return false;

      visited.add(current);

      final task = tasks.firstWhere(
        (t) => t.id == current,
        orElse: () => GanttTask(
          id: '',
          label: '',
          start: DateTime.now(),
          end: DateTime.now(),
        ),
      );

      if (task.id.isEmpty) return false;

      for (final depId in task.dependencies ?? <String>[]) {
        if (canReach(depId, target)) return true;
      }

      return false;
    }

    // If toTaskId can already reach fromTaskId, adding fromTaskId -> toTaskId
    // would create a cycle
    return canReach(toTaskId, fromTaskId);
  }

  /// Returns a topologically sorted list of task IDs.
  ///
  /// Tasks with no dependencies come first, followed by tasks that depend
  /// on them, etc. Returns null if there's a cycle.
  static List<String>? topologicalSort(List<GanttTask> tasks) {
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    // Initialize
    for (final task in tasks) {
      inDegree[task.id] = 0;
      adjacency[task.id] = [];
    }

    // Build graph (reverse direction: dependency -> dependent)
    for (final task in tasks) {
      for (final depId in task.dependencies ?? <String>[]) {
        if (adjacency.containsKey(depId)) {
          adjacency[depId]!.add(task.id);
          inDegree[task.id] = (inDegree[task.id] ?? 0) + 1;
        }
      }
    }

    // Find all tasks with no dependencies
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    final result = <String>[];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      for (final dependent in adjacency[current] ?? <String>[]) {
        inDegree[dependent] = (inDegree[dependent] ?? 1) - 1;
        if (inDegree[dependent] == 0) {
          queue.add(dependent);
        }
      }
    }

    // If we couldn't process all tasks, there's a cycle
    if (result.length != tasks.length) {
      return null;
    }

    return result;
  }
}
