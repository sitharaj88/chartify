import 'package:flutter/material.dart';

import '../../../core/base/series.dart';
import '../../../core/data/data_point.dart';

/// A data series for bar charts.
class BarSeries<X, Y extends num> extends ChartSeries<DataPoint<X, Y>> {
  const BarSeries({
    required super.data, super.name,
    super.color,
    super.visible,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(4)),
    this.gradient,
  });

  /// Border color for the bars.
  final Color? borderColor;

  /// Border width for the bars.
  final double borderWidth;

  /// Border radius for the bars.
  final BorderRadius borderRadius;

  /// Optional gradient fill for the bars.
  final Gradient? gradient;

  /// Creates a BarSeries from a list of values with auto-generated x values.
  static BarSeries<int, Y> fromValues<Y extends num>({
    required List<Y> values, String? name,
    Color? color,
    bool visible = true,
    Color? borderColor,
    double borderWidth = 0,
    BorderRadius borderRadius = const BorderRadius.vertical(top: Radius.circular(4)),
    Gradient? gradient,
  }) {
    final data = <DataPoint<int, Y>>[];
    for (var i = 0; i < values.length; i++) {
      data.add(DataPoint(x: i, y: values[i]));
    }
    return BarSeries<int, Y>(
      name: name,
      data: data,
      color: color,
      visible: visible,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      gradient: gradient,
    );
  }

  @override
  BarSeries<X, Y> copyWith({
    String? name,
    List<DataPoint<X, Y>>? data,
    Color? color,
    bool? visible,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) => BarSeries<X, Y>(
      name: name ?? this.name,
      data: data ?? this.data,
      color: color ?? this.color,
      visible: visible ?? this.visible,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      gradient: gradient ?? this.gradient,
    );
}

/// Configuration for bar positioning and sizing.
enum BarGrouping {
  /// Bars are grouped side by side.
  grouped,

  /// Bars are stacked on top of each other.
  stacked,

  /// Bars are stacked to show percentage (100% stacked).
  percentStacked,
}

/// Direction of the bars.
enum BarDirection {
  /// Vertical bars (default).
  vertical,

  /// Horizontal bars.
  horizontal,
}
