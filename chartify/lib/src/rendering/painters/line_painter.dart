import 'package:flutter/painting.dart';

import '../../core/math/geometry/bounds_calculator.dart';
import '../../core/math/geometry/coordinate_transform.dart';
import '../../core/math/interpolation/interpolator.dart';
import '../cache/path_cache.dart';
import '../renderers/marker_renderer.dart';
import 'series_painter.dart';

/// Types of line curves.
enum LineCurveType {
  /// Straight line segments.
  linear,

  /// Smooth monotone curve (no overshoot).
  monotone,

  /// Catmull-Rom spline.
  catmullRom,

  /// Cardinal spline.
  cardinal,

  /// Step function (after).
  stepAfter,

  /// Step function (before).
  stepBefore,

  /// Step function (middle).
  stepMiddle,
}

/// Configuration for line series rendering.
class LineSeriesConfig extends SeriesConfig {
  const LineSeriesConfig({
    super.visible = true,
    super.animationProgress = 1.0,
    this.color = const Color(0xFF2196F3),
    this.strokeWidth = 2.0,
    this.curveType = LineCurveType.linear,
    this.dashPattern,
    this.showMarkers = false,
    this.markerConfig,
    this.showArea = false,
    this.areaColor,
    this.areaGradient,
    this.tension = 0.5,
  });

  /// Line color.
  final Color color;

  /// Line stroke width.
  final double strokeWidth;

  /// Type of curve interpolation.
  final LineCurveType curveType;

  /// Dash pattern (null for solid line).
  final List<double>? dashPattern;

  /// Whether to show markers at data points.
  final bool showMarkers;

  /// Configuration for markers.
  final MarkerConfig? markerConfig;

  /// Whether to show filled area under the line.
  final bool showArea;

  /// Color for the area fill.
  final Color? areaColor;

  /// Gradient for the area fill.
  final List<Color>? areaGradient;

  /// Tension for spline curves (0.0 to 1.0).
  final double tension;

  /// Creates a copy with updated values.
  LineSeriesConfig copyWith({
    bool? visible,
    double? animationProgress,
    Color? color,
    double? strokeWidth,
    LineCurveType? curveType,
    List<double>? dashPattern,
    bool? showMarkers,
    MarkerConfig? markerConfig,
    bool? showArea,
    Color? areaColor,
    List<Color>? areaGradient,
    double? tension,
  }) {
    return LineSeriesConfig(
      visible: visible ?? this.visible,
      animationProgress: animationProgress ?? this.animationProgress,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      curveType: curveType ?? this.curveType,
      dashPattern: dashPattern ?? this.dashPattern,
      showMarkers: showMarkers ?? this.showMarkers,
      markerConfig: markerConfig ?? this.markerConfig,
      showArea: showArea ?? this.showArea,
      areaColor: areaColor ?? this.areaColor,
      areaGradient: areaGradient ?? this.areaGradient,
      tension: tension ?? this.tension,
    );
  }
}

/// Painter for line series.
///
/// Renders line charts with support for multiple curve types,
/// markers, and area fills.
class LinePainter extends SeriesPainter<LineSeriesConfig>
    with CurvedSeriesMixin, AreaFillMixin, GradientMixin, AnimatedSeriesMixin {
  LinePainter({
    required super.config,
    required super.seriesIndex,
    required this.data,
    this.labels,
  });

  /// Data points for this series.
  List<({double x, double y})> data;

  /// Optional labels for each data point.
  List<String>? labels;

  // Cached computations
  Path? _cachedLinePath;
  Path? _cachedAreaPath;
  List<Offset>? _cachedScreenPositions;
  int? _cachedDataHash;

  final MarkerRenderer _markerRenderer = MarkerRenderer(
    config: const MarkerConfig(),
  );

  /// Updates the data.
  void updateData(List<({double x, double y})> newData, {List<String>? newLabels}) {
    data = newData;
    labels = newLabels;
    invalidateCache();
  }

  @override
  void invalidateCache() {
    _cachedLinePath = null;
    _cachedAreaPath = null;
    _cachedScreenPositions = null;
    _cachedDataHash = null;
  }

  int _computeDataHash() {
    var hash = 0;
    for (final point in data) {
      hash = hash ^ point.x.hashCode ^ point.y.hashCode;
    }
    return hash;
  }

  @override
  void render(
    Canvas canvas,
    Rect chartArea,
    CoordinateTransform transform,
  ) {
    if (!config.visible || data.isEmpty) return;

    // Compute screen positions
    final currentHash = _computeDataHash();
    if (_cachedDataHash != currentHash || _cachedScreenPositions == null) {
      _cachedScreenPositions = getScreenPositions(data, transform);
      _cachedDataHash = currentHash;
      _cachedLinePath = null;
      _cachedAreaPath = null;
    }

    final positions = _cachedScreenPositions!;
    if (positions.isEmpty) return;

    // Build spatial index for hit testing
    buildSpatialIndex(chartArea);
    _registerHitRegions(positions);

    // Apply animation progress
    final animatedPositions = _applyAnimation(positions);

    // Get or build line path
    final linePath = _getLinePath(animatedPositions);

    // Draw area fill if enabled
    if (config.showArea) {
      _drawArea(canvas, chartArea, animatedPositions, linePath);
    }

    // Draw line
    _drawLine(canvas, linePath);

    // Draw markers if enabled
    if (config.showMarkers) {
      _drawMarkers(canvas, animatedPositions);
    }
  }

  List<Offset> _applyAnimation(List<Offset> positions) {
    if (config.animationProgress >= 1.0) return positions;

    // Reveal animation - draw partial line
    final count = (positions.length * config.animationProgress).ceil();
    return positions.take(count).toList();
  }

  void _registerHitRegions(List<Offset> positions) {
    const hitRadius = 20.0;

    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final info = DataPointInfo(
        seriesIndex: seriesIndex,
        dataIndex: i,
        screenPosition: pos,
        dataX: data[i].x,
        dataY: data[i].y,
        label: labels != null && i < labels!.length ? labels![i] : null,
        color: config.color,
      );

      registerHitRegion(
        info,
        Rect.fromCircle(center: pos, radius: hitRadius),
      );
    }
  }

  Path _getLinePath(List<Offset> positions) {
    if (_cachedLinePath != null && config.animationProgress >= 1.0) {
      return _cachedLinePath!;
    }

    final interpolator = _getInterpolator();
    final path = interpolator.createPath(positions);

    if (config.animationProgress >= 1.0) {
      _cachedLinePath = path;
    }

    return path;
  }

  CurveInterpolator _getInterpolator() {
    switch (config.curveType) {
      case LineCurveType.linear:
        return LinearInterpolator();
      case LineCurveType.monotone:
        return MonotoneCubicInterpolator();
      case LineCurveType.catmullRom:
        return CatmullRomInterpolator(tension: config.tension);
      case LineCurveType.cardinal:
        return CardinalInterpolator(tension: config.tension);
      case LineCurveType.stepAfter:
        return StepInterpolator(position: StepPosition.after);
      case LineCurveType.stepBefore:
        return StepInterpolator(position: StepPosition.before);
      case LineCurveType.stepMiddle:
        return StepInterpolator(position: StepPosition.middle);
    }
  }

  void _drawArea(
    Canvas canvas,
    Rect chartArea,
    List<Offset> positions,
    Path linePath,
  ) {
    if (positions.isEmpty) return;

    final areaPath = createAreaPath(positions, chartArea.bottom, linePath);

    final areaPaint = Paint()..style = PaintingStyle.fill;

    if (config.areaGradient != null && config.areaGradient!.isNotEmpty) {
      areaPaint.shader = createVerticalGradient(
        chartArea,
        config.areaGradient!,
      );
    } else {
      final baseColor = config.areaColor ?? config.color;
      areaPaint.color = baseColor.withAlpha((baseColor.alpha * 0.3).round());
    }

    canvas.drawPath(areaPath, areaPaint);
  }

  void _drawLine(Canvas canvas, Path linePath) {
    final linePaint = Paint()
      ..color = config.color
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (config.dashPattern != null && config.dashPattern!.isNotEmpty) {
      _drawDashedPath(canvas, linePath, linePaint);
    } else {
      canvas.drawPath(linePath, linePaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      var drawIndex = 0;
      final dashPattern = config.dashPattern!;

      while (distance < metric.length) {
        final dashLength = dashPattern[drawIndex % dashPattern.length];
        final isDraw = drawIndex.isEven;

        if (isDraw) {
          final end = (distance + dashLength).clamp(0.0, metric.length);
          final segment = metric.extractPath(distance, end);
          canvas.drawPath(segment, paint);
        }

        distance += dashLength;
        drawIndex++;
      }
    }
  }

  void _drawMarkers(Canvas canvas, List<Offset> positions) {
    final markerConfig = config.markerConfig ??
        MarkerConfig(
          shape: MarkerShape.circle,
          size: config.strokeWidth * 3,
          fillColor: config.color,
          strokeColor: const Color(0xFFFFFFFF),
          strokeWidth: 2.0,
        );

    _markerRenderer.update(markerConfig);
    _markerRenderer.drawMarkers(canvas, positions);
  }

  @override
  (Bounds, Bounds) calculateBounds() {
    return BoundsCalculator.calculateFromPoints(data);
  }

  @override
  void dispose() {
    super.dispose();
    _markerRenderer.dispose();
  }
}

/// Factory for creating line painters.
class LinePainterFactory {
  LinePainterFactory._();

  /// Creates a basic line painter.
  static LinePainter basic({
    required int seriesIndex,
    required List<({double x, double y})> data,
    required Color color,
    double strokeWidth = 2.0,
  }) {
    return LinePainter(
      seriesIndex: seriesIndex,
      data: data,
      config: LineSeriesConfig(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Creates a smooth line painter.
  static LinePainter smooth({
    required int seriesIndex,
    required List<({double x, double y})> data,
    required Color color,
    double strokeWidth = 2.0,
  }) {
    return LinePainter(
      seriesIndex: seriesIndex,
      data: data,
      config: LineSeriesConfig(
        color: color,
        strokeWidth: strokeWidth,
        curveType: LineCurveType.monotone,
      ),
    );
  }

  /// Creates a line painter with area fill.
  static LinePainter withArea({
    required int seriesIndex,
    required List<({double x, double y})> data,
    required Color color,
    List<Color>? gradientColors,
  }) {
    return LinePainter(
      seriesIndex: seriesIndex,
      data: data,
      config: LineSeriesConfig(
        color: color,
        curveType: LineCurveType.monotone,
        showArea: true,
        areaGradient: gradientColors,
      ),
    );
  }

  /// Creates a dashed line painter.
  static LinePainter dashed({
    required int seriesIndex,
    required List<({double x, double y})> data,
    required Color color,
    List<double> dashPattern = const [5, 3],
  }) {
    return LinePainter(
      seriesIndex: seriesIndex,
      data: data,
      config: LineSeriesConfig(
        color: color,
        dashPattern: dashPattern,
      ),
    );
  }

  /// Creates a step line painter.
  static LinePainter step({
    required int seriesIndex,
    required List<({double x, double y})> data,
    required Color color,
    LineCurveType stepType = LineCurveType.stepAfter,
  }) {
    return LinePainter(
      seriesIndex: seriesIndex,
      data: data,
      config: LineSeriesConfig(
        color: color,
        curveType: stepType,
      ),
    );
  }
}
