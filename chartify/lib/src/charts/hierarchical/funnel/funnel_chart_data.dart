import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single section in the funnel chart.
@immutable
class FunnelSection {
  const FunnelSection({
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

/// Mode for funnel section sizing.
enum FunnelMode {
  /// Section heights proportional to values.
  proportional,

  /// All sections have equal height.
  equalHeight,
}

/// Orientation for funnel chart.
enum FunnelOrientation {
  /// Vertical funnel (wide at top, narrow at bottom).
  vertical,

  /// Horizontal funnel (wide at left, narrow at right).
  horizontal,
}

/// Data configuration for funnel chart.
@immutable
class FunnelChartData {
  const FunnelChartData({
    required this.sections,
    this.mode = FunnelMode.proportional,
    this.orientation = FunnelOrientation.vertical,
    this.neckWidth = 0.3,
    this.neckHeight = 0.2,
    this.gap = 2,
    this.showLabels = true,
    this.labelPosition = FunnelLabelPosition.right,
    this.showValues = true,
    this.showConversionRate = false,
    this.borderRadius = 0,
    this.animation,
  });

  /// List of funnel sections (from widest to narrowest).
  final List<FunnelSection> sections;

  /// Mode for section sizing.
  final FunnelMode mode;

  /// Orientation of the funnel.
  final FunnelOrientation orientation;

  /// Width of the neck as ratio of total width (0-1).
  final double neckWidth;

  /// Height of the neck section as ratio of total height (0-1).
  final double neckHeight;

  /// Gap between sections.
  final double gap;

  /// Whether to show labels.
  final bool showLabels;

  /// Position of labels.
  final FunnelLabelPosition labelPosition;

  /// Whether to show values.
  final bool showValues;

  /// Whether to show conversion rate between sections.
  final bool showConversionRate;

  /// Border radius for section corners.
  final double borderRadius;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get total value of all sections.
  double get totalValue => sections.fold(0, (sum, s) => sum + s.value);

  /// Calculate conversion rate between two indices.
  double conversionRate(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= sections.length) return 0;
    if (toIndex < 0 || toIndex >= sections.length) return 0;
    if (sections[fromIndex].value == 0) return 0;
    return sections[toIndex].value / sections[fromIndex].value * 100;
  }
}

/// Position of labels in funnel chart.
enum FunnelLabelPosition {
  /// Labels on the left side.
  left,

  /// Labels on the right side.
  right,

  /// Labels inside the sections.
  inside,
}
