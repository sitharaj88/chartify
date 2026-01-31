import 'package:flutter/widgets.dart';

import '../../core/responsive/density_config.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/responsive/responsive_theme.dart';
import '../../core/responsive/text_scaling.dart';

/// Mixin providing responsive behavior for chart widgets.
///
/// This mixin provides:
/// - Device-aware padding calculation
/// - Scaled font sizes based on device and text accessibility settings
/// - WCAG-compliant touch targets (minimum 44-48dp)
/// - Responsive marker and stroke sizes
///
/// Example usage:
/// ```dart
/// class _MyChartState extends State<MyChart>
///     with ChartResponsiveMixin {
///
///   @override
///   Widget build(BuildContext context) {
///     return LayoutBuilder(
///       builder: (context, constraints) {
///         final responsiveConfig = getResponsiveConfig(constraints);
///         final padding = getResponsivePadding(context, constraints);
///         final fontSize = getScaledFontSize(context, 11.0);
///         // ... use responsive values
///       },
///     );
///   }
/// }
/// ```
mixin ChartResponsiveMixin<T extends StatefulWidget> on State<T> {
  /// Cached responsive config for performance.
  ResponsiveChartConfig? _cachedConfig;
  BoxConstraints? _cachedConstraints;

  /// Gets the responsive configuration based on constraints.
  ///
  /// Caches the result for performance when constraints haven't changed.
  ResponsiveChartConfig getResponsiveConfig(BoxConstraints constraints) {
    if (_cachedConfig != null &&
        _cachedConstraints?.maxWidth == constraints.maxWidth) {
      return _cachedConfig!;
    }

    _cachedConstraints = constraints;
    _cachedConfig = ResponsiveChartConfig.fromWidth(constraints.maxWidth);
    return _cachedConfig!;
  }

  /// Gets responsive padding based on device class and density.
  ///
  /// Returns device-appropriate padding that scales based on screen size.
  /// On mobile: smaller padding to maximize chart area
  /// On tablet: medium padding
  /// On desktop: larger padding for axis labels and margins
  EdgeInsets getResponsivePadding(
    BuildContext context,
    BoxConstraints constraints, {
    EdgeInsets? override,
  }) {
    if (override != null) return override;

    final config = getResponsiveConfig(constraints);
    final themeData = ResponsiveChartTheme.maybeOf(context);
    final densityConfig =
        themeData?.densityConfig ?? const DensityConfig.normal();

    return densityConfig.applyPaddingInsets(config.padding);
  }

  /// Gets scaled font size for labels.
  ///
  /// Applies both device-class scaling and system text scaling.
  /// Ensures minimum readable size (10sp) and maximum to prevent overflow.
  double getScaledFontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxScale,
  }) {
    final themeData = ResponsiveChartTheme.maybeOf(context);
    if (themeData?.textScalingConfig.enabled ?? false) {
      return themeData!.textScalingConfig.applyScaling(context, baseSize);
    }
    return ChartTextScaling.scaledFontSize(
      context,
      baseSize,
      minSize: minSize,
      maxScale: maxScale,
    );
  }

  /// Gets WCAG-compliant hit test radius.
  ///
  /// Returns a radius that ensures minimum touch target size of 44-48dp.
  /// On touch devices: minimum 24dp radius (48dp diameter)
  /// On desktop: can be smaller for precision
  double getHitTestRadius(
    BuildContext context,
    BoxConstraints constraints, {
    double? baseRadius,
  }) {
    final config = getResponsiveConfig(constraints);
    final base = baseRadius ?? config.hitTestRadius;

    // Ensure minimum WCAG-compliant size
    // minInteractiveSize is the diameter, so divide by 2 for radius
    return base.clamp(config.minInteractiveSize / 2, double.infinity);
  }

  /// Gets responsive marker size.
  ///
  /// Scales marker size based on device class and density.
  double getMarkerSize(
    BuildContext context,
    BoxConstraints constraints, {
    double? baseSize,
  }) {
    final config = getResponsiveConfig(constraints);
    final themeData = ResponsiveChartTheme.maybeOf(context);
    final densityConfig =
        themeData?.densityConfig ?? const DensityConfig.normal();

    final base = baseSize ?? config.markerSize;
    return densityConfig.applyMarkerSize(base);
  }

  /// Gets responsive stroke width.
  ///
  /// Scales stroke width based on device class and density.
  double getStrokeWidth(
    BuildContext context,
    BoxConstraints constraints, {
    double? baseWidth,
  }) {
    final config = getResponsiveConfig(constraints);
    final themeData = ResponsiveChartTheme.maybeOf(context);
    final densityConfig =
        themeData?.densityConfig ?? const DensityConfig.normal();

    final base = baseWidth ?? config.strokeWidth;
    return densityConfig.applyStrokeWidth(base);
  }

  /// Gets maximum number of axis labels for current width.
  ///
  /// Prevents label overlap by limiting labels based on available space.
  int getMaxAxisLabels(BoxConstraints constraints, {bool isXAxis = true}) {
    final config = getResponsiveConfig(constraints);
    if (isXAxis) {
      // For X axis, estimate based on available width and label width
      const estimatedLabelWidth = 50.0; // Average label width
      return (constraints.maxWidth / estimatedLabelWidth).floor().clamp(3, 12);
    }
    return config.maxAxisLabels;
  }

  /// Gets the current device class.
  DeviceClass getDeviceClass(BoxConstraints constraints) =>
      getResponsiveConfig(constraints).deviceClass;

  /// Clears cached configuration.
  ///
  /// Call this when constraints or configuration might have changed.
  void clearResponsiveCache() {
    _cachedConfig = null;
    _cachedConstraints = null;
  }

  @override
  void dispose() {
    clearResponsiveCache();
    super.dispose();
  }
}

/// Static utility methods for responsive charts.
///
/// Use these when you can't use the mixin (e.g., in CustomPainter).
class ChartResponsiveUtils {
  ChartResponsiveUtils._();

  /// Gets responsive configuration from width.
  static ResponsiveChartConfig configFromWidth(double width) =>
      ResponsiveChartConfig.fromWidth(width);

  /// Gets responsive padding for a given width.
  static EdgeInsets getPadding(double width, {DensityConfig? density}) =>
      (density ?? const DensityConfig.normal())
          .applyPaddingInsets(ResponsiveChartConfig.fromWidth(width).padding);

  /// Gets scaled font size.
  static double scaleFontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxScale,
  }) =>
      ChartTextScaling.scaledFontSize(
        context,
        baseSize,
        minSize: minSize,
        maxScale: maxScale,
      );

  /// Gets WCAG-compliant hit test radius for a given width.
  static double getHitTestRadius(double width, {double? baseRadius}) {
    final config = ResponsiveChartConfig.fromWidth(width);
    return (baseRadius ?? config.hitTestRadius)
        .clamp(config.minInteractiveSize / 2, double.infinity);
  }

  /// Gets device class from width.
  static DeviceClass getDeviceClass(double width) =>
      ResponsiveBreakpoints.fromWidth(width);

  /// Calculates axis label density based on available space.
  static int calculateAxisLabelCount(
    double availableSpace, {
    double estimatedLabelWidth = 50.0,
    int minLabels = 3,
    int maxLabels = 12,
  }) =>
      (availableSpace / estimatedLabelWidth).floor().clamp(minLabels, maxLabels);
}

/// Extension for easy access to responsive values in painters.
extension ChartResponsivePainterExtension on Size {
  /// Gets responsive configuration from size width.
  ResponsiveChartConfig get responsiveConfig =>
      ResponsiveChartConfig.fromWidth(width);

  /// Gets device class from size width.
  DeviceClass get deviceClass => ResponsiveBreakpoints.fromWidth(width);

  /// Gets responsive padding from size width.
  EdgeInsets getResponsivePadding({DensityConfig? density}) =>
      (density ?? const DensityConfig.normal())
          .applyPaddingInsets(ResponsiveChartConfig.fromWidth(width).padding);

  /// Gets WCAG-compliant hit test radius.
  double getHitTestRadius({double? baseRadius}) {
    final config = ResponsiveChartConfig.fromWidth(width);
    final base = baseRadius ?? config.hitTestRadius;
    return base.clamp(config.minInteractiveSize / 2, double.infinity);
  }
}
