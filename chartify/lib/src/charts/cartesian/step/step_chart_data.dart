import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/data/data_point.dart';

/// Step type determining where the step occurs.
enum StepType {
  /// Step occurs before the point (horizontal first, then vertical).
  before,

  /// Step occurs after the point (vertical first, then horizontal).
  after,

  /// Step occurs at the midpoint between points.
  middle,
}

/// A series of data for the step chart.
@immutable
class StepSeries<X, Y extends num> {
  const StepSeries({
    required this.data,
    this.name,
    this.color,
    this.lineWidth = 2.0,
    this.showMarkers = true,
    this.markerRadius = 4.0,
    this.fillArea = false,
    this.fillColor,
    this.fillOpacity = 0.2,
  });

  /// Data points for this series.
  final List<DataPoint<X, Y>> data;

  /// Optional name for legend.
  final String? name;

  /// Color of the line.
  final Color? color;

  /// Width of the step line.
  final double lineWidth;

  /// Whether to show markers at data points.
  final bool showMarkers;

  /// Radius of markers.
  final double markerRadius;

  /// Whether to fill the area under the steps.
  final bool fillArea;

  /// Color for the filled area.
  final Color? fillColor;

  /// Opacity of the fill (0.0 to 1.0).
  final double fillOpacity;
}

/// Data configuration for step chart.
@immutable
class StepChartData<X, Y extends num> {
  const StepChartData({
    required this.series,
    this.stepType = StepType.after,
    this.showGrid = true,
    this.showXAxis = true,
    this.showYAxis = true,
    this.xAxisLabel,
    this.yAxisLabel,
    this.minY,
    this.maxY,
    this.animation,
  });

  /// List of data series.
  final List<StepSeries<X, Y>> series;

  /// Type of step transition.
  final StepType stepType;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Whether to show X axis.
  final bool showXAxis;

  /// Whether to show Y axis.
  final bool showYAxis;

  /// Label for X axis.
  final String? xAxisLabel;

  /// Label for Y axis.
  final String? yAxisLabel;

  /// Minimum Y value (auto-calculated if null).
  final Y? minY;

  /// Maximum Y value (auto-calculated if null).
  final Y? maxY;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get all data points from all series.
  List<DataPoint<X, Y>> get allPoints =>
      series.expand((s) => s.data).toList();

  /// Calculate Y range from data.
  (double, double) calculateYRange() {
    if (series.isEmpty) return (0, 100);

    final allY = allPoints.map((p) => p.y.toDouble()).toList();
    if (allY.isEmpty) return (0, 100);

    final dataMin = allY.reduce((a, b) => a < b ? a : b);
    final dataMax = allY.reduce((a, b) => a > b ? a : b);

    final min = minY?.toDouble() ?? dataMin;
    final max = maxY?.toDouble() ?? dataMax;

    // Add padding
    final range = max - min;
    final padding = range * 0.1;

    return (min - padding, max + padding);
  }
}
