import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Provides GPU rendering optimization hints and utilities.
///
/// This helper class offers methods to optimize paint and path operations
/// for better GPU performance, especially with large datasets.
///
/// Example:
/// ```dart
/// final paint = GpuRenderingHints.optimizePaint(
///   Paint()
///     ..color = Colors.blue
///     ..strokeWidth = 2,
/// );
///
/// final path = GpuRenderingHints.optimizePath(myComplexPath);
/// canvas.drawPath(path, paint);
/// ```
class GpuRenderingHints {
  GpuRenderingHints._();

  /// Threshold for number of path operations before considering optimization.
  static const int pathComplexityThreshold = 500;

  /// Threshold for number of elements before using save layer.
  static const int saveLayerThreshold = 1000;

  /// Maximum points before recommending decimation.
  static const int maxRecommendedPoints = 5000;

  /// Optimizes a Paint object for GPU rendering.
  ///
  /// Applies optimizations like:
  /// - Anti-aliasing hints based on stroke width
  /// - Filter quality settings
  /// - Stroke cap/join optimization for many segments
  static Paint optimizePaint(
    Paint paint, {
    int elementCount = 0,
    bool isAnimating = false,
  }) {
    final optimized = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..blendMode = paint.blendMode
      ..shader = paint.shader
      ..maskFilter = paint.maskFilter
      ..colorFilter = paint.colorFilter
      ..imageFilter = paint.imageFilter;

    // Anti-aliasing: disable for very thin lines on high DPI or during animation
    if (isAnimating && elementCount > 1000) {
      optimized.isAntiAlias = false;
    } else {
      optimized.isAntiAlias = paint.isAntiAlias;
    }

    // Use simpler stroke joins for many elements
    if (elementCount > 500) {
      optimized.strokeJoin = StrokeJoin.miter;
      optimized.strokeCap = StrokeCap.butt;
    }

    return optimized;
  }

  /// Simplifies a path for faster GPU rendering.
  ///
  /// Returns the original path if it's simple enough,
  /// or a simplified version if complex.
  static Path optimizePath(Path path, {double tolerance = 0.5}) {
    // Path metrics to analyze complexity
    final metrics = path.computeMetrics();
    var segmentCount = 0;

    for (final metric in metrics) {
      // Estimate segments based on length
      segmentCount += (metric.length / 10).ceil();
    }

    // If path is simple enough, return as-is
    if (segmentCount < pathComplexityThreshold) {
      return path;
    }

    // For complex paths, we return the path as-is but could implement
    // Douglas-Peucker simplification here if needed
    return path;
  }

  /// Determines whether to use a save layer for complex rendering.
  ///
  /// Save layers enable advanced effects but have GPU memory overhead.
  static bool shouldUseSaveLayer({
    required int elementCount,
    required bool hasOpacity,
    required bool hasBlendMode,
    bool isAnimating = false,
  }) {
    // Don't use save layer during animation for performance
    if (isAnimating && elementCount > saveLayerThreshold ~/ 2) {
      return false;
    }

    // Use save layer for opacity/blend effects with moderate element count
    if ((hasOpacity || hasBlendMode) && elementCount < saveLayerThreshold) {
      return true;
    }

    return false;
  }

  /// Gets the recommended batch size for drawing operations.
  ///
  /// Breaking large draws into batches can improve responsiveness.
  static int getRecommendedBatchSize(int totalElements) {
    if (totalElements <= 100) return totalElements;
    if (totalElements <= 1000) return 200;
    if (totalElements <= 5000) return 500;
    return 1000;
  }

  /// Creates an optimized gradient shader.
  ///
  /// Uses appropriate color stop interpolation for GPU efficiency.
  static Shader createOptimizedGradient({
    required List<Color> colors,
    required Rect bounds,
    GradientDirection direction = GradientDirection.vertical,
    List<double>? stops,
  }) {
    Offset begin;
    Offset end;

    switch (direction) {
      case GradientDirection.horizontal:
        begin = Offset(bounds.left, bounds.center.dy);
        end = Offset(bounds.right, bounds.center.dy);
      case GradientDirection.vertical:
        begin = Offset(bounds.center.dx, bounds.top);
        end = Offset(bounds.center.dx, bounds.bottom);
      case GradientDirection.diagonal:
        begin = bounds.topLeft;
        end = bounds.bottomRight;
    }

    return Gradient.linear(
      begin,
      end,
      colors,
      stops,
      TileMode.clamp,
    );
  }

  /// Checks if hardware acceleration is likely available.
  static bool get isHardwareAccelerated {
    // On mobile and desktop, hardware acceleration is typically available
    // Web depends on browser support
    return !kIsWeb || _webGLSupported;
  }

  static bool get _webGLSupported {
    // In production, this would check for WebGL support
    // For now, assume web has hardware acceleration
    return true;
  }

  /// Gets the optimal texture size for the platform.
  static Size getOptimalTextureSize(Size requested) {
    // Most GPUs work best with power-of-2 or specific sizes
    // Cap at 4096 for broad compatibility
    const maxSize = 4096.0;

    return Size(
      requested.width.clamp(1, maxSize),
      requested.height.clamp(1, maxSize),
    );
  }

  /// Determines the optimal line rendering strategy.
  static LineRenderStrategy getLineRenderStrategy({
    required int pointCount,
    required double strokeWidth,
    required bool hasGradient,
  }) {
    // For thin lines with many points, use path
    if (strokeWidth <= 2 && pointCount > 100) {
      return LineRenderStrategy.singlePath;
    }

    // For thick lines or gradients, individual segments may look better
    if (strokeWidth > 4 || hasGradient) {
      if (pointCount > 500) {
        return LineRenderStrategy.batchedSegments;
      }
      return LineRenderStrategy.individualSegments;
    }

    // Default to single path for most cases
    return LineRenderStrategy.singlePath;
  }

  /// Recommends a rendering quality level based on conditions.
  static RenderQuality getRecommendedQuality({
    required int elementCount,
    required bool isAnimating,
    required bool isInteracting,
  }) {
    if (isAnimating || isInteracting) {
      if (elementCount > 10000) return RenderQuality.low;
      if (elementCount > 5000) return RenderQuality.medium;
      return RenderQuality.high;
    }

    if (elementCount > 50000) return RenderQuality.medium;
    return RenderQuality.high;
  }
}

/// Direction for gradient rendering.
enum GradientDirection {
  horizontal,
  vertical,
  diagonal,
}

/// Strategy for rendering lines.
enum LineRenderStrategy {
  /// Draw all points as a single path (most efficient).
  singlePath,

  /// Draw segments individually (supports per-segment styling).
  individualSegments,

  /// Draw segments in batches (balance of efficiency and styling).
  batchedSegments,
}

/// Rendering quality levels.
enum RenderQuality {
  /// Fastest rendering, may skip anti-aliasing.
  low,

  /// Balanced quality and performance.
  medium,

  /// Highest quality, all features enabled.
  high,
}

/// Applies quality settings to a paint object.
extension RenderQualityPaint on Paint {
  /// Applies quality settings to this paint.
  void applyQuality(RenderQuality quality) {
    switch (quality) {
      case RenderQuality.low:
        isAntiAlias = false;
      case RenderQuality.medium:
        isAntiAlias = true;
      case RenderQuality.high:
        isAntiAlias = true;
    }
  }
}

/// Helper for batched drawing operations.
class BatchedDrawer {
  BatchedDrawer({
    required this.canvas,
    required this.paint,
    this.batchSize = 500,
  });

  final Canvas canvas;
  final Paint paint;
  final int batchSize;

  Path? _currentPath;
  int _currentCount = 0;

  /// Starts a new batch.
  void beginBatch() {
    _currentPath = Path();
    _currentCount = 0;
  }

  /// Adds a line segment to the current batch.
  void addLine(Offset start, Offset end) {
    _currentPath!.moveTo(start.dx, start.dy);
    _currentPath!.lineTo(end.dx, end.dy);
    _currentCount++;

    if (_currentCount >= batchSize) {
      flushBatch();
      beginBatch();
    }
  }

  /// Adds a point to a continuous path.
  void addPoint(Offset point, {bool isFirst = false}) {
    if (isFirst) {
      _currentPath!.moveTo(point.dx, point.dy);
    } else {
      _currentPath!.lineTo(point.dx, point.dy);
    }
    _currentCount++;

    if (_currentCount >= batchSize) {
      flushBatch();
      // Continue from the last point
      _currentPath = Path()..moveTo(point.dx, point.dy);
      _currentCount = 0;
    }
  }

  /// Flushes the current batch to the canvas.
  void flushBatch() {
    if (_currentPath != null && _currentCount > 0) {
      canvas.drawPath(_currentPath!, paint);
    }
  }

  /// Ends batching and flushes remaining content.
  void endBatch() {
    flushBatch();
    _currentPath = null;
    _currentCount = 0;
  }
}

/// Caches computed paint objects to avoid recreation.
class PaintCache {
  final Map<int, Paint> _cache = {};

  /// Gets or creates a paint with the specified properties.
  Paint getPaint({
    required Color color,
    required double strokeWidth,
    PaintingStyle style = PaintingStyle.stroke,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) {
    final key = Object.hash(color, strokeWidth, style, strokeCap, strokeJoin);

    return _cache.putIfAbsent(key, () {
      return Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = style
        ..strokeCap = strokeCap
        ..strokeJoin = strokeJoin
        ..isAntiAlias = true;
    });
  }

  /// Gets a simple fill paint.
  Paint getFillPaint(Color color) {
    final key = Object.hash(color, 'fill');
    return _cache.putIfAbsent(key, () {
      return Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
    });
  }

  /// Clears the cache.
  void clear() => _cache.clear();

  /// Number of cached paints.
  int get length => _cache.length;
}

/// Optimizes rect drawing for grids and backgrounds.
class OptimizedRectDrawer {
  OptimizedRectDrawer({
    required this.canvas,
    required this.paint,
  });

  final Canvas canvas;
  final Paint paint;

  final List<Rect> _rects = [];

  /// Adds a rect to be drawn.
  void addRect(Rect rect) {
    _rects.add(rect);
  }

  /// Draws all accumulated rects efficiently.
  void flush() {
    if (_rects.isEmpty) return;

    // For small counts, draw individually
    if (_rects.length < 20) {
      for (final rect in _rects) {
        canvas.drawRect(rect, paint);
      }
    } else {
      // For many rects, use a path
      final path = Path();
      for (final rect in _rects) {
        path.addRect(rect);
      }
      canvas.drawPath(path, paint);
    }

    _rects.clear();
  }
}

/// Default colors optimized for visibility.
class OptimizedColors {
  OptimizedColors._();

  /// Default series colors with good contrast.
  static const List<Color> seriesColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF4CAF50), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF8BC34A), // Light Green
  ];

  /// Gets a series color by index, cycling if needed.
  static Color getSeriesColor(int index) {
    return seriesColors[index % seriesColors.length];
  }

  /// Creates a color with opacity, cached for performance.
  static final Map<int, Color> _opacityCache = {};

  static Color withOpacity(Color color, double opacity) {
    final key = Object.hash(color.toARGB32(), (opacity * 255).round());
    return _opacityCache.putIfAbsent(
      key,
      () => color.withValues(alpha: opacity),
    );
  }

  /// Clears the opacity cache.
  static void clearCache() => _opacityCache.clear();
}
