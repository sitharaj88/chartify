import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gantt_chart_data.dart';

/// Edge being resized on a task bar.
enum ResizeEdge {
  /// Resizing the start edge (changes start date).
  start,

  /// Resizing the end edge (changes end date).
  end,
}

/// Result of a task drag operation.
@immutable
class TaskDragResult {
  const TaskDragResult({
    required this.taskId,
    required this.newStart,
    required this.newEnd,
    required this.originalStart,
    required this.originalEnd,
  });

  final String taskId;
  final DateTime newStart;
  final DateTime newEnd;
  final DateTime originalStart;
  final DateTime originalEnd;

  /// Duration change in days (positive = longer, negative = shorter).
  int get durationChange => newEnd.difference(newStart).inDays -
      originalEnd.difference(originalStart).inDays;

  /// Start date change in days (positive = later, negative = earlier).
  int get startChange => newStart.difference(originalStart).inDays;

  /// End date change in days (positive = later, negative = earlier).
  int get endChange => newEnd.difference(originalEnd).inDays;

  /// Whether the dates have changed.
  bool get hasChanged => startChange != 0 || endChange != 0;
}

/// Result of a task resize operation.
@immutable
class TaskResizeResult {
  const TaskResizeResult({
    required this.taskId,
    required this.edge,
    required this.newStart,
    required this.newEnd,
    required this.originalStart,
    required this.originalEnd,
  });

  final String taskId;
  final ResizeEdge edge;
  final DateTime newStart;
  final DateTime newEnd;
  final DateTime originalStart;
  final DateTime originalEnd;

  /// Duration change in days.
  int get durationChange => newEnd.difference(newStart).inDays -
      originalEnd.difference(originalStart).inDays;

  /// Whether the dates have changed.
  bool get hasChanged =>
      newStart != originalStart || newEnd != originalEnd;
}

/// Snap mode for drag operations.
enum SnapMode {
  /// No snapping.
  none,

  /// Snap to day boundaries.
  day,

  /// Snap to week boundaries (Monday).
  week,

  /// Snap to month boundaries.
  month,
}

/// Configuration for Gantt chart interactions.
@immutable
class GanttInteractionConfig {
  const GanttInteractionConfig({
    this.enableDrag = true,
    this.enableResize = true,
    this.enableMultiSelect = true,
    this.enableKeyboardNavigation = true,
    this.snapMode = SnapMode.day,
    this.hapticFeedback = true,
    this.minimumDuration = const Duration(days: 1),
    this.resizeHandleWidth = 8.0,
  });

  /// Whether task dragging is enabled.
  final bool enableDrag;

  /// Whether task resizing is enabled.
  final bool enableResize;

  /// Whether multi-selection is enabled.
  final bool enableMultiSelect;

  /// Whether keyboard navigation is enabled.
  final bool enableKeyboardNavigation;

  /// Snap mode for drag/resize operations.
  final SnapMode snapMode;

  /// Whether to provide haptic feedback.
  final bool hapticFeedback;

  /// Minimum task duration.
  final Duration minimumDuration;

  /// Width of resize handles at bar edges.
  final double resizeHandleWidth;
}

/// Controller for Gantt chart interactions.
///
/// Manages drag, resize, selection, and keyboard navigation.
class GanttInteractionController extends ChangeNotifier {
  GanttInteractionController({
    this.config = const GanttInteractionConfig(),
  });

  final GanttInteractionConfig config;

  // Selection state
  final Set<String> _selectedTaskIds = {};
  String? _focusedTaskId;

  // Drag state
  String? _draggingTaskId;
  Offset? _dragStartPosition;
  DateTime? _dragOriginalStart;
  DateTime? _dragOriginalEnd;

  // Resize state
  String? _resizingTaskId;
  ResizeEdge? _resizeEdge;
  DateTime? _resizeOriginalStart;
  DateTime? _resizeOriginalEnd;

  /// Currently selected task IDs.
  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);

  /// Currently focused task ID (for keyboard navigation).
  String? get focusedTaskId => _focusedTaskId;

  /// Whether a task is currently being dragged.
  bool get isDragging => _draggingTaskId != null;

  /// Whether a task is currently being resized.
  bool get isResizing => _resizingTaskId != null;

  /// ID of the task being dragged.
  String? get draggingTaskId => _draggingTaskId;

  /// ID of the task being resized.
  String? get resizingTaskId => _resizingTaskId;

  /// Current resize edge.
  ResizeEdge? get resizeEdge => _resizeEdge;

  // === Selection ===

  /// Selects a task.
  ///
  /// If [addToSelection] is true, adds to current selection.
  /// Otherwise, replaces the current selection.
  void selectTask(String taskId, {bool addToSelection = false}) {
    if (!addToSelection) {
      _selectedTaskIds.clear();
    }
    _selectedTaskIds.add(taskId);
    _focusedTaskId = taskId;
    notifyListeners();
  }

  /// Toggles task selection.
  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
      if (_focusedTaskId == taskId) {
        _focusedTaskId = _selectedTaskIds.isEmpty ? null : _selectedTaskIds.first;
      }
    } else {
      _selectedTaskIds.add(taskId);
      _focusedTaskId = taskId;
    }
    notifyListeners();
  }

  /// Selects a range of tasks (for Shift+click).
  void selectRange(List<GanttTask> tasks, String fromId, String toId) {
    final fromIndex = tasks.indexWhere((t) => t.id == fromId);
    final toIndex = tasks.indexWhere((t) => t.id == toId);

    if (fromIndex == -1 || toIndex == -1) return;

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    for (var i = start; i <= end; i++) {
      _selectedTaskIds.add(tasks[i].id);
    }
    _focusedTaskId = toId;
    notifyListeners();
  }

  /// Clears all selection.
  void clearSelection() {
    _selectedTaskIds.clear();
    _focusedTaskId = null;
    notifyListeners();
  }

  /// Checks if a task is selected.
  bool isSelected(String taskId) => _selectedTaskIds.contains(taskId);

  /// Selects all tasks.
  void selectAll(List<GanttTask> tasks) {
    for (final task in tasks) {
      _selectedTaskIds.add(task.id);
    }
    notifyListeners();
  }

  // === Drag ===

  /// Starts dragging a task.
  void startDrag(String taskId, Offset position, DateTime start, DateTime end) {
    if (!config.enableDrag) return;

    _draggingTaskId = taskId;
    _dragStartPosition = position;
    _dragOriginalStart = start;
    _dragOriginalEnd = end;

    if (config.hapticFeedback) {
      HapticFeedback.selectionClick();
    }

    notifyListeners();
  }

  /// Updates drag position and returns new dates.
  TaskDragResult? updateDrag(
    Offset currentPosition,
    double pixelsPerDay,
    DateTime chartStartDate,
  ) {
    if (_draggingTaskId == null ||
        _dragStartPosition == null ||
        _dragOriginalStart == null ||
        _dragOriginalEnd == null) {
      return null;
    }

    final deltaX = currentPosition.dx - _dragStartPosition!.dx;
    final deltaDays = (deltaX / pixelsPerDay).round();

    var newStart = _dragOriginalStart!.add(Duration(days: deltaDays));
    var newEnd = _dragOriginalEnd!.add(Duration(days: deltaDays));

    // Apply snapping
    newStart = _snapDate(newStart);
    newEnd = _snapDate(newEnd);

    return TaskDragResult(
      taskId: _draggingTaskId!,
      newStart: newStart,
      newEnd: newEnd,
      originalStart: _dragOriginalStart!,
      originalEnd: _dragOriginalEnd!,
    );
  }

  /// Ends dragging.
  TaskDragResult? endDrag(
    Offset finalPosition,
    double pixelsPerDay,
    DateTime chartStartDate,
  ) {
    final result = updateDrag(finalPosition, pixelsPerDay, chartStartDate);

    _draggingTaskId = null;
    _dragStartPosition = null;
    _dragOriginalStart = null;
    _dragOriginalEnd = null;

    if (config.hapticFeedback && result?.hasChanged == true) {
      HapticFeedback.lightImpact();
    }

    notifyListeners();
    return result;
  }

  /// Cancels dragging.
  void cancelDrag() {
    _draggingTaskId = null;
    _dragStartPosition = null;
    _dragOriginalStart = null;
    _dragOriginalEnd = null;
    notifyListeners();
  }

  // === Resize ===

  /// Starts resizing a task.
  void startResize(
    String taskId,
    ResizeEdge edge,
    DateTime start,
    DateTime end,
  ) {
    if (!config.enableResize) return;

    _resizingTaskId = taskId;
    _resizeEdge = edge;
    _resizeOriginalStart = start;
    _resizeOriginalEnd = end;

    if (config.hapticFeedback) {
      HapticFeedback.selectionClick();
    }

    notifyListeners();
  }

  /// Updates resize and returns new dates.
  TaskResizeResult? updateResize(
    double deltaX,
    double pixelsPerDay,
  ) {
    if (_resizingTaskId == null ||
        _resizeEdge == null ||
        _resizeOriginalStart == null ||
        _resizeOriginalEnd == null) {
      return null;
    }

    final deltaDays = (deltaX / pixelsPerDay).round();
    var newStart = _resizeOriginalStart!;
    var newEnd = _resizeOriginalEnd!;

    if (_resizeEdge == ResizeEdge.start) {
      newStart = _resizeOriginalStart!.add(Duration(days: deltaDays));
      newStart = _snapDate(newStart);
      // Ensure minimum duration
      if (newEnd.difference(newStart) < config.minimumDuration) {
        newStart = newEnd.subtract(config.minimumDuration);
      }
    } else {
      newEnd = _resizeOriginalEnd!.add(Duration(days: deltaDays));
      newEnd = _snapDate(newEnd);
      // Ensure minimum duration
      if (newEnd.difference(newStart) < config.minimumDuration) {
        newEnd = newStart.add(config.minimumDuration);
      }
    }

    return TaskResizeResult(
      taskId: _resizingTaskId!,
      edge: _resizeEdge!,
      newStart: newStart,
      newEnd: newEnd,
      originalStart: _resizeOriginalStart!,
      originalEnd: _resizeOriginalEnd!,
    );
  }

  /// Ends resizing.
  TaskResizeResult? endResize(double deltaX, double pixelsPerDay) {
    final result = updateResize(deltaX, pixelsPerDay);

    _resizingTaskId = null;
    _resizeEdge = null;
    _resizeOriginalStart = null;
    _resizeOriginalEnd = null;

    if (config.hapticFeedback && result?.hasChanged == true) {
      HapticFeedback.lightImpact();
    }

    notifyListeners();
    return result;
  }

  /// Cancels resizing.
  void cancelResize() {
    _resizingTaskId = null;
    _resizeEdge = null;
    _resizeOriginalStart = null;
    _resizeOriginalEnd = null;
    notifyListeners();
  }

  // === Keyboard Navigation ===

  /// Handles keyboard events.
  ///
  /// Returns true if the event was handled.
  bool handleKeyEvent(
    KeyEvent event,
    List<GanttTask> tasks,
  ) {
    if (!config.enableKeyboardNavigation) return false;
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;

    // Arrow navigation
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(tasks, 1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(tasks, -1);
      return true;
    }

    // Selection with Space/Enter
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (_focusedTaskId != null) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          toggleTaskSelection(_focusedTaskId!);
        } else {
          selectTask(_focusedTaskId!);
        }
        return true;
      }
    }

    // Select all with Ctrl+A
    if (key == LogicalKeyboardKey.keyA &&
        HardwareKeyboard.instance.isControlPressed) {
      selectAll(tasks);
      return true;
    }

    // Escape to clear selection
    if (key == LogicalKeyboardKey.escape) {
      if (isDragging) {
        cancelDrag();
      } else if (isResizing) {
        cancelResize();
      } else {
        clearSelection();
      }
      return true;
    }

    // Home/End for first/last task
    if (key == LogicalKeyboardKey.home) {
      if (tasks.isNotEmpty) {
        _focusedTaskId = tasks.first.id;
        if (!HardwareKeyboard.instance.isShiftPressed) {
          _selectedTaskIds.clear();
        }
        _selectedTaskIds.add(_focusedTaskId!);
        notifyListeners();
      }
      return true;
    }
    if (key == LogicalKeyboardKey.end) {
      if (tasks.isNotEmpty) {
        _focusedTaskId = tasks.last.id;
        if (!HardwareKeyboard.instance.isShiftPressed) {
          _selectedTaskIds.clear();
        }
        _selectedTaskIds.add(_focusedTaskId!);
        notifyListeners();
      }
      return true;
    }

    return false;
  }

  void _moveFocus(List<GanttTask> tasks, int delta) {
    if (tasks.isEmpty) return;

    int currentIndex = -1;
    if (_focusedTaskId != null) {
      currentIndex = tasks.indexWhere((t) => t.id == _focusedTaskId);
    }

    int newIndex;
    if (currentIndex == -1) {
      newIndex = delta > 0 ? 0 : tasks.length - 1;
    } else {
      newIndex = (currentIndex + delta).clamp(0, tasks.length - 1);
    }

    _focusedTaskId = tasks[newIndex].id;

    if (HardwareKeyboard.instance.isShiftPressed && config.enableMultiSelect) {
      _selectedTaskIds.add(_focusedTaskId!);
    } else {
      _selectedTaskIds.clear();
      _selectedTaskIds.add(_focusedTaskId!);
    }

    notifyListeners();
  }

  // === Helpers ===

  DateTime _snapDate(DateTime date) {
    switch (config.snapMode) {
      case SnapMode.none:
        return date;
      case SnapMode.day:
        return DateTime(date.year, date.month, date.day);
      case SnapMode.week:
        // Snap to Monday
        final weekday = date.weekday;
        final daysToMonday = weekday == 7 ? 1 : -(weekday - 1);
        return DateTime(date.year, date.month, date.day + daysToMonday);
      case SnapMode.month:
        return DateTime(date.year, date.month, 1);
    }
  }

  /// Determines if a position is on a resize handle.
  ResizeEdge? getResizeEdge(
    Offset position,
    Rect taskRect,
  ) {
    if (!config.enableResize) return null;

    if (position.dx >= taskRect.left &&
        position.dx <= taskRect.left + config.resizeHandleWidth) {
      return ResizeEdge.start;
    }
    if (position.dx >= taskRect.right - config.resizeHandleWidth &&
        position.dx <= taskRect.right) {
      return ResizeEdge.end;
    }
    return null;
  }

  @override
  void dispose() {
    _selectedTaskIds.clear();
    super.dispose();
  }
}
