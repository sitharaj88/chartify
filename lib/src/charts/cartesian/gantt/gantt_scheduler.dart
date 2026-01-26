import 'gantt_chart_data.dart';

/// Scheduling result for a single task.
class TaskSchedule {
  const TaskSchedule({
    required this.taskId,
    required this.earlyStart,
    required this.earlyFinish,
    required this.lateStart,
    required this.lateFinish,
    required this.totalFloat,
    required this.freeFloat,
    required this.isCritical,
  });

  /// The task ID.
  final String taskId;

  /// Earliest possible start date.
  final DateTime earlyStart;

  /// Earliest possible finish date.
  final DateTime earlyFinish;

  /// Latest possible start date without delaying the project.
  final DateTime lateStart;

  /// Latest possible finish date without delaying the project.
  final DateTime lateFinish;

  /// Total float (slack) in days.
  ///
  /// How much the task can be delayed without delaying the project.
  final int totalFloat;

  /// Free float in days.
  ///
  /// How much the task can be delayed without delaying any successor.
  final int freeFloat;

  /// Whether this task is on the critical path.
  final bool isCritical;
}

/// Result of schedule calculation.
class GanttScheduleResult {
  const GanttScheduleResult({
    required this.schedules,
    required this.criticalPath,
    required this.projectStart,
    required this.projectEnd,
    required this.projectDuration,
  });

  /// Schedule for each task, keyed by task ID.
  final Map<String, TaskSchedule> schedules;

  /// List of task IDs on the critical path, in order.
  final List<String> criticalPath;

  /// Project start date.
  final DateTime projectStart;

  /// Project end date.
  final DateTime projectEnd;

  /// Total project duration in days.
  final int projectDuration;

  /// Gets the schedule for a task.
  TaskSchedule? getSchedule(String taskId) => schedules[taskId];

  /// Checks if a task is on the critical path.
  bool isTaskCritical(String taskId) => schedules[taskId]?.isCritical ?? false;

  /// Gets the total float for a task.
  int? getFloat(String taskId) => schedules[taskId]?.totalFloat;
}

/// Calculates project schedules using the Critical Path Method (CPM).
class GanttScheduler {
  GanttScheduler._();

  /// Calculates the schedule for all tasks using CPM.
  ///
  /// This implements the Critical Path Method:
  /// 1. Forward pass - calculate early start/finish dates
  /// 2. Backward pass - calculate late start/finish dates
  /// 3. Float calculation - determine slack for each task
  /// 4. Critical path - identify tasks with zero float
  static GanttScheduleResult calculateSchedule(
    List<GanttTask> tasks, {
    List<GanttDependency> dependencies = const [],
  }) {
    if (tasks.isEmpty) {
      return GanttScheduleResult(
        schedules: const {},
        criticalPath: const [],
        projectStart: DateTime.now(),
        projectEnd: DateTime.now(),
        projectDuration: 0,
      );
    }

    // Build task map for quick lookup
    final taskMap = <String, GanttTask>{};
    for (final task in tasks) {
      taskMap[task.id] = task;
    }

    // Build dependency graph
    final predecessors = <String, List<_DependencyInfo>>{};
    final successors = <String, List<_DependencyInfo>>{};

    for (final task in tasks) {
      predecessors[task.id] = [];
      successors[task.id] = [];
    }

    // Add explicit dependencies
    for (final dep in dependencies) {
      if (taskMap.containsKey(dep.fromTaskId) &&
          taskMap.containsKey(dep.toTaskId)) {
        predecessors[dep.toTaskId]!.add(_DependencyInfo(
          taskId: dep.fromTaskId,
          type: dep.type,
          lag: dep.lag,
        ),);
        successors[dep.fromTaskId]!.add(_DependencyInfo(
          taskId: dep.toTaskId,
          type: dep.type,
          lag: dep.lag,
        ),);
      }
    }

    // Add simple dependencies from GanttTask.dependencies
    for (final task in tasks) {
      if (task.dependencies != null) {
        for (final depId in task.dependencies!) {
          if (taskMap.containsKey(depId)) {
            // Check if not already added as explicit dependency
            final alreadyExists = predecessors[task.id]!.any(
              (d) => d.taskId == depId,
            );
            if (!alreadyExists) {
              predecessors[task.id]!.add(_DependencyInfo(
                taskId: depId,
                type: DependencyType.finishToStart,
                lag: Duration.zero,
              ),);
              successors[depId]!.add(_DependencyInfo(
                taskId: task.id,
                type: DependencyType.finishToStart,
                lag: Duration.zero,
              ),);
            }
          }
        }
      }
    }

    // Forward pass - calculate early start and early finish
    final earlyStart = <String, DateTime>{};
    final earlyFinish = <String, DateTime>{};
    final processed = <String>{};

    // Find project start date
    var projectStartDate = tasks.first.start;
    for (final task in tasks) {
      if (task.start.isBefore(projectStartDate)) {
        projectStartDate = task.start;
      }
    }

    // Topological order processing
    final queue = <String>[];

    // Start with tasks that have no predecessors
    for (final task in tasks) {
      if (predecessors[task.id]!.isEmpty) {
        queue.add(task.id);
        earlyStart[task.id] = task.start;
        earlyFinish[task.id] = task.end;
        processed.add(task.id);
      }
    }

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final currentES = earlyStart[currentId]!;
      final currentEF = earlyFinish[currentId]!;

      // Process successors
      for (final succInfo in successors[currentId]!) {
        final succId = succInfo.taskId;
        final succTask = taskMap[succId]!;

        // Calculate constraint date based on dependency type
        DateTime constraintDate;
        switch (succInfo.type) {
          case DependencyType.finishToStart:
            constraintDate = currentEF.add(succInfo.lag);
          case DependencyType.startToStart:
            constraintDate = currentES.add(succInfo.lag);
          case DependencyType.finishToFinish:
            // Successor must finish when predecessor finishes
            constraintDate = currentEF.add(succInfo.lag);
            constraintDate = constraintDate.subtract(succTask.duration);
          case DependencyType.startToFinish:
            // Successor must finish when predecessor starts
            constraintDate = currentES.add(succInfo.lag);
            constraintDate = constraintDate.subtract(succTask.duration);
        }

        // Update early start for successor
        final existingES = earlyStart[succId];
        if (existingES == null || constraintDate.isAfter(existingES)) {
          earlyStart[succId] = constraintDate;
          earlyFinish[succId] = constraintDate.add(succTask.duration);
        }

        // Check if all predecessors have been processed
        final allPredsProcessed = predecessors[succId]!.every(
          (p) => processed.contains(p.taskId),
        );

        if (allPredsProcessed && !processed.contains(succId)) {
          // Use task's own start date if no predecessors constrain it
          if (earlyStart[succId] == null) {
            earlyStart[succId] = succTask.start;
            earlyFinish[succId] = succTask.end;
          }
          processed.add(succId);
          queue.add(succId);
        }
      }
    }

    // Handle any unprocessed tasks (no dependencies)
    for (final task in tasks) {
      if (!processed.contains(task.id)) {
        earlyStart[task.id] = task.start;
        earlyFinish[task.id] = task.end;
        processed.add(task.id);
      }
    }

    // Find project end date
    var projectEndDate = earlyFinish.values.first;
    for (final ef in earlyFinish.values) {
      if (ef.isAfter(projectEndDate)) {
        projectEndDate = ef;
      }
    }

    // Backward pass - calculate late start and late finish
    final lateStart = <String, DateTime>{};
    final lateFinish = <String, DateTime>{};
    final processedBack = <String>{};
    final queueBack = <String>[];

    // Start with tasks that have no successors
    for (final task in tasks) {
      if (successors[task.id]!.isEmpty) {
        queueBack.add(task.id);
        lateFinish[task.id] = projectEndDate;
        lateStart[task.id] = projectEndDate.subtract(task.duration);
        processedBack.add(task.id);
      }
    }

    while (queueBack.isNotEmpty) {
      final currentId = queueBack.removeAt(0);
      final currentLS = lateStart[currentId]!;
      final currentLF = lateFinish[currentId]!;

      // Process predecessors
      for (final predInfo in predecessors[currentId]!) {
        final predId = predInfo.taskId;
        final predTask = taskMap[predId]!;

        // Calculate constraint date based on dependency type
        DateTime constraintDate;
        switch (predInfo.type) {
          case DependencyType.finishToStart:
            constraintDate = currentLS.subtract(predInfo.lag);
          case DependencyType.startToStart:
            constraintDate = currentLS.subtract(predInfo.lag);
            constraintDate = constraintDate.add(predTask.duration);
          case DependencyType.finishToFinish:
            constraintDate = currentLF.subtract(predInfo.lag);
          case DependencyType.startToFinish:
            constraintDate = currentLF.subtract(predInfo.lag);
            constraintDate = constraintDate.add(predTask.duration);
        }

        // Update late finish for predecessor
        final existingLF = lateFinish[predId];
        if (existingLF == null || constraintDate.isBefore(existingLF)) {
          lateFinish[predId] = constraintDate;
          lateStart[predId] = constraintDate.subtract(predTask.duration);
        }

        // Check if all successors have been processed
        final allSuccsProcessed = successors[predId]!.every(
          (s) => processedBack.contains(s.taskId),
        );

        if (allSuccsProcessed && !processedBack.contains(predId)) {
          if (lateFinish[predId] == null) {
            lateFinish[predId] = projectEndDate;
            lateStart[predId] = projectEndDate.subtract(predTask.duration);
          }
          processedBack.add(predId);
          queueBack.add(predId);
        }
      }
    }

    // Handle any unprocessed tasks
    for (final task in tasks) {
      if (!processedBack.contains(task.id)) {
        lateFinish[task.id] = projectEndDate;
        lateStart[task.id] = projectEndDate.subtract(task.duration);
        processedBack.add(task.id);
      }
    }

    // Calculate floats and identify critical path
    final schedules = <String, TaskSchedule>{};
    final criticalPath = <String>[];

    for (final task in tasks) {
      final es = earlyStart[task.id]!;
      final ef = earlyFinish[task.id]!;
      final ls = lateStart[task.id]!;
      final lf = lateFinish[task.id]!;

      final totalFloat = ls.difference(es).inDays;

      // Calculate free float (time until next successor's early start)
      var freeFloat = totalFloat;
      for (final succInfo in successors[task.id]!) {
        final succES = earlyStart[succInfo.taskId]!;
        int ff;
        switch (succInfo.type) {
          case DependencyType.finishToStart:
            ff = succES.subtract(succInfo.lag).difference(ef).inDays;
          case DependencyType.startToStart:
            ff = succES.subtract(succInfo.lag).difference(es).inDays;
          case DependencyType.finishToFinish:
            final succEF = earlyFinish[succInfo.taskId]!;
            ff = succEF.subtract(succInfo.lag).difference(ef).inDays;
          case DependencyType.startToFinish:
            final succEF = earlyFinish[succInfo.taskId]!;
            ff = succEF.subtract(succInfo.lag).difference(es).inDays;
        }
        if (ff < freeFloat) freeFloat = ff;
      }
      if (freeFloat < 0) freeFloat = 0;

      final isCritical = totalFloat == 0;

      schedules[task.id] = TaskSchedule(
        taskId: task.id,
        earlyStart: es,
        earlyFinish: ef,
        lateStart: ls,
        lateFinish: lf,
        totalFloat: totalFloat,
        freeFloat: freeFloat,
        isCritical: isCritical,
      );

      if (isCritical) {
        criticalPath.add(task.id);
      }
    }

    // Sort critical path by early start
    criticalPath.sort((a, b) => schedules[a]!.earlyStart.compareTo(schedules[b]!.earlyStart));

    return GanttScheduleResult(
      schedules: schedules,
      criticalPath: criticalPath,
      projectStart: projectStartDate,
      projectEnd: projectEndDate,
      projectDuration: projectEndDate.difference(projectStartDate).inDays,
    );
  }

  /// Gets the critical path from a schedule result.
  static List<String> getCriticalPath(GanttScheduleResult result) => result.criticalPath;

  /// Checks if a task is on the critical path.
  static bool isTaskCritical(String taskId, GanttScheduleResult result) => result.isTaskCritical(taskId);

  /// Calculates resource utilization over time.
  static Map<String, List<_ResourceUtilization>> calculateResourceUtilization(
    List<GanttTask> tasks,
    List<GanttResource> resources,
    DateTime startDate,
    DateTime endDate,
  ) {
    final result = <String, List<_ResourceUtilization>>{};

    for (final resource in resources) {
      final utilizations = <_ResourceUtilization>[];
      var currentDate = startDate;

      while (currentDate.isBefore(endDate)) {
        final nextDate = currentDate.add(const Duration(days: 1));

        // Find tasks assigned to this resource on this date
        double totalAllocation = 0;
        for (final task in tasks) {
          if (task.resourceId == resource.id &&
              !task.start.isAfter(currentDate) &&
              task.end.isAfter(currentDate)) {
            totalAllocation += 1.0; // Full allocation per task
          }
        }

        utilizations.add(_ResourceUtilization(
          date: currentDate,
          allocated: totalAllocation,
          capacity: resource.capacity,
          overallocated: totalAllocation > resource.capacity,
        ),);

        currentDate = nextDate;
      }

      result[resource.id] = utilizations;
    }

    return result;
  }
}

/// Internal dependency info for calculations.
class _DependencyInfo {
  const _DependencyInfo({
    required this.taskId,
    required this.type,
    required this.lag,
  });

  final String taskId;
  final DependencyType type;
  final Duration lag;
}

/// Resource utilization for a single day.
class _ResourceUtilization {
  const _ResourceUtilization({
    required this.date,
    required this.allocated,
    required this.capacity,
    required this.overallocated,
  });

  final DateTime date;
  final double allocated;
  final double capacity;
  final bool overallocated;
}
