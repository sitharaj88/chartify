import 'package:flutter/material.dart';

/// Type of sparkline visualization.
enum SparklineType {
  /// Simple line chart.
  line,

  /// Line chart with filled area below.
  area,

  /// Bar chart style.
  bar,

  /// Win/loss chart showing positive/negative as up/down bars.
  winLoss,
}

/// Reference line type for sparkline.
enum SparklineReferenceType {
  /// No reference line.
  none,

  /// Reference line at minimum value.
  min,

  /// Reference line at maximum value.
  max,

  /// Reference line at average value.
  average,

  /// Reference line at first value.
  first,

  /// Reference line at last value.
  last,

  /// Reference line at zero.
  zero,
}

/// Marker configuration for sparkline endpoints.
@immutable
class SparklineMarker {
  const SparklineMarker({
    this.show = true,
    this.radius = 3.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Whether to show the marker.
  final bool show;

  /// Radius of the marker.
  final double radius;

  /// Fill color of the marker (uses line color if null).
  final Color? color;

  /// Border color of the marker.
  final Color? borderColor;

  /// Border width of the marker.
  final double borderWidth;
}

/// Data configuration for sparkline chart.
@immutable
class SparklineChartData {
  const SparklineChartData({
    required this.values,
    this.type = SparklineType.line,
    this.color,
    this.negativeColor,
    this.lineWidth = 2.0,
    this.areaOpacity = 0.2,
    this.barWidth,
    this.barSpacing = 1.0,
    this.showFirstMarker = false,
    this.showLastMarker = true,
    this.showMinMarker = false,
    this.showMaxMarker = false,
    this.firstMarker = const SparklineMarker(),
    this.lastMarker = const SparklineMarker(),
    this.minMarker = const SparklineMarker(color: Colors.red),
    this.maxMarker = const SparklineMarker(color: Colors.green),
    this.referenceLineType = SparklineReferenceType.none,
    this.referenceLineColor,
    this.referenceLineWidth = 1.0,
    this.referenceLineDash = const [4, 4],
    this.curved = true,
    this.clipToZero = false,
  });

  /// The data values to display.
  final List<double> values;

  /// Type of sparkline visualization.
  final SparklineType type;

  /// Primary color for positive values/line.
  final Color? color;

  /// Color for negative values (win/loss and bar types).
  final Color? negativeColor;

  /// Width of the line (for line and area types).
  final double lineWidth;

  /// Opacity of the area fill (for area type).
  final double areaOpacity;

  /// Width of each bar (auto-calculated if null).
  final double? barWidth;

  /// Spacing between bars.
  final double barSpacing;

  /// Whether to show marker at first point.
  final bool showFirstMarker;

  /// Whether to show marker at last point.
  final bool showLastMarker;

  /// Whether to show marker at minimum value.
  final bool showMinMarker;

  /// Whether to show marker at maximum value.
  final bool showMaxMarker;

  /// Marker configuration for first point.
  final SparklineMarker firstMarker;

  /// Marker configuration for last point.
  final SparklineMarker lastMarker;

  /// Marker configuration for minimum point.
  final SparklineMarker minMarker;

  /// Marker configuration for maximum point.
  final SparklineMarker maxMarker;

  /// Type of reference line to show.
  final SparklineReferenceType referenceLineType;

  /// Color of the reference line.
  final Color? referenceLineColor;

  /// Width of the reference line.
  final double referenceLineWidth;

  /// Dash pattern for reference line.
  final List<double> referenceLineDash;

  /// Whether to use curved line (for line and area types).
  final bool curved;

  /// Whether to clip the area to zero (for area type with negative values).
  final bool clipToZero;

  /// Get the minimum value in the data.
  double get minValue => values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);

  /// Get the maximum value in the data.
  double get maxValue => values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

  /// Get the average value in the data.
  double get averageValue =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  /// Get the reference value based on type.
  double? get referenceValue {
    if (values.isEmpty) return null;
    switch (referenceLineType) {
      case SparklineReferenceType.none:
        return null;
      case SparklineReferenceType.min:
        return minValue;
      case SparklineReferenceType.max:
        return maxValue;
      case SparklineReferenceType.average:
        return averageValue;
      case SparklineReferenceType.first:
        return values.first;
      case SparklineReferenceType.last:
        return values.last;
      case SparklineReferenceType.zero:
        return 0;
    }
  }

  /// Get the index of the minimum value.
  int get minIndex {
    if (values.isEmpty) return -1;
    var minIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] < values[minIdx]) minIdx = i;
    }
    return minIdx;
  }

  /// Get the index of the maximum value.
  int get maxIndex {
    if (values.isEmpty) return -1;
    var maxIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    return maxIdx;
  }
}
