import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single box plot item showing five-number summary.
@immutable
class BoxPlotItem {
  const BoxPlotItem({
    required this.label,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    this.outliers,
    this.mean,
    this.color,
  });

  /// Create from raw data values.
  factory BoxPlotItem.fromValues({
    required String label,
    required List<double> values,
    double whiskerExtent = 1.5,
    Color? color,
  }) {
    if (values.isEmpty) {
      return BoxPlotItem(
        label: label,
        min: 0,
        q1: 0,
        median: 0,
        q3: 0,
        max: 0,
        color: color,
      );
    }

    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;

    final q1 = _percentile(sorted, 0.25);
    final median = _percentile(sorted, 0.5);
    final q3 = _percentile(sorted, 0.75);
    final iqr = q3 - q1;

    // Calculate whisker bounds
    final lowerFence = q1 - whiskerExtent * iqr;
    final upperFence = q3 + whiskerExtent * iqr;

    // Find actual min/max within fences
    final minInFence = sorted.firstWhere((v) => v >= lowerFence, orElse: () => sorted.first);
    final maxInFence = sorted.lastWhere((v) => v <= upperFence, orElse: () => sorted.last);

    // Find outliers
    final outliers = sorted.where((v) => v < lowerFence || v > upperFence).toList();

    // Calculate mean
    final mean = sorted.reduce((a, b) => a + b) / n;

    return BoxPlotItem(
      label: label,
      min: minInFence,
      q1: q1,
      median: median,
      q3: q3,
      max: maxInFence,
      outliers: outliers.isEmpty ? null : outliers,
      mean: mean,
      color: color,
    );
  }

  /// Label for this box plot.
  final String label;

  /// Minimum value (whisker end).
  final double min;

  /// First quartile (25th percentile).
  final double q1;

  /// Median (50th percentile).
  final double median;

  /// Third quartile (75th percentile).
  final double q3;

  /// Maximum value (whisker end).
  final double max;

  /// Optional list of outlier values.
  final List<double>? outliers;

  /// Optional mean value.
  final double? mean;

  /// Custom color for this box.
  final Color? color;

  /// Interquartile range (Q3 - Q1).
  double get iqr => q3 - q1;

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first;

    final index = p * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) return sorted[lower];

    final fraction = index - lower;
    return sorted[lower] * (1 - fraction) + sorted[upper] * fraction;
  }
}

/// Orientation for box plot.
enum BoxPlotOrientation {
  /// Vertical boxes (default).
  vertical,

  /// Horizontal boxes.
  horizontal,
}

/// Data configuration for box plot chart.
@immutable
class BoxPlotChartData {
  const BoxPlotChartData({
    required this.items,
    this.orientation = BoxPlotOrientation.vertical,
    this.boxWidth = 0.6,
    this.whiskerWidth = 0.4,
    this.strokeWidth = 1.5,
    this.showOutliers = true,
    this.outlierRadius = 4,
    this.showMean = false,
    this.meanMarkerSize = 6,
    this.showNotch = false,
    this.notchWidth = 0.3,
    this.fillOpacity = 0.3,
    this.animation,
  });

  /// List of box plot items.
  final List<BoxPlotItem> items;

  /// Orientation of the boxes.
  final BoxPlotOrientation orientation;

  /// Width of the box as ratio of available space.
  final double boxWidth;

  /// Width of whiskers as ratio of box width.
  final double whiskerWidth;

  /// Stroke width for outlines.
  final double strokeWidth;

  /// Whether to show outlier points.
  final bool showOutliers;

  /// Radius of outlier markers.
  final double outlierRadius;

  /// Whether to show mean marker.
  final bool showMean;

  /// Size of mean marker.
  final double meanMarkerSize;

  /// Whether to show notched boxes.
  final bool showNotch;

  /// Width of notch as ratio of box width.
  final double notchWidth;

  /// Opacity of box fill.
  final double fillOpacity;

  /// Animation configuration.
  final ChartAnimation? animation;
}
