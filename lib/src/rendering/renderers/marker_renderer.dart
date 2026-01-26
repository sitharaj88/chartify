import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'renderer.dart';

/// Types of built-in marker shapes.
enum MarkerShape {
  /// Circular marker.
  circle,

  /// Square marker.
  square,

  /// Diamond marker.
  diamond,

  /// Triangle pointing up.
  triangleUp,

  /// Triangle pointing down.
  triangleDown,

  /// Star shape.
  star,

  /// Cross/plus shape.
  cross,

  /// X shape.
  x,

  /// Horizontal line (dash).
  dash,

  /// Vertical line.
  verticalLine,

  /// Pentagon shape.
  pentagon,

  /// Hexagon shape.
  hexagon,

  /// Heart shape.
  heart,

  /// Arrow pointing up.
  arrowUp,

  /// Arrow pointing down.
  arrowDown,
}

/// Configuration for a marker.
class MarkerConfig extends RendererConfig {
  const MarkerConfig({
    this.visible = true,
    this.shape = MarkerShape.circle,
    this.size = 8.0,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 2.0,
    this.elevation = 0.0,
    this.shadowColor,
    this.customPath,
  });

  @override
  final bool visible;

  /// Shape of the marker.
  final MarkerShape shape;

  /// Size of the marker (diameter for circle, width/height for others).
  final double size;

  /// Fill color of the marker.
  final Color? fillColor;

  /// Stroke color of the marker.
  final Color? strokeColor;

  /// Width of the stroke.
  final double strokeWidth;

  /// Elevation for shadow effect.
  final double elevation;

  /// Color of the shadow.
  final Color? shadowColor;

  /// Custom path builder for custom shapes.
  final Path Function(Offset center, double size)? customPath;

  /// Creates a copy with updated values.
  MarkerConfig copyWith({
    bool? visible,
    MarkerShape? shape,
    double? size,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    double? elevation,
    Color? shadowColor,
    Path Function(Offset center, double size)? customPath,
  }) => MarkerConfig(
      visible: visible ?? this.visible,
      shape: shape ?? this.shape,
      size: size ?? this.size,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      customPath: customPath ?? this.customPath,
    );
}

/// Renderer for data point markers.
///
/// Draws various marker shapes at specified positions with
/// configurable fill, stroke, and shadow effects.
class MarkerRenderer with RendererMixin<MarkerConfig> implements ChartRenderer<MarkerConfig> {
  MarkerRenderer({
    required MarkerConfig config,
  }) : _config = config;

  MarkerConfig _config;

  // Cached paths for each shape
  final Map<MarkerShape, Path Function(Offset, double)> _pathBuilders = {};

  @override
  MarkerConfig get config => _config;

  @override
  void update(MarkerConfig newConfig) {
    if (_config != newConfig) {
      _config = newConfig;
      markNeedsRepaint();
    }
  }

  @override
  void render(Canvas canvas, Size size, Rect chartArea) {
    // This renderer is typically used via drawMarker, not render
    markPainted();
  }

  /// Draws a single marker at the specified position.
  void drawMarker(
    Canvas canvas,
    Offset position, {
    MarkerConfig? overrideConfig,
  }) {
    final config = overrideConfig ?? _config;
    if (!config.visible) return;

    final path = _buildPath(config.shape, position, config.size, config.customPath);

    // Draw shadow
    if (config.elevation > 0) {
      final shadowPaint = Paint()
        ..color = config.shadowColor ?? const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.elevation);
      canvas.drawPath(path.shift(Offset(0, config.elevation / 2)), shadowPaint);
    }

    // Draw fill
    if (config.fillColor != null) {
      final fillPaint = Paint()
        ..color = config.fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // Draw stroke
    if (config.strokeColor != null && config.strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = config.strokeColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }
  }

  /// Draws multiple markers efficiently.
  void drawMarkers(
    Canvas canvas,
    List<Offset> positions, {
    List<MarkerConfig>? configs,
  }) {
    for (var i = 0; i < positions.length; i++) {
      drawMarker(
        canvas,
        positions[i],
        overrideConfig: configs != null && i < configs.length ? configs[i] : null,
      );
    }
  }

  Path _buildPath(
    MarkerShape shape,
    Offset center,
    double size,
    Path Function(Offset, double)? customPath,
  ) {
    if (customPath != null) {
      return customPath(center, size);
    }

    final builder = _pathBuilders[shape] ?? _getPathBuilder(shape);
    _pathBuilders[shape] = builder;
    return builder(center, size);
  }

  Path Function(Offset, double) _getPathBuilder(MarkerShape shape) {
    switch (shape) {
      case MarkerShape.circle:
        return _buildCircle;
      case MarkerShape.square:
        return _buildSquare;
      case MarkerShape.diamond:
        return _buildDiamond;
      case MarkerShape.triangleUp:
        return _buildTriangleUp;
      case MarkerShape.triangleDown:
        return _buildTriangleDown;
      case MarkerShape.star:
        return _buildStar;
      case MarkerShape.cross:
        return _buildCross;
      case MarkerShape.x:
        return _buildX;
      case MarkerShape.dash:
        return _buildDash;
      case MarkerShape.verticalLine:
        return _buildVerticalLine;
      case MarkerShape.pentagon:
        return _buildPentagon;
      case MarkerShape.hexagon:
        return _buildHexagon;
      case MarkerShape.heart:
        return _buildHeart;
      case MarkerShape.arrowUp:
        return _buildArrowUp;
      case MarkerShape.arrowDown:
        return _buildArrowDown;
    }
  }

  Path _buildCircle(Offset center, double size) => Path()..addOval(Rect.fromCircle(center: center, radius: size / 2));

  Path _buildSquare(Offset center, double size) => Path()..addRect(Rect.fromCenter(center: center, width: size, height: size));

  Path _buildDiamond(Offset center, double size) {
    final half = size / 2;
    return Path()
      ..moveTo(center.dx, center.dy - half)
      ..lineTo(center.dx + half, center.dy)
      ..lineTo(center.dx, center.dy + half)
      ..lineTo(center.dx - half, center.dy)
      ..close();
  }

  Path _buildTriangleUp(Offset center, double size) {
    final half = size / 2;
    final height = size * 0.866; // sqrt(3)/2
    return Path()
      ..moveTo(center.dx, center.dy - height / 2)
      ..lineTo(center.dx + half, center.dy + height / 2)
      ..lineTo(center.dx - half, center.dy + height / 2)
      ..close();
  }

  Path _buildTriangleDown(Offset center, double size) {
    final half = size / 2;
    final height = size * 0.866;
    return Path()
      ..moveTo(center.dx, center.dy + height / 2)
      ..lineTo(center.dx + half, center.dy - height / 2)
      ..lineTo(center.dx - half, center.dy - height / 2)
      ..close();
  }

  Path _buildStar(Offset center, double size) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    const points = 5;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    return path..close();
  }

  Path _buildCross(Offset center, double size) {
    final half = size / 2;
    final thickness = size / 4;
    return Path()
      ..moveTo(center.dx - thickness / 2, center.dy - half)
      ..lineTo(center.dx + thickness / 2, center.dy - half)
      ..lineTo(center.dx + thickness / 2, center.dy - thickness / 2)
      ..lineTo(center.dx + half, center.dy - thickness / 2)
      ..lineTo(center.dx + half, center.dy + thickness / 2)
      ..lineTo(center.dx + thickness / 2, center.dy + thickness / 2)
      ..lineTo(center.dx + thickness / 2, center.dy + half)
      ..lineTo(center.dx - thickness / 2, center.dy + half)
      ..lineTo(center.dx - thickness / 2, center.dy + thickness / 2)
      ..lineTo(center.dx - half, center.dy + thickness / 2)
      ..lineTo(center.dx - half, center.dy - thickness / 2)
      ..lineTo(center.dx - thickness / 2, center.dy - thickness / 2)
      ..close();
  }

  Path _buildX(Offset center, double size) {
    final half = size / 2;
    final thickness = size / 6;
    return Path()
      ..moveTo(center.dx - half, center.dy - half + thickness)
      ..lineTo(center.dx - thickness, center.dy)
      ..lineTo(center.dx - half, center.dy + half - thickness)
      ..lineTo(center.dx - half + thickness, center.dy + half)
      ..lineTo(center.dx, center.dy + thickness)
      ..lineTo(center.dx + half - thickness, center.dy + half)
      ..lineTo(center.dx + half, center.dy + half - thickness)
      ..lineTo(center.dx + thickness, center.dy)
      ..lineTo(center.dx + half, center.dy - half + thickness)
      ..lineTo(center.dx + half - thickness, center.dy - half)
      ..lineTo(center.dx, center.dy - thickness)
      ..lineTo(center.dx - half + thickness, center.dy - half)
      ..close();
  }

  Path _buildDash(Offset center, double size) => Path()
      ..addRect(Rect.fromCenter(
        center: center,
        width: size,
        height: size / 3,
      ),);

  Path _buildVerticalLine(Offset center, double size) => Path()
      ..addRect(Rect.fromCenter(
        center: center,
        width: size / 3,
        height: size,
      ),);

  Path _buildPentagon(Offset center, double size) => _buildPolygon(center, size, 5);

  Path _buildHexagon(Offset center, double size) => _buildPolygon(center, size, 6);

  Path _buildPolygon(Offset center, double size, int sides) {
    final path = Path();
    final radius = size / 2;
    final angleStep = 2 * math.pi / sides;
    const startAngle = -math.pi / 2; // Start from top

    for (var i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    return path..close();
  }

  Path _buildHeart(Offset center, double size) {
    final path = Path();
    final half = size / 2;

    path.moveTo(center.dx, center.dy + half * 0.7);

    // Left curve
    path.cubicTo(
      center.dx - half, center.dy + half * 0.2,
      center.dx - half, center.dy - half * 0.5,
      center.dx, center.dy - half * 0.3,
    );

    // Right curve
    path.cubicTo(
      center.dx + half, center.dy - half * 0.5,
      center.dx + half, center.dy + half * 0.2,
      center.dx, center.dy + half * 0.7,
    );

    return path..close();
  }

  Path _buildArrowUp(Offset center, double size) {
    final half = size / 2;
    final third = size / 3;
    return Path()
      ..moveTo(center.dx, center.dy - half)
      ..lineTo(center.dx + half, center.dy)
      ..lineTo(center.dx + third / 2, center.dy)
      ..lineTo(center.dx + third / 2, center.dy + half)
      ..lineTo(center.dx - third / 2, center.dy + half)
      ..lineTo(center.dx - third / 2, center.dy)
      ..lineTo(center.dx - half, center.dy)
      ..close();
  }

  Path _buildArrowDown(Offset center, double size) {
    final half = size / 2;
    final third = size / 3;
    return Path()
      ..moveTo(center.dx, center.dy + half)
      ..lineTo(center.dx + half, center.dy)
      ..lineTo(center.dx + third / 2, center.dy)
      ..lineTo(center.dx + third / 2, center.dy - half)
      ..lineTo(center.dx - third / 2, center.dy - half)
      ..lineTo(center.dx - third / 2, center.dy)
      ..lineTo(center.dx - half, center.dy)
      ..close();
  }

  /// Gets the bounds for a marker at a position.
  Rect getMarkerBounds(Offset center, {double? size}) {
    final markerSize = size ?? _config.size;
    return Rect.fromCircle(center: center, radius: markerSize / 2);
  }

  @override
  EdgeInsets calculateInsets(Size availableSize) => EdgeInsets.zero;

  @override
  void dispose() {
    _pathBuilders.clear();
  }
}

/// Factory for creating common marker configurations.
class MarkerFactory {
  MarkerFactory._();

  /// Creates a filled circle marker.
  static MarkerConfig filledCircle({
    required Color color,
    double size = 8.0,
  }) => MarkerConfig(
      fillColor: color,
      size: size,
    );

  /// Creates a hollow circle marker.
  static MarkerConfig hollowCircle({
    required Color color,
    double size = 8.0,
    double strokeWidth = 2.0,
  }) => MarkerConfig(
      strokeColor: color,
      strokeWidth: strokeWidth,
      size: size,
    );

  /// Creates a marker with fill and stroke.
  static MarkerConfig filledWithStroke({
    required Color fillColor,
    required Color strokeColor,
    MarkerShape shape = MarkerShape.circle,
    double size = 8.0,
    double strokeWidth = 2.0,
  }) => MarkerConfig(
      shape: shape,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      size: size,
    );

  /// Creates a marker with shadow.
  static MarkerConfig withShadow({
    required Color color,
    MarkerShape shape = MarkerShape.circle,
    double size = 10.0,
    double elevation = 4.0,
  }) => MarkerConfig(
      shape: shape,
      fillColor: color,
      elevation: elevation,
      size: size,
    );

  /// Creates a hidden marker (for hit testing only).
  static MarkerConfig hidden({double size = 20.0}) => MarkerConfig(
      visible: false,
      size: size,
    );
}
