import 'dart:math' as math;
import 'dart:ui';

/// Abstract interface for curve interpolation.
///
/// Interpolators generate smooth paths through a set of control points.
abstract class CurveInterpolator {
  /// Creates a path through the given points.
  Path createPath(List<Offset> points);

  /// Gets a point on the interpolated curve at parameter t (0.0 to 1.0).
  Offset pointAt(List<Offset> points, double t);
}

/// Linear interpolation - straight line segments between points.
class LinearInterpolator extends CurveInterpolator {
  @override
  Path createPath(List<Offset> points) {
    if (points.isEmpty) return Path();

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  @override
  Offset pointAt(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    final totalSegments = points.length - 1;
    final scaledT = t * totalSegments;
    final segmentIndex = scaledT.floor().clamp(0, totalSegments - 1);
    final localT = scaledT - segmentIndex;

    final p0 = points[segmentIndex];
    final p1 = points[segmentIndex + 1];

    return Offset(
      lerpDouble(p0.dx, p1.dx, localT),
      lerpDouble(p0.dy, p1.dy, localT),
    );
  }
}

/// Monotone cubic interpolation (Fritsch-Carlson method).
///
/// Produces a smooth curve that preserves monotonicity - the curve
/// doesn't overshoot between points, making it ideal for charts.
class MonotoneCubicInterpolator extends CurveInterpolator {
  @override
  Path createPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    if (points.length == 1) {
      return Path()..moveTo(points.first.dx, points.first.dy);
    }
    if (points.length == 2) {
      return LinearInterpolator().createPath(points);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    // Calculate tangents using Fritsch-Carlson method
    final tangents = _calculateMonotoneTangents(points);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dx = p1.dx - p0.dx;

      // Control points for cubic Bezier
      final cp1 = Offset(p0.dx + dx / 3, p0.dy + tangents[i] * dx / 3);
      final cp2 = Offset(p1.dx - dx / 3, p1.dy - tangents[i + 1] * dx / 3);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    return path;
  }

  @override
  Offset pointAt(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    final totalSegments = points.length - 1;
    final scaledT = t * totalSegments;
    final segmentIndex = scaledT.floor().clamp(0, totalSegments - 1);
    final localT = scaledT - segmentIndex;

    final tangents = _calculateMonotoneTangents(points);

    final p0 = points[segmentIndex];
    final p1 = points[segmentIndex + 1];
    final dx = p1.dx - p0.dx;

    final cp1 = Offset(p0.dx + dx / 3, p0.dy + tangents[segmentIndex] * dx / 3);
    final cp2 = Offset(p1.dx - dx / 3, p1.dy - tangents[segmentIndex + 1] * dx / 3);

    return _cubicBezierPoint(p0, cp1, cp2, p1, localT);
  }

  List<double> _calculateMonotoneTangents(List<Offset> points) {
    final n = points.length;
    final tangents = List<double>.filled(n, 0);

    // Calculate slopes
    final slopes = <double>[];
    for (var i = 0; i < n - 1; i++) {
      final dx = points[i + 1].dx - points[i].dx;
      final dy = points[i + 1].dy - points[i].dy;
      slopes.add(dx != 0 ? dy / dx : 0);
    }

    // Calculate initial tangents
    tangents[0] = slopes[0];
    tangents[n - 1] = slopes[n - 2];

    for (var i = 1; i < n - 1; i++) {
      if (slopes[i - 1] * slopes[i] <= 0) {
        tangents[i] = 0;
      } else {
        tangents[i] = (slopes[i - 1] + slopes[i]) / 2;
      }
    }

    // Fritsch-Carlson modification for monotonicity
    for (var i = 0; i < n - 1; i++) {
      if (slopes[i].abs() < 1e-10) {
        tangents[i] = 0;
        tangents[i + 1] = 0;
      } else {
        final alpha = tangents[i] / slopes[i];
        final beta = tangents[i + 1] / slopes[i];
        final h = math.sqrt(alpha * alpha + beta * beta);
        if (h > 3) {
          final t = 3 / h;
          tangents[i] = t * alpha * slopes[i];
          tangents[i + 1] = t * beta * slopes[i];
        }
      }
    }

    return tangents;
  }

  Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;

    return Offset(
      mt3 * p0.dx + 3 * mt2 * t * p1.dx + 3 * mt * t2 * p2.dx + t3 * p3.dx,
      mt3 * p0.dy + 3 * mt2 * t * p1.dy + 3 * mt * t2 * p2.dy + t3 * p3.dy,
    );
  }
}

/// Catmull-Rom spline interpolation.
///
/// Creates smooth curves that pass through all control points.
class CatmullRomInterpolator extends CurveInterpolator {
  CatmullRomInterpolator({this.tension = 0.5, this.alpha = 0.5});

  /// Tension parameter (0.0 = loose, 1.0 = tight).
  final double tension;

  /// Parameterization type (0.0 = uniform, 0.5 = centripetal, 1.0 = chordal).
  final double alpha;

  @override
  Path createPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    if (points.length < 2) {
      return Path()..moveTo(points.first.dx, points.first.dy);
    }

    final path = Path();

    // Extend points at ends for smooth boundaries
    final extendedPoints = [
      _reflectPoint(points[1], points[0]),
      ...points,
      _reflectPoint(points[points.length - 2], points[points.length - 1]),
    ];

    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < extendedPoints.length - 2; i++) {
      final p0 = extendedPoints[i - 1];
      final p1 = extendedPoints[i];
      final p2 = extendedPoints[i + 1];
      final p3 = extendedPoints[i + 2];

      // Generate curve segment
      const steps = 20;
      for (var j = 1; j <= steps; j++) {
        final t = j / steps;
        final point = _catmullRomPoint(p0, p1, p2, p3, t);
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  @override
  Offset pointAt(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    final extendedPoints = [
      _reflectPoint(points[1], points[0]),
      ...points,
      _reflectPoint(points[points.length - 2], points[points.length - 1]),
    ];

    final totalSegments = points.length - 1;
    final scaledT = t * totalSegments;
    final segmentIndex = scaledT.floor().clamp(0, totalSegments - 1);
    final localT = scaledT - segmentIndex;

    final i = segmentIndex + 1; // Offset for extended points
    return _catmullRomPoint(
      extendedPoints[i - 1],
      extendedPoints[i],
      extendedPoints[i + 1],
      extendedPoints[i + 2],
      localT,
    );
  }

  Offset _reflectPoint(Offset reference, Offset point) => Offset(
      2 * point.dx - reference.dx,
      2 * point.dy - reference.dy,
    );

  Offset _catmullRomPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final s = (1 - tension) / 2;

    final m1x = s * (p2.dx - p0.dx);
    final m1y = s * (p2.dy - p0.dy);
    final m2x = s * (p3.dx - p1.dx);
    final m2y = s * (p3.dy - p1.dy);

    final a = 2 * t3 - 3 * t2 + 1;
    final b = t3 - 2 * t2 + t;
    final c = -2 * t3 + 3 * t2;
    final d = t3 - t2;

    return Offset(
      a * p1.dx + b * m1x + c * p2.dx + d * m2x,
      a * p1.dy + b * m1y + c * p2.dy + d * m2y,
    );
  }
}

/// Cardinal spline interpolation.
///
/// Similar to Catmull-Rom but with adjustable tension.
class CardinalInterpolator extends CurveInterpolator {
  CardinalInterpolator({this.tension = 0.0});

  /// Tension parameter (0.0 = Catmull-Rom, 1.0 = linear).
  final double tension;

  @override
  Path createPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    if (points.length < 2) {
      return Path()..moveTo(points.first.dx, points.first.dy);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[points.length - 1];

      final cp1 = Offset(
        p1.dx + (1 - tension) * (p2.dx - p0.dx) / 6,
        p1.dy + (1 - tension) * (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (1 - tension) * (p3.dx - p1.dx) / 6,
        p2.dy - (1 - tension) * (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  Offset pointAt(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    final totalSegments = points.length - 1;
    final scaledT = t * totalSegments;
    final segmentIndex = scaledT.floor().clamp(0, totalSegments - 1);
    final localT = scaledT - segmentIndex;

    final i = segmentIndex;
    final p0 = i > 0 ? points[i - 1] : points[0];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : points[points.length - 1];

    final cp1 = Offset(
      p1.dx + (1 - tension) * (p2.dx - p0.dx) / 6,
      p1.dy + (1 - tension) * (p2.dy - p0.dy) / 6,
    );
    final cp2 = Offset(
      p2.dx - (1 - tension) * (p3.dx - p1.dx) / 6,
      p2.dy - (1 - tension) * (p3.dy - p1.dy) / 6,
    );

    return _cubicBezierPoint(p1, cp1, cp2, p2, localT);
  }

  Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;

    return Offset(
      mt3 * p0.dx + 3 * mt2 * t * p1.dx + 3 * mt * t2 * p2.dx + t3 * p3.dx,
      mt3 * p0.dy + 3 * mt2 * t * p1.dy + 3 * mt * t2 * p2.dy + t3 * p3.dy,
    );
  }
}

/// Step interpolation for step charts.
enum StepPosition { before, after, middle }

class StepInterpolator extends CurveInterpolator {
  StepInterpolator({this.position = StepPosition.after});

  final StepPosition position;

  @override
  Path createPath(List<Offset> points) {
    if (points.isEmpty) return Path();

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      switch (position) {
        case StepPosition.before:
          path.lineTo(prev.dx, curr.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepPosition.after:
          path.lineTo(curr.dx, prev.dy);
          path.lineTo(curr.dx, curr.dy);
        case StepPosition.middle:
          final midX = (prev.dx + curr.dx) / 2;
          path.lineTo(midX, prev.dy);
          path.lineTo(midX, curr.dy);
          path.lineTo(curr.dx, curr.dy);
      }
    }

    return path;
  }

  @override
  Offset pointAt(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    final totalSegments = points.length - 1;
    final scaledT = t * totalSegments;
    final segmentIndex = scaledT.floor().clamp(0, totalSegments - 1);
    final localT = scaledT - segmentIndex;

    final prev = points[segmentIndex];
    final curr = points[segmentIndex + 1];

    switch (position) {
      case StepPosition.before:
        if (localT < 0.5) {
          return Offset(prev.dx, lerpDouble(prev.dy, curr.dy, localT * 2));
        } else {
          return Offset(lerpDouble(prev.dx, curr.dx, (localT - 0.5) * 2), curr.dy);
        }
      case StepPosition.after:
        if (localT < 0.5) {
          return Offset(lerpDouble(prev.dx, curr.dx, localT * 2), prev.dy);
        } else {
          return Offset(curr.dx, lerpDouble(prev.dy, curr.dy, (localT - 0.5) * 2));
        }
      case StepPosition.middle:
        final midX = (prev.dx + curr.dx) / 2;
        if (localT < 0.25) {
          return Offset(lerpDouble(prev.dx, midX, localT * 4), prev.dy);
        } else if (localT < 0.75) {
          return Offset(midX, lerpDouble(prev.dy, curr.dy, (localT - 0.25) * 2));
        } else {
          return Offset(lerpDouble(midX, curr.dx, (localT - 0.75) * 4), curr.dy);
        }
    }
  }
}

/// Utility function for linear interpolation.
double lerpDouble(double a, double b, double t) => a + (b - a) * t;
