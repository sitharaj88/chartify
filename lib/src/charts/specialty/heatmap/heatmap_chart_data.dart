import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Color scale configuration for heatmap.
@immutable
class HeatmapColorScale {
  const HeatmapColorScale({
    this.colors = const [Color(0xFFEBF5FB), Color(0xFF2196F3), Color(0xFF0D47A1)],
    this.stops,
  });

  /// Colors for the gradient (from low to high values).
  final List<Color> colors;

  /// Optional stops for the gradient (0-1).
  final List<double>? stops;

  /// Get color for a normalized value (0-1).
  Color getColor(double normalizedValue) {
    if (colors.isEmpty) return Colors.grey;
    if (colors.length == 1) return colors.first;

    final value = normalizedValue.clamp(0.0, 1.0);
    final effectiveStops = stops ?? List.generate(colors.length, (i) => i / (colors.length - 1));

    for (var i = 0; i < effectiveStops.length - 1; i++) {
      if (value >= effectiveStops[i] && value <= effectiveStops[i + 1]) {
        final t = (value - effectiveStops[i]) / (effectiveStops[i + 1] - effectiveStops[i]);
        return Color.lerp(colors[i], colors[i + 1], t)!;
      }
    }

    return colors.last;
  }

  /// Predefined: Blue scale (cold).
  static const HeatmapColorScale blues = HeatmapColorScale(
    colors: [Color(0xFFE3F2FD), Color(0xFF2196F3), Color(0xFF0D47A1)],
  );

  /// Predefined: Red scale (hot).
  static const HeatmapColorScale reds = HeatmapColorScale(
    colors: [Color(0xFFFFEBEE), Color(0xFFF44336), Color(0xFFB71C1C)],
  );

  /// Predefined: Green scale.
  static const HeatmapColorScale greens = HeatmapColorScale(
    colors: [Color(0xFFE8F5E9), Color(0xFF4CAF50), Color(0xFF1B5E20)],
  );

  /// Predefined: Diverging (blue-white-red).
  static const HeatmapColorScale diverging = HeatmapColorScale(
    colors: [Color(0xFF2196F3), Color(0xFFFFFFFF), Color(0xFFF44336)],
  );

  /// Predefined: Viridis-like.
  static const HeatmapColorScale viridis = HeatmapColorScale(
    colors: [Color(0xFF440154), Color(0xFF21908C), Color(0xFFFDE725)],
  );
}

/// Data configuration for heatmap chart.
@immutable
class HeatmapChartData {
  const HeatmapChartData({
    required this.data,
    this.rowLabels,
    this.columnLabels,
    this.colorScale = HeatmapColorScale.blues,
    this.minValue,
    this.maxValue,
    this.showValues = false,
    this.cellPadding = 1,
    this.cellBorderRadius = 2,
    this.showColorLegend = true,
    this.animation,
  });

  /// 2D matrix of values (rows x columns).
  final List<List<double>> data;

  /// Labels for rows (Y-axis).
  final List<String>? rowLabels;

  /// Labels for columns (X-axis).
  final List<String>? columnLabels;

  /// Color scale for mapping values to colors.
  final HeatmapColorScale colorScale;

  /// Minimum value for color scaling (auto-detected if null).
  final double? minValue;

  /// Maximum value for color scaling (auto-detected if null).
  final double? maxValue;

  /// Whether to show values in cells.
  final bool showValues;

  /// Padding between cells.
  final double cellPadding;

  /// Border radius of cells.
  final double cellBorderRadius;

  /// Whether to show color legend.
  final bool showColorLegend;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get number of rows.
  int get rowCount => data.length;

  /// Get number of columns.
  int get columnCount => data.isEmpty ? 0 : data.map((r) => r.length).reduce((a, b) => a > b ? a : b);

  /// Get the actual min value from data.
  double get computedMinValue {
    if (minValue != null) return minValue!;
    if (data.isEmpty) return 0;
    var min = double.infinity;
    for (final row in data) {
      for (final value in row) {
        if (value < min) min = value;
      }
    }
    return min.isFinite ? min : 0;
  }

  /// Get the actual max value from data.
  double get computedMaxValue {
    if (maxValue != null) return maxValue!;
    if (data.isEmpty) return 1;
    var max = double.negativeInfinity;
    for (final row in data) {
      for (final value in row) {
        if (value > max) max = value;
      }
    }
    return max.isFinite ? max : 1;
  }

  /// Get value at position.
  double? getValue(int row, int col) {
    if (row < 0 || row >= data.length) return null;
    if (col < 0 || col >= data[row].length) return null;
    return data[row][col];
  }
}
