import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/base/series.dart';
import 'bar_series.dart';

/// Configuration for the bar chart's X axis.
class BarXAxisConfig {
  const BarXAxisConfig({
    this.categories,
    this.labelFormatter,
    this.showLabels = true,
    this.labelRotation = 0,
  });

  /// Category labels for the X axis.
  final List<String>? categories;

  /// Custom label formatter.
  final String Function(dynamic value)? labelFormatter;

  /// Whether to show labels.
  final bool showLabels;

  /// Rotation angle for labels in degrees.
  final double labelRotation;
}

/// Configuration for the bar chart's Y axis.
class BarYAxisConfig {
  const BarYAxisConfig({
    this.min,
    this.max,
    this.labelFormatter,
    this.showLabels = true,
    this.tickCount = 5,
  });

  /// Minimum value (auto if null).
  final double? min;

  /// Maximum value (auto if null).
  final double? max;

  /// Custom label formatter.
  final String Function(double value)? labelFormatter;

  /// Whether to show labels.
  final bool showLabels;

  /// Number of tick marks.
  final int tickCount;
}

/// Data configuration for a bar chart.
class BarChartData extends ChartData {
  const BarChartData({
    required this.series,
    this.xAxis = const BarXAxisConfig(),
    this.yAxis = const BarYAxisConfig(),
    this.grouping = BarGrouping.grouped,
    this.direction = BarDirection.vertical,
    this.barSpacing = 0.2,
    this.groupSpacing = 0.3,
    this.animation,
  });

  /// The bar series to display.
  final List<BarSeries> series;

  @override
  List<ChartSeries<dynamic>> get allSeries => series;

  /// X axis configuration.
  final BarXAxisConfig xAxis;

  /// Y axis configuration.
  final BarYAxisConfig yAxis;

  /// How multiple series are grouped.
  final BarGrouping grouping;

  /// Direction of the bars.
  final BarDirection direction;

  /// Spacing between bars within a group (0-1).
  final double barSpacing;

  /// Spacing between groups (0-1).
  final double groupSpacing;

  /// Animation configuration.
  @override
  final ChartAnimation? animation;

  @override
  BarChartData copyWith({
    List<BarSeries>? series,
    BarXAxisConfig? xAxis,
    BarYAxisConfig? yAxis,
    BarGrouping? grouping,
    BarDirection? direction,
    double? barSpacing,
    double? groupSpacing,
    ChartAnimation? animation,
    String? title,
    String? subtitle,
  }) => BarChartData(
      series: series ?? this.series,
      xAxis: xAxis ?? this.xAxis,
      yAxis: yAxis ?? this.yAxis,
      grouping: grouping ?? this.grouping,
      direction: direction ?? this.direction,
      barSpacing: barSpacing ?? this.barSpacing,
      groupSpacing: groupSpacing ?? this.groupSpacing,
      animation: animation ?? this.animation,
    );
}
