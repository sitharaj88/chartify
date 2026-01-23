import 'dart:ui';

import '../../core/utils/cache_manager.dart';

/// Cached information about a path for efficient reuse.
class CachedPathInfo {
  CachedPathInfo({
    required this.path,
    required this.bounds,
    this.length,
    this.metrics,
  });

  /// The cached path.
  final Path path;

  /// The bounding rectangle of the path.
  final Rect bounds;

  /// The total length of the path (if computed).
  final double? length;

  /// Path metrics for animations (if computed).
  final PathMetrics? metrics;
}

/// Cache key for series paths.
class SeriesPathKey {
  SeriesPathKey({
    required this.seriesIndex,
    required this.width,
    required this.height,
    required this.dataHash,
    this.curveType,
    this.strokeWidth,
  });

  final int seriesIndex;
  final int width;
  final int height;
  final int dataHash;
  final String? curveType;
  final double? strokeWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesPathKey &&
          seriesIndex == other.seriesIndex &&
          width == other.width &&
          height == other.height &&
          dataHash == other.dataHash &&
          curveType == other.curveType &&
          strokeWidth == other.strokeWidth;

  @override
  int get hashCode => Object.hash(
        seriesIndex,
        width,
        height,
        dataHash,
        curveType,
        strokeWidth,
      );

  @override
  String toString() => 'SeriesPathKey($seriesIndex, ${width}x$height, $dataHash)';
}

/// Specialized cache for chart paths.
///
/// Caches computed paths along with their metrics for efficient
/// reuse across frames and for path-based animations.
class PathCache {
  PathCache({
    int maxSize = 100,
  }) : _cache = LRUCache<SeriesPathKey, CachedPathInfo>(
          maxSize: maxSize,
          onEvict: (_, info) {
            // Paths don't need explicit disposal in Dart
          },
        );

  final LRUCache<SeriesPathKey, CachedPathInfo> _cache;

  /// Gets a cached path or computes and caches it.
  CachedPathInfo getOrCompute(
    SeriesPathKey key,
    Path Function() computePath, {
    bool computeMetrics = false,
    bool computeLength = false,
  }) {
    var cached = _cache.get(key);
    if (cached != null) {
      // If we need metrics but don't have them, recompute
      if (computeMetrics && cached.metrics == null) {
        cached = _computeWithMetrics(cached.path, computeLength);
        _cache.put(key, cached);
      }
      return cached;
    }

    final path = computePath();
    final info = computeMetrics
        ? _computeWithMetrics(path, computeLength)
        : CachedPathInfo(
            path: path,
            bounds: path.getBounds(),
          );

    _cache.put(key, info);
    return info;
  }

  CachedPathInfo _computeWithMetrics(Path path, bool computeLength) {
    final metrics = path.computeMetrics();
    double? length;

    if (computeLength) {
      length = 0;
      for (final metric in metrics) {
        length = length! + metric.length;
      }
    }

    return CachedPathInfo(
      path: path,
      bounds: path.getBounds(),
      length: length,
      metrics: path.computeMetrics(),
    );
  }

  /// Gets a cached path if available.
  CachedPathInfo? get(SeriesPathKey key) => _cache.get(key);

  /// Invalidates a specific path.
  void invalidate(SeriesPathKey key) => _cache.remove(key);

  /// Invalidates all paths for a series.
  void invalidateSeries(int seriesIndex) {
    final keysToRemove = _cache.keys
        .where((k) => k.seriesIndex == seriesIndex)
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clears all cached paths.
  void clear() => _cache.clear();

  /// Number of cached paths.
  int get length => _cache.length;
}

/// Extracts a portion of a path for animation purposes.
///
/// Used to animate path drawing progressively.
class PathExtractor {
  PathExtractor(this.path) : _metrics = path.computeMetrics();

  final Path path;
  final PathMetrics _metrics;

  /// Gets the total length of the path.
  double get totalLength {
    var total = 0.0;
    for (final metric in path.computeMetrics()) {
      total += metric.length;
    }
    return total;
  }

  /// Extracts a portion of the path from 0 to the given fraction.
  ///
  /// [fraction] should be between 0.0 and 1.0.
  Path extractFraction(double fraction) {
    if (fraction <= 0) return Path();
    if (fraction >= 1) return path;

    final result = Path();
    final targetLength = totalLength * fraction;
    var accumulated = 0.0;

    for (final metric in _metrics) {
      if (accumulated >= targetLength) break;

      final remaining = targetLength - accumulated;
      if (remaining >= metric.length) {
        result.addPath(metric.extractPath(0, metric.length), Offset.zero);
        accumulated += metric.length;
      } else {
        result.addPath(metric.extractPath(0, remaining), Offset.zero);
        break;
      }
    }

    return result;
  }

  /// Extracts a segment of the path between two fractions.
  Path extractSegment(double startFraction, double endFraction) {
    if (startFraction >= endFraction) return Path();
    if (startFraction >= 1) return Path();
    if (endFraction <= 0) return Path();

    final result = Path();
    final total = totalLength;
    final startLength = total * startFraction.clamp(0, 1);
    final endLength = total * endFraction.clamp(0, 1);
    var accumulated = 0.0;

    for (final metric in _metrics) {
      final segmentEnd = accumulated + metric.length;

      if (segmentEnd <= startLength) {
        accumulated = segmentEnd;
        continue;
      }

      if (accumulated >= endLength) break;

      final localStart = (startLength - accumulated).clamp(0.0, metric.length);
      final localEnd = (endLength - accumulated).clamp(0.0, metric.length);

      if (localStart < localEnd) {
        result.addPath(
          metric.extractPath(localStart, localEnd),
          Offset.zero,
        );
      }

      accumulated = segmentEnd;
    }

    return result;
  }

  /// Gets a point along the path at the given fraction.
  Offset? pointAtFraction(double fraction) {
    final targetLength = totalLength * fraction.clamp(0, 1);
    var accumulated = 0.0;

    for (final metric in _metrics) {
      if (accumulated + metric.length >= targetLength) {
        final localT = targetLength - accumulated;
        final tangent = metric.getTangentForOffset(localT);
        return tangent?.position;
      }
      accumulated += metric.length;
    }

    return null;
  }

  /// Gets the tangent vector at a point along the path.
  Tangent? tangentAtFraction(double fraction) {
    final targetLength = totalLength * fraction.clamp(0, 1);
    var accumulated = 0.0;

    for (final metric in _metrics) {
      if (accumulated + metric.length >= targetLength) {
        final localT = targetLength - accumulated;
        return metric.getTangentForOffset(localT);
      }
      accumulated += metric.length;
    }

    return null;
  }
}

/// Global path cache instance.
class ChartPathCache {
  ChartPathCache._();

  static final instance = ChartPathCache._();

  /// Cache for line/area series paths.
  final seriesPaths = PathCache(maxSize: 100);

  /// Cache for axis paths.
  final axisPaths = PathCache(maxSize: 20);

  /// Cache for grid paths.
  final gridPaths = PathCache(maxSize: 10);

  /// Cache for marker paths.
  final markerPaths = PathCache(maxSize: 50);

  /// Clears all path caches.
  void clearAll() {
    seriesPaths.clear();
    axisPaths.clear();
    gridPaths.clear();
    markerPaths.clear();
  }
}
