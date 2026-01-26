import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../rendering/painters/series_painter.dart';

/// Provides semantic information for charts to support screen readers.
///
/// This class generates semantic labels and descriptions for chart elements,
/// making charts accessible to users with visual impairments.
///
/// Example:
/// ```dart
/// final semantics = ChartSemantics(
///   chartType: ChartType.line,
///   title: 'Monthly Revenue',
///   dataPoints: points,
/// );
///
/// return Semantics(
///   label: semantics.chartDescription,
///   child: CustomPaint(...),
/// );
/// ```
class ChartSemantics {
  const ChartSemantics({
    required this.chartType,
    this.title,
    this.subtitle,
    this.dataPoints = const [],
    this.seriesDescriptions = const [],
    this.xAxisLabel,
    this.yAxisLabel,
    this.valueFormatter,
    this.locale,
  });

  /// The type of chart.
  final ChartType chartType;

  /// The chart title.
  final String? title;

  /// The chart subtitle.
  final String? subtitle;

  /// Data points in the chart.
  final List<DataPointInfo> dataPoints;

  /// Descriptions for each series.
  final List<SeriesDescription> seriesDescriptions;

  /// Label for the X axis.
  final String? xAxisLabel;

  /// Label for the Y axis.
  final String? yAxisLabel;

  /// Custom formatter for values.
  final String Function(double)? valueFormatter;

  /// Locale for number formatting.
  final String? locale;

  /// Generates a comprehensive description of the chart.
  String get chartDescription {
    final buffer = StringBuffer();

    // Chart type and title
    buffer.write(_chartTypeName(chartType));
    if (title != null) {
      buffer.write(' titled "$title"');
    }
    buffer.write('. ');

    // Subtitle
    if (subtitle != null) {
      buffer.write('$subtitle. ');
    }

    // Axis labels
    if (xAxisLabel != null || yAxisLabel != null) {
      buffer.write('Shows ');
      if (yAxisLabel != null) buffer.write(yAxisLabel);
      if (xAxisLabel != null && yAxisLabel != null) buffer.write(' over ');
      if (xAxisLabel != null) buffer.write(xAxisLabel);
      buffer.write('. ');
    }

    // Series information
    if (seriesDescriptions.isNotEmpty) {
      buffer.write('Contains ${seriesDescriptions.length} ${seriesDescriptions.length == 1 ? "series" : "series"}: ');
      buffer.write(seriesDescriptions.map((s) => s.name).join(', '));
      buffer.write('. ');
    }

    // Data summary
    if (dataPoints.isNotEmpty) {
      buffer.write(_generateDataSummary());
    }

    return buffer.toString().trim();
  }

  /// Generates a summary of the data points.
  String _generateDataSummary() {
    if (dataPoints.isEmpty) return '';

    final buffer = StringBuffer();

    // Count data points
    buffer.write('${dataPoints.length} data point${dataPoints.length == 1 ? "" : "s"}. ');

    // Find min/max values
    final yValues = dataPoints.map((p) => p.dataY).toList();
    if (yValues.isNotEmpty) {
      final minValue = yValues.reduce((a, b) => a < b ? a : b);
      final maxValue = yValues.reduce((a, b) => a > b ? a : b);

      buffer.write('Values range from ${_formatValue(minValue)} to ${_formatValue(maxValue)}. ');

      // Find min/max points
      final minPoint = dataPoints.firstWhere((p) => p.dataY == minValue);
      final maxPoint = dataPoints.firstWhere((p) => p.dataY == maxValue);

      if (minPoint.label != null) {
        buffer.write('Minimum at ${minPoint.label}. ');
      }
      if (maxPoint.label != null && maxPoint != minPoint) {
        buffer.write('Maximum at ${maxPoint.label}. ');
      }
    }

    return buffer.toString();
  }

  /// Generates a description for a specific data point.
  String getDataPointDescription(DataPointInfo point) {
    final buffer = StringBuffer();

    // Series name
    if (point.color != null) {
      buffer.write('Series ${point.seriesIndex + 1}');
    }

    // Label
    if (point.label != null) {
      buffer.write(', ${point.label}');
    }

    // Value
    buffer.write(': ${_formatValue(point.dataY)}');

    // X value if different from label
    if (point.dataX != null && point.label == null) {
      buffer.write(' at ${_formatDynamicValue(point.dataX)}');
    }

    return buffer.toString();
  }

  /// Generates navigation hints for keyboard users.
  String get navigationHints => 'Use arrow keys to navigate between data points. '
        'Press Enter to select a point. '
        'Press Escape to clear selection. '
        'Press Tab to move to the next chart element.';

  /// Formats a dynamic value for display.
  String _formatDynamicValue(dynamic value) {
    if (value == null) return '';
    if (value is double) return _formatValue(value);
    if (value is int) return value.toString();
    if (value is DateTime) {
      return '${value.month}/${value.day}/${value.year}';
    }
    return value.toString();
  }

  String _formatValue(double value) {
    if (valueFormatter != null) {
      return valueFormatter!(value);
    }

    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} million';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} thousand';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _chartTypeName(ChartType type) {
    switch (type) {
      case ChartType.line:
        return 'Line chart';
      case ChartType.bar:
        return 'Bar chart';
      case ChartType.area:
        return 'Area chart';
      case ChartType.pie:
        return 'Pie chart';
      case ChartType.donut:
        return 'Donut chart';
      case ChartType.scatter:
        return 'Scatter plot';
      case ChartType.radar:
        return 'Radar chart';
      case ChartType.gauge:
        return 'Gauge chart';
      case ChartType.heatmap:
        return 'Heat map';
      case ChartType.treemap:
        return 'Tree map';
      case ChartType.funnel:
        return 'Funnel chart';
      case ChartType.waterfall:
        return 'Waterfall chart';
      case ChartType.candlestick:
        return 'Candlestick chart';
      case ChartType.bubble:
        return 'Bubble chart';
    }
  }
}

/// Types of charts for semantic descriptions.
enum ChartType {
  line,
  bar,
  area,
  pie,
  donut,
  scatter,
  radar,
  gauge,
  heatmap,
  treemap,
  funnel,
  waterfall,
  candlestick,
  bubble,
}

/// Description of a chart series for accessibility.
class SeriesDescription {
  const SeriesDescription({
    required this.name,
    this.color,
    this.description,
    this.dataPointCount = 0,
    this.minValue,
    this.maxValue,
    this.averageValue,
  });

  /// Name of the series.
  final String name;

  /// Color of the series (for description).
  final Color? color;

  /// Optional description of what this series represents.
  final String? description;

  /// Number of data points in this series.
  final int dataPointCount;

  /// Minimum value in this series.
  final double? minValue;

  /// Maximum value in this series.
  final double? maxValue;

  /// Average value in this series.
  final double? averageValue;

  /// Generates a full description of this series.
  String get fullDescription {
    final buffer = StringBuffer(name);

    if (description != null) {
      buffer.write(' ($description)');
    }

    if (dataPointCount > 0) {
      buffer.write(', $dataPointCount data points');
    }

    if (minValue != null && maxValue != null) {
      buffer.write(', ranging from $minValue to $maxValue');
    }

    if (averageValue != null) {
      buffer.write(', average $averageValue');
    }

    return buffer.toString();
  }
}

/// Widget that wraps a chart with semantic information.
///
/// This widget provides screen reader support by generating
/// appropriate semantic labels for the chart content.
class SemanticChartWrapper extends StatelessWidget {
  const SemanticChartWrapper({
    required this.child, required this.semantics, super.key,
    this.focusNode,
    this.onFocusChange,
  });

  /// The chart widget to wrap.
  final Widget child;

  /// Semantic information for the chart.
  final ChartSemantics semantics;

  /// Optional focus node for keyboard navigation.
  final FocusNode? focusNode;

  /// Callback when focus changes.
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) => Semantics(
      label: semantics.chartDescription,
      hint: semantics.navigationHints,
      container: true,
      child: Focus(
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        child: child,
      ),
    );
}

/// Mixin for charts that support accessibility features.
///
/// Add this mixin to chart state classes to enable accessibility support.
mixin ChartAccessibilityMixin<T extends StatefulWidget> on State<T> {
  /// The chart semantics.
  ChartSemantics? _semantics;

  /// Currently focused data point index.
  int? _focusedPointIndex;

  /// All data points for navigation.
  List<DataPointInfo> _accessiblePoints = [];

  /// Focus node for keyboard navigation.
  late final FocusNode _chartFocusNode;

  /// Whether the chart currently has focus.
  bool get hasFocus => _chartFocusNode.hasFocus;

  /// The currently focused point.
  DataPointInfo? get focusedPoint =>
      _focusedPointIndex != null && _focusedPointIndex! < _accessiblePoints.length
          ? _accessiblePoints[_focusedPointIndex!]
          : null;

  /// Initialize accessibility support.
  void initAccessibility() {
    _chartFocusNode = FocusNode(
      debugLabel: 'ChartFocus',
    );
  }

  /// Dispose accessibility resources.
  void disposeAccessibility() {
    _chartFocusNode.dispose();
  }

  /// Update the semantic information.
  void updateSemantics(ChartSemantics semantics) {
    _semantics = semantics;
    _accessiblePoints = semantics.dataPoints;
  }

  /// Request focus on the chart.
  void requestChartFocus() {
    _chartFocusNode.requestFocus();
  }

  /// Navigate to the next data point.
  void navigateNext() {
    if (_accessiblePoints.isEmpty) return;

    setState(() {
      if (_focusedPointIndex == null) {
        _focusedPointIndex = 0;
      } else {
        _focusedPointIndex = (_focusedPointIndex! + 1) % _accessiblePoints.length;
      }
    });

    _announceCurrentPoint();
  }

  /// Navigate to the previous data point.
  void navigatePrevious() {
    if (_accessiblePoints.isEmpty) return;

    setState(() {
      if (_focusedPointIndex == null) {
        _focusedPointIndex = _accessiblePoints.length - 1;
      } else {
        _focusedPointIndex = (_focusedPointIndex! - 1 + _accessiblePoints.length) % _accessiblePoints.length;
      }
    });

    _announceCurrentPoint();
  }

  /// Clear the current focus.
  void clearFocus() {
    setState(() {
      _focusedPointIndex = null;
    });
  }

  /// Announce the currently focused point to screen readers.
  void _announceCurrentPoint() {
    if (_semantics == null || focusedPoint == null) return;

    final announcement = _semantics!.getDataPointDescription(focusedPoint!);
    // Trigger a semantic update by calling setState
    // The semantic label will be updated and announced by the accessibility service
    onPointAnnouncement?.call(announcement);
  }

  /// Callback for point announcements.
  /// Override this to handle announcements in your chart widget.
  void Function(String announcement)? onPointAnnouncement;

  /// Build the focus-handling wrapper.
  Widget buildAccessibleChart(Widget chart) => Focus(
      focusNode: _chartFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        label: _semantics?.chartDescription ?? 'Chart',
        hint: _semantics?.navigationHints,
        container: true,
        child: chart,
      ),
    );

  /// Handle keyboard events for navigation.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle key down events
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowDown) {
      navigateNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
      navigatePrevious();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      clearFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      if (_accessiblePoints.isNotEmpty) {
        setState(() => _focusedPointIndex = 0);
        _announceCurrentPoint();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      if (_accessiblePoints.isNotEmpty) {
        setState(() => _focusedPointIndex = _accessiblePoints.length - 1);
        _announceCurrentPoint();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

/// Extension to generate accessibility descriptions for common data patterns.
extension AccessibilityDescriptionExtension on List<DataPointInfo> {
  /// Generates a trend description for the data points.
  String get trendDescription {
    if (length < 2) return 'Insufficient data for trend analysis.';

    final firstValue = first.dataY;
    final lastValue = last.dataY;
    final change = lastValue - firstValue;
    final percentChange = firstValue != 0 ? (change / firstValue * 100) : 0;

    if (change > 0) {
      return 'Upward trend, increased by ${percentChange.abs().toStringAsFixed(1)}% '
          'from ${firstValue.toStringAsFixed(1)} to ${lastValue.toStringAsFixed(1)}.';
    } else if (change < 0) {
      return 'Downward trend, decreased by ${percentChange.abs().toStringAsFixed(1)}% '
          'from ${firstValue.toStringAsFixed(1)} to ${lastValue.toStringAsFixed(1)}.';
    } else {
      return 'No change, values remained at ${firstValue.toStringAsFixed(1)}.';
    }
  }

  /// Generates a summary of the data distribution.
  String get distributionSummary {
    if (isEmpty) return 'No data available.';

    final values = map((p) => p.dataY).toList();
    final sum = values.reduce((a, b) => a + b);
    final avg = sum / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return 'Data ranges from ${min.toStringAsFixed(1)} to ${max.toStringAsFixed(1)}, '
        'with an average of ${avg.toStringAsFixed(1)}.';
  }
}
