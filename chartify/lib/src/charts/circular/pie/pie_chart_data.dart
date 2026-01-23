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
    this.gradient,
    this.shadowElevation = 4,
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

  /// Optional gradient fill for this section.
  final Gradient? gradient;

  /// Shadow elevation for this section (0 = no shadow).
  final double shadowElevation;

  PieSection copyWith({
    double? value,
    String? label,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    double? explodeOffset,
    Gradient? gradient,
    double? shadowElevation,
  }) {
    return PieSection(
      value: value ?? this.value,
      label: label ?? this.label,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      explodeOffset: explodeOffset ?? this.explodeOffset,
      gradient: gradient ?? this.gradient,
      shadowElevation: shadowElevation ?? this.shadowElevation,
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
    this.segmentGap = 2,
    this.cornerRadius = 0,
    this.enableShadows = true,
    this.hoverDuration = const Duration(milliseconds: 200),
    this.labelConnector = PieLabelConnector.straight,
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

  /// Gap between segments in pixels.
  final double segmentGap;

  /// Corner radius for rounded segment edges.
  final double cornerRadius;

  /// Whether to enable drop shadows on segments.
  final bool enableShadows;

  /// Duration for hover animations.
  final Duration hoverDuration;

  /// Style of label connector lines.
  final PieLabelConnector labelConnector;

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
    double? segmentGap,
    double? cornerRadius,
    bool? enableShadows,
    Duration? hoverDuration,
    PieLabelConnector? labelConnector,
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
      segmentGap: segmentGap ?? this.segmentGap,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      enableShadows: enableShadows ?? this.enableShadows,
      hoverDuration: hoverDuration ?? this.hoverDuration,
      labelConnector: labelConnector ?? this.labelConnector,
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

/// Style of label connector lines.
enum PieLabelConnector {
  /// Straight line from pie to label.
  straight,

  /// Modern L-shaped elbow connector.
  elbow,
}
