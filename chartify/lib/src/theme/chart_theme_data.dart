import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  }) : _brightness = brightness;

  final Brightness? _brightness;

  /// The brightness of this theme.
  Brightness get brightness =>
      _brightness ?? ThemeData.estimateBrightnessForColor(backgroundColor);

  /// Creates a light theme.
  factory ChartThemeData.light() => ChartThemeData(
        colorPalette: ColorPalette.material(),
        backgroundColor: Colors.white,
        gridLineColor: const Color(0xFFE0E0E0),
        gridLineWidth: 1.0,
        axisLineColor: const Color(0xFF757575),
        axisLineWidth: 1.0,
        axisLabelColor: const Color(0xFF616161),
        titleStyle: const TextStyle(
          color: Color(0xFF212121),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        subtitleStyle: const TextStyle(
          color: Color(0xFF757575),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF616161),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        tooltipBackgroundColor: const Color(0xFF424242),
        tooltipTextColor: Colors.white,
        tooltipBorderColor: const Color(0xFF616161),
        tooltipBorderRadius: 8.0,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        legendTextStyle: const TextStyle(
          color: Color(0xFF616161),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectionColor: const Color(0x33448AFF),
        crosshairColor: const Color(0xFF9E9E9E),
      );

  /// Creates a dark theme.
  factory ChartThemeData.dark() => ChartThemeData(
        colorPalette: ColorPalette.materialDark(),
        backgroundColor: const Color(0xFF121212),
        gridLineColor: const Color(0xFF424242),
        gridLineWidth: 1.0,
        axisLineColor: const Color(0xFF757575),
        axisLineWidth: 1.0,
        axisLabelColor: const Color(0xFFBDBDBD),
        titleStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        subtitleStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        tooltipBackgroundColor: const Color(0xFF37474F),
        tooltipTextColor: Colors.white,
        tooltipBorderColor: const Color(0xFF546E7A),
        tooltipBorderRadius: 8.0,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        legendTextStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectionColor: const Color(0x4482B1FF),
        crosshairColor: const Color(0xFF757575),
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
      gridLineWidth: 1.0,
      axisLineColor: colorScheme.outline,
      axisLineWidth: 1.0,
      axisLabelColor: colorScheme.onSurfaceVariant,
      titleStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      subtitleStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      tooltipBackgroundColor: colorScheme.inverseSurface,
      tooltipTextColor: colorScheme.onInverseSurface,
      tooltipBorderColor: colorScheme.outline,
      tooltipBorderRadius: 8.0,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      legendTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      selectionColor: colorScheme.primary.withOpacity(0.2),
      crosshairColor: colorScheme.outline,
      brightness: brightness,
    );
  }

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

  /// Gets a color from the palette for a series.
  Color getSeriesColor(int index) => colorPalette[index];

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
          crosshairColor == other.crosshairColor;

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
        crosshairColor,
      );
}

/// A palette of colors for chart series.
@immutable
class ColorPalette {
  /// Creates a color palette from a list of colors.
  ///
  /// The [colors] list must not be empty.
  const ColorPalette(this.colors);

  /// The list of colors in this palette.
  final List<Color> colors;

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
    final step = 30.0;
    final start = -(count ~/ 2) * step;

    for (var i = 0; i < count; i++) {
      colors.add(hsl.withHue((hsl.hue + start + i * step) % 360).toColor());
    }

    return ColorPalette(colors);
  }

  /// Gets the color at the given index (wraps around).
  Color operator [](int index) => colors[index % colors.length];

  /// The number of colors in this palette.
  int get length => colors.length;

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
    super.key,
    required this.data,
    required super.child,
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
