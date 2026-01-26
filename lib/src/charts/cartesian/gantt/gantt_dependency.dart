import 'package:flutter/foundation.dart';

/// Types of task dependencies in project management.
///
/// These follow standard project management terminology:
/// - FS (Finish-to-Start): Task B starts when Task A finishes
/// - SS (Start-to-Start): Task B starts when Task A starts
/// - FF (Finish-to-Finish): Task B finishes when Task A finishes
/// - SF (Start-to-Finish): Task B finishes when Task A starts (rare)
enum DependencyType {
  /// Finish-to-Start: The most common dependency type.
  ///
  /// Task B cannot start until Task A finishes.
  /// Example: "Testing" cannot start until "Development" is complete.
  finishToStart,

  /// Start-to-Start: Tasks start together.
  ///
  /// Task B can start when Task A starts.
  /// Example: "Documentation" can start when "Development" starts.
  startToStart,

  /// Finish-to-Finish: Tasks finish together.
  ///
  /// Task B cannot finish until Task A finishes.
  /// Example: "QA Sign-off" cannot finish until "Testing" finishes.
  finishToFinish,

  /// Start-to-Finish: Inverse dependency (rarely used).
  ///
  /// Task B cannot finish until Task A starts.
  /// Example: "Security coverage" cannot end until "New system" starts.
  startToFinish,
}

/// Extension methods for [DependencyType].
extension DependencyTypeExtension on DependencyType {
  /// Short code representation (FS, SS, FF, SF).
  String get code {
    switch (this) {
      case DependencyType.finishToStart:
        return 'FS';
      case DependencyType.startToStart:
        return 'SS';
      case DependencyType.finishToFinish:
        return 'FF';
      case DependencyType.startToFinish:
        return 'SF';
    }
  }

  /// Human-readable name.
  String get displayName {
    switch (this) {
      case DependencyType.finishToStart:
        return 'Finish to Start';
      case DependencyType.startToStart:
        return 'Start to Start';
      case DependencyType.finishToFinish:
        return 'Finish to Finish';
      case DependencyType.startToFinish:
        return 'Start to Finish';
    }
  }

  /// Creates a DependencyType from its code (FS, SS, FF, SF).
  static DependencyType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'FS':
        return DependencyType.finishToStart;
      case 'SS':
        return DependencyType.startToStart;
      case 'FF':
        return DependencyType.finishToFinish;
      case 'SF':
        return DependencyType.startToFinish;
      default:
        throw ArgumentError('Unknown dependency type code: $code');
    }
  }
}

/// A dependency relationship between two tasks.
///
/// Represents a link from one task (predecessor) to another (successor),
/// defining when the successor can start or finish relative to the predecessor.
@immutable
class GanttDependency {
  /// Creates a new dependency.
  ///
  /// [fromTaskId] is the predecessor task.
  /// [toTaskId] is the successor (dependent) task.
  /// [type] defines the relationship (defaults to Finish-to-Start).
  /// [lag] is optional delay (positive) or lead (negative) time.
  const GanttDependency({
    required this.fromTaskId,
    required this.toTaskId,
    this.type = DependencyType.finishToStart,
    this.lag = Duration.zero,
  });

  /// The predecessor task ID.
  final String fromTaskId;

  /// The successor (dependent) task ID.
  final String toTaskId;

  /// The type of dependency relationship.
  final DependencyType type;

  /// Lag time (positive) or lead time (negative).
  ///
  /// - Positive lag: Successor must wait after the condition is met
  /// - Negative lag (lead): Successor can start before the condition is met
  ///
  /// Example: FS with lag of 2 days means successor starts 2 days after
  /// predecessor finishes.
  final Duration lag;

  /// Whether this dependency has a lag (delay).
  bool get hasLag => lag > Duration.zero;

  /// Whether this dependency has a lead (negative lag).
  bool get hasLead => lag < Duration.zero;

  /// Creates a copy with updated values.
  GanttDependency copyWith({
    String? fromTaskId,
    String? toTaskId,
    DependencyType? type,
    Duration? lag,
  }) => GanttDependency(
      fromTaskId: fromTaskId ?? this.fromTaskId,
      toTaskId: toTaskId ?? this.toTaskId,
      type: type ?? this.type,
      lag: lag ?? this.lag,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GanttDependency &&
        other.fromTaskId == fromTaskId &&
        other.toTaskId == toTaskId &&
        other.type == type &&
        other.lag == lag;
  }

  @override
  int get hashCode => Object.hash(fromTaskId, toTaskId, type, lag);

  @override
  String toString() {
    final lagStr = lag != Duration.zero
        ? ' ${lag.isNegative ? "-" : "+"}${lag.inDays}d'
        : '';
    return 'GanttDependency($fromTaskId -> $toTaskId [${type.code}$lagStr])';
  }
}

/// Factory methods for creating common dependency configurations.
class GanttDependencyFactory {
  GanttDependencyFactory._();

  /// Creates a standard Finish-to-Start dependency.
  ///
  /// Task [toTaskId] starts when task [fromTaskId] finishes.
  static GanttDependency finishToStart(
    String fromTaskId,
    String toTaskId, {
    Duration lag = Duration.zero,
  }) => GanttDependency(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      lag: lag,
    );

  /// Creates a Start-to-Start dependency.
  ///
  /// Task [toTaskId] starts when task [fromTaskId] starts.
  static GanttDependency startToStart(
    String fromTaskId,
    String toTaskId, {
    Duration lag = Duration.zero,
  }) => GanttDependency(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      type: DependencyType.startToStart,
      lag: lag,
    );

  /// Creates a Finish-to-Finish dependency.
  ///
  /// Task [toTaskId] finishes when task [fromTaskId] finishes.
  static GanttDependency finishToFinish(
    String fromTaskId,
    String toTaskId, {
    Duration lag = Duration.zero,
  }) => GanttDependency(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      type: DependencyType.finishToFinish,
      lag: lag,
    );

  /// Creates a Start-to-Finish dependency.
  ///
  /// Task [toTaskId] finishes when task [fromTaskId] starts.
  static GanttDependency startToFinish(
    String fromTaskId,
    String toTaskId, {
    Duration lag = Duration.zero,
  }) => GanttDependency(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      type: DependencyType.startToFinish,
      lag: lag,
    );
}

/// Utility class for working with dependencies.
class GanttDependencyUtils {
  GanttDependencyUtils._();

  /// Groups dependencies by their successor task ID.
  static Map<String, List<GanttDependency>> groupBySuccessor(
    List<GanttDependency> dependencies,
  ) {
    final result = <String, List<GanttDependency>>{};
    for (final dep in dependencies) {
      result.putIfAbsent(dep.toTaskId, () => []).add(dep);
    }
    return result;
  }

  /// Groups dependencies by their predecessor task ID.
  static Map<String, List<GanttDependency>> groupByPredecessor(
    List<GanttDependency> dependencies,
  ) {
    final result = <String, List<GanttDependency>>{};
    for (final dep in dependencies) {
      result.putIfAbsent(dep.fromTaskId, () => []).add(dep);
    }
    return result;
  }

  /// Gets all predecessor task IDs for a given task.
  static List<String> getPredecessors(
    String taskId,
    List<GanttDependency> dependencies,
  ) => dependencies
        .where((d) => d.toTaskId == taskId)
        .map((d) => d.fromTaskId)
        .toList();

  /// Gets all successor task IDs for a given task.
  static List<String> getSuccessors(
    String taskId,
    List<GanttDependency> dependencies,
  ) => dependencies
        .where((d) => d.fromTaskId == taskId)
        .map((d) => d.toTaskId)
        .toList();

  /// Checks if a dependency already exists between two tasks.
  static bool dependencyExists(
    String fromTaskId,
    String toTaskId,
    List<GanttDependency> dependencies,
  ) => dependencies.any(
      (d) => d.fromTaskId == fromTaskId && d.toTaskId == toTaskId,
    );
}
