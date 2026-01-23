import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/math/scales/scale.dart';
import '../cache/text_cache.dart';
import 'renderer.dart';

/// Configuration for axis rendering.
class AxisConfig extends RendererConfig {
  const AxisConfig({
    this.visible = true,
    this.position = ChartPosition.bottom,
    this.title,
    this.titleStyle,
    this.labelStyle,
    this.lineColor,
    this.lineWidth = 1.0,
    this.tickLength = 5.0,
    this.tickWidth = 1.0,
    this.tickColor,
    this.labelPadding = 4.0,
    this.labelRotation = 0.0,
    this.showLine = true,
    this.showTicks = true,
    this.showLabels = true,
    this.tickCount,
    this.labelFormatter,
    this.minLabelSpacing = 40.0,
  });

  @override
  final bool visible;

  /// Position of the axis.
  final ChartPosition position;

  /// Optional title for the axis.
  final String? title;

  /// Style for the axis title.
  final TextStyle? titleStyle;

  /// Style for axis labels.
  final TextStyle? labelStyle;

  /// Color of the axis line.
  final Color? lineColor;

  /// Width of the axis line.
  final double lineWidth;

  /// Length of tick marks.
  final double tickLength;

  /// Width of tick marks.
  final double tickWidth;

  /// Color of tick marks.
  final Color? tickColor;

  /// Padding between ticks and labels.
  final double labelPadding;

  /// Rotation angle for labels in degrees.
  final double labelRotation;

  /// Whether to show the axis line.
  final bool showLine;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Whether to show labels.
  final bool showLabels;

  /// Desired number of ticks (hint, may vary).
  final int? tickCount;

  /// Custom label formatter.
  final String Function(dynamic value)? labelFormatter;

  /// Minimum spacing between labels.
  final double minLabelSpacing;

  /// Whether this is a horizontal axis.
  bool get isHorizontal =>
      position == ChartPosition.top || position == ChartPosition.bottom;

  /// Whether this is a vertical axis.
  bool get isVertical =>
      position == ChartPosition.left || position == ChartPosition.right;

  /// Creates a copy with updated values.
  AxisConfig copyWith({
    bool? visible,
    ChartPosition? position,
    String? title,
    TextStyle? titleStyle,
    TextStyle? labelStyle,
    Color? lineColor,
    double? lineWidth,
    double? tickLength,
    double? tickWidth,
    Color? tickColor,
    double? labelPadding,
    double? labelRotation,
    bool? showLine,
    bool? showTicks,
    bool? showLabels,
    int? tickCount,
    String Function(dynamic value)? labelFormatter,
    double? minLabelSpacing,
  }) {
    return AxisConfig(
      visible: visible ?? this.visible,
      position: position ?? this.position,
      title: title ?? this.title,
      titleStyle: titleStyle ?? this.titleStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      tickLength: tickLength ?? this.tickLength,
      tickWidth: tickWidth ?? this.tickWidth,
      tickColor: tickColor ?? this.tickColor,
      labelPadding: labelPadding ?? this.labelPadding,
      labelRotation: labelRotation ?? this.labelRotation,
      showLine: showLine ?? this.showLine,
      showTicks: showTicks ?? this.showTicks,
      showLabels: showLabels ?? this.showLabels,
      tickCount: tickCount ?? this.tickCount,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      minLabelSpacing: minLabelSpacing ?? this.minLabelSpacing,
    );
  }
}

/// Renderer for chart axes.
///
/// Supports horizontal and vertical axes with customizable
/// ticks, labels, and titles.
class AxisRenderer<T> with RendererMixin<AxisConfig> implements ChartRenderer<AxisConfig> {
  AxisRenderer({
    required AxisConfig config,
    required this.scale,
    TextCache? textCache,
  })  : _config = config,
        _textCache = textCache ?? ChartTextCache.instance.axisLabels;

  AxisConfig _config;
  Scale<T> scale;
  final TextCache _textCache;

  // Cached calculations
  List<T>? _cachedTicks;
  List<CachedTextLayout>? _cachedLabels;
  double? _cachedMaxLabelSize;

  @override
  AxisConfig get config => _config;

  @override
  void update(AxisConfig newConfig) {
    if (_config != newConfig) {
      _config = newConfig;
      _invalidateCache();
      markNeedsRepaint();
    }
  }

  /// Updates the scale.
  void updateScale(Scale<T> newScale) {
    scale = newScale;
    _invalidateCache();
    markNeedsRepaint();
  }

  void _invalidateCache() {
    _cachedTicks = null;
    _cachedLabels = null;
    _cachedMaxLabelSize = null;
  }

  @override
  void render(Canvas canvas, Size size, Rect chartArea) {
    if (!_config.visible) return;

    final ticks = _getTicks();
    if (ticks.isEmpty) return;

    final paint = Paint()
      ..color = _config.lineColor ?? const Color(0xFF666666)
      ..strokeWidth = _config.lineWidth
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = _config.tickColor ?? _config.lineColor ?? const Color(0xFF666666)
      ..strokeWidth = _config.tickWidth
      ..style = PaintingStyle.stroke;

    // Draw axis line
    if (_config.showLine) {
      _drawAxisLine(canvas, chartArea, paint);
    }

    // Draw ticks and labels
    for (final tick in ticks) {
      final position = _getTickPosition(tick, chartArea);

      if (_config.showTicks) {
        _drawTick(canvas, position, tickPaint);
      }

      if (_config.showLabels) {
        _drawLabel(canvas, tick, position);
      }
    }

    // Draw title
    if (_config.title != null) {
      _drawTitle(canvas, size, chartArea);
    }

    markPainted();
  }

  List<T> _getTicks() {
    if (_cachedTicks != null) return _cachedTicks!;
    _cachedTicks = scale.ticks(count: _config.tickCount);
    return _cachedTicks!;
  }

  void _drawAxisLine(Canvas canvas, Rect chartArea, Paint paint) {
    switch (_config.position) {
      case ChartPosition.bottom:
        canvas.drawLine(
          Offset(chartArea.left, chartArea.bottom),
          Offset(chartArea.right, chartArea.bottom),
          paint,
        );
      case ChartPosition.top:
        canvas.drawLine(
          Offset(chartArea.left, chartArea.top),
          Offset(chartArea.right, chartArea.top),
          paint,
        );
      case ChartPosition.left:
        canvas.drawLine(
          Offset(chartArea.left, chartArea.top),
          Offset(chartArea.left, chartArea.bottom),
          paint,
        );
      case ChartPosition.right:
        canvas.drawLine(
          Offset(chartArea.right, chartArea.top),
          Offset(chartArea.right, chartArea.bottom),
          paint,
        );
      case ChartPosition.center:
        break; // Not applicable for axes
    }
  }

  double _getTickPosition(T tick, Rect chartArea) {
    final scaledValue = scale.scale(tick);

    if (_config.isHorizontal) {
      return scaledValue.clamp(chartArea.left, chartArea.right);
    } else {
      return scaledValue.clamp(chartArea.top, chartArea.bottom);
    }
  }

  void _drawTick(Canvas canvas, double position, Paint paint) {
    switch (_config.position) {
      case ChartPosition.bottom:
        canvas.drawLine(
          Offset(position, 0),
          Offset(position, _config.tickLength),
          paint,
        );
      case ChartPosition.top:
        canvas.drawLine(
          Offset(position, 0),
          Offset(position, -_config.tickLength),
          paint,
        );
      case ChartPosition.left:
        canvas.drawLine(
          Offset(0, position),
          Offset(-_config.tickLength, position),
          paint,
        );
      case ChartPosition.right:
        canvas.drawLine(
          Offset(0, position),
          Offset(_config.tickLength, position),
          paint,
        );
      case ChartPosition.center:
        break;
    }
  }

  void _drawLabel(Canvas canvas, T tick, double position) {
    final labelStyle = _config.labelStyle ??
        const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
        );

    final label = _config.labelFormatter?.call(tick) ??
        scale.tickFormatter()(tick);

    final layout = _textCache.layoutText(label, labelStyle);

    Offset labelOffset;
    switch (_config.position) {
      case ChartPosition.bottom:
        labelOffset = Offset(
          position - layout.width / 2,
          _config.tickLength + _config.labelPadding,
        );
      case ChartPosition.top:
        labelOffset = Offset(
          position - layout.width / 2,
          -_config.tickLength - _config.labelPadding - layout.height,
        );
      case ChartPosition.left:
        labelOffset = Offset(
          -_config.tickLength - _config.labelPadding - layout.width,
          position - layout.height / 2,
        );
      case ChartPosition.right:
        labelOffset = Offset(
          _config.tickLength + _config.labelPadding,
          position - layout.height / 2,
        );
      case ChartPosition.center:
        labelOffset = Offset(position - layout.width / 2, -layout.height / 2);
    }

    if (_config.labelRotation != 0) {
      canvas.save();
      canvas.translate(
        labelOffset.dx + layout.width / 2,
        labelOffset.dy + layout.height / 2,
      );
      canvas.rotate(_config.labelRotation * math.pi / 180);
      layout.painter.paint(
        canvas,
        Offset(-layout.width / 2, -layout.height / 2),
      );
      canvas.restore();
    } else {
      layout.painter.paint(canvas, labelOffset);
    }
  }

  void _drawTitle(Canvas canvas, Size size, Rect chartArea) {
    if (_config.title == null) return;

    final titleStyle = _config.titleStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        );

    final layout = _textCache.layoutText(_config.title!, titleStyle);

    Offset titleOffset;
    double rotation = 0;

    switch (_config.position) {
      case ChartPosition.bottom:
        titleOffset = Offset(
          chartArea.center.dx - layout.width / 2,
          chartArea.bottom + _getMaxLabelSize() + 20,
        );
      case ChartPosition.top:
        titleOffset = Offset(
          chartArea.center.dx - layout.width / 2,
          chartArea.top - _getMaxLabelSize() - 20 - layout.height,
        );
      case ChartPosition.left:
        rotation = -math.pi / 2;
        titleOffset = Offset(
          chartArea.left - _getMaxLabelSize() - 30,
          chartArea.center.dy,
        );
      case ChartPosition.right:
        rotation = math.pi / 2;
        titleOffset = Offset(
          chartArea.right + _getMaxLabelSize() + 30,
          chartArea.center.dy,
        );
      case ChartPosition.center:
        titleOffset = Offset(
          chartArea.center.dx - layout.width / 2,
          chartArea.center.dy - layout.height / 2,
        );
    }

    if (rotation != 0) {
      canvas.save();
      canvas.translate(titleOffset.dx, titleOffset.dy);
      canvas.rotate(rotation);
      layout.painter.paint(
        canvas,
        Offset(-layout.width / 2, -layout.height / 2),
      );
      canvas.restore();
    } else {
      layout.painter.paint(canvas, titleOffset);
    }
  }

  double _getMaxLabelSize() {
    if (_cachedMaxLabelSize != null) return _cachedMaxLabelSize!;

    final ticks = _getTicks();
    final labelStyle = _config.labelStyle ??
        const TextStyle(fontSize: 12, color: Color(0xFF666666));

    double maxSize = 0;
    for (final tick in ticks) {
      final label = _config.labelFormatter?.call(tick) ??
          scale.tickFormatter()(tick);
      final layout = _textCache.layoutText(label, labelStyle);

      if (_config.isHorizontal) {
        maxSize = math.max(maxSize, layout.height);
      } else {
        maxSize = math.max(maxSize, layout.width);
      }
    }

    _cachedMaxLabelSize = maxSize;
    return maxSize;
  }

  @override
  EdgeInsets calculateInsets(Size availableSize) {
    if (!_config.visible) return EdgeInsets.zero;

    var inset = 0.0;

    if (_config.showTicks) {
      inset += _config.tickLength;
    }

    if (_config.showLabels) {
      inset += _config.labelPadding + _getMaxLabelSize();
    }

    if (_config.title != null) {
      final titleStyle = _config.titleStyle ??
          const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
      final titleLayout = _textCache.layoutText(_config.title!, titleStyle);

      if (_config.isHorizontal) {
        inset += titleLayout.height + 10;
      } else {
        inset += titleLayout.height + 10; // Rotated, so height becomes width
      }
    }

    switch (_config.position) {
      case ChartPosition.bottom:
        return EdgeInsets.only(bottom: inset);
      case ChartPosition.top:
        return EdgeInsets.only(top: inset);
      case ChartPosition.left:
        return EdgeInsets.only(left: inset);
      case ChartPosition.right:
        return EdgeInsets.only(right: inset);
      case ChartPosition.center:
        return EdgeInsets.zero;
    }
  }

  @override
  void dispose() {
    _invalidateCache();
  }
}

/// Factory for creating common axis configurations.
class AxisFactory {
  AxisFactory._();

  /// Creates a standard bottom X axis.
  static AxisConfig bottomAxis({
    String? title,
    TextStyle? labelStyle,
    TextStyle? titleStyle,
    Color? color,
  }) {
    return AxisConfig(
      position: ChartPosition.bottom,
      title: title,
      titleStyle: titleStyle,
      labelStyle: labelStyle,
      lineColor: color,
      tickColor: color,
    );
  }

  /// Creates a standard left Y axis.
  static AxisConfig leftAxis({
    String? title,
    TextStyle? labelStyle,
    TextStyle? titleStyle,
    Color? color,
  }) {
    return AxisConfig(
      position: ChartPosition.left,
      title: title,
      titleStyle: titleStyle,
      labelStyle: labelStyle,
      lineColor: color,
      tickColor: color,
    );
  }

  /// Creates a minimal axis (line only, no ticks or labels).
  static AxisConfig minimalAxis(ChartPosition position, {Color? color}) {
    return AxisConfig(
      position: position,
      lineColor: color,
      showTicks: false,
      showLabels: false,
    );
  }

  /// Creates a hidden axis (for layout calculation only).
  static AxisConfig hiddenAxis(ChartPosition position) {
    return AxisConfig(
      position: position,
      visible: false,
    );
  }
}
