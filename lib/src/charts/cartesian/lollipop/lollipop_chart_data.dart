import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Orientation of the lollipop chart.
enum LollipopOrientation {
  /// Horizontal lollipops (default).
  horizontal,

  /// Vertical lollipops.
  vertical,
}

/// Shape of the lollipop marker.
enum LollipopMarkerShape {
  /// Circle marker.
  circle,

  /// Square marker.
  square,

  /// Diamond marker.
  diamond,

  /// Triangle marker.
  triangle,
}

/// A single lollipop item.
@immutable
class LollipopItem {
  const LollipopItem({
    required this.label,
    required this.value,
    this.color,
    this.markerShape,
  });

  /// Label for this item.
  final String label;

  /// Value of this item.
  final double value;

  /// Optional custom color.
  final Color? color;

  /// Optional custom marker shape.
  final LollipopMarkerShape? markerShape;
}

/// Data configuration for lollipop chart.
@immutable
class LollipopChartData {
  const LollipopChartData({
    required this.items,
    this.orientation = LollipopOrientation.horizontal,
    this.markerShape = LollipopMarkerShape.circle,
    this.markerSize = 12.0,
    this.stemWidth = 2.0,
    this.spacing = 8.0,
    this.showLabels = true,
    this.showValues = true,
    this.baselineValue = 0.0,
    this.minValue,
    this.maxValue,
    this.animation,
  });

  /// List of lollipop items.
  final List<LollipopItem> items;

  /// Orientation of the lollipops.
  final LollipopOrientation orientation;

  /// Default marker shape.
  final LollipopMarkerShape markerShape;

  /// Size of the marker.
  final double markerSize;

  /// Width of the stem line.
  final double stemWidth;

  /// Spacing between lollipops.
  final double spacing;

  /// Whether to show item labels.
  final bool showLabels;

  /// Whether to show values.
  final bool showValues;

  /// Baseline value for the stems.
  final double baselineValue;

  /// Minimum value for scale (auto-calculated if null).
  final double? minValue;

  /// Maximum value for scale (auto-calculated if null).
  final double? maxValue;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Calculate the value range.
  (double, double) calculateRange() {
    if (items.isEmpty) return (0, 100);

    final values = items.map((e) => e.value).toList()..add(baselineValue);
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    final min = minValue ?? dataMin;
    final max = maxValue ?? dataMax;

    final range = max - min;
    final padding = range * 0.1;

    return (min - padding, max + padding);
  }
}
