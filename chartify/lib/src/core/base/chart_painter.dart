import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../theme/chart_theme_data.dart';

/// Base class for all chart painters.
///
/// Provides a layered painting architecture for efficient rendering:
/// 1. Background
/// 2. Grid
/// 3. Axes
/// 4. Series (main data)
/// 5. Annotations
/// 6. Markers
/// 7. Overlay (tooltips, crosshairs, selections)
///
/// Subclasses should override the individual paint methods for their
/// specific chart type.
abstract class ChartPainter extends CustomPainter {
  /// Creates a chart painter.
  ChartPainter({
    required this.theme,
    this.animationValue = 1.0,
  });

  /// The theme data for styling.
  final ChartThemeData theme;

  /// The current animation value (0.0 to 1.0).
  final double animationValue;

  /// Cached paint objects for performance.
  final PaintCache _paintCache = PaintCache();

  /// Get cached paint object.
  Paint getPaint({
    required Color color,
    double strokeWidth = 1.0,
    PaintingStyle style = PaintingStyle.stroke,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) =>
      _paintCache.getPaint(
        color: color,
        strokeWidth: strokeWidth,
        style: style,
        strokeCap: strokeCap,
        strokeJoin: strokeJoin,
      );

  @override
  void paint(Canvas canvas, Size size) {
    // Save the canvas state
    canvas.save();

    // Paint each layer in order
    paintBackground(canvas, size);
    paintGrid(canvas, size);
    paintAxes(canvas, size);

    // Clip to chart area for series
    final chartArea = getChartArea(size);
    canvas.save();
    canvas.clipRect(chartArea);
    paintSeries(canvas, size, chartArea);
    canvas.restore();

    paintAnnotations(canvas, size, chartArea);
    paintMarkers(canvas, size, chartArea);
    paintOverlay(canvas, size);

    // Restore the canvas state
    canvas.restore();
  }

  /// Returns the rectangular area where chart data is rendered.
  ///
  /// Subclasses should override this to account for axes and padding.
  Rect getChartArea(Size size) => Rect.fromLTWH(0, 0, size.width, size.height);

  /// Paints the chart background.
  void paintBackground(Canvas canvas, Size size) {
    // Default: no background
    // Subclasses can override to paint a background
  }

  /// Paints the grid lines.
  void paintGrid(Canvas canvas, Size size) {
    // Default: no grid
    // Subclasses should override for charts that need grid lines
  }

  /// Paints the axes.
  void paintAxes(Canvas canvas, Size size) {
    // Default: no axes
    // Cartesian charts should override this
  }

  /// Paints the main series data.
  ///
  /// This is the main method that subclasses must implement.
  void paintSeries(Canvas canvas, Size size, Rect chartArea);

  /// Paints annotations (reference lines, bands, etc.).
  void paintAnnotations(Canvas canvas, Size size, Rect chartArea) {
    // Default: no annotations
    // Subclasses can override to paint annotations
  }

  /// Paints data point markers.
  void paintMarkers(Canvas canvas, Size size, Rect chartArea) {
    // Default: no markers
    // Subclasses can override to paint markers
  }

  /// Paints overlay elements (tooltips, crosshairs, selections).
  void paintOverlay(Canvas canvas, Size size) {
    // Default: no overlay
    // Subclasses can override for interactive elements
  }

  /// Draws a dashed line from [start] to [end].
  void drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashPattern,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final dashedPath = _createDashedPath(path, dashPattern);
    canvas.drawPath(dashedPath, paint);
  }

  /// Creates a dashed version of the given path.
  Path _createDashedPath(Path source, List<double> dashPattern) {
    final result = Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      var drawDash = true;
      var dashIndex = 0;

      while (distance < metric.length) {
        final dashLength = dashPattern[dashIndex % dashPattern.length];
        final nextDistance = distance + dashLength;

        if (drawDash) {
          final extractPath = metric.extractPath(
            distance,
            nextDistance.clamp(0, metric.length),
          );
          result.addPath(extractPath, Offset.zero);
        }

        distance = nextDistance;
        drawDash = !drawDash;
        dashIndex++;
      }
    }

    return result;
  }

  /// Draws text at the specified position.
  void drawText(
    Canvas canvas,
    String text,
    Offset position, {
    TextStyle? style,
    TextAlign align = TextAlign.center,
    double maxWidth = double.infinity,
    double rotation = 0,
  }) {
    final textStyle = style ?? theme.labelStyle;
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    if (rotation != 0) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation * (3.14159265359 / 180));
      canvas.translate(-position.dx, -position.dy);
      textPainter.paint(canvas, offset);
      canvas.restore();
    } else {
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue || theme != oldDelegate.theme;
}

/// Painter for Cartesian charts (line, bar, area, scatter).
abstract class CartesianChartPainter extends ChartPainter {
  /// Creates a Cartesian chart painter.
  CartesianChartPainter({
    required super.theme,
    super.animationValue,
    this.padding = const EdgeInsets.fromLTRB(50, 20, 20, 40),
    this.showGrid = true,
    this.gridDashPattern,
  });

  /// Padding around the chart area.
  final EdgeInsets padding;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Dash pattern for grid lines (null = solid).
  final List<double>? gridDashPattern;

  @override
  Rect getChartArea(Size size) => Rect.fromLTRB(
        padding.left,
        padding.top,
        size.width - padding.right,
        size.height - padding.bottom,
      );

  @override
  void paintGrid(Canvas canvas, Size size) {
    if (!showGrid) return;

    final chartArea = getChartArea(size);
    final gridPaint = getPaint(
      color: theme.gridLineColor,
      strokeWidth: theme.gridLineWidth,
    );

    // Paint horizontal lines
    final horizontalCount = 5;
    for (var i = 0; i <= horizontalCount; i++) {
      final y = chartArea.top + (chartArea.height / horizontalCount) * i;
      final start = Offset(chartArea.left, y);
      final end = Offset(chartArea.right, y);

      if (gridDashPattern != null) {
        drawDashedLine(canvas, start, end, gridPaint, gridDashPattern!);
      } else {
        canvas.drawLine(start, end, gridPaint);
      }
    }

    // Paint vertical lines
    final verticalCount = 5;
    for (var i = 0; i <= verticalCount; i++) {
      final x = chartArea.left + (chartArea.width / verticalCount) * i;
      final start = Offset(x, chartArea.top);
      final end = Offset(x, chartArea.bottom);

      if (gridDashPattern != null) {
        drawDashedLine(canvas, start, end, gridPaint, gridDashPattern!);
      } else {
        canvas.drawLine(start, end, gridPaint);
      }
    }
  }

  @override
  void paintAxes(Canvas canvas, Size size) {
    final chartArea = getChartArea(size);
    final axisPaint = getPaint(
      color: theme.axisLineColor,
      strokeWidth: theme.axisLineWidth,
    );

    // X-axis line
    canvas.drawLine(
      Offset(chartArea.left, chartArea.bottom),
      Offset(chartArea.right, chartArea.bottom),
      axisPaint,
    );

    // Y-axis line
    canvas.drawLine(
      Offset(chartArea.left, chartArea.top),
      Offset(chartArea.left, chartArea.bottom),
      axisPaint,
    );
  }
}

/// Painter for circular charts (pie, donut).
abstract class CircularChartPainter extends ChartPainter {
  /// Creates a circular chart painter.
  CircularChartPainter({
    required super.theme,
    super.animationValue,
    this.innerRadiusRatio = 0.0,
    this.startAngle = -90.0,
  });

  /// Ratio of inner radius to outer radius (0 = pie, >0 = donut).
  final double innerRadiusRatio;

  /// Starting angle in degrees (-90 = top).
  final double startAngle;

  /// Converts degrees to radians.
  double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);

  @override
  Rect getChartArea(Size size) {
    final minDimension = size.width < size.height ? size.width : size.height;
    final radius = minDimension / 2 - 20;
    final center = Offset(size.width / 2, size.height / 2);

    return Rect.fromCircle(center: center, radius: radius);
  }
}

/// Painter for polar charts (radar).
abstract class PolarChartPainter extends ChartPainter {
  /// Creates a polar chart painter.
  PolarChartPainter({
    required super.theme,
    super.animationValue,
    required this.axisCount,
    this.tickCount = 5,
  });

  /// Number of axes (spokes).
  final int axisCount;

  /// Number of tick marks per axis.
  final int tickCount;

  /// Converts degrees to radians.
  double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);

  @override
  Rect getChartArea(Size size) {
    final minDimension = size.width < size.height ? size.width : size.height;
    final radius = minDimension / 2 - 40;
    final center = Offset(size.width / 2, size.height / 2);

    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  void paintGrid(Canvas canvas, Size size) {
    final chartArea = getChartArea(size);
    final center = chartArea.center;
    final radius = chartArea.width / 2;

    final gridPaint = getPaint(
      color: theme.gridLineColor,
      strokeWidth: theme.gridLineWidth,
    );

    // Draw concentric circles
    for (var i = 1; i <= tickCount; i++) {
      final r = radius * (i / tickCount);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw axis lines (spokes)
    for (var i = 0; i < axisCount; i++) {
      final angle = degreesToRadians(-90 + (360 / axisCount) * i);
      final end = Offset(
        center.dx + radius * _cos(angle),
        center.dy + radius * _sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }
  }

  double _cos(double radians) {
    // Simple cosine approximation using Taylor series
    var result = 1.0;
    var term = 1.0;
    for (var i = 1; i < 10; i++) {
      term *= -radians * radians / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double radians) {
    // Simple sine approximation using Taylor series
    var result = radians;
    var term = radians;
    for (var i = 1; i < 10; i++) {
      term *= -radians * radians / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}

/// Cache for reusable Paint objects.
class PaintCache {
  final Map<int, Paint> _cache = {};

  /// Gets or creates a cached Paint object.
  Paint getPaint({
    required Color color,
    double strokeWidth = 1.0,
    PaintingStyle style = PaintingStyle.stroke,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) {
    final key = Object.hash(color, strokeWidth, style, strokeCap, strokeJoin);

    return _cache.putIfAbsent(
      key,
      () => Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = style
        ..strokeCap = strokeCap
        ..strokeJoin = strokeJoin
        ..isAntiAlias = true,
    );
  }

  /// Clears the cache.
  void clear() => _cache.clear();

  /// The number of cached paints.
  int get length => _cache.length;
}

/// Cache for computed paths.
class PathCache {
  Path? _cachedPath;
  int? _dataHash;

  /// Gets the cached path or computes a new one.
  Path getPath<T>(List<T> data, Path Function(List<T> data) builder) {
    final hash = Object.hashAll(data);
    if (_dataHash != hash) {
      _cachedPath = builder(data);
      _dataHash = hash;
    }
    return _cachedPath!;
  }

  /// Clears the cache.
  void clear() {
    _cachedPath = null;
    _dataHash = null;
  }

  /// Whether the cache contains a valid path.
  bool get hasCache => _cachedPath != null;
}
