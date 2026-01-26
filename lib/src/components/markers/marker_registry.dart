import 'dart:ui';

import '../../rendering/renderers/marker_renderer.dart';

/// A registry for custom marker shapes.
///
/// Allows registration of custom marker path builders
/// that can be used across all charts.
class MarkerRegistry {
  MarkerRegistry._();

  static final MarkerRegistry instance = MarkerRegistry._();

  final Map<String, Path Function(Offset center, double size)> _customMarkers =
      {};

  /// Registers a custom marker shape.
  ///
  /// The [pathBuilder] receives the center position and size,
  /// and should return a Path for the marker.
  void register(
    String name,
    Path Function(Offset center, double size) pathBuilder,
  ) {
    _customMarkers[name] = pathBuilder;
  }

  /// Unregisters a custom marker shape.
  void unregister(String name) {
    _customMarkers.remove(name);
  }

  /// Gets a custom marker path builder.
  Path Function(Offset center, double size)? get(String name) => _customMarkers[name];

  /// Checks if a custom marker is registered.
  bool has(String name) => _customMarkers.containsKey(name);

  /// Gets all registered custom marker names.
  Iterable<String> get names => _customMarkers.keys;

  /// Clears all custom markers.
  void clear() {
    _customMarkers.clear();
  }

  /// Creates a marker config for a custom marker.
  MarkerConfig createConfig(
    String name, {
    double size = 8.0,
    Color? fillColor,
    Color? strokeColor,
    double strokeWidth = 2.0,
    double elevation = 0.0,
  }) {
    final pathBuilder = _customMarkers[name];
    if (pathBuilder == null) {
      throw ArgumentError('Custom marker "$name" not found');
    }

    return MarkerConfig(
      size: size,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      elevation: elevation,
      customPath: pathBuilder,
    );
  }
}

/// Built-in marker shapes library.
class MarkerShapes {
  MarkerShapes._();

  /// Registers all enhanced marker shapes.
  static void registerAll() {
    final registry = MarkerRegistry.instance;

    // Arrows
    registry.register('arrowLeft', _buildArrowLeft);
    registry.register('arrowRight', _buildArrowRight);

    // Symbols
    registry.register('checkmark', _buildCheckmark);
    registry.register('crossmark', _buildCrossmark);
    registry.register('warning', _buildWarning);
    registry.register('info', _buildInfo);

    // Weather
    registry.register('sun', _buildSun);
    registry.register('cloud', _buildCloud);
    registry.register('raindrop', _buildRaindrop);

    // Misc
    registry.register('pin', _buildPin);
    registry.register('flag', _buildFlag);
    registry.register('target', _buildTarget);
    registry.register('ring', _buildRing);
    registry.register('donut', _buildDonut);
  }

  static Path _buildArrowLeft(Offset center, double size) {
    final half = size / 2;
    final third = size / 3;
    return Path()
      ..moveTo(center.dx - half, center.dy)
      ..lineTo(center.dx, center.dy - half)
      ..lineTo(center.dx, center.dy - third / 2)
      ..lineTo(center.dx + half, center.dy - third / 2)
      ..lineTo(center.dx + half, center.dy + third / 2)
      ..lineTo(center.dx, center.dy + third / 2)
      ..lineTo(center.dx, center.dy + half)
      ..close();
  }

  static Path _buildArrowRight(Offset center, double size) {
    final half = size / 2;
    final third = size / 3;
    return Path()
      ..moveTo(center.dx + half, center.dy)
      ..lineTo(center.dx, center.dy - half)
      ..lineTo(center.dx, center.dy - third / 2)
      ..lineTo(center.dx - half, center.dy - third / 2)
      ..lineTo(center.dx - half, center.dy + third / 2)
      ..lineTo(center.dx, center.dy + third / 2)
      ..lineTo(center.dx, center.dy + half)
      ..close();
  }

  static Path _buildCheckmark(Offset center, double size) {
    final half = size / 2;
    return Path()
      ..moveTo(center.dx - half, center.dy)
      ..lineTo(center.dx - half * 0.3, center.dy + half * 0.7)
      ..lineTo(center.dx + half, center.dy - half * 0.5);
  }

  static Path _buildCrossmark(Offset center, double size) {
    final half = size / 2;
    return Path()
      ..moveTo(center.dx - half, center.dy - half)
      ..lineTo(center.dx + half, center.dy + half)
      ..moveTo(center.dx + half, center.dy - half)
      ..lineTo(center.dx - half, center.dy + half);
  }

  static Path _buildWarning(Offset center, double size) {
    final half = size / 2;
    return Path()
      ..moveTo(center.dx, center.dy - half)
      ..lineTo(center.dx + half, center.dy + half * 0.7)
      ..lineTo(center.dx - half, center.dy + half * 0.7)
      ..close();
  }

  static Path _buildInfo(Offset center, double size) {
    final path = Path();
    final radius = size / 2;

    // Circle
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Info "i" - simplified as a vertical line
    path.moveTo(center.dx, center.dy - radius * 0.3);
    path.lineTo(center.dx, center.dy + radius * 0.5);

    return path;
  }

  static Path _buildSun(Offset center, double size) {
    final path = Path();
    final radius = size / 4;
    const rays = 8;

    // Center circle
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Rays
    for (var i = 0; i < rays; i++) {
      final angle = i * 3.14159 * 2 / rays;
      final innerX = center.dx + radius * 1.3 * _cos(angle);
      final innerY = center.dy + radius * 1.3 * _sin(angle);
      final outerX = center.dx + size / 2 * _cos(angle);
      final outerY = center.dy + size / 2 * _sin(angle);

      path.moveTo(innerX, innerY);
      path.lineTo(outerX, outerY);
    }

    return path;
  }

  static Path _buildCloud(Offset center, double size) {
    final path = Path();
    final w = size * 0.8;
    final h = size * 0.5;

    // Main body
    path.addOval(Rect.fromCenter(
      center: Offset(center.dx - w * 0.15, center.dy + h * 0.1),
      width: w * 0.5,
      height: h * 0.8,
    ),);
    path.addOval(Rect.fromCenter(
      center: Offset(center.dx + w * 0.15, center.dy + h * 0.1),
      width: w * 0.5,
      height: h * 0.8,
    ),);
    path.addOval(Rect.fromCenter(
      center: Offset(center.dx, center.dy - h * 0.1),
      width: w * 0.6,
      height: h * 0.9,
    ),);

    return path;
  }

  static Path _buildRaindrop(Offset center, double size) {
    final half = size / 2;
    return Path()
      ..moveTo(center.dx, center.dy - half)
      ..cubicTo(
        center.dx + half, center.dy,
        center.dx + half * 0.5, center.dy + half,
        center.dx, center.dy + half,
      )
      ..cubicTo(
        center.dx - half * 0.5, center.dy + half,
        center.dx - half, center.dy,
        center.dx, center.dy - half,
      )
      ..close();
  }

  static Path _buildPin(Offset center, double size) {
    final half = size / 2;
    final path = Path();

    // Pin head (circle)
    path.addOval(Rect.fromCircle(
      center: Offset(center.dx, center.dy - half * 0.3),
      radius: half * 0.5,
    ),);

    // Pin point
    path.moveTo(center.dx - half * 0.3, center.dy);
    path.lineTo(center.dx, center.dy + half);
    path.lineTo(center.dx + half * 0.3, center.dy);
    path.close();

    return path;
  }

  static Path _buildFlag(Offset center, double size) {
    final half = size / 2;
    return Path()
      // Pole
      ..moveTo(center.dx - half, center.dy + half)
      ..lineTo(center.dx - half, center.dy - half)
      // Flag
      ..lineTo(center.dx + half, center.dy - half * 0.3)
      ..lineTo(center.dx - half, center.dy + half * 0.1);
  }

  static Path _buildTarget(Offset center, double size) {
    final path = Path();
    final radii = [size / 2, size / 3, size / 6];

    for (final radius in radii) {
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    }

    return path;
  }

  static Path _buildRing(Offset center, double size) {
    final outer = size / 2;
    final inner = size / 3;
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: outer))
      ..addOval(Rect.fromCircle(center: center, radius: inner))
      ..fillType = PathFillType.evenOdd;
  }

  static Path _buildDonut(Offset center, double size) {
    final outer = size / 2;
    final inner = size / 4;
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: outer))
      ..addOval(Rect.fromCircle(center: center, radius: inner))
      ..fillType = PathFillType.evenOdd;
  }

  // Trig helpers
  static double _sin(double x) {
    while (x > 3.14159) {
      x -= 6.28318;
    }
    while (x < -3.14159) {
      x += 6.28318;
    }
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120);
  }

  static double _cos(double x) => _sin(x + 1.5708);
}

/// Preset marker configurations.
class MarkerPresets {
  MarkerPresets._();

  /// Small filled circle.
  static MarkerConfig smallDot(Color color) => MarkerConfig(
        size: 6,
        fillColor: color,
      );

  /// Medium filled circle.
  static MarkerConfig mediumDot(Color color) => MarkerConfig(
        fillColor: color,
      );

  /// Large filled circle.
  static MarkerConfig largeDot(Color color) => MarkerConfig(
        size: 12,
        fillColor: color,
      );

  /// Hollow circle with border.
  static MarkerConfig hollowCircle(Color color, {double strokeWidth = 2}) =>
      MarkerConfig(
        size: 10,
        strokeColor: color,
        strokeWidth: strokeWidth,
      );

  /// Filled circle with white border.
  static MarkerConfig borderedDot(Color color) => MarkerConfig(
        size: 10,
        fillColor: color,
        strokeColor: const Color(0xFFFFFFFF),
      );

  /// Square marker.
  static MarkerConfig square(Color color) => MarkerConfig(
        shape: MarkerShape.square,
        fillColor: color,
      );

  /// Diamond marker.
  static MarkerConfig diamond(Color color) => MarkerConfig(
        shape: MarkerShape.diamond,
        size: 10,
        fillColor: color,
      );

  /// Star marker.
  static MarkerConfig star(Color color) => MarkerConfig(
        shape: MarkerShape.star,
        size: 12,
        fillColor: color,
      );

  /// Triangle marker.
  static MarkerConfig triangle(Color color, {bool pointUp = true}) =>
      MarkerConfig(
        shape: pointUp ? MarkerShape.triangleUp : MarkerShape.triangleDown,
        size: 10,
        fillColor: color,
      );

  /// Creates a sequence of distinct markers for multiple series.
  static List<MarkerConfig> forSeries(List<Color> colors) {
    final shapes = [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.diamond,
      MarkerShape.triangleUp,
      MarkerShape.star,
      MarkerShape.hexagon,
      MarkerShape.triangleDown,
      MarkerShape.pentagon,
    ];

    return List.generate(colors.length, (i) => MarkerConfig(
          shape: shapes[i % shapes.length],
          fillColor: colors[i],
          strokeColor: const Color(0xFFFFFFFF),
          strokeWidth: 1.5,
        ),);
  }
}
