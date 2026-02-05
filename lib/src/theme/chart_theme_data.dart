import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../accessibility/contrast_validator.dart';

/// Theme data for charts.
///
/// Provides consistent styling across all chart types.
/// Can be used standalone or integrated with Material 3 theming.
///
/// Example:
/// ```dart
/// // Standalone usage
/// ChartTheme(
///   data: ChartThemeData.light(),
///   child: LineChart(...),
/// )
///
/// // Material 3 integration
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [ChartThemeData.light()],
///   ),
/// )
///
/// // Dynamic color from seed
/// ChartThemeData.fromSeed(Colors.blue)
///
/// // Modern design (recommended)
/// ChartThemeData.modern()
/// ```
@immutable
class ChartThemeData extends ThemeExtension<ChartThemeData> {
  /// Creates a chart theme data.
  const ChartThemeData({
    required this.colorPalette,
    required this.backgroundColor,
    required this.gridLineColor,
    required this.gridLineWidth,
    required this.axisLineColor,
    required this.axisLineWidth,
    required this.axisLabelColor,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.labelStyle,
    required this.tooltipBackgroundColor,
    required this.tooltipTextColor,
    required this.tooltipBorderColor,
    required this.tooltipBorderRadius,
    required this.tooltipPadding,
    required this.legendTextStyle,
    required this.selectionColor,
    required this.crosshairColor,
    Brightness? brightness,
    this.gridDashPattern,
    this.barCornerRadius = 6.0,
    this.defaultStrokeWidth = 2.5,
    this.defaultMarkerSize = 8.0,
    this.shadowBlurRadius = 8.0,
    this.shadowOpacity = 0.15,
    this.areaFillOpacity = 0.15,
  }) : _brightness = brightness;

  /// Creates a modern light theme with contemporary design standards.
  ///
  /// Features dashed grids, subtle shadows, refined typography,
  /// and a vibrant color palette optimized for max differentiation.
  factory ChartThemeData.modern() => const ChartThemeData(
        colorPalette: ColorPalette([
          Color(0xFF6366F1), // Indigo (hero)
          Color(0xFF10B981), // Emerald (strong contrast)
          Color(0xFFF59E0B), // Amber (warm complement)
          Color(0xFFEC4899), // Pink (accent)
          Color(0xFF3B82F6), // Blue
          Color(0xFF8B5CF6), // Violet
          Color(0xFFEF4444), // Red
          Color(0xFF14B8A6), // Teal
          Color(0xFFF97316), // Orange
          Color(0xFF06B6D4), // Cyan
        ]),
        backgroundColor: Color(0xFFFAFAFC),
        gridLineColor: Color(0xFFE5E7EB),
        gridLineWidth: 0.5,
        gridDashPattern: [6, 4],
        axisLineColor: Color(0xFFD1D5DB),
        axisLineWidth: 0.5,
        axisLabelColor: Color(0xFF9CA3AF),
        titleStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        subtitleStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        tooltipBackgroundColor: Color(0xEBFFFFFF),
        tooltipTextColor: Color(0xFF111827),
        tooltipBorderColor: Color(0xFFE5E7EB),
        tooltipBorderRadius: 10,
        tooltipPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        legendTextStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        selectionColor: Color(0x1F6366F1),
        crosshairColor: Color(0xFFD1D5DB),
      );

  /// Creates a modern dark theme with contemporary design standards.
  ///
  /// Dark variant optimized for OLED displays with vibrant colors
  /// that pop against the dark background.
  factory ChartThemeData.modernDark() => const ChartThemeData(
        colorPalette: ColorPalette([
          Color(0xFF818CF8), // Indigo 400 (hero)
          Color(0xFF34D399), // Emerald 400
          Color(0xFFFBBF24), // Amber 400
          Color(0xFFF472B6), // Pink 400
          Color(0xFF60A5FA), // Blue 400
          Color(0xFFA78BFA), // Violet 400
          Color(0xFFF87171), // Red 400
          Color(0xFF2DD4BF), // Teal 400
          Color(0xFFFB923C), // Orange 400
          Color(0xFF22D3EE), // Cyan 400
        ]),
        backgroundColor: Color(0xFF0F0F1A),
        gridLineColor: Color(0xFF374151),
        gridLineWidth: 0.5,
        gridDashPattern: [6, 4],
        axisLineColor: Color(0xFF4B5563),
        axisLineWidth: 0.5,
        axisLabelColor: Color(0xFF6B7280),
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        subtitleStyle: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        tooltipBackgroundColor: Color(0xF21F2937),
        tooltipTextColor: Colors.white,
        tooltipBorderColor: Color(0x14FFFFFF),
        tooltipBorderRadius: 10,
        tooltipPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        legendTextStyle: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        selectionColor: Color(0x26818CF8),
        crosshairColor: Color(0xFF4B5563),
      );

  /// Creates a light theme.
  factory ChartThemeData.light() => ChartThemeData(
        colorPalette: ColorPalette.modern(),
        backgroundColor: const Color(0xFFFAFAFC),
        gridLineColor: const Color(0xFFE5E7EB),
        gridLineWidth: 0.5,
        gridDashPattern: const [6, 4],
        axisLineColor: const Color(0xFFD1D5DB),
        axisLineWidth: 0.5,
        axisLabelColor: const Color(0xFF9CA3AF),
        titleStyle: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        subtitleStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        tooltipBackgroundColor: const Color(0xEBFFFFFF),
        tooltipTextColor: const Color(0xFF111827),
        tooltipBorderColor: const Color(0xFFE5E7EB),
        tooltipBorderRadius: 10,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        legendTextStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        selectionColor: const Color(0x1F6366F1),
        crosshairColor: const Color(0xFFD1D5DB),
      );

  /// Creates a dark theme.
  factory ChartThemeData.dark() => ChartThemeData(
        colorPalette: ColorPalette.modernDark(),
        backgroundColor: const Color(0xFF0F0F1A),
        gridLineColor: const Color(0xFF374151),
        gridLineWidth: 0.5,
        gridDashPattern: const [6, 4],
        axisLineColor: const Color(0xFF4B5563),
        axisLineWidth: 0.5,
        axisLabelColor: const Color(0xFF6B7280),
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        subtitleStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        tooltipBackgroundColor: const Color(0xF21F2937),
        tooltipTextColor: Colors.white,
        tooltipBorderColor: const Color(0x14FFFFFF),
        tooltipBorderRadius: 10,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        legendTextStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        selectionColor: const Color(0x26818CF8),
        crosshairColor: const Color(0xFF4B5563),
      );

  /// Creates a theme from a seed color using Material 3 color scheme.
  factory ChartThemeData.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ChartThemeData(
      colorPalette: ColorPalette.fromColorScheme(colorScheme),
      backgroundColor: colorScheme.surface,
      gridLineColor: colorScheme.outlineVariant,
      gridLineWidth: 0.5,
      gridDashPattern: const [6, 4],
      axisLineColor: colorScheme.outline,
      axisLineWidth: 0.5,
      axisLabelColor: colorScheme.onSurfaceVariant,
      titleStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      subtitleStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      tooltipBackgroundColor: colorScheme.inverseSurface,
      tooltipTextColor: colorScheme.onInverseSurface,
      tooltipBorderColor: colorScheme.outline,
      tooltipBorderRadius: 10,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      legendTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      selectionColor: colorScheme.primary.withValues(alpha: 0.12),
      crosshairColor: colorScheme.outline,
      brightness: brightness,
    );
  }

  final Brightness? _brightness;

  /// The brightness of this theme.
  Brightness get brightness =>
      _brightness ?? ThemeData.estimateBrightnessForColor(backgroundColor);

  /// The color palette for chart series.
  final ColorPalette colorPalette;

  /// The background color of the chart.
  final Color backgroundColor;

  /// The color of grid lines.
  final Color gridLineColor;

  /// The width of grid lines.
  final double gridLineWidth;

  /// The color of axis lines.
  final Color axisLineColor;

  /// The width of axis lines.
  final double axisLineWidth;

  /// The color of axis labels.
  final Color axisLabelColor;

  /// The text style for chart titles.
  final TextStyle titleStyle;

  /// The text style for chart subtitles.
  final TextStyle subtitleStyle;

  /// The text style for axis labels and data labels.
  final TextStyle labelStyle;

  /// The background color of tooltips.
  final Color tooltipBackgroundColor;

  /// The text color of tooltips.
  final Color tooltipTextColor;

  /// The border color of tooltips.
  final Color tooltipBorderColor;

  /// The border radius of tooltips.
  final double tooltipBorderRadius;

  /// The padding inside tooltips.
  final EdgeInsets tooltipPadding;

  /// The text style for legend items.
  final TextStyle legendTextStyle;

  /// The color for selection highlighting.
  final Color selectionColor;

  /// The color for crosshair lines.
  final Color crosshairColor;

  /// Dash pattern for grid lines. Null for solid lines.
  final List<double>? gridDashPattern;

  /// Default corner radius for bar charts.
  final double barCornerRadius;

  /// Default stroke width for line series.
  final double defaultStrokeWidth;

  /// Default marker size for data points.
  final double defaultMarkerSize;

  /// Default shadow blur radius for chart elements.
  final double shadowBlurRadius;

  /// Default shadow opacity (0.0 to 1.0).
  final double shadowOpacity;

  /// Default opacity for area fills under lines.
  final double areaFillOpacity;

  /// Gets a color from the palette for a series.
  Color getSeriesColor(int index) => colorPalette[index];

  /// Validates that all palette colors meet contrast requirements against the background.
  ///
  /// Returns a map of failing color indices to their contrast issues.
  /// An empty map means all colors pass validation.
  Map<int, ContrastIssue> validateColorContrast({
    ContrastLevel level = ContrastLevel.aa,
  }) =>
      ContrastValidator.validatePalette(
        colorPalette.colors,
        backgroundColor,
        level: level,
      );

  /// Returns true if all palette colors meet the specified contrast level.
  bool meetsContrastRequirements({ContrastLevel level = ContrastLevel.aa}) =>
      validateColorContrast(level: level).isEmpty;

  /// Creates a copy of this theme with colors adjusted for accessibility.
  ///
  /// Automatically adjusts any palette colors that don't meet the specified
  /// contrast level against the background.
  ChartThemeData withAccessibleColors({ContrastLevel level = ContrastLevel.aa}) {
    final accessibleColors = colorPalette.colors.map((color) {
      if (ContrastValidator.meetsLevel(color, backgroundColor, level)) {
        return color;
      }
      return ContrastValidator.suggestAccessibleColor(
        color,
        backgroundColor,
        level: level,
      );
    }).toList();

    return copyWith(colorPalette: ColorPalette(accessibleColors));
  }

  @override
  ChartThemeData copyWith({
    ColorPalette? colorPalette,
    Color? backgroundColor,
    Color? gridLineColor,
    double? gridLineWidth,
    Color? axisLineColor,
    double? axisLineWidth,
    Color? axisLabelColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? labelStyle,
    Color? tooltipBackgroundColor,
    Color? tooltipTextColor,
    Color? tooltipBorderColor,
    double? tooltipBorderRadius,
    EdgeInsets? tooltipPadding,
    TextStyle? legendTextStyle,
    Color? selectionColor,
    Color? crosshairColor,
    Brightness? brightness,
    List<double>? gridDashPattern,
    double? barCornerRadius,
    double? defaultStrokeWidth,
    double? defaultMarkerSize,
    double? shadowBlurRadius,
    double? shadowOpacity,
    double? areaFillOpacity,
  }) =>
      ChartThemeData(
        colorPalette: colorPalette ?? this.colorPalette,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        gridLineColor: gridLineColor ?? this.gridLineColor,
        gridLineWidth: gridLineWidth ?? this.gridLineWidth,
        axisLineColor: axisLineColor ?? this.axisLineColor,
        axisLineWidth: axisLineWidth ?? this.axisLineWidth,
        axisLabelColor: axisLabelColor ?? this.axisLabelColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        labelStyle: labelStyle ?? this.labelStyle,
        tooltipBackgroundColor:
            tooltipBackgroundColor ?? this.tooltipBackgroundColor,
        tooltipTextColor: tooltipTextColor ?? this.tooltipTextColor,
        tooltipBorderColor: tooltipBorderColor ?? this.tooltipBorderColor,
        tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
        tooltipPadding: tooltipPadding ?? this.tooltipPadding,
        legendTextStyle: legendTextStyle ?? this.legendTextStyle,
        selectionColor: selectionColor ?? this.selectionColor,
        crosshairColor: crosshairColor ?? this.crosshairColor,
        brightness: brightness ?? _brightness,
        gridDashPattern: gridDashPattern ?? this.gridDashPattern,
        barCornerRadius: barCornerRadius ?? this.barCornerRadius,
        defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
        defaultMarkerSize: defaultMarkerSize ?? this.defaultMarkerSize,
        shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
        shadowOpacity: shadowOpacity ?? this.shadowOpacity,
        areaFillOpacity: areaFillOpacity ?? this.areaFillOpacity,
      );

  @override
  ChartThemeData lerp(covariant ChartThemeData? other, double t) {
    if (other == null) return this;

    return ChartThemeData(
      colorPalette: colorPalette.lerp(other.colorPalette, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      gridLineColor: Color.lerp(gridLineColor, other.gridLineColor, t)!,
      gridLineWidth: lerpDouble(gridLineWidth, other.gridLineWidth, t)!,
      axisLineColor: Color.lerp(axisLineColor, other.axisLineColor, t)!,
      axisLineWidth: lerpDouble(axisLineWidth, other.axisLineWidth, t)!,
      axisLabelColor: Color.lerp(axisLabelColor, other.axisLabelColor, t)!,
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t)!,
      subtitleStyle: TextStyle.lerp(subtitleStyle, other.subtitleStyle, t)!,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t)!,
      tooltipBackgroundColor:
          Color.lerp(tooltipBackgroundColor, other.tooltipBackgroundColor, t)!,
      tooltipTextColor:
          Color.lerp(tooltipTextColor, other.tooltipTextColor, t)!,
      tooltipBorderColor:
          Color.lerp(tooltipBorderColor, other.tooltipBorderColor, t)!,
      tooltipBorderRadius:
          lerpDouble(tooltipBorderRadius, other.tooltipBorderRadius, t)!,
      tooltipPadding: EdgeInsets.lerp(tooltipPadding, other.tooltipPadding, t)!,
      legendTextStyle:
          TextStyle.lerp(legendTextStyle, other.legendTextStyle, t)!,
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t)!,
      crosshairColor: Color.lerp(crosshairColor, other.crosshairColor, t)!,
      brightness: t < 0.5 ? _brightness : other._brightness,
      gridDashPattern: t < 0.5 ? gridDashPattern : other.gridDashPattern,
      barCornerRadius: lerpDouble(barCornerRadius, other.barCornerRadius, t)!,
      defaultStrokeWidth: lerpDouble(defaultStrokeWidth, other.defaultStrokeWidth, t)!,
      defaultMarkerSize: lerpDouble(defaultMarkerSize, other.defaultMarkerSize, t)!,
      shadowBlurRadius: lerpDouble(shadowBlurRadius, other.shadowBlurRadius, t)!,
      shadowOpacity: lerpDouble(shadowOpacity, other.shadowOpacity, t)!,
      areaFillOpacity: lerpDouble(areaFillOpacity, other.areaFillOpacity, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartThemeData &&
          runtimeType == other.runtimeType &&
          colorPalette == other.colorPalette &&
          backgroundColor == other.backgroundColor &&
          gridLineColor == other.gridLineColor &&
          gridLineWidth == other.gridLineWidth &&
          axisLineColor == other.axisLineColor &&
          axisLineWidth == other.axisLineWidth &&
          axisLabelColor == other.axisLabelColor &&
          titleStyle == other.titleStyle &&
          subtitleStyle == other.subtitleStyle &&
          labelStyle == other.labelStyle &&
          tooltipBackgroundColor == other.tooltipBackgroundColor &&
          tooltipTextColor == other.tooltipTextColor &&
          tooltipBorderColor == other.tooltipBorderColor &&
          tooltipBorderRadius == other.tooltipBorderRadius &&
          tooltipPadding == other.tooltipPadding &&
          legendTextStyle == other.legendTextStyle &&
          selectionColor == other.selectionColor &&
          crosshairColor == other.crosshairColor &&
          barCornerRadius == other.barCornerRadius &&
          defaultStrokeWidth == other.defaultStrokeWidth &&
          defaultMarkerSize == other.defaultMarkerSize &&
          shadowBlurRadius == other.shadowBlurRadius &&
          shadowOpacity == other.shadowOpacity &&
          areaFillOpacity == other.areaFillOpacity;

  @override
  int get hashCode => Object.hash(
        colorPalette,
        backgroundColor,
        gridLineColor,
        gridLineWidth,
        axisLineColor,
        axisLineWidth,
        axisLabelColor,
        titleStyle,
        subtitleStyle,
        labelStyle,
        tooltipBackgroundColor,
        tooltipTextColor,
        tooltipBorderColor,
        tooltipBorderRadius,
        tooltipPadding,
        legendTextStyle,
        selectionColor,
        Object.hash(
          crosshairColor,
          barCornerRadius,
          defaultStrokeWidth,
          defaultMarkerSize,
          shadowBlurRadius,
          shadowOpacity,
          areaFillOpacity,
        ),
      );
}

/// A palette of colors for chart series.
@immutable
class ColorPalette {
  /// Creates a color palette from a list of colors.
  ///
  /// The [colors] list must not be empty.
  const ColorPalette(this.colors);

  /// Creates a Material Design color palette.
  factory ColorPalette.material() => const ColorPalette([
        Color(0xFF2196F3), // Blue
        Color(0xFFF44336), // Red
        Color(0xFF4CAF50), // Green
        Color(0xFFFF9800), // Orange
        Color(0xFF9C27B0), // Purple
        Color(0xFF00BCD4), // Cyan
        Color(0xFFE91E63), // Pink
        Color(0xFF8BC34A), // Light Green
        Color(0xFF3F51B5), // Indigo
        Color(0xFFFF5722), // Deep Orange
      ]);

  /// Creates a modern color palette with vibrant contemporary colors.
  ///
  /// Ordered for maximum visual differentiation when using 2-4 series.
  factory ColorPalette.modern() => const ColorPalette([
        Color(0xFF6366F1), // Indigo (hero)
        Color(0xFF10B981), // Emerald (strong contrast)
        Color(0xFFF59E0B), // Amber (warm complement)
        Color(0xFFEC4899), // Pink (accent)
        Color(0xFF3B82F6), // Blue
        Color(0xFF8B5CF6), // Violet
        Color(0xFFEF4444), // Red
        Color(0xFF14B8A6), // Teal
        Color(0xFFF97316), // Orange
        Color(0xFF06B6D4), // Cyan
      ]);

  /// Creates a Material Design dark color palette.
  factory ColorPalette.materialDark() => const ColorPalette([
        Color(0xFF64B5F6), // Blue 300
        Color(0xFFE57373), // Red 300
        Color(0xFF81C784), // Green 300
        Color(0xFFFFB74D), // Orange 300
        Color(0xFFBA68C8), // Purple 300
        Color(0xFF4DD0E1), // Cyan 300
        Color(0xFFF06292), // Pink 300
        Color(0xFFAED581), // Light Green 300
        Color(0xFF7986CB), // Indigo 300
        Color(0xFFFF8A65), // Deep Orange 300
      ]);

  /// Creates a modern dark color palette with vibrant colors optimized for dark backgrounds.
  ///
  /// Ordered for maximum visual differentiation when using 2-4 series.
  factory ColorPalette.modernDark() => const ColorPalette([
        Color(0xFF818CF8), // Indigo 400 (hero)
        Color(0xFF34D399), // Emerald 400
        Color(0xFFFBBF24), // Amber 400
        Color(0xFFF472B6), // Pink 400
        Color(0xFF60A5FA), // Blue 400
        Color(0xFFA78BFA), // Violet 400
        Color(0xFFF87171), // Red 400
        Color(0xFF2DD4BF), // Teal 400
        Color(0xFFFB923C), // Orange 400
        Color(0xFF22D3EE), // Cyan 400
      ]);

  /// Creates a color palette from a Material 3 color scheme.
  factory ColorPalette.fromColorScheme(ColorScheme scheme) => ColorPalette([
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        scheme.error,
        scheme.primaryContainer,
        scheme.secondaryContainer,
        scheme.tertiaryContainer,
        scheme.errorContainer,
      ]);

  /// Creates a monochromatic palette from a single color.
  factory ColorPalette.monochromatic(Color baseColor, {int count = 6}) {
    final hsl = HSLColor.fromColor(baseColor);
    final colors = <Color>[];

    for (var i = 0; i < count; i++) {
      final lightness = 0.3 + (0.4 * i / (count - 1));
      colors.add(hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor());
    }

    return ColorPalette(colors);
  }

  /// Creates a complementary palette from a base color.
  factory ColorPalette.complementary(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return ColorPalette([
      baseColor,
      hsl.withHue((hsl.hue + 180) % 360).toColor(),
      hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor(),
      hsl
          .withHue((hsl.hue + 180) % 360)
          .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
          .toColor(),
    ]);
  }

  /// Creates an analogous palette from a base color.
  factory ColorPalette.analogous(Color baseColor, {int count = 5}) {
    final hsl = HSLColor.fromColor(baseColor);
    final colors = <Color>[];
    const step = 30.0;
    final start = -(count ~/ 2) * step;

    for (var i = 0; i < count; i++) {
      colors.add(hsl.withHue((hsl.hue + start + i * step) % 360).toColor());
    }

    return ColorPalette(colors);
  }

  /// Creates a high contrast palette suitable for accessibility.
  ///
  /// These colors meet WCAG AA requirements on most backgrounds.
  factory ColorPalette.highContrast({Brightness brightness = Brightness.light}) {
    if (brightness == Brightness.dark) {
      return const ColorPalette([
        Color(0xFFFFFFFF), // White
        Color(0xFFFFFF00), // Yellow
        Color(0xFF00FFFF), // Cyan
        Color(0xFFFF00FF), // Magenta
        Color(0xFF00FF00), // Lime
        Color(0xFFFFAA00), // Orange
        Color(0xFFFF6699), // Pink
        Color(0xFF99FF99), // Light Green
      ]);
    }
    return const ColorPalette([
      Color(0xFF000000), // Black
      Color(0xFF0000CC), // Dark Blue
      Color(0xFFCC0000), // Dark Red
      Color(0xFF006600), // Dark Green
      Color(0xFF660066), // Dark Purple
      Color(0xFF996600), // Dark Orange
      Color(0xFF006666), // Dark Teal
      Color(0xFF660000), // Dark Maroon
    ]);
  }

  /// The list of colors in this palette.
  final List<Color> colors;

  /// Gets the color at the given index (wraps around).
  Color operator [](int index) => colors[index % colors.length];

  /// The number of colors in this palette.
  int get length => colors.length;

  /// Validates all colors against a background and returns contrast issues.
  Map<int, ContrastIssue> validateContrast(
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) =>
      ContrastValidator.validatePalette(colors, background, level: level);

  /// Returns a new palette with colors adjusted to meet contrast requirements.
  ColorPalette ensureContrast(
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) {
    final adjustedColors = colors.map((color) {
      if (ContrastValidator.meetsLevel(color, background, level)) {
        return color;
      }
      return ContrastValidator.suggestAccessibleColor(
        color,
        background,
        level: level,
      );
    }).toList();

    return ColorPalette(adjustedColors);
  }

  /// Interpolates between two palettes.
  ColorPalette lerp(ColorPalette other, double t) {
    final maxLength =
        colors.length > other.colors.length ? colors.length : other.colors.length;
    final lerpedColors = <Color>[];

    for (var i = 0; i < maxLength; i++) {
      final c1 = this[i];
      final c2 = other[i];
      lerpedColors.add(Color.lerp(c1, c2, t)!);
    }

    return ColorPalette(lerpedColors);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorPalette &&
          runtimeType == other.runtimeType &&
          listEquals(colors, other.colors);

  @override
  int get hashCode => Object.hashAll(colors);
}

/// InheritedWidget for providing chart theme to descendants.
class ChartTheme extends InheritedWidget {
  /// Creates a chart theme widget.
  const ChartTheme({
    required this.data, required super.child, super.key,
  });

  /// The theme data.
  final ChartThemeData data;

  /// Gets the chart theme from the given context.
  ///
  /// If no ChartTheme is found, returns the theme from MaterialApp's
  /// ThemeExtension, or falls back to light theme.
  static ChartThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ChartTheme>();
    if (widget != null) return widget.data;

    // Try to get from Material theme extensions
    final theme = Theme.of(context);
    final chartTheme = theme.extension<ChartThemeData>();
    if (chartTheme != null) return chartTheme;

    // Fallback based on brightness
    return theme.brightness == Brightness.dark
        ? ChartThemeData.dark()
        : ChartThemeData.light();
  }

  /// Gets the chart theme from the given context, or null if not found.
  static ChartThemeData? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ChartTheme>();
    return widget?.data;
  }

  @override
  bool updateShouldNotify(ChartTheme oldWidget) => data != oldWidget.data;
}

/// Extension for easy access to chart theme from BuildContext.
extension ChartThemeExtension on BuildContext {
  /// Gets the chart theme data from this context.
  ChartThemeData get chartTheme => ChartTheme.of(this);
}
