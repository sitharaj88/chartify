import 'package:flutter/widgets.dart';

import '../../accessibility/focus_indicator.dart';
import '../../accessibility/high_contrast.dart';
import 'density_config.dart';
import 'responsive_config.dart';
import 'text_scaling.dart';

/// Unified responsive theme provider for charts.
///
/// Combines responsive configuration, density settings, text scaling,
/// focus indicators, and high contrast settings into a single provider.
///
/// Example:
/// ```dart
/// ResponsiveChartTheme(
///   child: MyChart(),
/// )
///
/// // Access in child widgets:
/// final theme = ResponsiveChartTheme.of(context);
/// final padding = theme.responsiveConfig.padding;
/// ```
class ResponsiveChartTheme extends StatelessWidget {
  const ResponsiveChartTheme({
    required this.child,
    super.key,
    this.responsiveConfig,
    this.densityConfig,
    this.textScalingConfig,
    this.focusIndicatorStyle,
    this.highContrastConfig,
  });

  /// The child widget tree.
  final Widget child;

  /// Override responsive configuration.
  final ResponsiveChartConfig? responsiveConfig;

  /// Override density configuration.
  final DensityConfig? densityConfig;

  /// Override text scaling configuration.
  final TextScalingConfig? textScalingConfig;

  /// Override focus indicator style.
  final FocusIndicatorStyle? focusIndicatorStyle;

  /// Override high contrast configuration.
  final HighContrastConfig? highContrastConfig;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final resolvedConfig = responsiveConfig ??
              ResponsiveChartConfig.fromConstraints(constraints);

          final resolvedDensity = densityConfig ??
              DensityConfig.fromDensity(ChartDensity.normal);

          final resolvedTextScaling =
              textScalingConfig ?? const TextScalingConfig();

          final resolvedFocusStyle =
              focusIndicatorStyle ?? const FocusIndicatorStyle();

          final resolvedHighContrast =
              highContrastConfig ?? const HighContrastConfig();

          return _ResponsiveChartThemeData(
            responsiveConfig: resolvedConfig,
            densityConfig: resolvedDensity,
            textScalingConfig: resolvedTextScaling,
            focusIndicatorStyle: resolvedFocusStyle,
            highContrastConfig: resolvedHighContrast,
            child: child,
          );
        },
      );

  /// Gets the complete theme data from context.
  static ResponsiveChartThemeData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ResponsiveChartThemeData>();
    if (inherited != null) {
      return ResponsiveChartThemeData(
        responsiveConfig: inherited.responsiveConfig,
        densityConfig: inherited.densityConfig,
        textScalingConfig: inherited.textScalingConfig,
        focusIndicatorStyle: inherited.focusIndicatorStyle,
        highContrastConfig: inherited.highContrastConfig,
      );
    }

    // Return defaults if no theme found
    return ResponsiveChartThemeData.defaults(context);
  }

  /// Gets the theme data from context, or null if not found.
  static ResponsiveChartThemeData? maybeOf(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ResponsiveChartThemeData>();
    if (inherited == null) return null;

    return ResponsiveChartThemeData(
      responsiveConfig: inherited.responsiveConfig,
      densityConfig: inherited.densityConfig,
      textScalingConfig: inherited.textScalingConfig,
      focusIndicatorStyle: inherited.focusIndicatorStyle,
      highContrastConfig: inherited.highContrastConfig,
    );
  }

  /// Creates theme with automatic configuration based on context.
  static Widget auto({
    required Widget child,
    bool detectHighContrast = true,
  }) =>
      Builder(
        builder: (context) {
          HighContrastConfig? highContrast;
          if (detectHighContrast) {
            final mediaQuery = MediaQuery.of(context);
            if (mediaQuery.highContrast) {
              highContrast = const HighContrastConfig(enabled: true);
            }
          }

          return ResponsiveChartTheme(
            highContrastConfig: highContrast,
            child: child,
          );
        },
      );
}

/// Internal inherited widget for theme data.
class _ResponsiveChartThemeData extends InheritedWidget {
  const _ResponsiveChartThemeData({
    required this.responsiveConfig,
    required this.densityConfig,
    required this.textScalingConfig,
    required this.focusIndicatorStyle,
    required this.highContrastConfig,
    required super.child,
  });

  final ResponsiveChartConfig responsiveConfig;
  final DensityConfig densityConfig;
  final TextScalingConfig textScalingConfig;
  final FocusIndicatorStyle focusIndicatorStyle;
  final HighContrastConfig highContrastConfig;

  @override
  bool updateShouldNotify(_ResponsiveChartThemeData oldWidget) =>
      responsiveConfig != oldWidget.responsiveConfig ||
      densityConfig != oldWidget.densityConfig ||
      textScalingConfig != oldWidget.textScalingConfig ||
      focusIndicatorStyle != oldWidget.focusIndicatorStyle ||
      highContrastConfig != oldWidget.highContrastConfig;
}

/// Data class containing all theme configuration.
class ResponsiveChartThemeData {
  const ResponsiveChartThemeData({
    required this.responsiveConfig,
    required this.densityConfig,
    required this.textScalingConfig,
    required this.focusIndicatorStyle,
    required this.highContrastConfig,
  });

  /// Creates theme data with defaults based on context.
  factory ResponsiveChartThemeData.defaults(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveChartThemeData(
      responsiveConfig: ResponsiveChartConfig.fromWidth(size.width),
      densityConfig: const DensityConfig.normal(),
      textScalingConfig: const TextScalingConfig(),
      focusIndicatorStyle: const FocusIndicatorStyle(),
      highContrastConfig: const HighContrastConfig(),
    );
  }

  /// Responsive configuration (breakpoints, padding, etc.).
  final ResponsiveChartConfig responsiveConfig;

  /// Density configuration (spacing multipliers).
  final DensityConfig densityConfig;

  /// Text scaling configuration.
  final TextScalingConfig textScalingConfig;

  /// Focus indicator style.
  final FocusIndicatorStyle focusIndicatorStyle;

  /// High contrast configuration.
  final HighContrastConfig highContrastConfig;

  /// Convenience getters for common values.

  /// Gets the current device class.
  DeviceClass get deviceClass => responsiveConfig.deviceClass;

  /// Gets the chart padding with density applied.
  EdgeInsets get padding =>
      densityConfig.applyPaddingInsets(responsiveConfig.padding);

  /// Gets the title font size with density applied.
  double get titleFontSize =>
      responsiveConfig.titleFontSize * densityConfig.spacingMultiplier;

  /// Gets the label font size.
  double get labelFontSize => responsiveConfig.labelFontSize;

  /// Gets the stroke width with density applied.
  double get strokeWidth =>
      densityConfig.applyStrokeWidth(responsiveConfig.strokeWidth);

  /// Gets the hit test radius.
  double get hitTestRadius => responsiveConfig.hitTestRadius;

  /// Gets the marker size with density applied.
  double get markerSize =>
      densityConfig.applyMarkerSize(responsiveConfig.markerSize);

  /// Gets the legend position.
  LegendPosition get legendPosition => responsiveConfig.legendPosition;

  /// Whether high contrast mode is enabled.
  bool get isHighContrast => highContrastConfig.enabled;

  /// Whether text scaling is enabled.
  bool get enableTextScaling => textScalingConfig.enabled;

  /// Applies text scaling to a font size.
  double scaledFontSize(BuildContext context, double baseSize) =>
      textScalingConfig.applyScaling(context, baseSize);

  /// Creates a copy with updated values.
  ResponsiveChartThemeData copyWith({
    ResponsiveChartConfig? responsiveConfig,
    DensityConfig? densityConfig,
    TextScalingConfig? textScalingConfig,
    FocusIndicatorStyle? focusIndicatorStyle,
    HighContrastConfig? highContrastConfig,
  }) =>
      ResponsiveChartThemeData(
        responsiveConfig: responsiveConfig ?? this.responsiveConfig,
        densityConfig: densityConfig ?? this.densityConfig,
        textScalingConfig: textScalingConfig ?? this.textScalingConfig,
        focusIndicatorStyle: focusIndicatorStyle ?? this.focusIndicatorStyle,
        highContrastConfig: highContrastConfig ?? this.highContrastConfig,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResponsiveChartThemeData &&
        other.responsiveConfig == responsiveConfig &&
        other.densityConfig == densityConfig &&
        other.textScalingConfig == textScalingConfig &&
        other.focusIndicatorStyle == focusIndicatorStyle &&
        other.highContrastConfig == highContrastConfig;
  }

  @override
  int get hashCode => Object.hash(
        responsiveConfig,
        densityConfig,
        textScalingConfig,
        focusIndicatorStyle,
        highContrastConfig,
      );
}

/// Extension for easy access to responsive theme.
extension ResponsiveChartThemeExtension on BuildContext {
  /// Gets the responsive chart theme data.
  ResponsiveChartThemeData get chartTheme => ResponsiveChartTheme.of(this);

  /// Gets the responsive chart theme data, or null if not found.
  ResponsiveChartThemeData? get maybeChartTheme =>
      ResponsiveChartTheme.maybeOf(this);

  /// Gets chart padding from theme.
  EdgeInsets get chartPadding => chartTheme.padding;

  /// Gets chart font size for labels.
  double get chartLabelFontSize => chartTheme.labelFontSize;

  /// Gets chart stroke width.
  double get chartStrokeWidth => chartTheme.strokeWidth;

  /// Gets chart marker size.
  double get chartMarkerSize => chartTheme.markerSize;

  /// Whether high contrast mode is enabled.
  bool get isChartHighContrast => chartTheme.isHighContrast;
}

/// Mixin for widgets that use responsive theme.
mixin ResponsiveChartThemeMixin<T extends StatefulWidget> on State<T> {
  /// Cached theme data.
  ResponsiveChartThemeData? _cachedTheme;

  /// Gets the theme data, caching for performance.
  ResponsiveChartThemeData getTheme(BuildContext context) {
    _cachedTheme ??= ResponsiveChartTheme.of(context);
    return _cachedTheme!;
  }

  /// Clears the cached theme (call when theme might have changed).
  void clearThemeCache() {
    _cachedTheme = null;
  }

  /// Gets padding from theme.
  EdgeInsets getPadding(BuildContext context) => getTheme(context).padding;

  /// Gets font size from theme with scaling applied.
  double getScaledFontSize(BuildContext context, double baseSize) =>
      getTheme(context).scaledFontSize(context, baseSize);

  /// Gets stroke width from theme.
  double getStrokeWidth(BuildContext context) => getTheme(context).strokeWidth;

  /// Gets marker size from theme.
  double getMarkerSize(BuildContext context) => getTheme(context).markerSize;

  /// Gets the focus indicator style.
  FocusIndicatorStyle getFocusStyle(BuildContext context) =>
      getTheme(context).focusIndicatorStyle;

  /// Gets whether high contrast mode is enabled.
  bool isHighContrast(BuildContext context) => getTheme(context).isHighContrast;
}
