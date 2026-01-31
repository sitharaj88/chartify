import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../core/base/chart_controller.dart' as controller;
import '../rendering/painters/series_painter.dart' as painter;
import 'chart_semantics.dart';
import 'contrast_validator.dart';
import 'high_contrast.dart';
import 'live_region.dart';

/// Converts a DataPointInfo from chart_controller to series_painter format.
painter.DataPointInfo toSemanticDataPointInfo(controller.DataPointInfo info) => painter.DataPointInfo(
    seriesIndex: info.seriesIndex,
    dataIndex: info.pointIndex,
    screenPosition: info.position,
    dataX: info.xValue,
    dataY: (info.yValue is num) ? (info.yValue as num).toDouble() : 0.0,
    label: info.label ?? info.seriesName,
  );

/// Unified accessibility helper for charts.
///
/// Provides easy integration of accessibility features including:
/// - Screen reader support via Semantics
/// - Keyboard navigation
/// - Focus management
/// - Color contrast validation
/// - High contrast mode support
///
/// Example:
/// ```dart
/// class _MyChartState extends State<MyChart> {
///   late final ChartAccessibility _accessibility;
///
///   @override
///   void initState() {
///     super.initState();
///     _accessibility = ChartAccessibility(
///       chartType: ChartType.line,
///       title: 'Sales Chart',
///     );
///   }
///
///   @override
///   void dispose() {
///     _accessibility.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return _accessibility.wrap(
///       child: CustomPaint(...),
///       dataPoints: _dataPoints,
///     );
///   }
/// }
/// ```
class ChartAccessibility {
  ChartAccessibility({
    required this.chartType,
    this.title,
    this.subtitle,
    this.xAxisLabel,
    this.yAxisLabel,
    this.valueFormatter,
    this.onPointSelected,
    this.onNavigate,
    this.onSeriesFocus,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
    this.jumpSize = 10,
    this.enableZoomKeys = true,
  }) {
    _focusNode = FocusNode(debugLabel: 'ChartAccessibility');
    _liveRegion = LiveRegionController();
  }

  /// The type of chart.
  final ChartType chartType;

  /// The chart title.
  final String? title;

  /// The chart subtitle.
  final String? subtitle;

  /// Label for the X axis.
  final String? xAxisLabel;

  /// Label for the Y axis.
  final String? yAxisLabel;

  /// Custom formatter for values.
  final String Function(double)? valueFormatter;

  /// Called when a data point is selected via keyboard.
  final void Function(controller.DataPointInfo point)? onPointSelected;

  /// Called when navigation occurs.
  final void Function(int index)? onNavigate;

  /// Called when a series is focused via number keys (1-9).
  final void Function(int seriesIndex)? onSeriesFocus;

  /// Called when zoom in is requested (+/= key).
  final VoidCallback? onZoomIn;

  /// Called when zoom out is requested (-/_ key).
  final VoidCallback? onZoomOut;

  /// Called when zoom reset is requested (R key).
  final VoidCallback? onZoomReset;

  /// Number of points to jump on Page Up/Down.
  final int jumpSize;

  /// Whether zoom keys (+/-/R) are enabled.
  final bool enableZoomKeys;

  late final FocusNode _focusNode;
  late final LiveRegionController _liveRegion;
  List<controller.DataPointInfo> _dataPoints = [];
  Map<int, List<controller.DataPointInfo>> _seriesDataPoints = {};
  int _focusedIndex = -1;
  int _focusedSeriesIndex = 0;

  /// The focus node for keyboard navigation.
  FocusNode get focusNode => _focusNode;

  /// The currently focused data point index.
  int get focusedIndex => _focusedIndex;

  /// The currently focused data point.
  controller.DataPointInfo? get focusedPoint =>
      _focusedIndex >= 0 && _focusedIndex < _dataPoints.length
          ? _dataPoints[_focusedIndex]
          : null;

  /// Updates the data points for navigation.
  void updateDataPoints(List<controller.DataPointInfo> points) {
    _dataPoints = points;
    if (_focusedIndex >= points.length) {
      _focusedIndex = points.isEmpty ? -1 : points.length - 1;
    }
  }

  /// Disposes resources.
  void dispose() {
    _focusNode.dispose();
    _liveRegion.dispose();
  }

  /// Gets the live region controller for external use.
  LiveRegionController get liveRegion => _liveRegion;

  /// Gets the currently focused series index.
  int get focusedSeriesIndex => _focusedSeriesIndex;

  /// Wraps a chart widget with accessibility support.
  ///
  /// This adds:
  /// - Semantic labels for screen readers
  /// - Keyboard navigation support
  /// - Focus management
  Widget wrap({
    required Widget child,
    List<controller.DataPointInfo>? dataPoints,
    List<SeriesDescription>? seriesDescriptions,
  }) {
    if (dataPoints != null) {
      _dataPoints = dataPoints;
    }

    // Convert to semantic data points
    final semanticPoints =
        _dataPoints.map(toSemanticDataPointInfo).toList();

    final semantics = ChartSemantics(
      chartType: chartType,
      title: title,
      subtitle: subtitle,
      dataPoints: semanticPoints,
      seriesDescriptions: seriesDescriptions ?? [],
      xAxisLabel: xAxisLabel,
      yAxisLabel: yAxisLabel,
      valueFormatter: valueFormatter,
    );

    return Semantics(
      label: semantics.chartDescription,
      hint: semantics.navigationHints,
      container: true,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: child,
      ),
    );
  }

  /// Handles keyboard events for navigation.
  ///
  /// Supported keys:
  /// - Arrow keys: Navigate between points
  /// - Home/End: Jump to first/last point
  /// - Page Up/Down: Jump by [jumpSize] points
  /// - Enter/Space: Select current point
  /// - Escape: Clear selection
  /// - 1-9: Focus series by index
  /// - D: Announce data description
  /// - T: Announce trend
  /// - S: Announce summary
  /// - +/=: Zoom in (if enabled)
  /// - -/_: Zoom out (if enabled)
  /// - R: Reset zoom (if enabled)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Arrow key navigation
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _navigateNext();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _navigatePrevious();
      return KeyEventResult.handled;
    }

    // Jump navigation
    if (key == LogicalKeyboardKey.home) {
      _navigateToFirst();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.end) {
      _navigateToLast();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.pageDown) {
      _navigateForward(jumpSize);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.pageUp) {
      _navigateBackward(jumpSize);
      return KeyEventResult.handled;
    }

    // Selection
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _selectCurrentPoint();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _clearFocus();
      return KeyEventResult.handled;
    }

    // Number keys for series selection (1-9)
    final seriesIndex = _getSeriesIndexFromKey(key);
    if (seriesIndex != null) {
      _focusSeries(seriesIndex);
      return KeyEventResult.handled;
    }

    // Announcement keys
    if (key == LogicalKeyboardKey.keyD) {
      _announceDataDescription();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyT) {
      _announceTrend();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyS) {
      _announceSummary();
      return KeyEventResult.handled;
    }

    // Zoom keys (if enabled)
    if (enableZoomKeys) {
      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.add ||
          key == LogicalKeyboardKey.numpadAdd) {
        onZoomIn?.call();
        _liveRegion.announce('Zooming in');
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract) {
        onZoomOut?.call();
        _liveRegion.announce('Zooming out');
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyR) {
        onZoomReset?.call();
        _liveRegion.announce('Zoom reset');
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Gets series index from number key (1-9).
  int? _getSeriesIndexFromKey(LogicalKeyboardKey key) {
    const numberKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    final index = numberKeys.indexOf(key);
    return index >= 0 ? index : null;
  }

  void _navigateNext() {
    if (_dataPoints.isEmpty) return;
    _focusedIndex = (_focusedIndex + 1) % _dataPoints.length;
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  void _navigatePrevious() {
    if (_dataPoints.isEmpty) return;
    _focusedIndex =
        (_focusedIndex - 1 + _dataPoints.length) % _dataPoints.length;
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  void _navigateToFirst() {
    if (_dataPoints.isEmpty) return;
    _focusedIndex = 0;
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  void _navigateToLast() {
    if (_dataPoints.isEmpty) return;
    _focusedIndex = _dataPoints.length - 1;
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  /// Navigates forward by a specified number of points.
  void _navigateForward(int count) {
    if (_dataPoints.isEmpty) return;
    _focusedIndex = math.min(_focusedIndex + count, _dataPoints.length - 1);
    if (_focusedIndex < 0) _focusedIndex = 0;
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  /// Navigates backward by a specified number of points.
  void _navigateBackward(int count) {
    if (_dataPoints.isEmpty) return;
    _focusedIndex = math.max(_focusedIndex - count, 0);
    onNavigate?.call(_focusedIndex);
    _announceCurrentPoint();
  }

  /// Focuses on a specific series by index.
  void _focusSeries(int seriesIndex) {
    // Group data points by series
    _seriesDataPoints.clear();
    for (final point in _dataPoints) {
      final series = point.seriesIndex;
      _seriesDataPoints.putIfAbsent(series, () => []).add(point);
    }

    // Check if series exists
    if (!_seriesDataPoints.containsKey(seriesIndex)) {
      _liveRegion.announce('Series ${seriesIndex + 1} not found');
      return;
    }

    _focusedSeriesIndex = seriesIndex;
    final seriesPoints = _seriesDataPoints[seriesIndex]!;

    // Find first point of this series in the main list
    final firstPointIndex = _dataPoints.indexWhere(
      (p) => p.seriesIndex == seriesIndex,
    );

    if (firstPointIndex >= 0) {
      _focusedIndex = firstPointIndex;
      onNavigate?.call(_focusedIndex);
      onSeriesFocus?.call(seriesIndex);
      _liveRegion.announce(
        'Series ${seriesIndex + 1} selected, ${seriesPoints.length} points',
      );
      _announceCurrentPoint();
    }
  }

  /// Announces detailed data description for current point.
  void _announceDataDescription() {
    final point = focusedPoint;
    if (point == null) {
      _liveRegion.announce('No point selected');
      return;
    }

    final semanticPoint = toSemanticDataPointInfo(point);
    final buffer = StringBuffer();

    buffer.write('Data point ${_focusedIndex + 1} of ${_dataPoints.length}. ');

    if (semanticPoint.label != null) {
      buffer.write('Label: ${semanticPoint.label}. ');
    }

    buffer.write('Value: ${_formatValue(semanticPoint.dataY)}. ');

    if (semanticPoint.dataX != null) {
      buffer.write('Position: ${semanticPoint.dataX}. ');
    }

    buffer.write('Series ${point.seriesIndex + 1}.');

    _liveRegion.announce(buffer.toString());
  }

  /// Announces trend information for visible data.
  void _announceTrend() {
    if (_dataPoints.length < 2) {
      _liveRegion.announce('Insufficient data for trend analysis');
      return;
    }

    final semanticPoints = _dataPoints.map(toSemanticDataPointInfo).toList();
    _liveRegion.announceTrend(semanticPoints);
  }

  /// Announces chart summary.
  void _announceSummary() {
    final semanticPoints = _dataPoints.map(toSemanticDataPointInfo).toList();
    final semantics = ChartSemantics(
      chartType: chartType,
      title: title,
      subtitle: subtitle,
      dataPoints: semanticPoints,
      xAxisLabel: xAxisLabel,
      yAxisLabel: yAxisLabel,
      valueFormatter: valueFormatter,
    );

    _liveRegion.announceChartSummary(semantics);
  }

  /// Formats a value for announcement.
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

  void _selectCurrentPoint() {
    final point = focusedPoint;
    if (point != null) {
      onPointSelected?.call(point);
    }
  }

  void _clearFocus() {
    _focusedIndex = -1;
    onNavigate?.call(-1);
  }

  void _announceCurrentPoint() {
    final point = focusedPoint;
    if (point == null) return;

    final semanticPoint = toSemanticDataPointInfo(point);
    final semantics = ChartSemantics(
      chartType: chartType,
      valueFormatter: valueFormatter,
    );

    final announcement = semantics.getDataPointDescription(semanticPoint);
    // Note: Using deprecated announce API for compatibility
    // ignore: deprecated_member_use
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Requests focus on the chart.
  void requestFocus() {
    _focusNode.requestFocus();
  }
}

/// Builder for creating accessible chart widgets.
///
/// Provides a convenient way to add accessibility to charts
/// with minimal boilerplate.
class AccessibleChartBuilder extends StatefulWidget {
  const AccessibleChartBuilder({
    required this.chartType, required this.builder, super.key,
    this.title,
    this.subtitle,
    this.xAxisLabel,
    this.yAxisLabel,
    this.dataPoints = const [],
    this.seriesDescriptions = const [],
    this.valueFormatter,
    this.chartController,
    this.onPointSelected,
  });

  /// The type of chart.
  final ChartType chartType;

  /// Builder function that creates the chart widget.
  final Widget Function(
    BuildContext context,
    ChartAccessibility accessibility,
  ) builder;

  /// The chart title.
  final String? title;

  /// The chart subtitle.
  final String? subtitle;

  /// Label for the X axis.
  final String? xAxisLabel;

  /// Label for the Y axis.
  final String? yAxisLabel;

  /// Data points for navigation.
  final List<controller.DataPointInfo> dataPoints;

  /// Series descriptions.
  final List<SeriesDescription> seriesDescriptions;

  /// Custom formatter for values.
  final String Function(double)? valueFormatter;

  /// Optional chart controller for synchronization.
  final controller.ChartController? chartController;

  /// Called when a data point is selected via keyboard.
  final void Function(controller.DataPointInfo point)? onPointSelected;

  @override
  State<AccessibleChartBuilder> createState() => _AccessibleChartBuilderState();
}

class _AccessibleChartBuilderState extends State<AccessibleChartBuilder> {
  late ChartAccessibility _accessibility;

  @override
  void initState() {
    super.initState();
    _accessibility = ChartAccessibility(
      chartType: widget.chartType,
      title: widget.title,
      subtitle: widget.subtitle,
      xAxisLabel: widget.xAxisLabel,
      yAxisLabel: widget.yAxisLabel,
      valueFormatter: widget.valueFormatter,
      onPointSelected: widget.onPointSelected,
      onNavigate: _handleNavigate,
    );
    _accessibility.updateDataPoints(widget.dataPoints);
  }

  @override
  void didUpdateWidget(AccessibleChartBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataPoints != oldWidget.dataPoints) {
      _accessibility.updateDataPoints(widget.dataPoints);
    }
  }

  @override
  void dispose() {
    _accessibility.dispose();
    super.dispose();
  }

  void _handleNavigate(int index) {
    if (widget.chartController != null && index >= 0) {
      final point = widget.dataPoints[index];
      widget.chartController!.setHoveredPoint(point);
    } else {
      widget.chartController?.clearHoveredPoint();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => _accessibility.wrap(
      dataPoints: widget.dataPoints,
      seriesDescriptions: widget.seriesDescriptions,
      child: widget.builder(context, _accessibility),
    );
}

/// Extension for validating chart colors against a background.
extension ChartColorAccessibility on List<Color> {
  /// Validates all colors meet contrast requirements against the background.
  ///
  /// Returns a map of colors that fail validation with suggested replacements.
  Map<int, ContrastIssue> validateContrast(
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) =>
      ContrastValidator.validatePalette(this, background, level: level);

  /// Returns a list of colors adjusted to meet contrast requirements.
  List<Color> ensureContrast(
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) =>
      map((color) {
        if (ContrastValidator.meetsLevel(color, background, level)) {
          return color;
        }
        return ContrastValidator.suggestAccessibleColor(
          color,
          background,
          level: level,
        );
      }).toList();
}

/// Helper for creating accessible color palettes.
class AccessibleColorPalette {
  AccessibleColorPalette._();

  /// Gets colors appropriate for the given brightness.
  static List<Color> forBrightness(Brightness brightness) =>
      HighContrastColors.forBrightness(brightness);

  /// Validates and adjusts a palette for accessibility.
  static List<Color> ensureAccessible(
    List<Color> colors,
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) =>
      colors.ensureContrast(background, level: level);

  /// Creates a palette that meets WCAG AA requirements.
  static List<Color> wcagAA(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final baseColors = forBrightness(brightness);
    return baseColors.ensureContrast(background);
  }

  /// Creates a palette that meets WCAG AAA requirements.
  static List<Color> wcagAAA(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final baseColors = forBrightness(brightness);
    return baseColors.ensureContrast(background, level: ContrastLevel.aaa);
  }
}
