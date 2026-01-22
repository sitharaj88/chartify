import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Controller for managing chart state.
///
/// Provides functionality for:
/// - Viewport control (pan, zoom)
/// - Data point selection
/// - Hover state tracking
///
/// Example:
/// ```dart
/// final controller = ChartController();
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Selection changed: ${controller.selectedIndices}');
/// });
///
/// // Control viewport
/// controller.zoom(1.5, Offset(100, 100));
/// controller.pan(Offset(10, 0));
///
/// // Select data points
/// controller.selectPoint(0, 5);
/// ```
class ChartController extends ChangeNotifier {
  /// Creates a chart controller.
  ChartController({
    ChartViewport? initialViewport,
  }) : _viewport = initialViewport ?? const ChartViewport();

  ChartViewport _viewport;
  final Set<DataPointIndex> _selectedIndices = {};
  DataPointInfo? _hoveredPoint;
  DataPointInfo? _tooltipPoint;
  bool _isInteracting = false;

  // ============== Viewport Control ==============

  /// The current viewport.
  ChartViewport get viewport => _viewport;

  /// Sets the viewport.
  set viewport(ChartViewport value) {
    if (_viewport != value) {
      _viewport = value;
      notifyListeners();
    }
  }

  /// Pans the viewport by the given delta.
  void pan(Offset delta) {
    _viewport = _viewport.pan(delta);
    notifyListeners();
  }

  /// Zooms the viewport by the given scale around the focal point.
  void zoom(double scale, Offset focalPoint) {
    _viewport = _viewport.zoom(scale, focalPoint);
    notifyListeners();
  }

  /// Resets the viewport to its initial state.
  void resetViewport() {
    _viewport = const ChartViewport();
    notifyListeners();
  }

  /// Sets the visible range for the X axis.
  void setXRange(double min, double max) {
    _viewport = _viewport.copyWith(xMin: min, xMax: max);
    notifyListeners();
  }

  /// Sets the visible range for the Y axis.
  void setYRange(double min, double max) {
    _viewport = _viewport.copyWith(yMin: min, yMax: max);
    notifyListeners();
  }

  // ============== Selection ==============

  /// The currently selected data point indices.
  Set<DataPointIndex> get selectedIndices => Set.unmodifiable(_selectedIndices);

  /// Whether any data points are selected.
  bool get hasSelection => _selectedIndices.isNotEmpty;

  /// Selects a data point.
  void selectPoint(int seriesIndex, int pointIndex) {
    final index = DataPointIndex(seriesIndex, pointIndex);
    _selectedIndices.add(index);
    notifyListeners();
  }

  /// Toggles the selection of a data point.
  void togglePoint(int seriesIndex, int pointIndex) {
    final index = DataPointIndex(seriesIndex, pointIndex);
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  /// Deselects a data point.
  void deselectPoint(int seriesIndex, int pointIndex) {
    final index = DataPointIndex(seriesIndex, pointIndex);
    if (_selectedIndices.remove(index)) {
      notifyListeners();
    }
  }

  /// Clears all selections.
  void clearSelection() {
    if (_selectedIndices.isNotEmpty) {
      _selectedIndices.clear();
      notifyListeners();
    }
  }

  /// Selects all points in a series.
  void selectSeries(int seriesIndex, int pointCount) {
    for (var i = 0; i < pointCount; i++) {
      _selectedIndices.add(DataPointIndex(seriesIndex, i));
    }
    notifyListeners();
  }

  /// Checks if a specific point is selected.
  bool isPointSelected(int seriesIndex, int pointIndex) =>
      _selectedIndices.contains(DataPointIndex(seriesIndex, pointIndex));

  // ============== Hover State ==============

  /// The currently hovered data point info.
  DataPointInfo? get hoveredPoint => _hoveredPoint;

  /// Sets the hovered point.
  void setHoveredPoint(DataPointInfo? point) {
    if (_hoveredPoint != point) {
      _hoveredPoint = point;
      notifyListeners();
    }
  }

  /// Clears the hover state.
  void clearHover() => setHoveredPoint(null);

  /// Clears the hovered point.
  void clearHoveredPoint() => setHoveredPoint(null);

  // ============== Tooltip ==============

  /// The current tooltip point info.
  DataPointInfo? get tooltipPoint => _tooltipPoint;

  /// Shows a tooltip for the given point.
  void showTooltip(DataPointInfo point) {
    if (_tooltipPoint != point) {
      _tooltipPoint = point;
      notifyListeners();
    }
  }

  /// Hides the tooltip.
  void hideTooltip() {
    if (_tooltipPoint != null) {
      _tooltipPoint = null;
      notifyListeners();
    }
  }

  // ============== Interaction State ==============

  /// Whether the user is currently interacting (panning, zooming).
  bool get isInteracting => _isInteracting;

  /// Marks the start of an interaction.
  void startInteraction() {
    if (!_isInteracting) {
      _isInteracting = true;
      notifyListeners();
    }
  }

  /// Marks the end of an interaction.
  void endInteraction() {
    if (_isInteracting) {
      _isInteracting = false;
      notifyListeners();
    }
  }

  // ============== Navigation ==============

  /// Moves selection to the next point.
  void selectNext(int seriesPointCount) {
    if (_selectedIndices.isEmpty) {
      selectPoint(0, 0);
      return;
    }

    final current = _selectedIndices.last;
    final nextIndex = (current.pointIndex + 1) % seriesPointCount;
    _selectedIndices.clear();
    selectPoint(current.seriesIndex, nextIndex);
  }

  /// Moves selection to the previous point.
  void selectPrevious(int seriesPointCount) {
    if (_selectedIndices.isEmpty) {
      selectPoint(0, seriesPointCount - 1);
      return;
    }

    final current = _selectedIndices.last;
    final prevIndex =
        (current.pointIndex - 1 + seriesPointCount) % seriesPointCount;
    _selectedIndices.clear();
    selectPoint(current.seriesIndex, prevIndex);
  }

  @override
  void dispose() {
    _selectedIndices.clear();
    _hoveredPoint = null;
    _tooltipPoint = null;
    super.dispose();
  }
}

/// Represents the visible viewport of a chart.
@immutable
class ChartViewport {
  /// Creates a chart viewport.
  const ChartViewport({
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.translateX = 0.0,
    this.translateY = 0.0,
  });

  /// Minimum visible X value (null = auto).
  final double? xMin;

  /// Maximum visible X value (null = auto).
  final double? xMax;

  /// Minimum visible Y value (null = auto).
  final double? yMin;

  /// Maximum visible Y value (null = auto).
  final double? yMax;

  /// Horizontal scale factor.
  final double scaleX;

  /// Vertical scale factor.
  final double scaleY;

  /// Horizontal translation.
  final double translateX;

  /// Vertical translation.
  final double translateY;

  /// Whether this viewport has custom bounds.
  bool get hasCustomBounds =>
      xMin != null || xMax != null || yMin != null || yMax != null;

  /// Whether this viewport is zoomed.
  bool get isZoomed => scaleX != 1.0 || scaleY != 1.0;

  /// Whether this viewport is panned.
  bool get isPanned => translateX != 0.0 || translateY != 0.0;

  /// Creates a panned version of this viewport.
  ChartViewport pan(Offset delta) => copyWith(
        translateX: translateX + delta.dx,
        translateY: translateY + delta.dy,
      );

  /// Creates a zoomed version of this viewport.
  ChartViewport zoom(double scale, Offset focalPoint) {
    final newScaleX = (scaleX * scale).clamp(0.1, 10.0);
    final newScaleY = (scaleY * scale).clamp(0.1, 10.0);

    // Adjust translation to keep the focal point stationary
    final scaleChange = scale - 1.0;
    final newTranslateX = translateX - focalPoint.dx * scaleChange;
    final newTranslateY = translateY - focalPoint.dy * scaleChange;

    return copyWith(
      scaleX: newScaleX,
      scaleY: newScaleY,
      translateX: newTranslateX,
      translateY: newTranslateY,
    );
  }

  /// Creates a copy with the given values replaced.
  ChartViewport copyWith({
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    double? scaleX,
    double? scaleY,
    double? translateX,
    double? translateY,
  }) =>
      ChartViewport(
        xMin: xMin ?? this.xMin,
        xMax: xMax ?? this.xMax,
        yMin: yMin ?? this.yMin,
        yMax: yMax ?? this.yMax,
        scaleX: scaleX ?? this.scaleX,
        scaleY: scaleY ?? this.scaleY,
        translateX: translateX ?? this.translateX,
        translateY: translateY ?? this.translateY,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartViewport &&
          runtimeType == other.runtimeType &&
          xMin == other.xMin &&
          xMax == other.xMax &&
          yMin == other.yMin &&
          yMax == other.yMax &&
          scaleX == other.scaleX &&
          scaleY == other.scaleY &&
          translateX == other.translateX &&
          translateY == other.translateY;

  @override
  int get hashCode => Object.hash(
        xMin,
        xMax,
        yMin,
        yMax,
        scaleX,
        scaleY,
        translateX,
        translateY,
      );

  @override
  String toString() =>
      'ChartViewport(x: $xMin-$xMax, y: $yMin-$yMax, scale: ($scaleX, $scaleY))';
}

/// Represents an index into a specific data point.
@immutable
class DataPointIndex {
  /// Creates a data point index.
  const DataPointIndex(this.seriesIndex, this.pointIndex);

  /// The index of the series.
  final int seriesIndex;

  /// The index of the point within the series.
  final int pointIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPointIndex &&
          runtimeType == other.runtimeType &&
          seriesIndex == other.seriesIndex &&
          pointIndex == other.pointIndex;

  @override
  int get hashCode => Object.hash(seriesIndex, pointIndex);

  @override
  String toString() => 'DataPointIndex($seriesIndex, $pointIndex)';
}

/// Information about a data point (for hover, selection, tooltip).
@immutable
class DataPointInfo {
  /// Creates data point info.
  const DataPointInfo({
    required this.seriesIndex,
    required this.pointIndex,
    required this.position,
    this.xValue,
    this.yValue,
    this.seriesName,
    this.label,
    this.metadata,
  });

  /// The index of the series.
  final int seriesIndex;

  /// The index of the point within the series.
  final int pointIndex;

  /// The position of the point in screen coordinates.
  final Offset position;

  /// The X value of the data point.
  final dynamic xValue;

  /// The Y value of the data point.
  final dynamic yValue;

  /// The name of the series.
  final String? seriesName;

  /// Optional label for display.
  final String? label;

  /// Optional metadata from the data point.
  final Map<String, dynamic>? metadata;

  /// Creates a copy with the given values replaced.
  DataPointInfo copyWith({
    int? seriesIndex,
    int? pointIndex,
    Offset? position,
    dynamic xValue,
    dynamic yValue,
    String? seriesName,
    String? label,
    Map<String, dynamic>? metadata,
  }) =>
      DataPointInfo(
        seriesIndex: seriesIndex ?? this.seriesIndex,
        pointIndex: pointIndex ?? this.pointIndex,
        position: position ?? this.position,
        xValue: xValue ?? this.xValue,
        yValue: yValue ?? this.yValue,
        seriesName: seriesName ?? this.seriesName,
        label: label ?? this.label,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPointInfo &&
          runtimeType == other.runtimeType &&
          seriesIndex == other.seriesIndex &&
          pointIndex == other.pointIndex;

  @override
  int get hashCode => Object.hash(seriesIndex, pointIndex);

  @override
  String toString() =>
      'DataPointInfo(series: $seriesIndex, point: $pointIndex, pos: $position)';
}
