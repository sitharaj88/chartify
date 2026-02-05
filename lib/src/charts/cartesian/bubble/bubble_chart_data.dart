import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../core/base/chart_data.dart';
import '../../../core/data/data_point.dart';

/// Bubble size scaling method.
enum BubbleSizeScaling {
  /// Linear scaling - size is directly proportional to value.
  linear,

  /// Square root scaling - better for area perception.
  sqrt,

  /// Logarithmic scaling - for large value ranges.
  log,
}

/// Configuration for bubble sizing.
@immutable
class BubbleSizeConfig {
  const BubbleSizeConfig({
    this.minSize = 8.0,
    this.maxSize = 40.0,
    this.scaling = BubbleSizeScaling.sqrt,
  });

  /// Minimum bubble diameter.
  final double minSize;

  /// Maximum bubble diameter.
  final double maxSize;

  /// Scaling method for bubble sizes.
  final BubbleSizeScaling scaling;

  /// Calculate the display size for a given value within the range.
  double calculateSize(double value, double minValue, double maxValue) {
    if (minValue == maxValue) return (minSize + maxSize) / 2;

    double normalizedValue;
    switch (scaling) {
      case BubbleSizeScaling.linear:
        normalizedValue = (value - minValue) / (maxValue - minValue);
      case BubbleSizeScaling.sqrt:
        final sqrtMin = minValue >= 0 ? _sqrt(minValue) : -_sqrt(-minValue);
        final sqrtMax = maxValue >= 0 ? _sqrt(maxValue) : -_sqrt(-maxValue);
        final sqrtVal = value >= 0 ? _sqrt(value) : -_sqrt(-value);
        normalizedValue = (sqrtVal - sqrtMin) / (sqrtMax - sqrtMin);
      case BubbleSizeScaling.log:
        final logMin = minValue > 0 ? _log(minValue) : 0;
        final logMax = maxValue > 0 ? _log(maxValue) : 0;
        final logVal = value > 0 ? _log(value) : 0;
        normalizedValue = logMax == logMin ? 0.5 : (logVal - logMin) / (logMax - logMin);
    }

    return minSize + (maxSize - minSize) * normalizedValue.clamp(0, 1);
  }

  /// Computes the square root for bubble size scaling.
  double _sqrt(double x) => x >= 0 ? math.sqrt(x) : -math.sqrt(x.abs());

  /// Computes the natural logarithm for bubble size scaling.
  double _log(double x) => x > 0 ? math.log(x) : 0;
}

/// A data point for bubble charts.
class BubbleDataPoint<X, Y extends num> extends DataPoint<X, Y> {
  const BubbleDataPoint({
    required super.x,
    required super.y,
    required this.size,
    super.metadata,
    this.color,
    this.label,
  });

  /// Size value for this bubble.
  final double size;

  /// Custom color for this bubble.
  final Color? color;

  /// Label to display inside/near the bubble.
  final String? label;
}

/// A data series for bubble charts.
class BubbleSeries<X, Y extends num> {
  const BubbleSeries({
    required this.data, this.name,
    this.color,
    this.visible = true,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
    this.opacity = 0.7,
  });

  /// Series name for legend/tooltip.
  final String? name;

  /// Data points in this series.
  final List<BubbleDataPoint<X, Y>> data;

  /// Default color for bubbles in this series.
  final Color? color;

  /// Whether this series is visible.
  final bool visible;

  /// Border color for bubbles.
  final Color borderColor;

  /// Border width for bubbles.
  final double borderWidth;

  /// Opacity of bubble fills.
  final double opacity;

  bool get isEmpty => data.isEmpty;
  int get length => data.length;
}

/// Label position for bubble labels.
enum BubbleLabelPosition {
  /// Label inside the bubble (centered).
  inside,

  /// Label above the bubble.
  above,

  /// Label below the bubble.
  below,
}

/// Data configuration for bubble chart.
@immutable
class BubbleChartData {
  const BubbleChartData({
    required this.series,
    this.xAxis,
    this.yAxis,
    this.sizeConfig = const BubbleSizeConfig(),
    this.showLabels = false,
    this.labelPosition = BubbleLabelPosition.inside,
    this.animation,
  });

  /// Data series to display.
  final List<BubbleSeries<dynamic, num>> series;

  /// X-axis configuration.
  final AxisConfig? xAxis;

  /// Y-axis configuration.
  final AxisConfig? yAxis;

  /// Configuration for bubble sizing.
  final BubbleSizeConfig sizeConfig;

  /// Whether to show labels on bubbles.
  final bool showLabels;

  /// Position of bubble labels.
  final BubbleLabelPosition labelPosition;

  /// Animation configuration.
  final ChartAnimation? animation;
}
