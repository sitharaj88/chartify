import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../core/math/scales/scale.dart';
import 'renderer.dart';

/// Configuration for grid rendering.
class GridConfig extends RendererConfig {
  const GridConfig({
    this.visible = true,
    this.horizontalLines = true,
    this.verticalLines = true,
    this.lineColor,
    this.lineWidth = 1.0,
    this.dashPattern,
    this.horizontalTickCount = 5,
    this.verticalTickCount = 5,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.fillColor,
    this.alternatingFillColors,
  });

  @override
  final bool visible;

  /// Whether to draw horizontal grid lines.
  final bool horizontalLines;

  /// Whether to draw vertical grid lines.
  final bool verticalLines;

  /// Color of grid lines.
  final Color? lineColor;

  /// Width of grid lines.
  final double lineWidth;

  /// Dash pattern for grid lines (null for solid).
  final List<double>? dashPattern;

  /// Number of horizontal grid lines (hint). Default is 5 for cleaner charts.
  final int horizontalTickCount;

  /// Number of vertical grid lines (hint). Default is 5 for cleaner charts.
  final int verticalTickCount;

  /// Whether to draw a border around the chart area.
  final bool showBorder;

  /// Color of the border.
  final Color? borderColor;

  /// Width of the border.
  final double borderWidth;

  /// Fill color for the chart area.
  final Color? fillColor;

  /// Alternating fill colors for bands.
  final List<Color>? alternatingFillColors;

  /// Creates a copy with updated values.
  GridConfig copyWith({
    bool? visible,
    bool? horizontalLines,
    bool? verticalLines,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    int? horizontalTickCount,
    int? verticalTickCount,
    bool? showBorder,
    Color? borderColor,
    double? borderWidth,
    Color? fillColor,
    List<Color>? alternatingFillColors,
  }) {
    return GridConfig(
      visible: visible ?? this.visible,
      horizontalLines: horizontalLines ?? this.horizontalLines,
      verticalLines: verticalLines ?? this.verticalLines,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      horizontalTickCount: horizontalTickCount ?? this.horizontalTickCount,
      verticalTickCount: verticalTickCount ?? this.verticalTickCount,
      showBorder: showBorder ?? this.showBorder,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      fillColor: fillColor ?? this.fillColor,
      alternatingFillColors: alternatingFillColors ?? this.alternatingFillColors,
    );
  }
}

/// Renderer for chart grid lines.
///
/// Draws horizontal and vertical grid lines based on scale ticks,
/// with support for dashed lines and alternating bands.
class GridRenderer<X, Y> with RendererMixin<GridConfig> implements ChartRenderer<GridConfig> {
  GridRenderer({
    required GridConfig config,
    this.xScale,
    this.yScale,
  }) : _config = config;

  GridConfig _config;
  Scale<X>? xScale;
  Scale<Y>? yScale;

  // Cached paths for performance
  Path? _horizontalLinesPath;
  Path? _verticalLinesPath;
  Path? _borderPath;

  @override
  GridConfig get config => _config;

  @override
  void update(GridConfig newConfig) {
    if (_config != newConfig) {
      _config = newConfig;
      _invalidateCache();
      markNeedsRepaint();
    }
  }

  /// Updates the scales.
  void updateScales({Scale<X>? newXScale, Scale<Y>? newYScale}) {
    if (newXScale != null) xScale = newXScale;
    if (newYScale != null) yScale = newYScale;
    _invalidateCache();
    markNeedsRepaint();
  }

  void _invalidateCache() {
    _horizontalLinesPath = null;
    _verticalLinesPath = null;
    _borderPath = null;
  }

  @override
  void render(Canvas canvas, Size size, Rect chartArea) {
    if (!_config.visible) return;

    // Draw background fill
    if (_config.fillColor != null) {
      final fillPaint = Paint()
        ..color = _config.fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(chartArea, fillPaint);
    }

    // Draw alternating bands
    if (_config.alternatingFillColors != null && yScale != null) {
      _drawAlternatingBands(canvas, chartArea);
    }

    final linePaint = Paint()
      ..color = _config.lineColor ?? const Color(0xFFE0E0E0)
      ..strokeWidth = _config.lineWidth
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    if (_config.horizontalLines && yScale != null) {
      _drawHorizontalLines(canvas, chartArea, linePaint);
    }

    // Draw vertical lines
    if (_config.verticalLines && xScale != null) {
      _drawVerticalLines(canvas, chartArea, linePaint);
    }

    // Draw border
    if (_config.showBorder) {
      _drawBorder(canvas, chartArea);
    }

    markPainted();
  }

  void _drawAlternatingBands(Canvas canvas, Rect chartArea) {
    final colors = _config.alternatingFillColors!;
    if (colors.isEmpty) return;

    final ticks = yScale!.ticks(count: _config.horizontalTickCount);
    if (ticks.length < 2) return;

    for (var i = 0; i < ticks.length - 1; i++) {
      final y1 = yScale!.scale(ticks[i]).clamp(chartArea.top, chartArea.bottom);
      final y2 = yScale!.scale(ticks[i + 1]).clamp(chartArea.top, chartArea.bottom);

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(chartArea.left, y1, chartArea.right, y2),
        paint,
      );
    }
  }

  void _drawHorizontalLines(Canvas canvas, Rect chartArea, Paint paint) {
    final ticks = yScale!.ticks(count: _config.horizontalTickCount);

    if (_config.dashPattern != null) {
      for (final tick in ticks) {
        final y = yScale!.scale(tick);
        if (y >= chartArea.top && y <= chartArea.bottom) {
          _drawDashedLine(
            canvas,
            Offset(chartArea.left, y),
            Offset(chartArea.right, y),
            paint,
          );
        }
      }
    } else {
      final path = _horizontalLinesPath ?? _buildHorizontalLinesPath(ticks, chartArea);
      _horizontalLinesPath = path;
      canvas.drawPath(path, paint);
    }
  }

  Path _buildHorizontalLinesPath(List<Y> ticks, Rect chartArea) {
    final path = Path();

    for (final tick in ticks) {
      final y = yScale!.scale(tick);
      if (y >= chartArea.top && y <= chartArea.bottom) {
        path.moveTo(chartArea.left, y);
        path.lineTo(chartArea.right, y);
      }
    }

    return path;
  }

  void _drawVerticalLines(Canvas canvas, Rect chartArea, Paint paint) {
    final ticks = xScale!.ticks(count: _config.verticalTickCount);

    if (_config.dashPattern != null) {
      for (final tick in ticks) {
        final x = xScale!.scale(tick);
        if (x >= chartArea.left && x <= chartArea.right) {
          _drawDashedLine(
            canvas,
            Offset(x, chartArea.top),
            Offset(x, chartArea.bottom),
            paint,
          );
        }
      }
    } else {
      final path = _verticalLinesPath ?? _buildVerticalLinesPath(ticks, chartArea);
      _verticalLinesPath = path;
      canvas.drawPath(path, paint);
    }
  }

  Path _buildVerticalLinesPath(List<X> ticks, Rect chartArea) {
    final path = Path();

    for (final tick in ticks) {
      final x = xScale!.scale(tick);
      if (x >= chartArea.left && x <= chartArea.right) {
        path.moveTo(x, chartArea.top);
        path.lineTo(x, chartArea.bottom);
      }
    }

    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final pattern = _config.dashPattern!;
    if (pattern.isEmpty) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (dx * dx + dy * dy);
    final distance = length > 0 ? _sqrt(length) : 0.0;

    if (distance == 0) return;

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var currentDistance = 0.0;
    var patternIndex = 0;
    var drawing = true;

    while (currentDistance < distance) {
      final segmentLength = pattern[patternIndex % pattern.length];
      final nextDistance = (currentDistance + segmentLength).clamp(0.0, distance);

      if (drawing) {
        canvas.drawLine(
          Offset(
            start.dx + unitDx * currentDistance,
            start.dy + unitDy * currentDistance,
          ),
          Offset(
            start.dx + unitDx * nextDistance,
            start.dy + unitDy * nextDistance,
          ),
          paint,
        );
      }

      currentDistance = nextDistance;
      patternIndex++;
      drawing = !drawing;
    }
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  void _drawBorder(Canvas canvas, Rect chartArea) {
    final borderPaint = Paint()
      ..color = _config.borderColor ?? _config.lineColor ?? const Color(0xFFE0E0E0)
      ..strokeWidth = _config.borderWidth
      ..style = PaintingStyle.stroke;

    _borderPath ??= Path()..addRect(chartArea);
    canvas.drawPath(_borderPath!, borderPaint);
  }

  @override
  EdgeInsets calculateInsets(Size availableSize) {
    // Grid doesn't require any insets
    return EdgeInsets.zero;
  }

  @override
  void dispose() {
    _invalidateCache();
  }
}

/// Factory for creating common grid configurations.
class GridFactory {
  GridFactory._();

  /// Creates a standard grid with both horizontal and vertical lines.
  static GridConfig standard({Color? color, double lineWidth = 1.0}) {
    return GridConfig(
      lineColor: color ?? const Color(0xFFE0E0E0),
      lineWidth: lineWidth,
    );
  }

  /// Creates a grid with only horizontal lines.
  static GridConfig horizontalOnly({Color? color, double lineWidth = 1.0}) {
    return GridConfig(
      horizontalLines: true,
      verticalLines: false,
      lineColor: color ?? const Color(0xFFE0E0E0),
      lineWidth: lineWidth,
    );
  }

  /// Creates a grid with only vertical lines.
  static GridConfig verticalOnly({Color? color, double lineWidth = 1.0}) {
    return GridConfig(
      horizontalLines: false,
      verticalLines: true,
      lineColor: color ?? const Color(0xFFE0E0E0),
      lineWidth: lineWidth,
    );
  }

  /// Creates a dashed grid.
  static GridConfig dashed({
    Color? color,
    double lineWidth = 1.0,
    List<double> dashPattern = const [5, 3],
  }) {
    return GridConfig(
      lineColor: color ?? const Color(0xFFE0E0E0),
      lineWidth: lineWidth,
      dashPattern: dashPattern,
    );
  }

  /// Creates a grid with alternating colored bands.
  static GridConfig banded({
    required List<Color> colors,
    bool showLines = false,
  }) {
    return GridConfig(
      horizontalLines: showLines,
      verticalLines: false,
      alternatingFillColors: colors,
    );
  }

  /// Creates an invisible grid (no visible elements).
  static GridConfig hidden() {
    return const GridConfig(visible: false);
  }
}
