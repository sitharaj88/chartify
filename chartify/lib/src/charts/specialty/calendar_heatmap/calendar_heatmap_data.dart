import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single data point in the calendar heatmap.
@immutable
class CalendarDataPoint {
  const CalendarDataPoint({
    required this.date,
    required this.value,
  });

  /// The date for this data point.
  final DateTime date;

  /// The value for this date.
  final double value;
}

/// Data configuration for calendar heatmap chart.
@immutable
class CalendarHeatmapData {
  const CalendarHeatmapData({
    required this.data,
    this.startDate,
    this.endDate,
    this.cellSize = 12.0,
    this.cellSpacing = 2.0,
    this.cellRadius = 2.0,
    this.showMonthLabels = true,
    this.showDayLabels = true,
    this.emptyColor,
    this.colorStops,
    this.minValue,
    this.maxValue,
    this.animation,
  });

  /// List of data points.
  final List<CalendarDataPoint> data;

  /// Start date (defaults to first data point or 1 year ago).
  final DateTime? startDate;

  /// End date (defaults to last data point or today).
  final DateTime? endDate;

  /// Size of each cell.
  final double cellSize;

  /// Spacing between cells.
  final double cellSpacing;

  /// Corner radius of cells.
  final double cellRadius;

  /// Whether to show month labels.
  final bool showMonthLabels;

  /// Whether to show day of week labels.
  final bool showDayLabels;

  /// Color for empty/zero cells.
  final Color? emptyColor;

  /// Color gradient stops (defaults to green gradient like GitHub).
  final List<Color>? colorStops;

  /// Minimum value (auto-calculated if null).
  final double? minValue;

  /// Maximum value (auto-calculated if null).
  final double? maxValue;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Default color gradient (GitHub-style green).
  static const List<Color> defaultColorStops = [
    Color(0xFFEBEDF0), // Empty
    Color(0xFF9BE9A8), // Low
    Color(0xFF40C463), // Medium-Low
    Color(0xFF30A14E), // Medium-High
    Color(0xFF216E39), // High
  ];

  /// Get computed start date.
  DateTime get computedStartDate {
    if (startDate != null) return startDate!;
    if (data.isNotEmpty) {
      final earliest = data.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);
      return DateTime(earliest.year, earliest.month, earliest.day);
    }
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month, now.day);
  }

  /// Get computed end date.
  DateTime get computedEndDate {
    if (endDate != null) return endDate!;
    if (data.isNotEmpty) {
      final latest = data.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);
      return DateTime(latest.year, latest.month, latest.day);
    }
    return DateTime.now();
  }

  /// Calculate value range.
  (double, double) calculateRange() {
    if (data.isEmpty) return (0, 10);

    final values = data.map((d) => d.value).toList();
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    return (minValue ?? 0, maxValue ?? dataMax);
  }

  /// Create a data map for quick lookup.
  Map<String, double> toDataMap() {
    final map = <String, double>{};
    for (final point in data) {
      final key = _dateKey(point.date);
      map[key] = point.value;
    }
    return map;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
