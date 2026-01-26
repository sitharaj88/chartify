import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Binning method for histogram.
enum HistogramBinningMethod {
  /// Sturges' formula: k = ceil(log2(n) + 1)
  sturges,

  /// Scott's rule: h = 3.49 * std * n^(-1/3)
  scott,

  /// Freedman-Diaconis: h = 2 * IQR * n^(-1/3)
  freedmanDiaconis,

  /// Square root: k = sqrt(n)
  squareRoot,

  /// Fixed number of bins
  fixed,
}

/// Mode for histogram display.
enum HistogramMode {
  /// Show frequency count.
  frequency,

  /// Show relative frequency (probability).
  density,

  /// Show cumulative frequency.
  cumulative,

  /// Show cumulative percentage.
  cumulativePercent,
}

/// A single bin in the histogram.
@immutable
class HistogramBin {
  const HistogramBin({
    required this.start,
    required this.end,
    required this.count,
    this.color,
  });

  /// Start value of the bin (inclusive).
  final double start;

  /// End value of the bin (exclusive, except for last bin).
  final double end;

  /// Count of values in this bin.
  final int count;

  /// Custom color for this bin.
  final Color? color;

  /// Width of the bin.
  double get width => end - start;

  /// Center value of the bin.
  double get center => (start + end) / 2;
}

/// Data configuration for histogram chart.
@immutable
class HistogramChartData {
  const HistogramChartData({
    required this.values,
    this.binCount,
    this.binEdges,
    this.binningMethod = HistogramBinningMethod.sturges,
    this.mode = HistogramMode.frequency,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.barSpacing = 0,
    this.showDistributionCurve = false,
    this.distributionCurveColor,
    this.animation,
  });

  /// Raw data values to bin.
  final List<double> values;

  /// Fixed number of bins (overrides binningMethod).
  final int? binCount;

  /// Custom bin edges (overrides binCount and binningMethod).
  final List<double>? binEdges;

  /// Method for automatic binning.
  final HistogramBinningMethod binningMethod;

  /// Display mode for the histogram.
  final HistogramMode mode;

  /// Fill color for bars.
  final Color? color;

  /// Border color for bars.
  final Color? borderColor;

  /// Border width for bars.
  final double borderWidth;

  /// Spacing between bars (0 for true histogram style).
  final double barSpacing;

  /// Whether to overlay a distribution curve.
  final bool showDistributionCurve;

  /// Color for the distribution curve.
  final Color? distributionCurveColor;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Calculate bins from the data.
  List<HistogramBin> calculateBins() {
    if (values.isEmpty) return [];

    final sortedValues = List<double>.from(values)..sort();
    final minVal = sortedValues.first;
    final maxVal = sortedValues.last;

    // Determine bin edges
    List<double> edges;
    if (binEdges != null && binEdges!.isNotEmpty) {
      edges = binEdges!;
    } else {
      final numBins = binCount ?? _calculateBinCount(sortedValues);
      final binWidth = (maxVal - minVal) / numBins;
      edges = List.generate(numBins + 1, (i) => minVal + i * binWidth);
    }

    // Count values in each bin
    final bins = <HistogramBin>[];
    for (var i = 0; i < edges.length - 1; i++) {
      final start = edges[i];
      final end = edges[i + 1];
      final isLast = i == edges.length - 2;

      final count = sortedValues.where((v) {
        if (isLast) {
          return v >= start && v <= end;
        }
        return v >= start && v < end;
      }).length;

      bins.add(HistogramBin(start: start, end: end, count: count));
    }

    return bins;
  }

  int _calculateBinCount(List<double> sortedValues) {
    final n = sortedValues.length;
    if (n == 0) return 1;

    switch (binningMethod) {
      case HistogramBinningMethod.sturges:
        return (math.log(n) / math.ln2 + 1).ceil();

      case HistogramBinningMethod.scott:
        final std = _standardDeviation(sortedValues);
        if (std == 0) return 1;
        final h = 3.49 * std * math.pow(n, -1 / 3);
        final range = sortedValues.last - sortedValues.first;
        return (range / h).ceil().clamp(1, 100);

      case HistogramBinningMethod.freedmanDiaconis:
        final iqr = _interquartileRange(sortedValues);
        if (iqr == 0) return math.sqrt(n).ceil();
        final h = 2 * iqr * math.pow(n, -1 / 3);
        final range = sortedValues.last - sortedValues.first;
        return (range / h).ceil().clamp(1, 100);

      case HistogramBinningMethod.squareRoot:
        return math.sqrt(n).ceil();

      case HistogramBinningMethod.fixed:
        return binCount ?? 10;
    }
  }

  double _standardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    return math.sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  double _interquartileRange(List<double> sortedValues) {
    if (sortedValues.length < 4) return sortedValues.last - sortedValues.first;
    final q1Index = (sortedValues.length * 0.25).floor();
    final q3Index = (sortedValues.length * 0.75).floor();
    return sortedValues[q3Index] - sortedValues[q1Index];
  }
}
