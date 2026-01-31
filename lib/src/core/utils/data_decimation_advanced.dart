import '../base/chart_controller.dart';
import '../data/data_point.dart';

/// Decimation algorithms for enterprise-level large dataset support.
///
/// Provides efficient algorithms for reducing data point count while
/// preserving visual fidelity:
/// - LTTB (Largest Triangle Three Buckets) - Best for time series
/// - Min-Max - Preserves peaks and valleys per bucket
/// - Adaptive - Automatically adjusts based on viewport zoom
///
/// Example:
/// ```dart
/// // Decimate 100,000 points to 2,000 using LTTB
/// final decimated = AdvancedDecimator.lttb(
///   largeDataset,
///   targetPoints: 2000,
/// );
///
/// // Adaptive decimation based on viewport
/// final visible = AdvancedDecimator.adaptive(
///   data,
///   viewport: controller.viewport,
///   maxVisiblePoints: 2000,
/// );
/// ```
class AdvancedDecimator {
  AdvancedDecimator._();

  /// Decimates data using LTTB (Largest Triangle Three Buckets) algorithm.
  ///
  /// LTTB is particularly effective for time series data as it preserves
  /// the visual characteristics of the data better than simple sampling.
  ///
  /// The algorithm:
  /// 1. Always keeps the first and last points
  /// 2. Divides remaining data into equal-sized buckets
  /// 3. For each bucket, selects the point that forms the largest triangle
  ///    with the selected point from the previous bucket and the average
  ///    of the next bucket
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(n)
  ///
  /// Reference: Steinarsson, S. (2013). "Downsampling Time Series for
  /// Visual Representation"
  static List<DataPoint<X, Y>> lttb<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required int targetPoints,
  }) {
    final length = data.length;

    // If we have fewer points than target, return a copy
    if (length <= targetPoints) {
      return List.from(data);
    }

    // Need at least 3 points for LTTB
    if (targetPoints < 3) {
      if (targetPoints == 2) {
        return [data.first, data.last];
      } else if (targetPoints == 1) {
        return [data.first];
      }
      return [];
    }

    final result = <DataPoint<X, Y>>[];
    result.add(data.first); // Always keep first point

    // Calculate bucket size (excluding first and last points)
    final bucketSize = (length - 2) / (targetPoints - 2);

    var previousPointIndex = 0;

    for (var bucketIndex = 0; bucketIndex < targetPoints - 2; bucketIndex++) {
      // Current bucket boundaries
      final currentBucketStart = ((bucketIndex * bucketSize) + 1).floor();
      final currentBucketEnd =
          (((bucketIndex + 1) * bucketSize) + 1).floor().clamp(0, length - 1);

      // Next bucket boundaries (for calculating average)
      final nextBucketStart = currentBucketEnd;
      final nextBucketEnd =
          (((bucketIndex + 2) * bucketSize) + 1).floor().clamp(0, length);

      // Calculate average point of next bucket
      double avgX = 0;
      double avgY = 0;
      var avgCount = 0;

      for (var i = nextBucketStart;
          i < nextBucketEnd && i < length;
          i++) {
        avgX += data[i].x.toDouble();
        avgY += data[i].y.toDouble();
        avgCount++;
      }

      if (avgCount > 0) {
        avgX /= avgCount;
        avgY /= avgCount;
      } else {
        // Fallback to last point if no points in next bucket
        avgX = data.last.x.toDouble();
        avgY = data.last.y.toDouble();
      }

      // Find point in current bucket that maximizes triangle area
      var maxArea = -1.0;
      var selectedIndex = currentBucketStart;

      final prevX = data[previousPointIndex].x.toDouble();
      final prevY = data[previousPointIndex].y.toDouble();

      for (var i = currentBucketStart; i < currentBucketEnd && i < length; i++) {
        final currX = data[i].x.toDouble();
        final currY = data[i].y.toDouble();

        // Calculate triangle area using cross product
        final area = ((prevX - avgX) * (currY - prevY) -
                (prevX - currX) * (avgY - prevY))
            .abs();

        if (area > maxArea) {
          maxArea = area;
          selectedIndex = i;
        }
      }

      result.add(data[selectedIndex]);
      previousPointIndex = selectedIndex;
    }

    result.add(data.last); // Always keep last point

    return result;
  }

  /// Decimates data using Min-Max bucket sampling.
  ///
  /// For each bucket, preserves both minimum and maximum Y values,
  /// ensuring peaks and valleys are never lost. This is ideal for
  /// financial data where extremes are critical.
  ///
  /// Each bucket contributes up to 4 points: first, min, max, last
  /// (in temporal order, with duplicates removed).
  ///
  /// Time complexity: O(n)
  /// Space complexity: O(targetPoints)
  static List<DataPoint<X, Y>> minMax<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required int bucketCount,
  }) {
    if (data.isEmpty) return [];
    if (data.length <= bucketCount * 2) return List.from(data);
    if (bucketCount < 1) return [data.first, data.last];

    final result = <DataPoint<X, Y>>[];
    final bucketSize = data.length / bucketCount;

    for (var i = 0; i < bucketCount; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor().clamp(0, data.length);

      if (start >= end) continue;

      // Find min and max in bucket
      var minIdx = start;
      var maxIdx = start;
      var minY = data[start].y.toDouble();
      var maxY = data[start].y.toDouble();

      for (var j = start + 1; j < end; j++) {
        final y = data[j].y.toDouble();
        if (y < minY) {
          minY = y;
          minIdx = j;
        }
        if (y > maxY) {
          maxY = y;
          maxIdx = j;
        }
      }

      // Add points in temporal order
      final indices = <int>{start};

      if (minIdx != maxIdx) {
        if (minIdx < maxIdx) {
          indices.add(minIdx);
          indices.add(maxIdx);
        } else {
          indices.add(maxIdx);
          indices.add(minIdx);
        }
      } else {
        indices.add(minIdx);
      }

      indices.add(end - 1);

      // Add unique points in order
      final sortedIndices = indices.toList()..sort();
      for (final idx in sortedIndices) {
        if (result.isEmpty || result.last != data[idx]) {
          result.add(data[idx]);
        }
      }
    }

    return result;
  }

  /// Adaptive decimation based on viewport zoom level.
  ///
  /// Combines viewport culling with intelligent decimation:
  /// 1. First culls data to visible range + margin
  /// 2. Then applies LTTB if remaining points exceed threshold
  ///
  /// This provides optimal performance at any zoom level.
  ///
  /// Time complexity: O(n) for initial cull + O(visible) for decimation
  static List<DataPoint<X, Y>> adaptive<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required ChartViewport viewport,
    int maxVisiblePoints = 2000,
    double marginFactor = 0.1,
  }) {
    if (data.isEmpty) return [];
    if (data.length <= maxVisiblePoints) return List.from(data);

    // Calculate visible x-range
    final rangeMinX = viewport.xMin ?? data.first.x.toDouble();
    final rangeMaxX = viewport.xMax ?? data.last.x.toDouble();
    final visibleRange = rangeMaxX - rangeMinX;
    final margin = visibleRange * marginFactor;

    // Cull to visible range with margin
    final culled = _cullToRange(
      data,
      minX: rangeMinX - margin,
      maxX: rangeMaxX + margin,
    );

    // If culled data fits, return it
    if (culled.length <= maxVisiblePoints) {
      return culled;
    }

    // Apply LTTB decimation to culled data
    return lttb(culled, targetPoints: maxVisiblePoints);
  }

  /// Viewport-based decimation with pixel-aware target point calculation.
  ///
  /// Calculates optimal point count based on available pixels,
  /// ensuring no more than [pointsPerPixel] data points per horizontal pixel.
  static List<DataPoint<X, Y>> forPixelDensity<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required double chartWidth,
    required ChartViewport viewport,
    double pointsPerPixel = 2.0,
  }) {
    if (data.isEmpty) return [];

    // Calculate target points based on available pixels
    final targetPoints = (chartWidth * pointsPerPixel).round();

    return adaptive(
      data,
      viewport: viewport,
      maxVisiblePoints: targetPoints.clamp(100, 10000),
    );
  }

  /// Mode-based decimation with automatic algorithm selection.
  ///
  /// Selects the best algorithm based on data characteristics:
  /// - Small datasets: No decimation
  /// - Time series: LTTB
  /// - Financial data: Min-Max
  /// - General: Adaptive
  static List<DataPoint<X, Y>> auto<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required int targetPoints,
    DecimationMode mode = DecimationMode.adaptive,
    ChartViewport? viewport,
  }) {
    if (data.length <= targetPoints) return List.from(data);

    switch (mode) {
      case DecimationMode.none:
        return List.from(data);

      case DecimationMode.lttb:
        return lttb(data, targetPoints: targetPoints);

      case DecimationMode.minMax:
        return minMax(data, bucketCount: targetPoints ~/ 2);

      case DecimationMode.adaptive:
        return adaptive(
          data,
          viewport: viewport ?? const ChartViewport(),
          maxVisiblePoints: targetPoints,
        );
    }
  }

  /// Culls data to a specific X range using binary search.
  static List<DataPoint<X, Y>> _cullToRange<X extends num, Y extends num>(
    List<DataPoint<X, Y>> data, {
    required double minX,
    required double maxX,
  }) {
    if (data.isEmpty) return [];

    // Binary search for start index
    var start = 0;
    var end = data.length;

    // Find first point >= minX
    var low = 0;
    var high = data.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (data[mid].x.toDouble() < minX) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    start = (low - 1).clamp(0, data.length - 1);

    // Find last point <= maxX
    low = 0;
    high = data.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (data[mid].x.toDouble() <= maxX) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    end = low.clamp(0, data.length);

    if (start >= end) return [];
    return data.sublist(start, end);
  }
}

/// Decimation mode for automatic algorithm selection.
enum DecimationMode {
  /// No decimation - use all points
  none,

  /// LTTB algorithm - best for time series
  lttb,

  /// Min-Max algorithm - preserves peaks/valleys
  minMax,

  /// Adaptive - combines viewport culling with LTTB
  adaptive,
}

/// Configuration for automatic decimation.
class DecimationConfig {
  const DecimationConfig({
    this.mode = DecimationMode.adaptive,
    this.maxVisiblePoints = 2000,
    this.threshold = 5000,
    this.marginFactor = 0.1,
  });

  /// Decimation algorithm to use.
  final DecimationMode mode;

  /// Maximum points to display after decimation.
  final int maxVisiblePoints;

  /// Minimum point count before decimation is applied.
  final int threshold;

  /// Extra margin when culling to viewport (as fraction of visible range).
  final double marginFactor;

  /// Default configuration for most use cases.
  static const standard = DecimationConfig();

  /// Configuration optimized for financial charts.
  static const financial = DecimationConfig(
    mode: DecimationMode.minMax,
    maxVisiblePoints: 3000,
  );

  /// Configuration optimized for streaming data.
  static const streaming = DecimationConfig(
    mode: DecimationMode.lttb,
    maxVisiblePoints: 1000,
    threshold: 2000,
  );

  /// No decimation - for small datasets.
  static const disabled = DecimationConfig(
    mode: DecimationMode.none,
    threshold: 9007199254740991, // Max safe integer
  );

  /// Creates a copy with updated values.
  DecimationConfig copyWith({
    DecimationMode? mode,
    int? maxVisiblePoints,
    int? threshold,
    double? marginFactor,
  }) {
    return DecimationConfig(
      mode: mode ?? this.mode,
      maxVisiblePoints: maxVisiblePoints ?? this.maxVisiblePoints,
      threshold: threshold ?? this.threshold,
      marginFactor: marginFactor ?? this.marginFactor,
    );
  }
}

/// Extension methods for easy decimation of data point lists.
extension AdvancedDecimatorExtension<X extends num, Y extends num>
    on List<DataPoint<X, Y>> {
  /// Decimates using LTTB algorithm.
  List<DataPoint<X, Y>> lttb({required int targetPoints}) =>
      AdvancedDecimator.lttb(this, targetPoints: targetPoints);

  /// Decimates using Min-Max algorithm.
  List<DataPoint<X, Y>> minMax({required int bucketCount}) =>
      AdvancedDecimator.minMax(this, bucketCount: bucketCount);

  /// Decimates adaptively based on viewport.
  List<DataPoint<X, Y>> adaptive({
    required ChartViewport viewport,
    int maxVisiblePoints = 2000,
  }) =>
      AdvancedDecimator.adaptive(
        this,
        viewport: viewport,
        maxVisiblePoints: maxVisiblePoints,
      );

  /// Decimates based on pixel density.
  List<DataPoint<X, Y>> forPixelDensity({
    required double chartWidth,
    required ChartViewport viewport,
    double pointsPerPixel = 2.0,
  }) =>
      AdvancedDecimator.forPixelDensity(
        this,
        chartWidth: chartWidth,
        viewport: viewport,
        pointsPerPixel: pointsPerPixel,
      );
}
