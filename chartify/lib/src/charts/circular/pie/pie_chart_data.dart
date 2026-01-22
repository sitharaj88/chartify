import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/base/series.dart';

/// A section in a pie/donut chart.
@immutable
class PieSection {
  const PieSection({
    required this.value,
    this.label,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.explodeOffset = 0,
  });

  /// The value of this section.
  final double value;

  /// Label for this section.
  final String? label;

  /// Color for this section (uses theme color if null).
  final Color? color;

  /// Border color.
  final Color? borderColor;

  /// Border width.
  final double borderWidth;

  /// Offset when exploded (in pixels).
  final double explodeOffset;

  PieSection copyWith({
    double? value,
    String? label,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    double? explodeOffset,
  }) {
    return PieSection(
      value: value ?? this.value,
      label: label ?? this.label,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      explodeOffset: explodeOffset ?? this.explodeOffset,
    );
  }
}

/// Data configuration for a pie chart.
class PieChartData extends ChartData {
  const PieChartData({
    required this.sections,
    this.startAngle = -90,
    this.holeRadius = 0,
    this.strokeWidth = 0,
    this.strokeColor,
    this.showLabels = true,
    this.labelPosition = PieLabelPosition.outside,
    this.labelStyle,
    this.animation,
  });

  /// The sections to display.
  final List<PieSection> sections;

  /// Starting angle in degrees (-90 = top).
  final double startAngle;

  /// Radius of the center hole (0 = full pie, >0 = donut).
  final double holeRadius;

  /// Stroke width between sections.
  final double strokeWidth;

  /// Stroke color between sections.
  final Color? strokeColor;

  /// Whether to show labels.
  final bool showLabels;

  /// Position of the labels.
  final PieLabelPosition labelPosition;

  /// Style for the labels.
  final TextStyle? labelStyle;

  /// Animation configuration.
  @override
  final ChartAnimation? animation;

  @override
  List<ChartSeries<dynamic>> get allSeries => const [];

  /// Total value of all sections.
  double get total => sections.fold(0, (sum, s) => sum + s.value);

  @override
  PieChartData copyWith({
    List<PieSection>? sections,
    double? startAngle,
    double? holeRadius,
    double? strokeWidth,
    Color? strokeColor,
    bool? showLabels,
    PieLabelPosition? labelPosition,
    TextStyle? labelStyle,
    ChartAnimation? animation,
    String? title,
    String? subtitle,
  }) {
    return PieChartData(
      sections: sections ?? this.sections,
      startAngle: startAngle ?? this.startAngle,
      holeRadius: holeRadius ?? this.holeRadius,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      showLabels: showLabels ?? this.showLabels,
      labelPosition: labelPosition ?? this.labelPosition,
      labelStyle: labelStyle ?? this.labelStyle,
      animation: animation ?? this.animation,
    );
  }
}

/// Position of pie chart labels.
enum PieLabelPosition {
  /// Labels inside the sections.
  inside,

  /// Labels outside with lines.
  outside,

  /// No labels (for legend only).
  none,
}
