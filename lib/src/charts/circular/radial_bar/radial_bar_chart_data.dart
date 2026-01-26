import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single bar item in the radial bar chart.
@immutable
class RadialBarItem {
  const RadialBarItem({
    required this.value,
    this.maxValue = 100,
    this.label,
    this.color,
    this.trackColor,
    this.thickness,
    this.gradient,
  });

  /// Current value of this bar.
  final double value;

  /// Maximum value for this bar (default 100).
  final double maxValue;

  /// Optional label for this bar.
  final String? label;

  /// Color for the progress arc.
  final Color? color;

  /// Color for the background track.
  final Color? trackColor;

  /// Thickness of this specific bar (overrides chart default).
  final double? thickness;

  /// Gradient for the progress arc (overrides color).
  final Gradient? gradient;

  /// Get the normalized value (0-1).
  double get normalizedValue => (value / maxValue).clamp(0.0, 1.0);

  /// Get the formatted percentage.
  String get percentageText => '${(normalizedValue * 100).toStringAsFixed(0)}%';
}

/// Label position for radial bar labels.
enum RadialBarLabelPosition {
  /// Label at the end of the bar arc.
  end,

  /// Label in the center of the chart.
  center,

  /// Label outside the bar.
  outside,
}

/// Data configuration for radial bar chart.
@immutable
class RadialBarChartData {
  const RadialBarChartData({
    required this.bars,
    this.startAngle = -90,
    this.maxAngle = 360,
    this.innerRadius = 0.3,
    this.thickness = 20,
    this.trackGap = 8,
    this.strokeCap = StrokeCap.round,
    this.showLabels = true,
    this.labelPosition = RadialBarLabelPosition.end,
    this.showTrack = true,
    this.trackOpacity = 0.2,
    this.animation,
  });

  /// List of radial bar items to display.
  final List<RadialBarItem> bars;

  /// Starting angle in degrees (-90 = top).
  final double startAngle;

  /// Maximum sweep angle in degrees.
  final double maxAngle;

  /// Inner radius as a ratio of the available radius (0-1).
  final double innerRadius;

  /// Default thickness of each bar.
  final double thickness;

  /// Gap between bars.
  final double trackGap;

  /// Cap style for bar ends.
  final StrokeCap strokeCap;

  /// Whether to show labels.
  final bool showLabels;

  /// Position of labels.
  final RadialBarLabelPosition labelPosition;

  /// Whether to show the background track.
  final bool showTrack;

  /// Opacity of the background track.
  final double trackOpacity;

  /// Animation configuration.
  final ChartAnimation? animation;
}
