import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../core/math/geometry/bounds_calculator.dart';
import '../../core/math/geometry/coordinate_transform.dart';
import 'series_painter.dart';

/// Orientation for bars.
enum BarOrientation {
  /// Vertical bars (default).
  vertical,

  /// Horizontal bars.
  horizontal,
}

/// Configuration for bar series rendering.
class BarSeriesConfig extends SeriesConfig {
  const BarSeriesConfig({
    super.visible = true,
    super.animationProgress = 1.0,
    this.color = const Color(0xFF2196F3),
    this.colors,
    this.borderColor,
    this.borderWidth = 0.0,
    this.cornerRadius = 0.0,
    this.orientation = BarOrientation.vertical,
    this.barWidth,
    this.barWidthFraction = 0.8,
    this.gradient,
    this.showValues = false,
    this.valueStyle,
    this.valueFormatter,
  });

  /// Default bar color.
  final Color color;

  /// Colors for individual bars (overrides color).
  final List<Color>? colors;

  /// Border color for bars.
  final Color? borderColor;

  /// Border width for bars.
  final double borderWidth;

  /// Corner radius for bars.
  final double cornerRadius;

  /// Bar orientation.
  final BarOrientation orientation;

  /// Fixed bar width (null for auto).
  final double? barWidth;

  /// Fraction of available width for each bar (0.0 to 1.0).
  final double barWidthFraction;

  /// Gradient for bars.
  final List<Color>? gradient;

  /// Whether to show values on bars.
  final bool showValues;

  /// Style for value labels.
  final TextStyle? valueStyle;

  /// Custom value formatter.
  final String Function(double value)? valueFormatter;

  /// Creates a copy with updated values.
  BarSeriesConfig copyWith({
    bool? visible,
    double? animationProgress,
    Color? color,
    List<Color>? colors,
    Color? borderColor,
    double? borderWidth,
    double? cornerRadius,
    BarOrientation? orientation,
    double? barWidth,
    double? barWidthFraction,
    List<Color>? gradient,
    bool? showValues,
    TextStyle? valueStyle,
    String Function(double value)? valueFormatter,
  }) {
    return BarSeriesConfig(
      visible: visible ?? this.visible,
      animationProgress: animationProgress ?? this.animationProgress,
      color: color ?? this.color,
      colors: colors ?? this.colors,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      orientation: orientation ?? this.orientation,
      barWidth: barWidth ?? this.barWidth,
      barWidthFraction: barWidthFraction ?? this.barWidthFraction,
      gradient: gradient ?? this.gradient,
      showValues: showValues ?? this.showValues,
      valueStyle: valueStyle ?? this.valueStyle,
      valueFormatter: valueFormatter ?? this.valueFormatter,
    );
  }
}

/// Data for a single bar.
class BarData {
  const BarData({
    required this.x,
    required this.y,
    this.label,
    this.color,
  });

  /// X position (category index for categorical, value for numerical).
  final double x;

  /// Y value (bar height).
  final double y;

  /// Optional label.
  final String? label;

  /// Optional color override.
  final Color? color;
}

/// Painter for bar series.
///
/// Renders bar charts with support for vertical/horizontal orientation,
/// rounded corners, gradients, and value labels.
///
/// For large datasets (50+ bars), viewport culling is automatically
/// applied to only render visible bars.
class BarPainter extends SeriesPainter<BarSeriesConfig>
    with GradientMixin, AnimatedSeriesMixin, ViewportCullingMixin {
  BarPainter({
    required super.config,
    required super.seriesIndex,
    required this.data,
    this.groupIndex = 0,
    this.groupCount = 1,
  });

  /// Data points for this series.
  List<BarData> data;

  /// Index of this series within a group (for grouped bars).
  int groupIndex;

  /// Total number of series in the group.
  int groupCount;

  // Cached computations
  List<Rect>? _cachedBarRects;
  int? _cachedDataHash;

  // Viewport culling state
  int _visibleStartIndex = 0;
  List<BarData> _visibleData = [];

  /// Updates the data.
  void updateData(List<BarData> newData) {
    data = newData;
    invalidateCache();
  }

  /// Updates grouping information.
  void updateGrouping({int? groupIndex, int? groupCount}) {
    if (groupIndex != null) this.groupIndex = groupIndex;
    if (groupCount != null) this.groupCount = groupCount;
    invalidateCache();
  }

  @override
  void invalidateCache() {
    _cachedBarRects = null;
    _cachedDataHash = null;
  }

  int _computeDataHash() {
    var hash = groupIndex ^ groupCount;
    for (final bar in data) {
      hash = hash ^ bar.x.hashCode ^ bar.y.hashCode;
    }
    return hash;
  }

  @override
  void render(
    Canvas canvas,
    Rect chartArea,
    CoordinateTransform transform,
  ) {
    if (!config.visible || data.isEmpty) return;

    // Apply viewport culling for large datasets
    _applyViewportCulling(transform.xBounds);

    // Compute bar rectangles
    final currentHash = _computeDataHash();
    if (_cachedDataHash != currentHash || _cachedBarRects == null) {
      _cachedBarRects = _computeBarRects(chartArea, transform);
      _cachedDataHash = currentHash;
    }

    final barRects = _cachedBarRects!;
    if (barRects.isEmpty) return;

    // Build spatial index for hit testing
    buildSpatialIndex(chartArea);
    _registerHitRegions(barRects);

    // Draw bars
    for (var i = 0; i < barRects.length; i++) {
      final originalIndex = _visibleStartIndex + i;
      _drawBar(canvas, chartArea, barRects[i], originalIndex);
    }

    // Draw value labels
    if (config.showValues) {
      _drawValueLabels(canvas, barRects);
    }
  }

  /// Applies viewport culling to get visible data.
  void _applyViewportCulling(Bounds visibleBounds) {
    // Skip culling for small datasets
    if (data.length <= cullingThreshold) {
      _visibleStartIndex = 0;
      _visibleData = data;
      return;
    }

    final result = cullDataToViewport(
      data,
      visibleBounds,
      getX: (d) => d.x,
    );

    _visibleStartIndex = result.startIndex;
    _visibleData = result.data;
  }

  List<Rect> _computeBarRects(Rect chartArea, CoordinateTransform transform) {
    final rects = <Rect>[];
    if (_visibleData.isEmpty) return rects;

    // Calculate bar width based on total data count (not visible)
    // to maintain consistent bar widths during panning
    final availableWidth = config.orientation == BarOrientation.vertical
        ? chartArea.width
        : chartArea.height;

    final totalBarWidth = config.barWidth ??
        (availableWidth / data.length * config.barWidthFraction);

    final groupBarWidth = totalBarWidth / groupCount;
    final barWidth = groupBarWidth * 0.9; // Small gap between grouped bars

    for (var i = 0; i < _visibleData.length; i++) {
      final bar = _visibleData[i];

      // Apply animation
      final animatedY = bar.y * config.animationProgress;

      if (config.orientation == BarOrientation.vertical) {
        final screenX = transform.dataToScreenX(bar.x);
        final screenY = transform.dataToScreenY(animatedY);
        final baseline = transform.dataToScreenY(0);

        final left = screenX -
            totalBarWidth / 2 +
            groupIndex * groupBarWidth +
            (groupBarWidth - barWidth) / 2;

        rects.add(Rect.fromLTRB(
          left,
          math.min(screenY, baseline),
          left + barWidth,
          math.max(screenY, baseline),
        ));
      } else {
        final screenX = transform.dataToScreenX(animatedY);
        final screenY = transform.dataToScreenY(bar.x);
        final baseline = transform.dataToScreenX(0);

        final top = screenY -
            totalBarWidth / 2 +
            groupIndex * groupBarWidth +
            (groupBarWidth - barWidth) / 2;

        rects.add(Rect.fromLTRB(
          math.min(screenX, baseline),
          top,
          math.max(screenX, baseline),
          top + barWidth,
        ));
      }
    }

    return rects;
  }

  void _registerHitRegions(List<Rect> barRects) {
    for (var i = 0; i < barRects.length; i++) {
      // Use original data index (accounting for viewport culling offset)
      final originalIndex = _visibleStartIndex + i;
      final bar = _visibleData[i];
      final rect = barRects[i];

      final info = DataPointInfo(
        seriesIndex: seriesIndex,
        dataIndex: originalIndex,
        screenPosition: rect.center,
        dataX: bar.x,
        dataY: bar.y,
        label: bar.label,
        color: _getBarColor(originalIndex),
        value: config.valueFormatter?.call(bar.y) ?? bar.y.toString(),
      );

      registerHitRegion(info, rect);
    }
  }

  void _drawBar(
      Canvas canvas, Rect chartArea, Rect rect, int originalIndex) {
    final color = _getBarColor(originalIndex);
    final barY = data[originalIndex].y;

    // Create bar paint
    final fillPaint = Paint()..style = PaintingStyle.fill;

    if (config.gradient != null && config.gradient!.isNotEmpty) {
      fillPaint.shader = config.orientation == BarOrientation.vertical
          ? createVerticalGradient(rect, config.gradient!)
          : createHorizontalGradient(rect, config.gradient!);
    } else {
      fillPaint.color = color;
    }

    // Draw bar with optional corner radius
    if (config.cornerRadius > 0) {
      final rrect = _createRoundedBar(rect, barY);
      canvas.drawRRect(rrect, fillPaint);

      // Draw border
      if (config.borderWidth > 0 && config.borderColor != null) {
        final borderPaint = Paint()
          ..color = config.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.borderWidth;
        canvas.drawRRect(rrect, borderPaint);
      }
    } else {
      canvas.drawRect(rect, fillPaint);

      // Draw border
      if (config.borderWidth > 0 && config.borderColor != null) {
        final borderPaint = Paint()
          ..color = config.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.borderWidth;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  RRect _createRoundedBar(Rect rect, double yValue) {
    final radius = Radius.circular(config.cornerRadius);

    // Only round the top corners for vertical bars, left for horizontal
    // Use the actual bar's y value to determine direction
    if (config.orientation == BarOrientation.vertical) {
      if (yValue >= 0) {
        return RRect.fromRectAndCorners(
          rect,
          topLeft: radius,
          topRight: radius,
        );
      } else {
        return RRect.fromRectAndCorners(
          rect,
          bottomLeft: radius,
          bottomRight: radius,
        );
      }
    } else {
      if (yValue >= 0) {
        return RRect.fromRectAndCorners(
          rect,
          topRight: radius,
          bottomRight: radius,
        );
      } else {
        return RRect.fromRectAndCorners(
          rect,
          topLeft: radius,
          bottomLeft: radius,
        );
      }
    }
  }

  /// Gets the color for a bar at the given original index.
  Color _getBarColor(int originalIndex) {
    // Check for individual bar color from original data
    if (originalIndex < data.length && data[originalIndex].color != null) {
      return data[originalIndex].color!;
    }

    // Check for colors array
    if (config.colors != null && originalIndex < config.colors!.length) {
      return config.colors![originalIndex];
    }

    return config.color;
  }

  void _drawValueLabels(Canvas canvas, List<Rect> barRects) {
    final style = config.valueStyle ??
        const TextStyle(
          fontSize: 10,
          color: Color(0xFF333333),
        );

    for (var i = 0; i < barRects.length; i++) {
      final bar = _visibleData[i];
      final rect = barRects[i];

      final valueText = config.valueFormatter?.call(bar.y) ??
          bar.y.toStringAsFixed(1);

      final textPainter = TextPainter(
        text: TextSpan(text: valueText, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      Offset position;
      if (config.orientation == BarOrientation.vertical) {
        position = Offset(
          rect.center.dx - textPainter.width / 2,
          rect.top - textPainter.height - 4,
        );
      } else {
        position = Offset(
          rect.right + 4,
          rect.center.dy - textPainter.height / 2,
        );
      }

      textPainter.paint(canvas, position);
    }
  }

  @override
  (Bounds, Bounds) calculateBounds() {
    if (data.isEmpty) {
      return (const Bounds(min: 0, max: 1), const Bounds(min: 0, max: 1));
    }

    final xValues = data.map((b) => b.x).toList();
    final yValues = data.map((b) => b.y).toList();

    final xBounds = Bounds.fromValues(xValues);
    var yBounds = Bounds.fromValues(yValues);

    // Include zero for bar charts
    yBounds = Bounds.includingZero(yBounds);

    return (xBounds, yBounds);
  }
}

/// Factory for creating bar painters.
class BarPainterFactory {
  BarPainterFactory._();

  /// Creates a basic vertical bar painter.
  static BarPainter vertical({
    required int seriesIndex,
    required List<BarData> data,
    required Color color,
  }) {
    return BarPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: BarSeriesConfig(color: color),
    );
  }

  /// Creates a horizontal bar painter.
  static BarPainter horizontal({
    required int seriesIndex,
    required List<BarData> data,
    required Color color,
  }) {
    return BarPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: BarSeriesConfig(
        color: color,
        orientation: BarOrientation.horizontal,
      ),
    );
  }

  /// Creates a bar painter with rounded corners.
  static BarPainter rounded({
    required int seriesIndex,
    required List<BarData> data,
    required Color color,
    double cornerRadius = 4.0,
  }) {
    return BarPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: BarSeriesConfig(
        color: color,
        cornerRadius: cornerRadius,
      ),
    );
  }

  /// Creates a bar painter with gradient.
  static BarPainter gradient({
    required int seriesIndex,
    required List<BarData> data,
    required List<Color> colors,
  }) {
    return BarPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: BarSeriesConfig(
        color: colors.first,
        gradient: colors,
      ),
    );
  }
}
