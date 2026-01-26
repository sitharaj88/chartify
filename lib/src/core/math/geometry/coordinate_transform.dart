import 'dart:ui';

import '../scales/scale.dart';
import 'bounds_calculator.dart';

/// Transforms coordinates between data space and screen space.
///
/// This class provides efficient, reusable coordinate transformations
/// for chart rendering and hit testing.
class CoordinateTransform {
  CoordinateTransform({
    required this.chartArea,
    required this.xBounds,
    required this.yBounds,
    this.invertY = true,
  })  : _xScale = LinearScale(
          domain: (xBounds.min, xBounds.max),
          range: (chartArea.left, chartArea.right),
        ),
        _yScale = LinearScale(
          domain: (yBounds.min, yBounds.max),
          range: invertY
              ? (chartArea.bottom, chartArea.top)
              : (chartArea.top, chartArea.bottom),
        );

  /// The chart drawing area in screen coordinates.
  final Rect chartArea;

  /// The data bounds for the X axis.
  final Bounds xBounds;

  /// The data bounds for the Y axis.
  final Bounds yBounds;

  /// Whether to invert Y (true for typical charts where Y increases upward).
  final bool invertY;

  final LinearScale _xScale;
  final LinearScale _yScale;

  /// Converts a data X value to screen X coordinate.
  double dataToScreenX(double x) => _xScale.scale(x);

  /// Converts a data Y value to screen Y coordinate.
  double dataToScreenY(double y) => _yScale.scale(y);

  /// Converts data coordinates to screen coordinates.
  Offset dataToScreen(double x, double y) => Offset(dataToScreenX(x), dataToScreenY(y));

  /// Converts a screen X coordinate to data X value.
  double screenToDataX(double x) => _xScale.invert(x);

  /// Converts a screen Y coordinate to data Y value.
  double screenToDataY(double y) => _yScale.invert(y);

  /// Converts screen coordinates to data coordinates.
  (double, double) screenToData(Offset screen) => (screenToDataX(screen.dx), screenToDataY(screen.dy));

  /// Converts a list of data points to screen coordinates.
  List<Offset> dataPointsToScreen(List<({double x, double y})> points) => points.map((p) => dataToScreen(p.x, p.y)).toList();

  /// Whether a screen point is within the chart area.
  bool containsScreen(Offset screen) => chartArea.contains(screen);

  /// Whether a data point is within the data bounds.
  bool containsData(double x, double y) => xBounds.contains(x) && yBounds.contains(y);

  /// Returns a clipped version of the screen point within chart area.
  Offset clipToChartArea(Offset screen) => Offset(
      screen.dx.clamp(chartArea.left, chartArea.right),
      screen.dy.clamp(chartArea.top, chartArea.bottom),
    );

  /// Creates a new transform with updated chart area.
  CoordinateTransform withChartArea(Rect newChartArea) => CoordinateTransform(
      chartArea: newChartArea,
      xBounds: xBounds,
      yBounds: yBounds,
      invertY: invertY,
    );

  /// Creates a new transform with updated bounds.
  CoordinateTransform withBounds({Bounds? newXBounds, Bounds? newYBounds}) => CoordinateTransform(
      chartArea: chartArea,
      xBounds: newXBounds ?? xBounds,
      yBounds: newYBounds ?? yBounds,
      invertY: invertY,
    );

  /// Gets the pixel width per data unit.
  double get pixelsPerUnitX => chartArea.width / xBounds.range;

  /// Gets the pixel height per data unit.
  double get pixelsPerUnitY => chartArea.height / yBounds.range;
}

/// Coordinate transform for polar/radial charts.
class PolarCoordinateTransform {
  PolarCoordinateTransform({
    required this.center,
    required this.radius,
    this.startAngle = -90, // Start from top
    this.clockwise = true,
    this.innerRadius = 0,
  });

  /// The center point of the polar coordinate system.
  final Offset center;

  /// The outer radius.
  final double radius;

  /// The inner radius (for donut charts).
  final double innerRadius;

  /// Start angle in degrees (0 = right, -90 = top).
  final double startAngle;

  /// Whether angles increase clockwise.
  final bool clockwise;

  /// Converts polar coordinates to screen coordinates.
  ///
  /// [angle] is in degrees, [r] is the radial distance (0 to 1).
  Offset polarToScreen(double angle, double r) {
    final effectiveAngle = startAngle + (clockwise ? angle : -angle);
    final radians = effectiveAngle * (3.141592653589793 / 180);
    final effectiveRadius = innerRadius + r * (radius - innerRadius);

    return Offset(
      center.dx + effectiveRadius * _cos(radians),
      center.dy + effectiveRadius * _sin(radians),
    );
  }

  /// Converts screen coordinates to polar coordinates.
  ///
  /// Returns (angle in degrees, radius fraction 0-1).
  (double, double) screenToPolar(Offset screen) {
    final dx = screen.dx - center.dx;
    final dy = screen.dy - center.dy;

    final distance = dx * dx + dy * dy;
    final sqrtDistance = distance > 0 ? _sqrt(distance) : 0.0;

    // Calculate radius fraction
    final r = (sqrtDistance - innerRadius) / (radius - innerRadius);

    // Calculate angle
    var angle = _atan2(dy, dx) * (180 / 3.141592653589793);
    angle = angle - startAngle;
    if (!clockwise) angle = -angle;

    // Normalize to 0-360
    while (angle < 0) {
      angle += 360;
    }
    while (angle >= 360) {
      angle -= 360;
    }

    return (angle, r.clamp(0.0, 1.0));
  }

  /// Gets a point on the arc at the given angle and radius fraction.
  Offset arcPoint(double angle, {double r = 1.0}) => polarToScreen(angle, r);

  /// Creates an arc path from startAngle to endAngle.
  Path createArc(
    double startAngle,
    double sweepAngle, {
    double innerR = 0,
    double outerR = 1,
  }) {
    final path = Path();

    final outerStart = polarToScreen(startAngle, outerR);
    final innerStart = polarToScreen(startAngle, innerR);
    final outerEnd = polarToScreen(startAngle + sweepAngle, outerR);
    final innerEnd = polarToScreen(startAngle + sweepAngle, innerR);

    final outerRadius = innerRadius + outerR * (radius - innerRadius);
    final innerRadiusActual = innerRadius + innerR * (radius - innerRadius);

    path.moveTo(outerStart.dx, outerStart.dy);

    // Outer arc
    path.arcToPoint(
      outerEnd,
      radius: Radius.circular(outerRadius),
      clockwise: clockwise ? sweepAngle > 0 : sweepAngle < 0,
      largeArc: sweepAngle.abs() > 180,
    );

    // Line to inner arc
    path.lineTo(innerEnd.dx, innerEnd.dy);

    // Inner arc (reversed direction)
    if (innerRadiusActual > 0) {
      path.arcToPoint(
        innerStart,
        radius: Radius.circular(innerRadiusActual),
        clockwise: clockwise ? sweepAngle < 0 : sweepAngle > 0,
        largeArc: sweepAngle.abs() > 180,
      );
    }

    path.close();
    return path;
  }

  // Efficient trig functions using lookup or Taylor series
  static double _sin(double x) {
    // Normalize to [-π, π]
    while (x > 3.141592653589793) {
      x -= 6.283185307179586;
    }
    while (x < -3.141592653589793) {
      x += 6.283185307179586;
    }

    // Taylor series approximation for better performance
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;

    return x - x3 / 6 + x5 / 120 - x7 / 5040;
  }

  static double _cos(double x) {
    return _sin(x + 1.5707963267948966); // cos(x) = sin(x + π/2)
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    // Newton's method for fast square root
    var guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    // Fast atan2 approximation
    if (x == 0) {
      if (y > 0) return 1.5707963267948966;
      if (y < 0) return -1.5707963267948966;
      return 0;
    }

    final absY = y.abs();
    final absX = x.abs();

    double angle;
    if (absX > absY) {
      final ratio = y / x;
      angle = ratio / (1 + 0.28 * ratio * ratio);
      if (x < 0) {
        angle += y >= 0 ? 3.141592653589793 : -3.141592653589793;
      }
    } else {
      final ratio = x / y;
      angle = 1.5707963267948966 - ratio / (1 + 0.28 * ratio * ratio);
      if (y < 0) {
        angle -= 3.141592653589793;
      }
    }

    return angle;
  }
}
