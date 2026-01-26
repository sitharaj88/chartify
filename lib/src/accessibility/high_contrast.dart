import 'package:flutter/widgets.dart';

/// High contrast color schemes for accessibility.
///
/// Provides predefined color palettes that meet WCAG contrast requirements
/// for users with visual impairments.
class HighContrastColors {
  HighContrastColors._();

  /// High contrast colors for light backgrounds.
  static const List<Color> lightBackground = [
    Color(0xFF000000), // Black
    Color(0xFF0000CC), // Dark Blue
    Color(0xFFCC0000), // Dark Red
    Color(0xFF006600), // Dark Green
    Color(0xFF660066), // Dark Purple
    Color(0xFF996600), // Dark Orange
    Color(0xFF006666), // Dark Teal
    Color(0xFF660000), // Dark Maroon
  ];

  /// High contrast colors for dark backgrounds.
  static const List<Color> darkBackground = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FF00), // Lime
    Color(0xFFFFAA00), // Orange
    Color(0xFFFF6699), // Pink
    Color(0xFF99FF99), // Light Green
  ];

  /// Gets high contrast colors based on brightness.
  static List<Color> forBrightness(Brightness brightness) => brightness == Brightness.dark ? darkBackground : lightBackground;
}

/// Configuration for high contrast mode.
class HighContrastConfig {
  const HighContrastConfig({
    this.enabled = false,
    this.increaseStrokeWidth = true,
    this.strokeWidthMultiplier = 1.5,
    this.showPatterns = true,
    this.increaseMarkerSize = true,
    this.markerSizeMultiplier = 1.5,
    this.useStrongBorders = true,
    this.borderWidth = 2.0,
    this.borderColor,
  });

  /// Whether high contrast mode is enabled.
  final bool enabled;

  /// Whether to increase stroke width for better visibility.
  final bool increaseStrokeWidth;

  /// Multiplier for stroke width when enabled.
  final double strokeWidthMultiplier;

  /// Whether to show patterns in addition to colors.
  final bool showPatterns;

  /// Whether to increase marker size.
  final bool increaseMarkerSize;

  /// Multiplier for marker size when enabled.
  final double markerSizeMultiplier;

  /// Whether to use strong borders around chart elements.
  final bool useStrongBorders;

  /// Border width for strong borders.
  final double borderWidth;

  /// Custom border color (uses contrast color if null).
  final Color? borderColor;

  /// Creates a copy with updated values.
  HighContrastConfig copyWith({
    bool? enabled,
    bool? increaseStrokeWidth,
    double? strokeWidthMultiplier,
    bool? showPatterns,
    bool? increaseMarkerSize,
    double? markerSizeMultiplier,
    bool? useStrongBorders,
    double? borderWidth,
    Color? borderColor,
  }) => HighContrastConfig(
      enabled: enabled ?? this.enabled,
      increaseStrokeWidth: increaseStrokeWidth ?? this.increaseStrokeWidth,
      strokeWidthMultiplier: strokeWidthMultiplier ?? this.strokeWidthMultiplier,
      showPatterns: showPatterns ?? this.showPatterns,
      increaseMarkerSize: increaseMarkerSize ?? this.increaseMarkerSize,
      markerSizeMultiplier: markerSizeMultiplier ?? this.markerSizeMultiplier,
      useStrongBorders: useStrongBorders ?? this.useStrongBorders,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
}

/// Patterns for distinguishing data series in high contrast mode.
enum ChartPattern {
  /// Solid fill (no pattern).
  solid,

  /// Horizontal lines.
  horizontalLines,

  /// Vertical lines.
  verticalLines,

  /// Diagonal lines (top-left to bottom-right).
  diagonalLines,

  /// Reverse diagonal lines (top-right to bottom-left).
  reverseDiagonalLines,

  /// Dots pattern.
  dots,

  /// Cross-hatch pattern.
  crossHatch,

  /// Grid pattern.
  grid,
}

/// Utility for applying patterns to chart elements.
class PatternPainter {
  PatternPainter._();

  /// Creates a pattern shader for the given pattern type.
  static Shader? createPatternShader(
    ChartPattern pattern,
    Color color,
    Rect bounds, {
    double spacing = 8.0,
    double lineWidth = 2.0,
  }) {
    if (pattern == ChartPattern.solid) return null;

    // For complex patterns, we would create a custom shader.
    // This is a simplified implementation that returns null
    // and relies on the caller to handle pattern drawing.
    return null;
  }

  /// Draws a pattern on the canvas within the given path.
  static void drawPattern(
    Canvas canvas,
    Path clipPath,
    ChartPattern pattern,
    Color color, {
    double spacing = 8.0,
    double lineWidth = 2.0,
  }) {
    if (pattern == ChartPattern.solid) return;

    canvas.save();
    canvas.clipPath(clipPath);

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final bounds = clipPath.getBounds();

    switch (pattern) {
      case ChartPattern.solid:
        break;

      case ChartPattern.horizontalLines:
        _drawHorizontalLines(canvas, bounds, paint, spacing);

      case ChartPattern.verticalLines:
        _drawVerticalLines(canvas, bounds, paint, spacing);

      case ChartPattern.diagonalLines:
        _drawDiagonalLines(canvas, bounds, paint, spacing, false);

      case ChartPattern.reverseDiagonalLines:
        _drawDiagonalLines(canvas, bounds, paint, spacing, true);

      case ChartPattern.dots:
        _drawDots(canvas, bounds, paint, spacing);

      case ChartPattern.crossHatch:
        _drawDiagonalLines(canvas, bounds, paint, spacing, false);
        _drawDiagonalLines(canvas, bounds, paint, spacing, true);

      case ChartPattern.grid:
        _drawHorizontalLines(canvas, bounds, paint, spacing);
        _drawVerticalLines(canvas, bounds, paint, spacing);
    }

    canvas.restore();
  }

  static void _drawHorizontalLines(
    Canvas canvas,
    Rect bounds,
    Paint paint,
    double spacing,
  ) {
    for (var y = bounds.top; y <= bounds.bottom; y += spacing) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        paint,
      );
    }
  }

  static void _drawVerticalLines(
    Canvas canvas,
    Rect bounds,
    Paint paint,
    double spacing,
  ) {
    for (var x = bounds.left; x <= bounds.right; x += spacing) {
      canvas.drawLine(
        Offset(x, bounds.top),
        Offset(x, bounds.bottom),
        paint,
      );
    }
  }

  static void _drawDiagonalLines(
    Canvas canvas,
    Rect bounds,
    Paint paint,
    double spacing,
    bool reverse,
  ) {
    final diagonal = bounds.width + bounds.height;

    for (var d = -diagonal; d <= diagonal; d += spacing) {
      Offset start;
      Offset end;
      if (reverse) {
        start = Offset(bounds.right + d, bounds.top);
        end = Offset(bounds.left + d, bounds.bottom);
      } else {
        start = Offset(bounds.left + d, bounds.top);
        end = Offset(bounds.right + d, bounds.bottom);
      }
      canvas.drawLine(start, end, paint);
    }
  }

  static void _drawDots(
    Canvas canvas,
    Rect bounds,
    Paint paint,
    double spacing,
  ) {
    paint.style = PaintingStyle.fill;
    final dotRadius = paint.strokeWidth;

    for (var y = bounds.top; y <= bounds.bottom; y += spacing) {
      for (var x = bounds.left; x <= bounds.right; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }
}

/// Mixin for charts that support high contrast mode.
mixin HighContrastMixin {
  /// High contrast configuration.
  HighContrastConfig get highContrastConfig;

  /// Gets the pattern for a series index.
  ChartPattern getPatternForSeries(int index) {
    const patterns = ChartPattern.values;
    return patterns[index % patterns.length];
  }

  /// Applies high contrast adjustments to stroke width.
  double applyHighContrastStrokeWidth(double baseWidth) {
    if (!highContrastConfig.enabled || !highContrastConfig.increaseStrokeWidth) {
      return baseWidth;
    }
    return baseWidth * highContrastConfig.strokeWidthMultiplier;
  }

  /// Applies high contrast adjustments to marker size.
  double applyHighContrastMarkerSize(double baseSize) {
    if (!highContrastConfig.enabled || !highContrastConfig.increaseMarkerSize) {
      return baseSize;
    }
    return baseSize * highContrastConfig.markerSizeMultiplier;
  }

  /// Gets border paint for high contrast mode.
  Paint? getHighContrastBorderPaint(Brightness brightness) {
    if (!highContrastConfig.enabled || !highContrastConfig.useStrongBorders) {
      return null;
    }

    final borderColor = highContrastConfig.borderColor ??
        (brightness == Brightness.dark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000000));

    return Paint()
      ..color = borderColor
      ..strokeWidth = highContrastConfig.borderWidth
      ..style = PaintingStyle.stroke;
  }
}

/// Widget that provides high contrast mode context.
class HighContrastProvider extends InheritedWidget {
  const HighContrastProvider({
    required super.child, required this.config, super.key,
  });

  /// The high contrast configuration.
  final HighContrastConfig config;

  /// Gets the high contrast config from context.
  static HighContrastConfig of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<HighContrastProvider>();
    return provider?.config ?? const HighContrastConfig();
  }

  /// Gets the high contrast config from context, or null if not found.
  static HighContrastConfig? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<HighContrastProvider>();
    return provider?.config;
  }

  @override
  bool updateShouldNotify(HighContrastProvider oldWidget) => config != oldWidget.config;
}

/// Extension for checking system high contrast settings.
extension HighContrastExtension on MediaQueryData {
  /// Whether the system has high contrast mode enabled.
  bool get isHighContrastEnabled => highContrast;
}
