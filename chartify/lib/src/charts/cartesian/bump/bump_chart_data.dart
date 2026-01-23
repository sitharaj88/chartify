import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single series in the bump chart showing rankings over time.
@immutable
class BumpSeries {
  const BumpSeries({
    required this.label,
    required this.rankings,
    this.color,
  });

  /// Label for this series.
  final String label;

  /// Rankings at each time point (1 = first place).
  /// The list index corresponds to the time point index.
  final List<int> rankings;

  /// Optional custom color.
  final Color? color;
}

/// Data configuration for bump chart.
@immutable
class BumpChartData {
  const BumpChartData({
    required this.series,
    this.timeLabels,
    this.lineWidth = 3.0,
    this.markerSize = 10.0,
    this.showLabels = true,
    this.showRankings = true,
    this.smoothLines = true,
    this.animation,
  });

  /// List of series (competitors/items being ranked).
  final List<BumpSeries> series;

  /// Labels for each time point on x-axis.
  final List<String>? timeLabels;

  /// Width of the connecting lines.
  final double lineWidth;

  /// Size of rank markers.
  final double markerSize;

  /// Whether to show series labels on the sides.
  final bool showLabels;

  /// Whether to show rank numbers in markers.
  final bool showRankings;

  /// Whether to use smooth curved lines.
  final bool smoothLines;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get the number of time points.
  int get timePointCount {
    if (series.isEmpty) return 0;
    return series.map((s) => s.rankings.length).reduce((a, b) => a > b ? a : b);
  }

  /// Get the maximum rank (number of competitors).
  int get maxRank => series.length;
}
