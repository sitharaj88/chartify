import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/data_point.dart';

/// Base class for all chart series.
///
/// A series represents a collection of data points that are visualized
/// together with consistent styling and behavior.
///
/// [T] is the type of data point in this series.
@immutable
abstract class ChartSeries<T> {
  /// Creates a chart series with the given data and styling options.
  const ChartSeries({
    required this.data,
    this.name,
    this.color,
    this.visible = true,
  });

  /// The data points in this series.
  final List<T> data;

  /// Optional name for this series (used in legends and tooltips).
  final String? name;

  /// The color for this series.
  ///
  /// If null, the chart will assign a color from its color palette.
  final Color? color;

  /// Whether this series is visible.
  final bool visible;

  /// The number of data points in this series.
  int get length => data.length;

  /// Returns true if this series has no data points.
  bool get isEmpty => data.isEmpty;

  /// Returns true if this series has data points.
  bool get isNotEmpty => data.isNotEmpty;

  /// Creates a copy of this series with the given values replaced.
  ChartSeries<T> copyWith({
    List<T>? data,
    String? name,
    Color? color,
    bool? visible,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSeries<T> &&
          runtimeType == other.runtimeType &&
          listEquals(data, other.data) &&
          name == other.name &&
          color == other.color &&
          visible == other.visible;

  @override
  int get hashCode => Object.hash(data, name, color, visible);
}

/// Base class for Cartesian chart series (line, bar, area, scatter).
@immutable
abstract class CartesianSeries<T extends DataPoint<dynamic, dynamic>>
    extends ChartSeries<T> {
  /// Creates a Cartesian series.
  const CartesianSeries({
    required super.data,
    super.name,
    super.color,
    super.visible,
    this.xAxisId,
    this.yAxisId,
  });

  /// The ID of the x-axis to use for this series.
  ///
  /// If null, the primary x-axis is used.
  final String? xAxisId;

  /// The ID of the y-axis to use for this series.
  ///
  /// If null, the primary y-axis is used.
  final String? yAxisId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CartesianSeries<T> &&
          xAxisId == other.xAxisId &&
          yAxisId == other.yAxisId;

  @override
  int get hashCode => Object.hash(super.hashCode, xAxisId, yAxisId);
}

/// Base class for circular chart series (pie, donut).
@immutable
abstract class CircularSeries<T> extends ChartSeries<T> {
  /// Creates a circular series.
  const CircularSeries({
    required super.data,
    super.name,
    super.color,
    super.visible,
    this.innerRadiusRatio = 0.0,
    this.startAngle = -90.0,
    this.endAngle = 270.0,
  });

  /// The ratio of inner radius to outer radius (0.0 to 1.0).
  ///
  /// A value of 0.0 creates a pie chart, values > 0 create a donut chart.
  final double innerRadiusRatio;

  /// The starting angle in degrees (0 = 3 o'clock, -90 = 12 o'clock).
  final double startAngle;

  /// The ending angle in degrees.
  final double endAngle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CircularSeries<T> &&
          innerRadiusRatio == other.innerRadiusRatio &&
          startAngle == other.startAngle &&
          endAngle == other.endAngle;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, innerRadiusRatio, startAngle, endAngle);
}

/// Base class for polar chart series (radar).
@immutable
abstract class PolarSeries<T extends DataPoint<dynamic, num>>
    extends ChartSeries<T> {
  /// Creates a polar series.
  const PolarSeries({
    required super.data,
    super.name,
    super.color,
    super.visible,
    this.fillOpacity = 0.3,
    this.strokeWidth = 2.0,
  });

  /// The fill opacity for the area (0.0 to 1.0).
  final double fillOpacity;

  /// The stroke width for the line.
  final double strokeWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PolarSeries<T> &&
          fillOpacity == other.fillOpacity &&
          strokeWidth == other.strokeWidth;

  @override
  int get hashCode => Object.hash(super.hashCode, fillOpacity, strokeWidth);
}

/// Represents a single section in a pie/donut chart.
@immutable
class PieSection {
  /// Creates a pie section.
  const PieSection({
    required this.value,
    this.label,
    this.color,
    this.explodeOffset = 0.0,
    this.metadata,
  });

  /// The value of this section.
  final double value;

  /// Optional label for this section.
  final String? label;

  /// Optional color for this section.
  final Color? color;

  /// The offset for exploded pie sections (0.0 = no explosion).
  final double explodeOffset;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a copy with the given values replaced.
  PieSection copyWith({
    double? value,
    String? label,
    Color? color,
    double? explodeOffset,
    Map<String, dynamic>? metadata,
  }) =>
      PieSection(
        value: value ?? this.value,
        label: label ?? this.label,
        color: color ?? this.color,
        explodeOffset: explodeOffset ?? this.explodeOffset,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieSection &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          explodeOffset == other.explodeOffset;

  @override
  int get hashCode => Object.hash(value, label, color, explodeOffset);

  @override
  String toString() => 'PieSection(value: $value, label: $label)';
}

/// Represents a gauge range segment.
@immutable
class GaugeRange {
  /// Creates a gauge range.
  const GaugeRange({
    required this.start,
    required this.end,
    this.color,
    this.label,
  });

  /// The start value of this range.
  final double start;

  /// The end value of this range.
  final double end;

  /// Optional color for this range.
  final Color? color;

  /// Optional label for this range.
  final String? label;

  /// Creates a copy with the given values replaced.
  GaugeRange copyWith({
    double? start,
    double? end,
    Color? color,
    String? label,
  }) =>
      GaugeRange(
        start: start ?? this.start,
        end: end ?? this.end,
        color: color ?? this.color,
        label: label ?? this.label,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaugeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          color == other.color &&
          label == other.label;

  @override
  int get hashCode => Object.hash(start, end, color, label);

  @override
  String toString() => 'GaugeRange($start - $end)';
}

/// Represents a funnel/pyramid section.
@immutable
class FunnelSection {
  /// Creates a funnel section.
  const FunnelSection({
    required this.value,
    required this.label,
    this.color,
    this.metadata,
  });

  /// The value of this section.
  final double value;

  /// The label for this section.
  final String label;

  /// Optional color for this section.
  final Color? color;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a copy with the given values replaced.
  FunnelSection copyWith({
    double? value,
    String? label,
    Color? color,
    Map<String, dynamic>? metadata,
  }) =>
      FunnelSection(
        value: value ?? this.value,
        label: label ?? this.label,
        color: color ?? this.color,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunnelSection &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          color == other.color;

  @override
  int get hashCode => Object.hash(value, label, color);

  @override
  String toString() => 'FunnelSection(value: $value, label: $label)';
}
