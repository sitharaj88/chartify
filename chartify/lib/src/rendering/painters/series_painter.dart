import 'package:flutter/painting.dart';

import '../../core/gestures/spatial_index.dart';
import '../../core/math/geometry/bounds_calculator.dart';
import '../../core/math/geometry/coordinate_transform.dart';
import '../renderers/renderer.dart';

/// Base configuration for series rendering.
abstract class SeriesConfig {
  const SeriesConfig({
    this.visible = true,
    this.animationProgress = 1.0,
  });

  /// Whether this series is visible.
  final bool visible;

  /// Animation progress (0.0 to 1.0).
  final double animationProgress;
}

/// Information about a data point for hit testing and tooltips.
class DataPointInfo {
  const DataPointInfo({
    required this.seriesIndex,
    required this.dataIndex,
    required this.screenPosition,
    required this.dataX,
    required this.dataY,
    this.label,
    this.value,
    this.color,
    this.metadata,
  });

  /// Index of the series this point belongs to.
  final int seriesIndex;

  /// Index of the data point within the series.
  final int dataIndex;

  /// Screen position of the data point.
  final Offset screenPosition;

  /// X value in data space.
  final dynamic dataX;

  /// Y value in data space.
  final double dataY;

  /// Optional label for this point.
  final String? label;

  /// Optional formatted value.
  final String? value;

  /// Color of this data point.
  final Color? color;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;
}

/// Abstract base class for series painters.
///
/// Series painters are responsible for rendering data series
/// (lines, bars, areas, etc.) with efficient caching and hit testing.
abstract class SeriesPainter<T extends SeriesConfig> {
  SeriesPainter({
    required T config,
    required this.seriesIndex,
  }) : _config = config;

  T _config;
  final int seriesIndex;

  // Spatial index for hit testing
  ChartSpatialIndex? _spatialIndex;

  /// Current configuration.
  T get config => _config;

  /// Updates the configuration.
  void updateConfig(T newConfig) {
    _config = newConfig;
    invalidateCache();
  }

  /// Renders the series to the canvas.
  ///
  /// [canvas] - The canvas to draw on.
  /// [chartArea] - The area designated for data rendering.
  /// [transform] - Coordinate transform for data-to-screen mapping.
  void render(
    Canvas canvas,
    Rect chartArea,
    CoordinateTransform transform,
  );

  /// Performs hit testing at the given screen point.
  DataPointInfo? hitTest(Offset point) {
    if (_spatialIndex == null) return null;
    final result = _spatialIndex!.findNearest(point);
    if (result == null) return null;
    return result.item as DataPointInfo?;
  }

  /// Builds the spatial index for hit testing.
  void buildSpatialIndex(Rect chartArea) {
    _spatialIndex = ChartSpatialIndex(bounds: chartArea);
  }

  /// Registers a data point for hit testing.
  void registerHitRegion(DataPointInfo info, Rect bounds) {
    _spatialIndex?.registerDataPoint(
      item: info,
      bounds: bounds,
      dataIndex: info.dataIndex,
      seriesIndex: info.seriesIndex,
    );
  }

  /// Invalidates cached computations.
  void invalidateCache();

  /// Calculates bounds for the data.
  (Bounds, Bounds) calculateBounds();

  /// Releases resources.
  void dispose() {
    _spatialIndex?.clear();
  }
}

/// Mixin for series that support interpolated curves.
mixin CurvedSeriesMixin<T extends SeriesConfig> on SeriesPainter<T> {
  /// Gets screen positions for data points.
  List<Offset> getScreenPositions(
    List<({double x, double y})> data,
    CoordinateTransform transform,
  ) {
    return data.map((p) => transform.dataToScreen(p.x, p.y)).toList();
  }
}

/// Mixin for series that support area fills.
mixin AreaFillMixin<T extends SeriesConfig> on SeriesPainter<T> {
  /// Creates a filled area path from line points.
  Path createAreaPath(
    List<Offset> points,
    double baseline,
    Path linePath,
  ) {
    if (points.isEmpty) return Path();

    final areaPath = Path()..addPath(linePath, Offset.zero);

    // Close the area to the baseline
    areaPath.lineTo(points.last.dx, baseline);
    areaPath.lineTo(points.first.dx, baseline);
    areaPath.close();

    return areaPath;
  }
}

/// Mixin for series that support gradient fills.
mixin GradientMixin {
  /// Creates a vertical gradient shader.
  Shader createVerticalGradient(
    Rect bounds,
    List<Color> colors, {
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(bounds);
  }

  /// Creates a horizontal gradient shader.
  Shader createHorizontalGradient(
    Rect bounds,
    List<Color> colors, {
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
      stops: stops,
    ).createShader(bounds);
  }
}

/// Mixin for animated series.
mixin AnimatedSeriesMixin<T extends SeriesConfig> on SeriesPainter<T> {
  /// Interpolates between old and new values.
  double lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  /// Interpolates positions.
  Offset lerpOffset(Offset start, Offset end, double progress) {
    return Offset(
      lerp(start.dx, end.dx, progress),
      lerp(start.dy, end.dy, progress),
    );
  }

  /// Interpolates colors.
  Color lerpColor(Color start, Color end, double progress) {
    return Color.lerp(start, end, progress) ?? end;
  }
}

/// Manager for multiple series painters.
class SeriesPainterManager {
  SeriesPainterManager();

  final List<SeriesPainter<SeriesConfig>> _painters = [];

  /// Adds a painter.
  void add(SeriesPainter<SeriesConfig> painter) {
    _painters.add(painter);
  }

  /// Removes a painter.
  void remove(SeriesPainter<SeriesConfig> painter) {
    _painters.remove(painter);
    painter.dispose();
  }

  /// Gets a painter by index.
  SeriesPainter<SeriesConfig>? getAt(int index) {
    if (index < 0 || index >= _painters.length) return null;
    return _painters[index];
  }

  /// Renders all series.
  void renderAll(
    Canvas canvas,
    Rect chartArea,
    CoordinateTransform transform,
  ) {
    for (final painter in _painters) {
      if (painter.config.visible) {
        painter.render(canvas, chartArea, transform);
      }
    }
  }

  /// Performs hit testing across all series.
  DataPointInfo? hitTest(Offset point) {
    // Test in reverse order (topmost first)
    for (var i = _painters.length - 1; i >= 0; i--) {
      final result = _painters[i].hitTest(point);
      if (result != null) return result;
    }
    return null;
  }

  /// Calculates combined bounds for all series.
  (Bounds, Bounds) calculateCombinedBounds() {
    if (_painters.isEmpty) {
      return (const Bounds(min: 0, max: 1), const Bounds(min: 0, max: 1));
    }

    final allBounds = _painters.map((p) => p.calculateBounds()).toList();
    final xBounds = Bounds.union(allBounds.map((b) => b.$1));
    final yBounds = Bounds.union(allBounds.map((b) => b.$2));

    return (xBounds, yBounds);
  }

  /// Invalidates all caches.
  void invalidateAll() {
    for (final painter in _painters) {
      painter.invalidateCache();
    }
  }

  /// Disposes all painters.
  void dispose() {
    for (final painter in _painters) {
      painter.dispose();
    }
    _painters.clear();
  }

  /// Number of painters.
  int get length => _painters.length;

  /// Whether there are any painters.
  bool get isEmpty => _painters.isEmpty;

  /// Whether there are painters.
  bool get isNotEmpty => _painters.isNotEmpty;
}
