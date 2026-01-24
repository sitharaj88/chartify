import '../data/data_point.dart';
import '../errors/chart_error_boundary.dart';

/// Utilities for validating chart data to prevent rendering errors.
///
/// Provides methods to check for invalid values (NaN, infinity, null)
/// and either filter them out or throw descriptive errors.
class DataValidator {
  DataValidator._();

  /// Validates that a numeric value is finite (not NaN or infinity).
  ///
  /// Returns true if the value is valid, false otherwise.
  static bool isValidNumber(num? value) {
    if (value == null) return false;
    if (value is double && (value.isNaN || value.isInfinite)) return false;
    return true;
  }

  /// Validates a data point's numeric values.
  ///
  /// Returns true if both x and y values are valid numbers.
  static bool isValidDataPoint<X, Y>(DataPoint<X, Y> point) {
    // Check x value if numeric
    if (point.x is num && !isValidNumber(point.x as num)) {
      return false;
    }
    // Check y value if numeric
    if (point.y is num && !isValidNumber(point.y as num)) {
      return false;
    }
    return true;
  }

  /// Filters out invalid data points from a list.
  ///
  /// Returns a new list containing only valid data points.
  /// Invalid points (with NaN, infinity, or null numeric values) are removed.
  static List<DataPoint<X, Y>> filterValidPoints<X, Y>(
    List<DataPoint<X, Y>> points,
  ) =>
      points.where(isValidDataPoint).toList();

  /// Validates a list of data points and throws if any are invalid.
  ///
  /// Use this for strict validation that requires all points to be valid.
  /// Throws [InvalidChartDataException] with details about invalid points.
  static void validatePoints<X, Y>(
    List<DataPoint<X, Y>> points, {
    String? seriesName,
  }) {
    final invalidIndices = <int>[];

    for (var i = 0; i < points.length; i++) {
      if (!isValidDataPoint(points[i])) {
        invalidIndices.add(i);
      }
    }

    if (invalidIndices.isNotEmpty) {
      final prefix = seriesName != null ? 'Series "$seriesName": ' : '';
      throw InvalidChartDataException(
        '${prefix}Invalid data points at indices: ${invalidIndices.join(', ')}. '
        'Values must be finite numbers (not NaN or infinity).',
      );
    }
  }

  /// Clamps a value to a safe range for rendering.
  ///
  /// Replaces NaN with 0, and clamps infinity to the provided bounds.
  static double clampToSafeValue(
    double value, {
    double min = -1e10,
    double max = 1e10,
    double defaultValue = 0,
  }) {
    if (value.isNaN) return defaultValue;
    if (value.isInfinite) {
      return value.isNegative ? min : max;
    }
    return value.clamp(min, max);
  }

  /// Validates bounds (min/max range) for chart axes.
  ///
  /// Ensures min < max and both are finite values.
  /// Returns validated bounds or throws [InvalidChartConfigException].
  static (double, double) validateBounds(
    double min,
    double max, {
    String? axisName,
  }) {
    if (!isValidNumber(min) || !isValidNumber(max)) {
      throw InvalidChartConfigException(
        '${axisName ?? 'Axis'} bounds contain invalid values: min=$min, max=$max',
      );
    }

    if (min >= max) {
      // Auto-adjust if min equals or exceeds max
      if (min == max) {
        return (min - 1, max + 1);
      }
      throw InvalidChartConfigException(
        '${axisName ?? 'Axis'} min ($min) must be less than max ($max)',
      );
    }

    return (min, max);
  }

  /// Checks if a list of data points is empty or all invalid.
  ///
  /// Returns true if there's at least one valid data point.
  static bool hasValidData<X, Y>(List<DataPoint<X, Y>> points) {
    if (points.isEmpty) return false;
    return points.any(isValidDataPoint);
  }

  /// Calculates safe bounds from a list of numeric values.
  ///
  /// Filters out invalid values and returns (min, max) tuple.
  /// Returns null if no valid values exist.
  static (double, double)? calculateSafeBounds(Iterable<num> values) {
    final validValues = values.where(isValidNumber).cast<num>().toList();

    if (validValues.isEmpty) return null;

    var min = validValues.first.toDouble();
    var max = min;

    for (final value in validValues.skip(1)) {
      final v = value.toDouble();
      if (v < min) min = v;
      if (v > max) max = v;
    }

    return (min, max);
  }
}

/// Extension methods for data point validation.
extension DataPointValidation<X, Y> on DataPoint<X, Y> {
  /// Whether this data point has valid numeric values.
  bool get isValid => DataValidator.isValidDataPoint(this);
}

/// Extension methods for list of data points.
extension DataPointListValidation<X, Y> on List<DataPoint<X, Y>> {
  /// Returns a new list with only valid data points.
  List<DataPoint<X, Y>> get validOnly => DataValidator.filterValidPoints(this);

  /// Whether this list has at least one valid data point.
  bool get hasValidData => DataValidator.hasValidData(this);

  /// Validates all points and throws if any are invalid.
  void validate({String? seriesName}) =>
      DataValidator.validatePoints(this, seriesName: seriesName);
}
