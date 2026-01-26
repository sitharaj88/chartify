import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../core/base/chart_controller.dart' as controller;
import '../rendering/painters/series_painter.dart' as painter;
import 'chart_semantics.dart';
import 'contrast_validator.dart';
import 'high_contrast.dart';

/// Converts a DataPointInfo from chart_controller to series_painter format.
painter.DataPointInfo toSemanticDataPointInfo(controller.DataPointInfo info) {
  return painter.DataPointInfo(
    seriesIndex: info.seriesIndex,
    dataIndex: info.pointIndex,
    screenPosition: info.position,
    dataX: info.xValue,
    dataY: (info.yValue is num) ? (info.yValue as num).toDouble() : 0.0,
    label: info.label ?? info.seriesName,
    color: null,
  );
}

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
  }) {
    _focusNode = FocusNode(debugLabel: 'ChartAccessibility');
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

  late final FocusNode _focusNode;
  List<controller.DataPointInfo> _dataPoints = [];
  int _focusedIndex = -1;

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
  }

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
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (_dataPoints.isEmpty) return KeyEventResult.ignored;

    final key = event.logicalKey;

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

    if (key == LogicalKeyboardKey.home) {
      _navigateToFirst();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.end) {
      _navigateToLast();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _selectCurrentPoint();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _clearFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
    super.key,
    required this.chartType,
    required this.builder,
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
  Widget build(BuildContext context) {
    return _accessibility.wrap(
      dataPoints: widget.dataPoints,
      seriesDescriptions: widget.seriesDescriptions,
      child: widget.builder(context, _accessibility),
    );
  }
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
