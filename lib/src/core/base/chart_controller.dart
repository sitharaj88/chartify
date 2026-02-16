import 'dart:async';
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Controller for managing chart state.
///
/// Provides functionality for:
/// - Viewport control (pan, zoom)
/// - Animated zoom and pan
/// - Zoom constraints
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
/// // Animated zoom
/// controller.animateZoom(2.0, Offset(100, 100));
///
/// // Select data points
/// controller.selectPoint(0, 5);
/// ```
class ChartController extends ChangeNotifier {
  /// Creates a chart controller.
  ChartController({
    ChartViewport? initialViewport,
    Set<int>? hiddenSeriesIndices,
    this.minZoomX = 0.5,
    this.maxZoomX = 20.0,
    this.minZoomY = 0.5,
    this.maxZoomY = 20.0,
    this.enableMomentum = true,
    this.constrainPanToBounds = true,
  })  : _viewport = initialViewport ?? const ChartViewport(),
        _initialViewport = initialViewport ?? const ChartViewport(),
        _hiddenSeriesIndices = hiddenSeriesIndices?.toSet() ?? {};

  ChartViewport _viewport;
  final ChartViewport _initialViewport;
  final Set<DataPointIndex> _selectedIndices = {};
  final Set<int> _hiddenSeriesIndices;
  DataPointInfo? _hoveredPoint;
  DataPointInfo? _tooltipPoint;
  bool _isInteracting = false;

  // Zoom constraints
  /// Minimum zoom level for X axis.
  final double minZoomX;

  /// Maximum zoom level for X axis.
  final double maxZoomX;

  /// Minimum zoom level for Y axis.
  final double minZoomY;

  /// Maximum zoom level for Y axis.
  final double maxZoomY;

  /// Whether to apply momentum after pan gestures.
  final bool enableMomentum;

  /// Whether to constrain panning to data bounds.
  final bool constrainPanToBounds;

  // Animation state
  _ViewportAnimation? _currentAnimation;

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
    _viewport = _viewport.zoomConstrained(
      scale,
      focalPoint,
      minScaleX: minZoomX,
      maxScaleX: maxZoomX,
      minScaleY: minZoomY,
      maxScaleY: maxZoomY,
    );
    notifyListeners();
  }

  /// Zooms to a specific scale level with animation.
  ///
  /// Returns a Future that completes when the animation is done.
  Future<void> animateZoom(
    double targetScale,
    Offset focalPoint, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) async {
    final startViewport = _viewport;
    final endViewport = _viewport.zoomConstrained(
      targetScale / _viewport.scaleX,
      focalPoint,
      minScaleX: minZoomX,
      maxScaleX: maxZoomX,
      minScaleY: minZoomY,
      maxScaleY: maxZoomY,
    );

    await _animateViewport(startViewport, endViewport, duration, curve);
  }

  /// Zooms to fit the specified data range.
  ///
  /// Returns a Future that completes when the animation is done.
  Future<void> zoomToRange({
    required double xMin,
    required double xMax,
    double? yMin,
    double? yMax,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    bool animate = true,
  }) async {
    final endViewport = _viewport.copyWith(
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
      scaleX: 1.0,
      scaleY: 1.0,
      translateX: 0.0,
      translateY: 0.0,
    );

    if (animate) {
      await _animateViewport(_viewport, endViewport, duration, curve);
    } else {
      _viewport = endViewport;
      notifyListeners();
    }
  }

  /// Resets the viewport to its initial state.
  void resetViewport() {
    _stopAnimation();
    _viewport = _initialViewport;
    notifyListeners();
  }

  /// Resets the viewport with animation.
  Future<void> animateReset({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) async {
    await _animateViewport(_viewport, _initialViewport, duration, curve);
  }

  /// Handles pinch zoom gesture.
  ///
  /// Call this with the two focal points and the scale delta.
  void handlePinchZoom({
    required Offset focal1,
    required Offset focal2,
    required double scale,
    required double previousScale,
  }) {
    final center = Offset(
      (focal1.dx + focal2.dx) / 2,
      (focal1.dy + focal2.dy) / 2,
    );
    final scaleDelta = scale / previousScale;
    zoom(scaleDelta, center);
  }

  /// Handles scroll wheel zoom.
  ///
  /// [scrollDelta] is typically event.scrollDelta.dy from a PointerScrollEvent.
  /// [focalPoint] is the mouse position.
  void handleScrollWheelZoom({
    required double scrollDelta,
    required Offset focalPoint,
    double zoomFactor = 1.1,
  }) {
    final scale = scrollDelta < 0 ? zoomFactor : 1 / zoomFactor;
    zoom(scale, focalPoint);
  }

  /// Internal animation helper.
  Future<void> _animateViewport(
    ChartViewport start,
    ChartViewport end,
    Duration duration,
    Curve curve,
  ) async {
    _stopAnimation();

    final completer = Completer<void>();
    final startTime = DateTime.now();

    void tick() {
      final elapsed = DateTime.now().difference(startTime);
      final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
      final curvedT = curve.transform(t);

      _viewport = ChartViewport(
        xMin: _lerpNullable(start.xMin, end.xMin, curvedT),
        xMax: _lerpNullable(start.xMax, end.xMax, curvedT),
        yMin: _lerpNullable(start.yMin, end.yMin, curvedT),
        yMax: _lerpNullable(start.yMax, end.yMax, curvedT),
        scaleX: _lerp(start.scaleX, end.scaleX, curvedT),
        scaleY: _lerp(start.scaleY, end.scaleY, curvedT),
        translateX: _lerp(start.translateX, end.translateX, curvedT),
        translateY: _lerp(start.translateY, end.translateY, curvedT),
      );
      notifyListeners();

      if (t >= 1.0) {
        _currentAnimation = null;
        completer.complete();
      } else {
        _currentAnimation = _ViewportAnimation(tick, completer);
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          if (_currentAnimation?.tick == tick) {
            tick();
          }
        });
      }
    }

    _currentAnimation = _ViewportAnimation(tick, completer);
    tick();

    return completer.future;
  }

  void _stopAnimation() {
    _currentAnimation = null;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double? _lerpNullable(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return _lerp(a, b, t);
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

  // ============== Series Visibility ==============

  /// The indices of hidden series.
  Set<int> get hiddenSeriesIndices => Set.unmodifiable(_hiddenSeriesIndices);

  /// Whether any series are hidden.
  bool get hasHiddenSeries => _hiddenSeriesIndices.isNotEmpty;

  /// Checks if a series is visible.
  bool isSeriesVisible(int seriesIndex) =>
      !_hiddenSeriesIndices.contains(seriesIndex);

  /// Checks if a series is hidden.
  bool isSeriesHidden(int seriesIndex) =>
      _hiddenSeriesIndices.contains(seriesIndex);

  /// Hides a series.
  void hideSeries(int seriesIndex) {
    if (_hiddenSeriesIndices.add(seriesIndex)) {
      notifyListeners();
    }
  }

  /// Shows a previously hidden series.
  void showSeries(int seriesIndex) {
    if (_hiddenSeriesIndices.remove(seriesIndex)) {
      notifyListeners();
    }
  }

  /// Toggles the visibility of a series.
  void toggleSeriesVisibility(int seriesIndex) {
    if (_hiddenSeriesIndices.contains(seriesIndex)) {
      _hiddenSeriesIndices.remove(seriesIndex);
    } else {
      _hiddenSeriesIndices.add(seriesIndex);
    }
    notifyListeners();
  }

  /// Shows all series.
  void showAllSeries() {
    if (_hiddenSeriesIndices.isNotEmpty) {
      _hiddenSeriesIndices.clear();
      notifyListeners();
    }
  }

  /// Hides all series except the one at the given index.
  ///
  /// Useful for "isolate" functionality (double-click to focus on one series).
  void isolateSeries(int seriesIndex, int totalSeriesCount) {
    _hiddenSeriesIndices.clear();
    for (var i = 0; i < totalSeriesCount; i++) {
      if (i != seriesIndex) {
        _hiddenSeriesIndices.add(i);
      }
    }
    notifyListeners();
  }

  /// Returns the visible series indices given the total count.
  List<int> getVisibleSeriesIndices(int totalSeriesCount) {
    final visible = <int>[];
    for (var i = 0; i < totalSeriesCount; i++) {
      if (!_hiddenSeriesIndices.contains(i)) {
        visible.add(i);
      }
    }
    return visible;
  }

  @override
  void dispose() {
    _selectedIndices.clear();
    _hiddenSeriesIndices.clear();
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

  /// Creates a zoomed version with constraints.
  ChartViewport zoomConstrained(
    double scale,
    Offset focalPoint, {
    double minScaleX = 0.5,
    double maxScaleX = 20.0,
    double minScaleY = 0.5,
    double maxScaleY = 20.0,
  }) {
    final newScaleX = (scaleX * scale).clamp(minScaleX, maxScaleX);
    final newScaleY = (scaleY * scale).clamp(minScaleY, maxScaleY);

    // Calculate the actual scale change after clamping
    final actualScaleX = newScaleX / scaleX;
    final actualScaleY = newScaleY / scaleY;

    // Adjust translation to keep the focal point stationary
    final newTranslateX = translateX - focalPoint.dx * (actualScaleX - 1.0);
    final newTranslateY = translateY - focalPoint.dy * (actualScaleY - 1.0);

    return copyWith(
      scaleX: newScaleX,
      scaleY: newScaleY,
      translateX: newTranslateX,
      translateY: newTranslateY,
    );
  }

  /// Zooms only in the X direction.
  ChartViewport zoomX(double scale, double focalX, {double min = 0.5, double max = 20.0}) {
    final newScaleX = (scaleX * scale).clamp(min, max);
    final actualScale = newScaleX / scaleX;
    final newTranslateX = translateX - focalX * (actualScale - 1.0);

    return copyWith(
      scaleX: newScaleX,
      translateX: newTranslateX,
    );
  }

  /// Zooms only in the Y direction.
  ChartViewport zoomY(double scale, double focalY, {double min = 0.5, double max = 20.0}) {
    final newScaleY = (scaleY * scale).clamp(min, max);
    final actualScale = newScaleY / scaleY;
    final newTranslateY = translateY - focalY * (actualScale - 1.0);

    return copyWith(
      scaleY: newScaleY,
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

/// Internal class for tracking viewport animations.
class _ViewportAnimation {
  _ViewportAnimation(this.tick, this.completer);

  final void Function() tick;
  final Completer<void> completer;
}

/// Configuration for zoom behavior.
@immutable
class ZoomConfig {
  /// Creates a zoom configuration.
  const ZoomConfig({
    this.minZoomX = 0.5,
    this.maxZoomX = 20.0,
    this.minZoomY = 0.5,
    this.maxZoomY = 20.0,
    this.enablePinchZoom = true,
    this.enableScrollWheelZoom = true,
    this.enableDoubleTapZoom = true,
    this.scrollWheelZoomFactor = 1.1,
    this.doubleTapZoomFactor = 2.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  /// Standard zoom configuration.
  static const standard = ZoomConfig();

  /// Configuration for financial charts (more zoom range).
  static const financial = ZoomConfig(
    maxZoomX: 50.0,
    maxZoomY: 10.0,
  );

  /// Configuration for touch-only devices.
  static const touchOnly = ZoomConfig(
    enableScrollWheelZoom: false,
  );

  /// Minimum zoom level for X axis.
  final double minZoomX;

  /// Maximum zoom level for X axis.
  final double maxZoomX;

  /// Minimum zoom level for Y axis.
  final double minZoomY;

  /// Maximum zoom level for Y axis.
  final double maxZoomY;

  /// Whether pinch zoom is enabled.
  final bool enablePinchZoom;

  /// Whether scroll wheel zoom is enabled.
  final bool enableScrollWheelZoom;

  /// Whether double tap zoom is enabled.
  final bool enableDoubleTapZoom;

  /// Zoom factor for scroll wheel.
  final double scrollWheelZoomFactor;

  /// Zoom factor for double tap.
  final double doubleTapZoomFactor;

  /// Duration of zoom animations.
  final Duration animationDuration;

  /// Curve for zoom animations.
  final Curve animationCurve;

  /// Creates a copy with the given values replaced.
  ZoomConfig copyWith({
    double? minZoomX,
    double? maxZoomX,
    double? minZoomY,
    double? maxZoomY,
    bool? enablePinchZoom,
    bool? enableScrollWheelZoom,
    bool? enableDoubleTapZoom,
    double? scrollWheelZoomFactor,
    double? doubleTapZoomFactor,
    Duration? animationDuration,
    Curve? animationCurve,
  }) =>
      ZoomConfig(
        minZoomX: minZoomX ?? this.minZoomX,
        maxZoomX: maxZoomX ?? this.maxZoomX,
        minZoomY: minZoomY ?? this.minZoomY,
        maxZoomY: maxZoomY ?? this.maxZoomY,
        enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
        enableScrollWheelZoom: enableScrollWheelZoom ?? this.enableScrollWheelZoom,
        enableDoubleTapZoom: enableDoubleTapZoom ?? this.enableDoubleTapZoom,
        scrollWheelZoomFactor: scrollWheelZoomFactor ?? this.scrollWheelZoomFactor,
        doubleTapZoomFactor: doubleTapZoomFactor ?? this.doubleTapZoomFactor,
        animationDuration: animationDuration ?? this.animationDuration,
        animationCurve: animationCurve ?? this.animationCurve,
      );
}
