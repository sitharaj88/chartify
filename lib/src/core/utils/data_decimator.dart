import 'dart:math' as math;

import '../data/data_point.dart';
import '../math/geometry/bounds_calculator.dart';

/// Utilities for reducing data point count while preserving visual appearance.
///
/// Provides algorithms for:
/// - Line simplification (Douglas-Peucker)
/// - Viewport-aware culling
/// - Temporal decimation for streaming data
/// - Min/max preservation for accurate peaks
///
/// Example:
/// ```dart
/// // Simplify a line with 10,000 points
/// final simplified = DataDecimator.simplify(
///   points,
///   tolerance: 2.0, // pixels
/// );
///
/// // Cull to visible viewport
/// final visible = DataDecimator.cullToViewport(
///   points,
///   visibleBounds: Bounds(min: 0, max: 100),
///   margin: 0.1, // 10% margin
/// );
/// ```
class DataDecimator {
  DataDecimator._();

  /// Simplifies a list of data points using Douglas-Peucker algorithm.
  ///
  /// Preserves the overall shape while reducing point count.
  /// [tolerance] is the maximum perpendicular distance (in data units)
  /// that a point can deviate from the simplified line.
  ///
  /// Time complexity: O(n log n) average, O(n²) worst case.
  static List<DataPoint<X, Y>> simplify<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points, {
    required double tolerance,
  }) {
    if (points.length <= 2) return List.from(points);
    if (tolerance <= 0) return List.from(points);

    final result = <DataPoint<X, Y>>[];
    final stack = <(int, int)>[];

    // Start with first and last points
    result.add(points.first);
    stack.add((0, points.length - 1));

    final included = List.filled(points.length, false);
    included[0] = true;
    included[points.length - 1] = true;

    while (stack.isNotEmpty) {
      final (start, end) = stack.removeLast();

      // Find point with maximum distance from line segment
      var maxDistance = 0.0;
      var maxIndex = start;

      for (var i = start + 1; i < end; i++) {
        final distance = _perpendicularDistance(
          points[i],
          points[start],
          points[end],
        );
        if (distance > maxDistance) {
          maxDistance = distance;
          maxIndex = i;
        }
      }

      // If max distance > tolerance, keep the point and recurse
      if (maxDistance > tolerance) {
        included[maxIndex] = true;
        stack.add((start, maxIndex));
        stack.add((maxIndex, end));
      }
    }

    // Build result maintaining original order
    for (var i = 0; i < points.length; i++) {
      if (included[i]) {
        result.add(points[i]);
      }
    }

    // Ensure last point is included (may be duplicate, dedupe)
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result.toSet().toList(); // Remove duplicates while preserving order
  }

  /// Calculates perpendicular distance from point to line segment.
  static double _perpendicularDistance<X extends num, Y extends num>(
    DataPoint<X, Y> point,
    DataPoint<X, Y> lineStart,
    DataPoint<X, Y> lineEnd,
  ) {
    final px = point.x.toDouble();
    final py = point.y.toDouble();
    final x1 = lineStart.x.toDouble();
    final y1 = lineStart.y.toDouble();
    final x2 = lineEnd.x.toDouble();
    final y2 = lineEnd.y.toDouble();

    final dx = x2 - x1;
    final dy = y2 - y1;

    // Line segment length squared
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) {
      // Line segment is a point
      return math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1));
    }

    // Perpendicular distance using cross product
    final area = ((py - y1) * dx - (px - x1) * dy).abs();
    return area / math.sqrt(lengthSq);
  }

  /// Culls data points to those within a viewport with optional margin.
  ///
  /// [visibleBounds] defines the visible x-range.
  /// [margin] adds extra percentage on each side (0.1 = 10%).
  ///
  /// This is faster than rendering all points for zoomed views.
  static List<DataPoint<X, Y>> cullToViewport<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points, {
    required Bounds visibleBounds,
    double margin = 0.1,
  }) {
    if (points.isEmpty) return [];

    final range = visibleBounds.max - visibleBounds.min;
    final marginAmount = range * margin;
    final minX = visibleBounds.min - marginAmount;
    final maxX = visibleBounds.max + marginAmount;

    // Binary search for start index (assuming sorted by x)
    var startIdx = _binarySearchLeft(points, minX);
    var endIdx = _binarySearchRight(points, maxX);

    // Include one point before and after for proper line connection
    if (startIdx > 0) startIdx--;
    if (endIdx < points.length - 1) endIdx++;

    return points.sublist(startIdx, endIdx + 1);
  }

  /// Binary search for leftmost point >= value.
  static int _binarySearchLeft<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points,
    double value,
  ) {
    var low = 0;
    var high = points.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (points[mid].x.toDouble() < value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low.clamp(0, points.length - 1);
  }

  /// Binary search for rightmost point <= value.
  static int _binarySearchRight<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points,
    double value,
  ) {
    var low = 0;
    var high = points.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (points[mid].x.toDouble() <= value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return (low - 1).clamp(0, points.length - 1);
  }

  /// Decimates points to a maximum count while preserving min/max peaks.
  ///
  /// Useful for displaying large streaming datasets.
  /// Divides data into buckets and keeps first, last, min, and max of each bucket.
  ///
  /// [maxPoints] is the target number of output points.
  static List<DataPoint<X, Y>> temporalDecimate<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points, {
    required int maxPoints,
  }) {
    if (points.length <= maxPoints) return List.from(points);
    if (maxPoints < 4) return [points.first, points.last];

    final result = <DataPoint<X, Y>>[];

    // Always include first point
    result.add(points.first);

    // Calculate bucket size
    // Reserve 2 for first/last, remaining for buckets (4 points each: first, min, max, last)
    final bucketsNeeded = (maxPoints - 2) ~/ 4;
    final bucketSize = (points.length - 2) / bucketsNeeded;

    for (var i = 0; i < bucketsNeeded; i++) {
      final bucketStart = 1 + (i * bucketSize).round();
      final bucketEnd = 1 + ((i + 1) * bucketSize).round();

      if (bucketStart >= bucketEnd || bucketStart >= points.length - 1) continue;

      final endClamp = bucketEnd.clamp(bucketStart + 1, points.length - 1);

      // Find min/max in bucket
      var minPoint = points[bucketStart];
      var maxPoint = points[bucketStart];
      var minIdx = bucketStart;
      var maxIdx = bucketStart;

      for (var j = bucketStart; j < endClamp; j++) {
        if (points[j].y.toDouble() < minPoint.y.toDouble()) {
          minPoint = points[j];
          minIdx = j;
        }
        if (points[j].y.toDouble() > maxPoint.y.toDouble()) {
          maxPoint = points[j];
          maxIdx = j;
        }
      }

      // Add points in order: first, then min/max in x-order, then last
      result.add(points[bucketStart]);

      if (minIdx != bucketStart && maxIdx != bucketStart) {
        // Add min and max in correct x-order
        if (minIdx < maxIdx) {
          result.add(minPoint);
          result.add(maxPoint);
        } else if (maxIdx < minIdx) {
          result.add(maxPoint);
          result.add(minPoint);
        } else {
          // min and max are the same point
          result.add(minPoint);
        }
      } else if (minIdx != bucketStart) {
        result.add(minPoint);
      } else if (maxIdx != bucketStart) {
        result.add(maxPoint);
      }

      // Add last point of bucket if different
      if (endClamp - 1 != bucketStart &&
          endClamp - 1 != minIdx &&
          endClamp - 1 != maxIdx) {
        result.add(points[endClamp - 1]);
      }
    }

    // Always include last point
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result;
  }

  /// Downsamples by keeping every nth point.
  ///
  /// Simplest decimation method. Use [temporalDecimate] for better peak preservation.
  static List<DataPoint<X, Y>> everyNth<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points, {
    required int n,
  }) {
    if (n <= 1) return List.from(points);
    if (points.isEmpty) return [];

    final result = <DataPoint<X, Y>>[];

    for (var i = 0; i < points.length; i += n) {
      result.add(points[i]);
    }

    // Ensure last point is included
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result;
  }

  /// Calculates optimal simplification tolerance for a target point count.
  ///
  /// Binary searches for the tolerance that produces approximately [targetCount] points.
  static double calculateTolerance<X extends num, Y extends num>(
    List<DataPoint<X, Y>> points, {
    required int targetCount,
    double minTolerance = 0.01,
    double maxTolerance = 1000.0,
    int maxIterations = 20,
  }) {
    if (points.length <= targetCount) return 0;

    var low = minTolerance;
    var high = maxTolerance;

    for (var i = 0; i < maxIterations; i++) {
      final mid = (low + high) / 2;
      final simplified = simplify(points, tolerance: mid);

      if (simplified.length == targetCount) {
        return mid;
      } else if (simplified.length > targetCount) {
        low = mid;
      } else {
        high = mid;
      }

      // Close enough
      if ((simplified.length - targetCount).abs() <= targetCount * 0.1) {
        return mid;
      }
    }

    return (low + high) / 2;
  }
}

/// Extension methods for data point lists.
extension DataDecimatorExtension<X extends num, Y extends num>
    on List<DataPoint<X, Y>> {
  /// Simplifies this list using Douglas-Peucker algorithm.
  List<DataPoint<X, Y>> simplify({required double tolerance}) =>
      DataDecimator.simplify(this, tolerance: tolerance);

  /// Culls to visible viewport range.
  List<DataPoint<X, Y>> cullToViewport({
    required Bounds visibleBounds,
    double margin = 0.1,
  }) =>
      DataDecimator.cullToViewport(
        this,
        visibleBounds: visibleBounds,
        margin: margin,
      );

  /// Decimates to maximum point count while preserving peaks.
  List<DataPoint<X, Y>> decimate({required int maxPoints}) =>
      DataDecimator.temporalDecimate(this, maxPoints: maxPoints);
}
