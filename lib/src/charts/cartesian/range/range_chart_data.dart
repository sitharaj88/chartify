import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Orientation of the range chart.
enum RangeOrientation {
  /// Horizontal bars (default).
  horizontal,

  /// Vertical bars.
  vertical,
}

/// A single range item showing min/max values.
@immutable
class RangeItem {
  const RangeItem({
    required this.label,
    required this.min,
    required this.max,
    this.mid,
    this.color,
  });

  /// Label for this item.
  final String label;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Optional midpoint value (e.g., average).
  final double? mid;

  /// Optional custom color.
  final Color? color;

  /// The range span (max - min).
  double get range => max - min;
}

/// Data configuration for range chart.
@immutable
class RangeChartData {
  const RangeChartData({
    required this.items,
    this.orientation = RangeOrientation.horizontal,
    this.barWidth = 0.6,
    this.spacing = 8.0,
    this.showLabels = true,
    this.showValues = true,
    this.showMidMarker = true,
    this.midMarkerSize = 8.0,
    this.cornerRadius = 4.0,
    this.minValue,
    this.maxValue,
    this.animation,
  });

  /// List of range items.
  final List<RangeItem> items;

  /// Orientation of the bars.
  final RangeOrientation orientation;

  /// Width of bars as a fraction of available space (0.0 to 1.0).
  final double barWidth;

  /// Spacing between bars.
  final double spacing;

  /// Whether to show item labels.
  final bool showLabels;

  /// Whether to show min/max values on bars.
  final bool showValues;

  /// Whether to show midpoint marker.
  final bool showMidMarker;

  /// Size of the midpoint marker.
  final double midMarkerSize;

  /// Corner radius for bars.
  final double cornerRadius;

  /// Minimum value for scale (auto-calculated if null).
  final double? minValue;

  /// Maximum value for scale (auto-calculated if null).
  final double? maxValue;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Calculate the value range.
  (double, double) calculateRange() {
    if (items.isEmpty) return (0, 100);

    final allMin = items.map((e) => e.min).reduce((a, b) => a < b ? a : b);
    final allMax = items.map((e) => e.max).reduce((a, b) => a > b ? a : b);

    final min = minValue ?? allMin;
    final max = maxValue ?? allMax;

    final range = max - min;
    final padding = range * 0.1;

    return (min - padding, max + padding);
  }
}
