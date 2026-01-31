import 'dart:ui';

import '../base/chart_controller.dart';
import '../gestures/spatial_index.dart';
import '../utils/data_decimation_advanced.dart';
import 'data_point.dart';

/// A data processing pipeline for efficient large dataset handling.
///
/// The pipeline provides:
/// - Viewport-aware data filtering
/// - Automatic decimation when needed
/// - Spatial index building for hit testing
/// - Change notification for reactive updates
///
/// Example:
/// ```dart
/// final pipeline = DataPipeline<double, double>(
///   rawData: largeDataset,
///   decimationConfig: DecimationConfig.standard,
/// );
///
/// // Get visible data for current viewport
/// final visible = pipeline.getVisibleData(
///   controller.viewport,
///   chartArea,
/// );
/// ```
class DataPipeline<X extends num, Y extends num> {
  /// Creates a data pipeline for processing chart data.
  DataPipeline({
    required List<DataPoint<X, Y>> rawData,
    this.decimationConfig = const DecimationConfig(),
  }) : _rawData = rawData;

  final List<DataPoint<X, Y>> _rawData;
  final DecimationConfig decimationConfig;

  // Cached processed data
  List<DataPoint<X, Y>>? _cachedData;
  ChartViewport? _cachedViewport;
  Rect? _cachedChartArea;
  SpatialIndex<DataPointInfo>? _cachedSpatialIndex;

  /// The raw unprocessed data.
  List<DataPoint<X, Y>> get rawData => _rawData;

  /// Number of raw data points.
  int get rawDataCount => _rawData.length;

  /// Whether the dataset is considered large (needs decimation).
  bool get isLargeDataset => _rawData.length > decimationConfig.threshold;

  /// Returns processed data optimized for the current viewport.
  ///
  /// The processing includes:
  /// 1. Viewport culling (only visible range + margin)
  /// 2. Decimation if point count exceeds threshold
  /// 3. Caching for repeated calls with same parameters
  List<DataPoint<X, Y>> getVisibleData(
    ChartViewport viewport,
    Rect chartArea,
  ) {
    // Check cache validity
    if (_cachedData != null &&
        _isSameViewport(viewport, _cachedViewport) &&
        _isSameRect(chartArea, _cachedChartArea)) {
      return _cachedData!;
    }

    // Process data
    List<DataPoint<X, Y>> result;

    if (_rawData.length <= decimationConfig.maxVisiblePoints) {
      // Small dataset - use all points
      result = List.from(_rawData);
    } else {
      // Large dataset - apply decimation based on mode
      result = AdvancedDecimator.auto(
        _rawData,
        targetPoints: decimationConfig.maxVisiblePoints,
        mode: decimationConfig.mode,
        viewport: viewport,
      );
    }

    // Cache results
    _cachedData = result;
    _cachedViewport = viewport;
    _cachedChartArea = chartArea;
    _cachedSpatialIndex = null; // Invalidate spatial index

    return result;
  }

  /// Returns all data without viewport filtering (but still decimated if large).
  List<DataPoint<X, Y>> getAllData() {
    if (_rawData.length <= decimationConfig.maxVisiblePoints) {
      return List.from(_rawData);
    }

    return AdvancedDecimator.lttb(
      _rawData,
      targetPoints: decimationConfig.maxVisiblePoints,
    );
  }

  /// Builds a spatial index for efficient hit testing on visible data.
  ///
  /// The index is cached and rebuilt only when data changes.
  SpatialIndex<DataPointInfo> buildSpatialIndex(
    Rect chartArea,
    CoordinateMapper mapper,
  ) {
    if (_cachedSpatialIndex != null && _isSameRect(chartArea, _cachedChartArea)) {
      return _cachedSpatialIndex!;
    }

    final data = _cachedData ?? getAllData();
    final index = QuadTree<DataPointInfo>(bounds: chartArea);

    // Hit testing radius for point detection
    const hitRadius = 8.0;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final screenPos = mapper(point.x.toDouble(), point.y.toDouble());

      if (chartArea.contains(screenPos)) {
        // Create a small rect around the point for spatial indexing
        final hitBounds = Rect.fromCenter(
          center: screenPos,
          width: hitRadius * 2,
          height: hitRadius * 2,
        );

        index.insert(
          DataPointInfo(
            seriesIndex: 0,
            pointIndex: i,
            position: screenPos,
            xValue: point.x.toDouble(),
            yValue: point.y.toDouble(),
          ),
          hitBounds,
        );
      }
    }

    _cachedSpatialIndex = index;
    return index;
  }

  /// Invalidates all cached data, forcing reprocessing on next access.
  void invalidateCache() {
    _cachedData = null;
    _cachedViewport = null;
    _cachedChartArea = null;
    _cachedSpatialIndex = null;
  }

  /// Updates the raw data and invalidates cache.
  void updateData(List<DataPoint<X, Y>> newData) {
    _rawData.clear();
    _rawData.addAll(newData);
    invalidateCache();
  }

  /// Appends new data points (for streaming scenarios).
  void appendData(List<DataPoint<X, Y>> newPoints) {
    _rawData.addAll(newPoints);
    invalidateCache();
  }

  /// Removes data points older than the given x value (for rolling windows).
  void removeOlderThan(X minX) {
    _rawData.removeWhere((p) => p.x.toDouble() < minX.toDouble());
    invalidateCache();
  }

  /// Gets the data bounds (min/max for X and Y).
  DataBounds? getBounds() {
    if (_rawData.isEmpty) return null;

    var minX = _rawData.first.x.toDouble();
    var maxX = _rawData.first.x.toDouble();
    var minY = _rawData.first.y.toDouble();
    var maxY = _rawData.first.y.toDouble();

    for (final point in _rawData) {
      final x = point.x.toDouble();
      final y = point.y.toDouble();
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    return DataBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  bool _isSameViewport(ChartViewport a, ChartViewport? b) {
    if (b == null) return false;
    return a.xMin == b.xMin &&
        a.xMax == b.xMax &&
        a.yMin == b.yMin &&
        a.yMax == b.yMax &&
        a.scaleX == b.scaleX &&
        a.scaleY == b.scaleY;
  }

  bool _isSameRect(Rect a, Rect? b) {
    if (b == null) return false;
    return a.left == b.left &&
        a.top == b.top &&
        a.right == b.right &&
        a.bottom == b.bottom;
  }
}

/// Function type for mapping data coordinates to screen coordinates.
typedef CoordinateMapper = Offset Function(double x, double y);

/// Represents the bounds of a dataset.
class DataBounds {
  const DataBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  double get rangeX => maxX - minX;
  double get rangeY => maxY - minY;

  /// Expands bounds to include a point.
  DataBounds include(double x, double y) {
    return DataBounds(
      minX: x < minX ? x : minX,
      maxX: x > maxX ? x : maxX,
      minY: y < minY ? y : minY,
      maxY: y > maxY ? y : maxY,
    );
  }

  /// Adds padding to the bounds.
  DataBounds withPadding({
    double xPadding = 0,
    double yPadding = 0,
  }) {
    return DataBounds(
      minX: minX - xPadding,
      maxX: maxX + xPadding,
      minY: minY - yPadding,
      maxY: maxY + yPadding,
    );
  }

  /// Adds percentage-based padding.
  DataBounds withPaddingPercent({
    double xPercent = 0,
    double yPercent = 0,
  }) {
    final xPad = rangeX * xPercent;
    final yPad = rangeY * yPercent;
    return withPadding(xPadding: xPad, yPadding: yPad);
  }
}

/// Multi-series data pipeline for charts with multiple data series.
class MultiSeriesDataPipeline<X extends num, Y extends num> {
  MultiSeriesDataPipeline({
    required List<List<DataPoint<X, Y>>> seriesData,
    this.decimationConfig = const DecimationConfig(),
  }) : _pipelines = seriesData
            .map((data) => DataPipeline<X, Y>(
                  rawData: data,
                  decimationConfig: decimationConfig,
                ))
            .toList();

  final List<DataPipeline<X, Y>> _pipelines;
  final DecimationConfig decimationConfig;

  /// Number of series.
  int get seriesCount => _pipelines.length;

  /// Gets the pipeline for a specific series.
  DataPipeline<X, Y> operator [](int index) => _pipelines[index];

  /// Gets visible data for all series.
  List<List<DataPoint<X, Y>>> getVisibleData(
    ChartViewport viewport,
    Rect chartArea,
  ) {
    return _pipelines
        .map((p) => p.getVisibleData(viewport, chartArea))
        .toList();
  }

  /// Builds spatial index containing all series data.
  SpatialIndex<DataPointInfo> buildCombinedSpatialIndex(
    Rect chartArea,
    List<CoordinateMapper> mappers,
  ) {
    final index = QuadTree<DataPointInfo>(bounds: chartArea);

    // Hit testing radius for point detection
    const hitRadius = 8.0;

    for (var seriesIdx = 0; seriesIdx < _pipelines.length; seriesIdx++) {
      final data = _pipelines[seriesIdx]._cachedData ??
          _pipelines[seriesIdx].getAllData();
      final mapper = mappers[seriesIdx];

      for (var pointIdx = 0; pointIdx < data.length; pointIdx++) {
        final point = data[pointIdx];
        final screenPos = mapper(point.x.toDouble(), point.y.toDouble());

        if (chartArea.contains(screenPos)) {
          // Create a small rect around the point for spatial indexing
          final hitBounds = Rect.fromCenter(
            center: screenPos,
            width: hitRadius * 2,
            height: hitRadius * 2,
          );

          index.insert(
            DataPointInfo(
              seriesIndex: seriesIdx,
              pointIndex: pointIdx,
              position: screenPos,
              xValue: point.x.toDouble(),
              yValue: point.y.toDouble(),
            ),
            hitBounds,
          );
        }
      }
    }

    return index;
  }

  /// Gets combined bounds across all series.
  DataBounds? getCombinedBounds() {
    DataBounds? combined;

    for (final pipeline in _pipelines) {
      final bounds = pipeline.getBounds();
      if (bounds == null) continue;

      if (combined == null) {
        combined = bounds;
      } else {
        combined = DataBounds(
          minX: bounds.minX < combined.minX ? bounds.minX : combined.minX,
          maxX: bounds.maxX > combined.maxX ? bounds.maxX : combined.maxX,
          minY: bounds.minY < combined.minY ? bounds.minY : combined.minY,
          maxY: bounds.maxY > combined.maxY ? bounds.maxY : combined.maxY,
        );
      }
    }

    return combined;
  }

  /// Invalidates cache for all series.
  void invalidateAll() {
    for (final pipeline in _pipelines) {
      pipeline.invalidateCache();
    }
  }
}
