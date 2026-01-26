import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single section in the pyramid chart.
@immutable
class PyramidSection {
  const PyramidSection({
    required this.label,
    required this.value,
    this.color,
  });

  /// Label for this section.
  final String label;

  /// Value for this section.
  final double value;

  /// Custom color for this section.
  final Color? color;
}

/// Mode for pyramid section sizing.
enum PyramidMode {
  /// Section heights proportional to values.
  proportional,

  /// All sections have equal height.
  equalHeight,
}

/// Data configuration for pyramid chart.
@immutable
class PyramidChartData {
  const PyramidChartData({
    required this.sections,
    this.mode = PyramidMode.proportional,
    this.gap = 2,
    this.showLabels = true,
    this.labelPosition = PyramidLabelPosition.right,
    this.showValues = true,
    this.animation,
  });

  /// List of pyramid sections (from top/smallest to bottom/largest).
  final List<PyramidSection> sections;

  /// Mode for section sizing.
  final PyramidMode mode;

  /// Gap between sections.
  final double gap;

  /// Whether to show labels.
  final bool showLabels;

  /// Position of labels.
  final PyramidLabelPosition labelPosition;

  /// Whether to show values.
  final bool showValues;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get total value of all sections.
  double get totalValue => sections.fold(0, (sum, s) => sum + s.value);
}

/// Position of labels in pyramid chart.
enum PyramidLabelPosition {
  /// Labels on the left side.
  left,

  /// Labels on the right side.
  right,

  /// Labels inside the sections.
  inside,
}
