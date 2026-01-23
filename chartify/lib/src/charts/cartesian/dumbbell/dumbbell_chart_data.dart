import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Orientation of the dumbbell chart.
enum DumbbellOrientation {
  /// Horizontal dumbbells (default).
  horizontal,

  /// Vertical dumbbells.
  vertical,
}

/// A single dumbbell item showing two connected points.
@immutable
class DumbbellItem {
  const DumbbellItem({
    required this.label,
    required this.startValue,
    required this.endValue,
    this.startLabel,
    this.endLabel,
    this.startColor,
    this.endColor,
    this.connectorColor,
  });

  /// Label for this item.
  final String label;

  /// Start value (e.g., before, min, baseline).
  final double startValue;

  /// End value (e.g., after, max, current).
  final double endValue;

  /// Optional label for start point.
  final String? startLabel;

  /// Optional label for end point.
  final String? endLabel;

  /// Optional color for start marker.
  final Color? startColor;

  /// Optional color for end marker.
  final Color? endColor;

  /// Optional color for the connecting line.
  final Color? connectorColor;

  /// The difference between end and start.
  double get difference => endValue - startValue;

  /// Whether the change is positive.
  bool get isPositive => difference >= 0;
}

/// Data configuration for dumbbell chart.
@immutable
class DumbbellChartData {
  const DumbbellChartData({
    required this.items,
    this.orientation = DumbbellOrientation.horizontal,
    this.markerSize = 10.0,
    this.connectorWidth = 3.0,
    this.spacing = 8.0,
    this.showLabels = true,
    this.showValues = true,
    this.showDifference = false,
    this.startColor,
    this.endColor,
    this.positiveColor,
    this.negativeColor,
    this.minValue,
    this.maxValue,
    this.animation,
  });

  /// List of dumbbell items.
  final List<DumbbellItem> items;

  /// Orientation of the dumbbells.
  final DumbbellOrientation orientation;

  /// Size of the endpoint markers.
  final double markerSize;

  /// Width of the connecting line.
  final double connectorWidth;

  /// Spacing between dumbbells.
  final double spacing;

  /// Whether to show item labels.
  final bool showLabels;

  /// Whether to show values at endpoints.
  final bool showValues;

  /// Whether to show difference values.
  final bool showDifference;

  /// Default color for start markers.
  final Color? startColor;

  /// Default color for end markers.
  final Color? endColor;

  /// Color for positive changes.
  final Color? positiveColor;

  /// Color for negative changes.
  final Color? negativeColor;

  /// Minimum value for scale (auto-calculated if null).
  final double? minValue;

  /// Maximum value for scale (auto-calculated if null).
  final double? maxValue;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Calculate the value range.
  (double, double) calculateRange() {
    if (items.isEmpty) return (0, 100);

    final allValues = items.expand((e) => [e.startValue, e.endValue]).toList();
    final dataMin = allValues.reduce((a, b) => a < b ? a : b);
    final dataMax = allValues.reduce((a, b) => a > b ? a : b);

    final min = minValue ?? dataMin;
    final max = maxValue ?? dataMax;

    final range = max - min;
    final padding = range * 0.1;

    return (min - padding, max + padding);
  }
}
