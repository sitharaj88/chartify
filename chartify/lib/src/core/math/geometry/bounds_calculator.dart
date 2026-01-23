import 'dart:math' as math;

/// Represents bounds with min and max values.
class Bounds {
  const Bounds({
    required this.min,
    required this.max,
  });

  /// Creates bounds from a list of values.
  factory Bounds.fromValues(Iterable<double> values) {
    if (values.isEmpty) return const Bounds(min: 0, max: 1);

    var min = double.infinity;
    var max = double.negativeInfinity;

    for (final value in values) {
      if (value.isFinite) {
        if (value < min) min = value;
        if (value > max) max = value;
      }
    }

    if (min.isInfinite || max.isInfinite) {
      return const Bounds(min: 0, max: 1);
    }

    return Bounds(min: min, max: max);
  }

  /// Creates bounds that include zero.
  factory Bounds.includingZero(Bounds bounds) {
    return Bounds(
      min: math.min(bounds.min, 0),
      max: math.max(bounds.max, 0),
    );
  }

  /// The minimum value.
  final double min;

  /// The maximum value.
  final double max;

  /// The range (max - min).
  double get range => max - min;

  /// The center value.
  double get center => (min + max) / 2;

  /// Whether the bounds contain the value.
  bool contains(double value) => value >= min && value <= max;

  /// Returns bounds expanded by padding percentage.
  Bounds withPadding(double padding) {
    final paddingAmount = range * padding;
    return Bounds(
      min: min - paddingAmount,
      max: max + paddingAmount,
    );
  }

  /// Returns bounds with overridden min/max if provided.
  Bounds withOverrides({double? minOverride, double? maxOverride}) {
    return Bounds(
      min: minOverride ?? min,
      max: maxOverride ?? max,
    );
  }

  /// Returns nice rounded bounds suitable for chart axes.
  Bounds nice({int tickCount = 10}) {
    if (range == 0) {
      return Bounds(min: min - 1, max: max + 1);
    }

    final step = _niceStep(range / tickCount);
    return Bounds(
      min: (min / step).floor() * step,
      max: (max / step).ceil() * step,
    );
  }

  /// Merges with another bounds.
  Bounds merge(Bounds other) {
    return Bounds(
      min: math.min(min, other.min),
      max: math.max(max, other.max),
    );
  }

  /// Returns the union of multiple bounds.
  static Bounds union(Iterable<Bounds> bounds) {
    if (bounds.isEmpty) return const Bounds(min: 0, max: 1);

    var result = bounds.first;
    for (final b in bounds.skip(1)) {
      result = result.merge(b);
    }
    return result;
  }

  /// Calculates a nice step value.
  static double _niceStep(double rawStep) {
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor());
    final residual = rawStep / magnitude;

    double niceResidual;
    if (residual <= 1.0) {
      niceResidual = 1.0;
    } else if (residual <= 2.0) {
      niceResidual = 2.0;
    } else if (residual <= 5.0) {
      niceResidual = 5.0;
    } else {
      niceResidual = 10.0;
    }

    return niceResidual * magnitude;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bounds && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'Bounds($min, $max)';
}

/// Calculates bounds for chart data.
class BoundsCalculator {
  /// Calculates X and Y bounds from data points.
  static (Bounds, Bounds) calculateFromPoints<X, Y extends num>(
    List<({X x, Y y})> points, {
    double Function(X)? xMapper,
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    double padding = 0.0,
    bool includeZero = false,
  }) {
    if (points.isEmpty) {
      return (
        const Bounds(min: 0, max: 1),
        const Bounds(min: 0, max: 1),
      );
    }

    final xValues = <double>[];
    final yValues = <double>[];

    for (final point in points) {
      final xValue = xMapper != null ? xMapper(point.x) : (point.x as num).toDouble();
      xValues.add(xValue);
      yValues.add(point.y.toDouble());
    }

    var xBounds = Bounds.fromValues(xValues);
    var yBounds = Bounds.fromValues(yValues);

    if (includeZero) {
      yBounds = Bounds.includingZero(yBounds);
    }

    if (padding > 0) {
      xBounds = xBounds.withPadding(padding);
      yBounds = yBounds.withPadding(padding);
    }

    xBounds = xBounds.withOverrides(minOverride: xMin, maxOverride: xMax);
    yBounds = yBounds.withOverrides(minOverride: yMin, maxOverride: yMax);

    return (xBounds, yBounds);
  }

  /// Calculates bounds from a flat list of values.
  static Bounds calculateFromValues(
    Iterable<double> values, {
    double? min,
    double? max,
    double padding = 0.0,
    bool includeZero = false,
    bool nice = false,
    int niceTickCount = 10,
  }) {
    var bounds = Bounds.fromValues(values);

    if (includeZero) {
      bounds = Bounds.includingZero(bounds);
    }

    if (padding > 0) {
      bounds = bounds.withPadding(padding);
    }

    bounds = bounds.withOverrides(minOverride: min, maxOverride: max);

    if (nice) {
      bounds = bounds.nice(tickCount: niceTickCount);
    }

    return bounds;
  }

  /// Calculates bounds from multiple series.
  static (Bounds, Bounds) calculateFromMultipleSeries<X, Y extends num>(
    List<List<({X x, Y y})>> seriesList, {
    double Function(X)? xMapper,
    double? xMin,
    double? xMax,
    double? yMin,
    double? yMax,
    double padding = 0.0,
    bool includeZero = false,
  }) {
    if (seriesList.isEmpty || seriesList.every((s) => s.isEmpty)) {
      return (
        const Bounds(min: 0, max: 1),
        const Bounds(min: 0, max: 1),
      );
    }

    final allBounds = seriesList
        .where((s) => s.isNotEmpty)
        .map((s) => calculateFromPoints(s, xMapper: xMapper))
        .toList();

    var xBounds = Bounds.union(allBounds.map((b) => b.$1));
    var yBounds = Bounds.union(allBounds.map((b) => b.$2));

    if (includeZero) {
      yBounds = Bounds.includingZero(yBounds);
    }

    if (padding > 0) {
      xBounds = xBounds.withPadding(padding);
      yBounds = yBounds.withPadding(padding);
    }

    xBounds = xBounds.withOverrides(minOverride: xMin, maxOverride: xMax);
    yBounds = yBounds.withOverrides(minOverride: yMin, maxOverride: yMax);

    return (xBounds, yBounds);
  }

  /// Calculates stacked bounds (for stacked bar/area charts).
  static Bounds calculateStackedBounds(
    List<List<double>> stackedValues, {
    double? min,
    double? max,
    double padding = 0.0,
    bool includeZero = true,
  }) {
    if (stackedValues.isEmpty) return const Bounds(min: 0, max: 1);

    final sums = <double>[];
    final lengths = stackedValues.map((s) => s.length).toList();
    final maxLength = lengths.isEmpty ? 0 : lengths.reduce(math.max);

    for (var i = 0; i < maxLength; i++) {
      var positiveSum = 0.0;
      var negativeSum = 0.0;

      for (final series in stackedValues) {
        if (i < series.length) {
          final value = series[i];
          if (value >= 0) {
            positiveSum += value;
          } else {
            negativeSum += value;
          }
        }
      }

      sums.add(positiveSum);
      sums.add(negativeSum);
    }

    return calculateFromValues(
      sums,
      min: min,
      max: max,
      padding: padding,
      includeZero: includeZero,
    );
  }
}
