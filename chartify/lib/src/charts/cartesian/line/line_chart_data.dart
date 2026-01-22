import 'package:flutter/foundation.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/base/series.dart';
import 'line_series.dart';

/// Data configuration for line charts.
///
/// Example:
/// ```dart
/// LineChartData(
///   series: [
///     LineSeries(
///       name: 'Sales',
///       data: salesData,
///       color: Colors.blue,
///     ),
///     LineSeries(
///       name: 'Costs',
///       data: costsData,
///       color: Colors.red,
///     ),
///   ],
///   xAxis: AxisConfig(
///     label: 'Month',
///     type: AxisType.category,
///   ),
///   yAxis: AxisConfig(
///     label: 'Amount (\$)',
///     min: 0,
///   ),
/// )
/// ```
@immutable
class LineChartData extends CartesianChartData {
  /// Creates line chart data.
  const LineChartData({
    required this.series,
    super.animation,
    super.title,
    super.subtitle,
    super.xAxis,
    super.yAxis,
    super.secondaryYAxis,
    super.gridStyle,
    super.clipBehavior,
    this.showLegend = false,
    this.legendPosition = LegendPosition.bottom,
    this.crosshairEnabled = false,
    this.tooltipEnabled = true,
  });

  /// The line series to display.
  final List<LineSeries<dynamic, num>> series;

  /// Whether to show the legend.
  final bool showLegend;

  /// Position of the legend.
  final LegendPosition legendPosition;

  /// Whether to show a crosshair on hover/touch.
  final bool crosshairEnabled;

  /// Whether to show tooltips.
  final bool tooltipEnabled;

  @override
  List<ChartSeries<dynamic>> get allSeries => series;

  @override
  LineChartData copyWith({
    List<LineSeries<dynamic, num>>? series,
    ChartAnimation? animation,
    String? title,
    String? subtitle,
    AxisConfig? xAxis,
    AxisConfig? yAxis,
    AxisConfig? secondaryYAxis,
    GridStyle? gridStyle,
    bool? clipBehavior,
    bool? showLegend,
    LegendPosition? legendPosition,
    bool? crosshairEnabled,
    bool? tooltipEnabled,
  }) =>
      LineChartData(
        series: series ?? this.series,
        animation: animation ?? this.animation,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        xAxis: xAxis ?? this.xAxis,
        yAxis: yAxis ?? this.yAxis,
        secondaryYAxis: secondaryYAxis ?? this.secondaryYAxis,
        gridStyle: gridStyle ?? this.gridStyle,
        clipBehavior: clipBehavior ?? this.clipBehavior,
        showLegend: showLegend ?? this.showLegend,
        legendPosition: legendPosition ?? this.legendPosition,
        crosshairEnabled: crosshairEnabled ?? this.crosshairEnabled,
        tooltipEnabled: tooltipEnabled ?? this.tooltipEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineChartData &&
          runtimeType == other.runtimeType &&
          listEquals(series, other.series) &&
          animation == other.animation &&
          title == other.title &&
          subtitle == other.subtitle &&
          xAxis == other.xAxis &&
          yAxis == other.yAxis &&
          secondaryYAxis == other.secondaryYAxis &&
          gridStyle == other.gridStyle &&
          clipBehavior == other.clipBehavior &&
          showLegend == other.showLegend &&
          legendPosition == other.legendPosition &&
          crosshairEnabled == other.crosshairEnabled &&
          tooltipEnabled == other.tooltipEnabled;

  @override
  int get hashCode => Object.hash(
        series,
        animation,
        title,
        subtitle,
        xAxis,
        yAxis,
        secondaryYAxis,
        gridStyle,
        clipBehavior,
        showLegend,
        legendPosition,
        crosshairEnabled,
        tooltipEnabled,
      );
}

/// Legend positions.
enum LegendPosition {
  /// Legend at the top of the chart.
  top,

  /// Legend at the bottom of the chart.
  bottom,

  /// Legend on the left side of the chart.
  left,

  /// Legend on the right side of the chart.
  right,
}
