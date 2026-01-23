import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Orientation for bullet chart.
enum BulletOrientation {
  /// Horizontal bars (left to right).
  horizontal,

  /// Vertical bars (bottom to top).
  vertical,
}

/// A single bullet item with value, target, and ranges.
@immutable
class BulletItem {
  const BulletItem({
    required this.label,
    required this.value,
    this.target,
    this.ranges = const [],
    this.max,
    this.color,
  });

  /// Label for this bullet.
  final String label;

  /// Current value (featured measure).
  final double value;

  /// Target value (comparative measure).
  final double? target;

  /// Range thresholds for background bands.
  /// Should be in ascending order, e.g., [30, 60, 100] for poor/average/good.
  final List<double> ranges;

  /// Maximum value (uses max of ranges or value if not specified).
  final double? max;

  /// Custom color for the value bar.
  final Color? color;

  /// Computed maximum value.
  double get computedMax {
    if (max != null) return max!;
    if (ranges.isNotEmpty) return ranges.last;
    return value * 1.2;
  }
}

/// Data configuration for bullet chart.
@immutable
class BulletChartData {
  const BulletChartData({
    required this.items,
    this.orientation = BulletOrientation.horizontal,
    this.rangeColors,
    this.valueColor,
    this.targetColor,
    this.targetWidth = 3.0,
    this.valueHeight = 0.4,
    this.spacing = 16.0,
    this.showLabels = true,
    this.showValues = true,
    this.labelWidth = 80.0,
    this.animation,
  });

  /// List of bullet items to display.
  final List<BulletItem> items;

  /// Orientation of the bullets.
  final BulletOrientation orientation;

  /// Colors for range bands (from poor to good).
  /// Defaults to shades of gray if not specified.
  final List<Color>? rangeColors;

  /// Color for the value bar.
  final Color? valueColor;

  /// Color for the target marker.
  final Color? targetColor;

  /// Width of the target marker line.
  final double targetWidth;

  /// Height of the value bar as ratio of bullet height (0-1).
  final double valueHeight;

  /// Spacing between bullet items.
  final double spacing;

  /// Whether to show labels.
  final bool showLabels;

  /// Whether to show value text.
  final bool showValues;

  /// Width reserved for labels (horizontal) or height (vertical).
  final double labelWidth;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Default range colors (shades from dark to light).
  static const defaultRangeColors = [
    Color(0xFFD1D5DB), // Light gray (good)
    Color(0xFF9CA3AF), // Medium gray
    Color(0xFF6B7280), // Dark gray (poor)
  ];
}
