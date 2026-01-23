import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single slope item showing change between two time points.
@immutable
class SlopeItem {
  const SlopeItem({
    required this.label,
    required this.startValue,
    required this.endValue,
    this.color,
  });

  /// Label for this item/series.
  final String label;

  /// Value at start time point.
  final double startValue;

  /// Value at end time point.
  final double endValue;

  /// Optional custom color.
  final Color? color;

  /// The change between start and end.
  double get change => endValue - startValue;

  /// Whether the change is positive.
  bool get isPositive => change >= 0;

  /// The percentage change.
  double get percentChange =>
      startValue != 0 ? (change / startValue) * 100 : 0;
}

/// Data configuration for slope chart.
@immutable
class SlopeChartData {
  const SlopeChartData({
    required this.items,
    this.startLabel = 'Start',
    this.endLabel = 'End',
    this.showLabels = true,
    this.showValues = true,
    this.showChange = false,
    this.lineWidth = 2.0,
    this.markerSize = 8.0,
    this.labelWidth = 80.0,
    this.minValue,
    this.maxValue,
    this.animation,
  });

  /// List of slope items.
  final List<SlopeItem> items;

  /// Label for start column.
  final String startLabel;

  /// Label for end column.
  final String endLabel;

  /// Whether to show item labels at endpoints.
  final bool showLabels;

  /// Whether to show values at endpoints.
  final bool showValues;

  /// Whether to show change indicator.
  final bool showChange;

  /// Width of connecting lines.
  final double lineWidth;

  /// Size of endpoint markers.
  final double markerSize;

  /// Width reserved for labels on each side.
  final double labelWidth;

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
