import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single segment in the rose chart.
@immutable
class RoseSegment {
  const RoseSegment({
    required this.label,
    required this.value,
    this.color,
  });

  /// Label for this segment.
  final String label;

  /// Value of this segment.
  final double value;

  /// Optional custom color.
  final Color? color;
}

/// Data configuration for rose/polar chart.
@immutable
class RoseChartData {
  const RoseChartData({
    required this.segments,
    this.innerRadius = 0.0,
    this.startAngle = -math.pi / 2,
    this.gap = 2.0,
    this.showLabels = true,
    this.showValues = false,
    this.maxValue,
    this.animation,
  });

  /// List of segments.
  final List<RoseSegment> segments;

  /// Inner radius (0.0 for full circle, >0 for donut style).
  final double innerRadius;

  /// Start angle in radians (default: top, -pi/2).
  final double startAngle;

  /// Gap between segments in degrees.
  final double gap;

  /// Whether to show labels.
  final bool showLabels;

  /// Whether to show values on segments.
  final bool showValues;

  /// Maximum value for scale (auto-calculated if null).
  final double? maxValue;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get gap in radians.
  double get gapRadians => gap * math.pi / 180;

  /// Calculate maximum value from data.
  double get computedMaxValue {
    if (maxValue != null) return maxValue!;
    if (segments.isEmpty) return 100;
    return segments.map((s) => s.value).reduce((a, b) => a > b ? a : b);
  }
}
