import 'package:flutter/widgets.dart';

import '../../core/math/scales/scale.dart';
import '../../rendering/renderers/axis_renderer.dart';
import '../../rendering/renderers/renderer.dart';
import '../../theme/chart_theme_data.dart';

/// A standalone axis widget that can be used with any chart.
///
/// Supports both numerical and categorical axes with customizable
/// appearance and automatic tick generation.
class ChartAxis<T> extends StatelessWidget {
  const ChartAxis({
    super.key,
    required this.scale,
    this.config,
    this.position = ChartPosition.bottom,
    this.title,
    this.labelFormatter,
    this.tickCount,
    this.showLine = true,
    this.showTicks = true,
    this.showLabels = true,
    this.labelRotation = 0.0,
    this.labelStyle,
    this.titleStyle,
    this.lineColor,
    this.tickColor,
    this.lineWidth = 1.0,
    this.tickLength = 5.0,
  });

  /// The scale for this axis.
  final Scale<T> scale;

  /// Optional full configuration (overrides other properties).
  final AxisConfig? config;

  /// Position of the axis.
  final ChartPosition position;

  /// Optional title for the axis.
  final String? title;

  /// Custom label formatter.
  final String Function(T value)? labelFormatter;

  /// Desired number of ticks.
  final int? tickCount;

  /// Whether to show the axis line.
  final bool showLine;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Whether to show labels.
  final bool showLabels;

  /// Label rotation in degrees.
  final double labelRotation;

  /// Style for labels.
  final TextStyle? labelStyle;

  /// Style for the title.
  final TextStyle? titleStyle;

  /// Color of the axis line.
  final Color? lineColor;

  /// Color of tick marks.
  final Color? tickColor;

  /// Width of the axis line.
  final double lineWidth;

  /// Length of tick marks.
  final double tickLength;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    final effectiveConfig = config ??
        AxisConfig(
          position: position,
          title: title,
          titleStyle: titleStyle ?? theme.titleStyle,
          labelStyle: labelStyle ?? theme.labelStyle,
          lineColor: lineColor ?? theme.axisLineColor,
          tickColor: tickColor ?? theme.axisLineColor,
          lineWidth: lineWidth,
          tickLength: tickLength,
          labelRotation: labelRotation,
          showLine: showLine,
          showTicks: showTicks,
          showLabels: showLabels,
          tickCount: tickCount,
          labelFormatter: labelFormatter != null
              ? (dynamic v) => labelFormatter!(v as T)
              : null,
        );

    return CustomPaint(
      painter: _AxisPainter<T>(
        scale: scale,
        config: effectiveConfig,
      ),
    );
  }
}

class _AxisPainter<T> extends CustomPainter {
  _AxisPainter({
    required this.scale,
    required this.config,
  });

  final Scale<T> scale;
  final AxisConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final renderer = AxisRenderer<T>(
      config: config,
      scale: scale,
    );

    // Calculate chart area based on position
    final chartArea = _calculateChartArea(size);

    renderer.render(canvas, size, chartArea);
  }

  Rect _calculateChartArea(Size size) {
    // For standalone axis, the chart area is the full size
    // adjusted for the axis position
    switch (config.position) {
      case ChartPosition.bottom:
        return Rect.fromLTWH(0, 0, size.width, 0);
      case ChartPosition.top:
        return Rect.fromLTWH(0, size.height, size.width, 0);
      case ChartPosition.left:
        return Rect.fromLTWH(size.width, 0, 0, size.height);
      case ChartPosition.right:
        return Rect.fromLTWH(0, 0, 0, size.height);
      case ChartPosition.center:
        return Rect.fromLTWH(0, 0, size.width, size.height);
    }
  }

  @override
  bool shouldRepaint(covariant _AxisPainter<T> oldDelegate) {
    return scale != oldDelegate.scale || config != oldDelegate.config;
  }
}

/// Configuration builder for axes.
class AxisBuilder<T> {
  AxisBuilder({
    required this.scale,
    this.position = ChartPosition.bottom,
  });

  final Scale<T> scale;
  ChartPosition position;
  String? _title;
  TextStyle? _titleStyle;
  TextStyle? _labelStyle;
  Color? _lineColor;
  Color? _tickColor;
  double _lineWidth = 1.0;
  double _tickLength = 5.0;
  double _labelRotation = 0.0;
  bool _showLine = true;
  bool _showTicks = true;
  bool _showLabels = true;
  int? _tickCount;
  String Function(T)? _labelFormatter;

  /// Sets the axis title.
  AxisBuilder<T> title(String title, {TextStyle? style}) {
    _title = title;
    _titleStyle = style;
    return this;
  }

  /// Sets the label style.
  AxisBuilder<T> labelStyle(TextStyle style) {
    _labelStyle = style;
    return this;
  }

  /// Sets colors.
  AxisBuilder<T> colors({Color? line, Color? tick}) {
    _lineColor = line;
    _tickColor = tick;
    return this;
  }

  /// Sets line width.
  AxisBuilder<T> lineWidth(double width) {
    _lineWidth = width;
    return this;
  }

  /// Sets tick length.
  AxisBuilder<T> tickLength(double length) {
    _tickLength = length;
    return this;
  }

  /// Sets label rotation.
  AxisBuilder<T> labelRotation(double degrees) {
    _labelRotation = degrees;
    return this;
  }

  /// Hides the axis line.
  AxisBuilder<T> hideLine() {
    _showLine = false;
    return this;
  }

  /// Hides tick marks.
  AxisBuilder<T> hideTicks() {
    _showTicks = false;
    return this;
  }

  /// Hides labels.
  AxisBuilder<T> hideLabels() {
    _showLabels = false;
    return this;
  }

  /// Sets the number of ticks.
  AxisBuilder<T> tickCount(int count) {
    _tickCount = count;
    return this;
  }

  /// Sets a custom label formatter.
  AxisBuilder<T> formatLabels(String Function(T value) formatter) {
    _labelFormatter = formatter;
    return this;
  }

  /// Builds the axis configuration.
  AxisConfig build() {
    return AxisConfig(
      position: position,
      title: _title,
      titleStyle: _titleStyle,
      labelStyle: _labelStyle,
      lineColor: _lineColor,
      tickColor: _tickColor,
      lineWidth: _lineWidth,
      tickLength: _tickLength,
      labelRotation: _labelRotation,
      showLine: _showLine,
      showTicks: _showTicks,
      showLabels: _showLabels,
      tickCount: _tickCount,
      labelFormatter: _labelFormatter != null
          ? (dynamic v) => _labelFormatter!(v as T)
          : null,
    );
  }

  /// Builds the axis widget.
  ChartAxis<T> buildWidget() {
    return ChartAxis<T>(
      scale: scale,
      config: build(),
    );
  }
}

/// Extension to create axis builders from scales.
extension ScaleAxisExtension<T> on Scale<T> {
  /// Creates an axis builder for this scale.
  AxisBuilder<T> axis({ChartPosition position = ChartPosition.bottom}) {
    return AxisBuilder<T>(scale: this, position: position);
  }
}
