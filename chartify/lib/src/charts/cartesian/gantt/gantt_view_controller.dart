import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'gantt_chart_data.dart';

/// Sort field for tasks.
enum TaskSortField {
  /// Sort by task name.
  name,

  /// Sort by start date.
  start,

  /// Sort by end date.
  end,

  /// Sort by progress.
  progress,

  /// Sort by duration.
  duration,

  /// Sort by priority.
  priority,

  /// Keep original order.
  none,
}

/// Filter for task visibility.
typedef TaskFilter = bool Function(GanttTask task);

/// Controller for Gantt chart view settings.
///
/// Manages zoom level, visible date range, filtering, sorting,
/// and group collapse state.
class GanttViewController extends ChangeNotifier {
  GanttViewController({
    GanttViewMode viewMode = GanttViewMode.day,
    double zoomLevel = 1.0,
    DateTime? visibleStartDate,
    DateTime? visibleEndDate,
  })  : _viewMode = viewMode,
        _zoomLevel = zoomLevel.clamp(0.25, 4.0),
        _visibleStartDate = visibleStartDate,
        _visibleEndDate = visibleEndDate;

  // === View Mode ===

  GanttViewMode _viewMode;

  /// Current view mode (day, week, month, quarter, year).
  GanttViewMode get viewMode => _viewMode;

  set viewMode(GanttViewMode value) {
    if (_viewMode != value) {
      _viewMode = value;
      notifyListeners();
    }
  }

  // === Zoom ===

  double _zoomLevel;

  /// Current zoom level (0.25 = zoomed out, 4.0 = zoomed in).
  double get zoomLevel => _zoomLevel;

  set zoomLevel(double value) {
    final clamped = value.clamp(0.25, 4.0);
    if (_zoomLevel != clamped) {
      _zoomLevel = clamped;
      notifyListeners();
    }
  }

  /// Zooms in by a step.
  void zoomIn({double step = 0.25}) {
    zoomLevel = _zoomLevel + step;
  }

  /// Zooms out by a step.
  void zoomOut({double step = 0.25}) {
    zoomLevel = _zoomLevel - step;
  }

  /// Resets zoom to default.
  void resetZoom() {
    zoomLevel = 1.0;
  }

  /// Whether can zoom in further.
  bool get canZoomIn => _zoomLevel < 4.0;

  /// Whether can zoom out further.
  bool get canZoomOut => _zoomLevel > 0.25;

  // === Visible Date Range ===

  DateTime? _visibleStartDate;
  DateTime? _visibleEndDate;

  /// Start of visible date range.
  DateTime? get visibleStartDate => _visibleStartDate;

  /// End of visible date range.
  DateTime? get visibleEndDate => _visibleEndDate;

  /// Sets the visible date range.
  void setVisibleRange(DateTime start, DateTime end) {
    _visibleStartDate = start;
    _visibleEndDate = end;
    notifyListeners();
  }

  /// Scrolls to show a specific date.
  void scrollToDate(DateTime date, {Duration padding = const Duration(days: 7)}) {
    _visibleStartDate = date.subtract(padding);
    _visibleEndDate = date.add(padding);
    notifyListeners();
  }

  /// Scrolls to show a specific task.
  void scrollToTask(GanttTask task, {Duration padding = const Duration(days: 3)}) {
    _visibleStartDate = task.start.subtract(padding);
    _visibleEndDate = task.end.add(padding);
    notifyListeners();
  }

  /// Scrolls to today.
  void scrollToToday({Duration padding = const Duration(days: 14)}) {
    scrollToDate(DateTime.now(), padding: padding);
  }

  /// Resets visible range to show all tasks.
  void resetVisibleRange() {
    _visibleStartDate = null;
    _visibleEndDate = null;
    notifyListeners();
  }

  // === Filtering ===

  TaskFilter? _filter;
  bool _showCompletedTasks = true;
  Set<String>? _visibleResourceIds;

  /// Custom task filter.
  TaskFilter? get filter => _filter;

  set filter(TaskFilter? value) {
    _filter = value;
    notifyListeners();
  }

  /// Whether to show completed tasks.
  bool get showCompletedTasks => _showCompletedTasks;

  set showCompletedTasks(bool value) {
    if (_showCompletedTasks != value) {
      _showCompletedTasks = value;
      notifyListeners();
    }
  }

  /// Resource IDs to show (null = show all).
  Set<String>? get visibleResourceIds => _visibleResourceIds;

  set visibleResourceIds(Set<String>? value) {
    _visibleResourceIds = value;
    notifyListeners();
  }

  /// Filters to show only specific resource.
  void filterByResource(String resourceId) {
    _visibleResourceIds = {resourceId};
    notifyListeners();
  }

  /// Filters to show multiple resources.
  void filterByResources(Set<String> resourceIds) {
    _visibleResourceIds = resourceIds;
    notifyListeners();
  }

  /// Clears resource filter.
  void clearResourceFilter() {
    _visibleResourceIds = null;
    notifyListeners();
  }

  /// Clears all filters.
  void clearFilters() {
    _filter = null;
    _showCompletedTasks = true;
    _visibleResourceIds = null;
    notifyListeners();
  }

  /// Applies filters to a list of tasks.
  List<GanttTask> applyFilters(List<GanttTask> tasks) {
    var result = tasks;

    // Apply completed filter
    if (!_showCompletedTasks) {
      result = result.where((t) => t.progress < 1.0).toList();
    }

    // Apply resource filter
    if (_visibleResourceIds != null) {
      result = result.where((t) =>
          t.resourceId == null || _visibleResourceIds!.contains(t.resourceId)).toList();
    }

    // Apply custom filter
    if (_filter != null) {
      result = result.where(_filter!).toList();
    }

    return result;
  }

  // === Sorting ===

  TaskSortField _sortField = TaskSortField.none;
  bool _sortAscending = true;

  /// Current sort field.
  TaskSortField get sortField => _sortField;

  set sortField(TaskSortField value) {
    if (_sortField != value) {
      _sortField = value;
      notifyListeners();
    }
  }

  /// Whether sorting is ascending.
  bool get sortAscending => _sortAscending;

  set sortAscending(bool value) {
    if (_sortAscending != value) {
      _sortAscending = value;
      notifyListeners();
    }
  }

  /// Sets sort field and direction.
  void setSort(TaskSortField field, {bool ascending = true}) {
    _sortField = field;
    _sortAscending = ascending;
    notifyListeners();
  }

  /// Toggles sort direction.
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }

  /// Clears sorting.
  void clearSort() {
    _sortField = TaskSortField.none;
    _sortAscending = true;
    notifyListeners();
  }

  /// Applies sorting to a list of tasks.
  List<GanttTask> applySorting(List<GanttTask> tasks) {
    if (_sortField == TaskSortField.none) return tasks;

    final sorted = List<GanttTask>.from(tasks);

    int compare(GanttTask a, GanttTask b) {
      int result;
      switch (_sortField) {
        case TaskSortField.name:
          result = a.label.compareTo(b.label);
        case TaskSortField.start:
          result = a.start.compareTo(b.start);
        case TaskSortField.end:
          result = a.end.compareTo(b.end);
        case TaskSortField.progress:
          result = a.progress.compareTo(b.progress);
        case TaskSortField.duration:
          result = a.duration.compareTo(b.duration);
        case TaskSortField.priority:
          result = (a.priority ?? 0).compareTo(b.priority ?? 0);
        case TaskSortField.none:
          result = 0;
      }
      return _sortAscending ? result : -result;
    }

    sorted.sort(compare);
    return sorted;
  }

  // === Group Collapse ===

  final Set<String> _collapsedGroupIds = {};

  /// Set of collapsed group IDs.
  Set<String> get collapsedGroupIds => Set.unmodifiable(_collapsedGroupIds);

  /// Collapses a group.
  void collapseGroup(String groupId) {
    _collapsedGroupIds.add(groupId);
    notifyListeners();
  }

  /// Expands a group.
  void expandGroup(String groupId) {
    _collapsedGroupIds.remove(groupId);
    notifyListeners();
  }

  /// Toggles group collapse state.
  void toggleGroup(String groupId) {
    if (_collapsedGroupIds.contains(groupId)) {
      _collapsedGroupIds.remove(groupId);
    } else {
      _collapsedGroupIds.add(groupId);
    }
    notifyListeners();
  }

  /// Expands all groups.
  void expandAll() {
    _collapsedGroupIds.clear();
    notifyListeners();
  }

  /// Collapses all groups.
  void collapseAll(List<GanttTask> tasks) {
    for (final task in tasks) {
      if (task.isGroup) {
        _collapsedGroupIds.add(task.id);
      }
    }
    notifyListeners();
  }

  /// Whether a group is collapsed.
  bool isGroupCollapsed(String groupId) => _collapsedGroupIds.contains(groupId);

  // === Combined Processing ===

  /// Applies all view settings (filter, sort, collapse) to tasks.
  List<GanttTask> processTasksForView(List<GanttTask> tasks) {
    var result = tasks;

    // Apply filters
    result = applyFilters(result);

    // Apply sorting
    result = applySorting(result);

    // Note: Collapse state is handled by GanttChartData.visibleTasks
    // based on collapsedGroupIds

    return result;
  }

  /// Creates a GanttChartData copy with view controller settings applied.
  GanttChartData applyToData(GanttChartData data) {
    return data.copyWith(
      viewMode: _viewMode,
      collapsedGroupIds: _collapsedGroupIds,
      startDate: _visibleStartDate,
      endDate: _visibleEndDate,
    );
  }

  // === Preset Views ===

  /// Sets view to show this week.
  void showThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    setVisibleRange(startOfWeek, endOfWeek);
    viewMode = GanttViewMode.day;
  }

  /// Sets view to show this month.
  void showThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    setVisibleRange(startOfMonth, endOfMonth);
    viewMode = GanttViewMode.day;
  }

  /// Sets view to show this quarter.
  void showThisQuarter() {
    final now = DateTime.now();
    final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
    final startOfQuarter = DateTime(now.year, quarterStart, 1);
    final endOfQuarter = DateTime(now.year, quarterStart + 3, 0);
    setVisibleRange(startOfQuarter, endOfQuarter);
    viewMode = GanttViewMode.week;
  }

  /// Sets view to show this year.
  void showThisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    setVisibleRange(startOfYear, endOfYear);
    viewMode = GanttViewMode.month;
  }

  @override
  void dispose() {
    _collapsedGroupIds.clear();
    super.dispose();
  }
}

/// Utility class for exporting Gantt charts.
class GanttExporter {
  GanttExporter._();

  /// Exports the chart widget to PNG image data.
  ///
  /// [key] should be a GlobalKey attached to the GanttChart widget.
  /// [pixelRatio] controls the output resolution.
  static Future<Uint8List?> toPng(
    GlobalKey key, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Exports tasks to CSV format.
  static String toCsv(
    List<GanttTask> tasks, {
    bool includeHeaders = true,
    String separator = ',',
  }) {
    final buffer = StringBuffer();

    // Headers
    if (includeHeaders) {
      buffer.writeln([
        'ID',
        'Label',
        'Start',
        'End',
        'Duration (days)',
        'Progress (%)',
        'Resource',
        'Parent',
        'Dependencies',
        'Is Milestone',
        'Is Group',
        'Priority',
      ].join(separator));
    }

    // Data rows
    for (final task in tasks) {
      final row = [
        _escapeCsv(task.id),
        _escapeCsv(task.label),
        task.start.toIso8601String().split('T').first,
        task.end.toIso8601String().split('T').first,
        task.duration.inDays.toString(),
        (task.progress * 100).toStringAsFixed(1),
        _escapeCsv(task.resourceName ?? ''),
        _escapeCsv(task.parentId ?? ''),
        _escapeCsv(task.dependencies?.join(';') ?? ''),
        task.isMilestoneType ? 'Yes' : 'No',
        task.isGroup ? 'Yes' : 'No',
        task.priority?.toString() ?? '',
      ];
      buffer.writeln(row.join(separator));
    }

    return buffer.toString();
  }

  /// Exports tasks to JSON format.
  static String toJson(List<GanttTask> tasks) {
    final taskMaps = tasks.map((task) => {
          'id': task.id,
          'label': task.label,
          'start': task.start.toIso8601String(),
          'end': task.end.toIso8601String(),
          'progress': task.progress,
          'resourceId': task.resourceId,
          'resourceName': task.resourceName,
          'parentId': task.parentId,
          'level': task.level,
          'dependencies': task.dependencies,
          'isMilestone': task.isMilestoneType,
          'isGroup': task.isGroup,
          'priority': task.priority,
          if (task.baselineStart != null)
            'baselineStart': task.baselineStart!.toIso8601String(),
          if (task.baselineEnd != null)
            'baselineEnd': task.baselineEnd!.toIso8601String(),
        }).toList();

    // Manual JSON encoding to avoid import
    return _encodeJson(taskMaps);
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _encodeJson(List<Map<String, dynamic>> list) {
    final items = list.map(_encodeJsonMap).join(',\n  ');
    return '[\n  $items\n]';
  }

  static String _encodeJsonMap(Map<String, dynamic> map) {
    final pairs = map.entries
        .where((e) => e.value != null)
        .map((e) => '"${e.key}": ${_encodeJsonValue(e.value)}');
    return '{${pairs.join(', ')}}';
  }

  static String _encodeJsonValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is List) {
      final items = value.map(_encodeJsonValue).join(', ');
      return '[$items]';
    }
    if (value is Map<String, dynamic>) return _encodeJsonMap(value);
    return '"$value"';
  }
}
