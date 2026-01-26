import 'package:flutter/foundation.dart';

import '../../animation/chart_animation.dart';
import 'series.dart';

/// Base class for all chart data configurations.
///
/// Chart data contains all the information needed to render a chart,
/// including series data, axis configurations, and styling options.
@immutable
abstract class ChartData {
  /// Creates chart data.
  const ChartData({
    this.animation,
    this.title,
    this.subtitle,
  });

  /// Animation configuration for this chart.
  final ChartAnimation? animation;

  /// Optional chart title.
  final String? title;

  /// Optional chart subtitle.
  final String? subtitle;

  /// The series contained in this chart data.
  List<ChartSeries<dynamic>> get allSeries;

  /// Returns true if this chart data has no series or all series are empty.
  bool get isEmpty => allSeries.isEmpty || allSeries.every((s) => s.isEmpty);

  /// Returns true if this chart data has at least one non-empty series.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy of this chart data with the given values replaced.
  ChartData copyWith({
    ChartAnimation? animation,
    String? title,
    String? subtitle,
  });
}

/// Data configuration for Cartesian charts (line, bar, area, scatter).
@immutable
abstract class CartesianChartData extends ChartData {
  /// Creates Cartesian chart data.
  const CartesianChartData({
    super.animation,
    super.title,
    super.subtitle,
    this.xAxis,
    this.yAxis,
    this.secondaryYAxis,
    this.gridStyle,
    this.clipBehavior = true,
  });

  /// X-axis configuration.
  final AxisConfig? xAxis;

  /// Primary Y-axis configuration.
  final AxisConfig? yAxis;

  /// Optional secondary Y-axis configuration.
  final AxisConfig? secondaryYAxis;

  /// Grid styling configuration.
  final GridStyle? gridStyle;

  /// Whether to clip data outside the chart area.
  final bool clipBehavior;
}

/// Data configuration for circular charts (pie, donut).
@immutable
abstract class CircularChartData extends ChartData {
  /// Creates circular chart data.
  const CircularChartData({
    super.animation,
    super.title,
    super.subtitle,
    this.centerWidget,
    this.showLabels = true,
    this.labelPosition = LabelPosition.outside,
  });

  /// Optional widget to display in the center (for donut charts).
  final dynamic centerWidget; // Widget type avoided for pure dart file

  /// Whether to show labels on sections.
  final bool showLabels;

  /// Position of labels relative to sections.
  final LabelPosition labelPosition;
}

/// Data configuration for polar charts (radar).
@immutable
abstract class PolarChartData extends ChartData {
  /// Creates polar chart data.
  const PolarChartData({
    super.animation,
    super.title,
    super.subtitle,
    this.axisLabels = const [],
    this.maxValue,
    this.minValue = 0.0,
    this.tickCount = 5,
  });

  /// Labels for each axis in the radar chart.
  final List<String> axisLabels;

  /// Maximum value for the axes (auto-calculated if null).
  final double? maxValue;

  /// Minimum value for the axes.
  final double minValue;

  /// Number of tick marks on each axis.
  final int tickCount;
}

/// Axis configuration for Cartesian charts.
@immutable
class AxisConfig {
  /// Creates an axis configuration.
  const AxisConfig({
    this.id,
    this.type = AxisType.linear,
    this.label,
    this.min,
    this.max,
    this.interval,
    this.tickCount,
    this.showGridLines = true,
    this.showAxisLine = true,
    this.showLabels = true,
    this.showTicks = true,
    this.labelFormatter,
    this.labelRotation = 0,
    this.reversed = false,
    this.position,
  });

  /// Creates a linear axis configuration.
  factory AxisConfig.linear({
    String? id,
    String? label,
    double? min,
    double? max,
  }) =>
      AxisConfig(
        id: id,
        label: label,
        min: min,
        max: max,
      );

  /// Creates a logarithmic axis configuration.
  factory AxisConfig.logarithmic({
    String? id,
    String? label,
    double? min,
    double? max,
  }) =>
      AxisConfig(
        id: id,
        type: AxisType.logarithmic,
        label: label,
        min: min,
        max: max,
      );

  /// Creates a time axis configuration.
  factory AxisConfig.time({
    String? id,
    String? label,
    String Function(double value)? labelFormatter,
  }) =>
      AxisConfig(
        id: id,
        type: AxisType.time,
        label: label,
        labelFormatter: labelFormatter,
      );

  /// Creates a category axis configuration.
  factory AxisConfig.category({
    String? id,
    String? label,
  }) =>
      AxisConfig(
        id: id,
        type: AxisType.category,
        label: label,
      );

  /// Unique identifier for this axis (for multi-axis charts).
  final String? id;

  /// The type of axis scale.
  final AxisType type;

  /// Label for the axis.
  final String? label;

  /// Minimum value (auto-calculated if null).
  final double? min;

  /// Maximum value (auto-calculated if null).
  final double? max;

  /// Interval between tick marks.
  final double? interval;

  /// Number of tick marks (alternative to interval).
  final int? tickCount;

  /// Whether to show grid lines for this axis.
  final bool showGridLines;

  /// Whether to show the axis line.
  final bool showAxisLine;

  /// Whether to show axis labels.
  final bool showLabels;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Custom formatter for axis labels.
  final String Function(double value)? labelFormatter;

  /// Rotation angle for labels in degrees.
  final double labelRotation;

  /// Whether to reverse the axis direction.
  final bool reversed;

  /// Position of the axis (overrides default).
  final AxisPosition? position;

  /// Creates a copy with the given values replaced.
  AxisConfig copyWith({
    String? id,
    AxisType? type,
    String? label,
    double? min,
    double? max,
    double? interval,
    int? tickCount,
    bool? showGridLines,
    bool? showAxisLine,
    bool? showLabels,
    bool? showTicks,
    String Function(double value)? labelFormatter,
    double? labelRotation,
    bool? reversed,
    AxisPosition? position,
  }) =>
      AxisConfig(
        id: id ?? this.id,
        type: type ?? this.type,
        label: label ?? this.label,
        min: min ?? this.min,
        max: max ?? this.max,
        interval: interval ?? this.interval,
        tickCount: tickCount ?? this.tickCount,
        showGridLines: showGridLines ?? this.showGridLines,
        showAxisLine: showAxisLine ?? this.showAxisLine,
        showLabels: showLabels ?? this.showLabels,
        showTicks: showTicks ?? this.showTicks,
        labelFormatter: labelFormatter ?? this.labelFormatter,
        labelRotation: labelRotation ?? this.labelRotation,
        reversed: reversed ?? this.reversed,
        position: position ?? this.position,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          label == other.label &&
          min == other.min &&
          max == other.max &&
          interval == other.interval &&
          tickCount == other.tickCount &&
          showGridLines == other.showGridLines &&
          showAxisLine == other.showAxisLine &&
          showLabels == other.showLabels &&
          showTicks == other.showTicks &&
          labelRotation == other.labelRotation &&
          reversed == other.reversed &&
          position == other.position;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        label,
        min,
        max,
        interval,
        tickCount,
        showGridLines,
        showAxisLine,
        showLabels,
        showTicks,
        labelRotation,
        reversed,
        position,
      );
}

/// Grid style configuration.
@immutable
class GridStyle {
  /// Creates a grid style configuration.
  const GridStyle({
    this.showHorizontalLines = true,
    this.showVerticalLines = true,
    this.horizontalLineWidth = 1.0,
    this.verticalLineWidth = 1.0,
    this.horizontalDashPattern,
    this.verticalDashPattern,
  });

  /// Whether to show horizontal grid lines.
  final bool showHorizontalLines;

  /// Whether to show vertical grid lines.
  final bool showVerticalLines;

  /// Width of horizontal grid lines.
  final double horizontalLineWidth;

  /// Width of vertical grid lines.
  final double verticalLineWidth;

  /// Dash pattern for horizontal lines (null = solid).
  final List<double>? horizontalDashPattern;

  /// Dash pattern for vertical lines (null = solid).
  final List<double>? verticalDashPattern;

  /// Creates a copy with the given values replaced.
  GridStyle copyWith({
    bool? showHorizontalLines,
    bool? showVerticalLines,
    double? horizontalLineWidth,
    double? verticalLineWidth,
    List<double>? horizontalDashPattern,
    List<double>? verticalDashPattern,
  }) =>
      GridStyle(
        showHorizontalLines: showHorizontalLines ?? this.showHorizontalLines,
        showVerticalLines: showVerticalLines ?? this.showVerticalLines,
        horizontalLineWidth: horizontalLineWidth ?? this.horizontalLineWidth,
        verticalLineWidth: verticalLineWidth ?? this.verticalLineWidth,
        horizontalDashPattern:
            horizontalDashPattern ?? this.horizontalDashPattern,
        verticalDashPattern: verticalDashPattern ?? this.verticalDashPattern,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridStyle &&
          runtimeType == other.runtimeType &&
          showHorizontalLines == other.showHorizontalLines &&
          showVerticalLines == other.showVerticalLines &&
          horizontalLineWidth == other.horizontalLineWidth &&
          verticalLineWidth == other.verticalLineWidth &&
          listEquals(horizontalDashPattern, other.horizontalDashPattern) &&
          listEquals(verticalDashPattern, other.verticalDashPattern);

  @override
  int get hashCode => Object.hash(
        showHorizontalLines,
        showVerticalLines,
        horizontalLineWidth,
        verticalLineWidth,
        horizontalDashPattern,
        verticalDashPattern,
      );
}

/// Types of axis scales.
enum AxisType {
  /// Linear scale with evenly spaced values.
  linear,

  /// Logarithmic scale for exponential data.
  logarithmic,

  /// Time-based scale for date/time values.
  time,

  /// Categorical scale for discrete values.
  category,
}

/// Positions for axes.
enum AxisPosition {
  /// Left side of the chart (for Y-axis).
  left,

  /// Right side of the chart (for secondary Y-axis).
  right,

  /// Top of the chart (for X-axis).
  top,

  /// Bottom of the chart (for X-axis).
  bottom,
}

/// Positions for labels in circular charts.
enum LabelPosition {
  /// Labels inside the sections.
  inside,

  /// Labels outside the sections.
  outside,

  /// Labels connected with lines.
  connector,
}
