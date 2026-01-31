import 'package:flutter/widgets.dart';

/// Device class categories based on screen width.
///
/// Follows Material Design guidelines for responsive breakpoints.
enum DeviceClass {
  /// Mobile devices (width < 600dp)
  mobile,

  /// Tablet devices (600dp <= width < 1200dp)
  tablet,

  /// Desktop devices (width >= 1200dp)
  desktop,
}

/// Responsive breakpoint definitions.
///
/// Provides standard breakpoints for classifying devices and adapting
/// chart layouts accordingly.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Maximum width for mobile devices (exclusive).
  static const double mobileMax = 600.0;

  /// Maximum width for tablet devices (exclusive).
  static const double tabletMax = 1200.0;

  /// Minimum width for compact mobile layouts.
  static const double compactMobile = 320.0;

  /// Threshold for extra-large desktop displays.
  static const double largeDesktop = 1920.0;

  /// Determines the device class based on width.
  static DeviceClass fromWidth(double width) {
    if (width < mobileMax) return DeviceClass.mobile;
    if (width < tabletMax) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }

  /// Determines the device class from BoxConstraints.
  static DeviceClass fromConstraints(BoxConstraints constraints) =>
      fromWidth(constraints.maxWidth);

  /// Determines the device class from MediaQuery.
  static DeviceClass fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return fromWidth(size.width);
  }

  /// Whether the width represents a mobile device.
  static bool isMobile(double width) => width < mobileMax;

  /// Whether the width represents a tablet device.
  static bool isTablet(double width) =>
      width >= mobileMax && width < tabletMax;

  /// Whether the width represents a desktop device.
  static bool isDesktop(double width) => width >= tabletMax;

  /// Whether the width represents a compact layout (very small mobile).
  static bool isCompact(double width) => width < compactMobile;
}

/// Responsive configuration for chart elements.
///
/// Contains device-specific settings for padding, fonts, and interactive
/// elements that adapt to different screen sizes.
class ResponsiveChartConfig {
  const ResponsiveChartConfig({
    required this.deviceClass,
    required this.padding,
    required this.axisPadding,
    required this.titleFontSize,
    required this.labelFontSize,
    required this.legendFontSize,
    required this.strokeWidth,
    required this.hitTestRadius,
    required this.markerSize,
    required this.maxAxisLabels,
    required this.legendPosition,
    required this.showAxisTitles,
    required this.minInteractiveSize,
  });

  /// The device class this configuration is for.
  final DeviceClass deviceClass;

  /// Padding around the chart area.
  final EdgeInsets padding;

  /// Padding around axis labels.
  final EdgeInsets axisPadding;

  /// Font size for chart titles.
  final double titleFontSize;

  /// Font size for axis and data labels.
  final double labelFontSize;

  /// Font size for legend items.
  final double legendFontSize;

  /// Default stroke width for lines and borders.
  final double strokeWidth;

  /// Radius for hit testing (touch/click detection).
  final double hitTestRadius;

  /// Default marker size for data points.
  final double markerSize;

  /// Maximum number of axis labels to display.
  final int maxAxisLabels;

  /// Default legend position for this device class.
  final LegendPosition legendPosition;

  /// Whether to show axis titles.
  final bool showAxisTitles;

  /// Minimum size for interactive elements (WCAG compliance).
  final double minInteractiveSize;

  /// Creates a mobile-optimized configuration.
  ///
  /// Features:
  /// - Compact padding for limited screen space
  /// - Larger touch targets (24dp radius)
  /// - Bottom legend position
  /// - Fewer axis labels
  factory ResponsiveChartConfig.mobile() => const ResponsiveChartConfig(
        deviceClass: DeviceClass.mobile,
        padding: EdgeInsets.fromLTRB(40, 16, 16, 40),
        axisPadding: EdgeInsets.all(4),
        titleFontSize: 16.0,
        labelFontSize: 10.0,
        legendFontSize: 11.0,
        strokeWidth: 2.0,
        hitTestRadius: 24.0, // Large for touch
        markerSize: 6.0,
        maxAxisLabels: 5,
        legendPosition: LegendPosition.bottom,
        showAxisTitles: false,
        minInteractiveSize: 48.0, // WCAG 2.1 touch target
      );

  /// Creates a tablet-optimized configuration.
  ///
  /// Features:
  /// - Moderate padding
  /// - Medium touch targets
  /// - Right legend position
  /// - Moderate axis label count
  factory ResponsiveChartConfig.tablet() => const ResponsiveChartConfig(
        deviceClass: DeviceClass.tablet,
        padding: EdgeInsets.fromLTRB(48, 20, 20, 44),
        axisPadding: EdgeInsets.all(6),
        titleFontSize: 18.0,
        labelFontSize: 11.0,
        legendFontSize: 12.0,
        strokeWidth: 2.0,
        hitTestRadius: 20.0,
        markerSize: 7.0,
        maxAxisLabels: 8,
        legendPosition: LegendPosition.right,
        showAxisTitles: true,
        minInteractiveSize: 44.0,
      );

  /// Creates a desktop-optimized configuration.
  ///
  /// Features:
  /// - Spacious padding
  /// - Precise mouse-friendly hit targets
  /// - Right legend position
  /// - Many axis labels
  factory ResponsiveChartConfig.desktop() => const ResponsiveChartConfig(
        deviceClass: DeviceClass.desktop,
        padding: EdgeInsets.fromLTRB(56, 24, 24, 48),
        axisPadding: EdgeInsets.all(8),
        titleFontSize: 20.0,
        labelFontSize: 12.0,
        legendFontSize: 13.0,
        strokeWidth: 2.0,
        hitTestRadius: 12.0, // Precise for mouse
        markerSize: 8.0,
        maxAxisLabels: 12,
        legendPosition: LegendPosition.right,
        showAxisTitles: true,
        minInteractiveSize: 24.0,
      );

  /// Creates a configuration based on the available width.
  factory ResponsiveChartConfig.fromWidth(double width) {
    final deviceClass = ResponsiveBreakpoints.fromWidth(width);
    return ResponsiveChartConfig.fromDeviceClass(deviceClass);
  }

  /// Creates a configuration based on BoxConstraints.
  factory ResponsiveChartConfig.fromConstraints(BoxConstraints constraints) =>
      ResponsiveChartConfig.fromWidth(constraints.maxWidth);

  /// Creates a configuration based on BuildContext.
  factory ResponsiveChartConfig.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveChartConfig.fromWidth(size.width);
  }

  /// Creates a configuration for a specific device class.
  factory ResponsiveChartConfig.fromDeviceClass(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.mobile:
        return ResponsiveChartConfig.mobile();
      case DeviceClass.tablet:
        return ResponsiveChartConfig.tablet();
      case DeviceClass.desktop:
        return ResponsiveChartConfig.desktop();
    }
  }

  /// Creates a copy with updated values.
  ResponsiveChartConfig copyWith({
    DeviceClass? deviceClass,
    EdgeInsets? padding,
    EdgeInsets? axisPadding,
    double? titleFontSize,
    double? labelFontSize,
    double? legendFontSize,
    double? strokeWidth,
    double? hitTestRadius,
    double? markerSize,
    int? maxAxisLabels,
    LegendPosition? legendPosition,
    bool? showAxisTitles,
    double? minInteractiveSize,
  }) =>
      ResponsiveChartConfig(
        deviceClass: deviceClass ?? this.deviceClass,
        padding: padding ?? this.padding,
        axisPadding: axisPadding ?? this.axisPadding,
        titleFontSize: titleFontSize ?? this.titleFontSize,
        labelFontSize: labelFontSize ?? this.labelFontSize,
        legendFontSize: legendFontSize ?? this.legendFontSize,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        hitTestRadius: hitTestRadius ?? this.hitTestRadius,
        markerSize: markerSize ?? this.markerSize,
        maxAxisLabels: maxAxisLabels ?? this.maxAxisLabels,
        legendPosition: legendPosition ?? this.legendPosition,
        showAxisTitles: showAxisTitles ?? this.showAxisTitles,
        minInteractiveSize: minInteractiveSize ?? this.minInteractiveSize,
      );

  /// Interpolates between two configurations based on width.
  ///
  /// Useful for smooth transitions between breakpoints.
  static ResponsiveChartConfig lerp(
    ResponsiveChartConfig a,
    ResponsiveChartConfig b,
    double t,
  ) =>
      ResponsiveChartConfig(
        deviceClass: t < 0.5 ? a.deviceClass : b.deviceClass,
        padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
        axisPadding: EdgeInsets.lerp(a.axisPadding, b.axisPadding, t)!,
        titleFontSize: _lerpDouble(a.titleFontSize, b.titleFontSize, t),
        labelFontSize: _lerpDouble(a.labelFontSize, b.labelFontSize, t),
        legendFontSize: _lerpDouble(a.legendFontSize, b.legendFontSize, t),
        strokeWidth: _lerpDouble(a.strokeWidth, b.strokeWidth, t),
        hitTestRadius: _lerpDouble(a.hitTestRadius, b.hitTestRadius, t),
        markerSize: _lerpDouble(a.markerSize, b.markerSize, t),
        maxAxisLabels: (a.maxAxisLabels + (b.maxAxisLabels - a.maxAxisLabels) * t).round(),
        legendPosition: t < 0.5 ? a.legendPosition : b.legendPosition,
        showAxisTitles: t < 0.5 ? a.showAxisTitles : b.showAxisTitles,
        minInteractiveSize: _lerpDouble(a.minInteractiveSize, b.minInteractiveSize, t),
      );

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResponsiveChartConfig &&
        other.deviceClass == deviceClass &&
        other.padding == padding &&
        other.axisPadding == axisPadding &&
        other.titleFontSize == titleFontSize &&
        other.labelFontSize == labelFontSize &&
        other.legendFontSize == legendFontSize &&
        other.strokeWidth == strokeWidth &&
        other.hitTestRadius == hitTestRadius &&
        other.markerSize == markerSize &&
        other.maxAxisLabels == maxAxisLabels &&
        other.legendPosition == legendPosition &&
        other.showAxisTitles == showAxisTitles &&
        other.minInteractiveSize == minInteractiveSize;
  }

  @override
  int get hashCode => Object.hash(
        deviceClass,
        padding,
        axisPadding,
        titleFontSize,
        labelFontSize,
        legendFontSize,
        strokeWidth,
        hitTestRadius,
        markerSize,
        maxAxisLabels,
        legendPosition,
        showAxisTitles,
        minInteractiveSize,
      );
}

/// Legend position options.
enum LegendPosition {
  /// Legend at top of chart.
  top,

  /// Legend at bottom of chart.
  bottom,

  /// Legend at left of chart.
  left,

  /// Legend at right of chart.
  right,

  /// Legend hidden.
  none,
}

/// Extension for responsive configuration on BoxConstraints.
extension ResponsiveConstraintsExtension on BoxConstraints {
  /// Gets the device class for these constraints.
  DeviceClass get deviceClass => ResponsiveBreakpoints.fromConstraints(this);

  /// Gets the responsive configuration for these constraints.
  ResponsiveChartConfig get responsiveConfig =>
      ResponsiveChartConfig.fromConstraints(this);

  /// Whether these constraints represent a mobile device.
  bool get isMobile => ResponsiveBreakpoints.isMobile(maxWidth);

  /// Whether these constraints represent a tablet device.
  bool get isTablet => ResponsiveBreakpoints.isTablet(maxWidth);

  /// Whether these constraints represent a desktop device.
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(maxWidth);
}

/// Extension for responsive configuration on BuildContext.
extension ResponsiveContextExtension on BuildContext {
  /// Gets the device class from MediaQuery.
  DeviceClass get deviceClass => ResponsiveBreakpoints.fromContext(this);

  /// Gets the responsive configuration from MediaQuery.
  ResponsiveChartConfig get responsiveChartConfig =>
      ResponsiveChartConfig.fromContext(this);

  /// Whether this context represents a mobile device.
  bool get isMobile {
    final size = MediaQuery.sizeOf(this);
    return ResponsiveBreakpoints.isMobile(size.width);
  }

  /// Whether this context represents a tablet device.
  bool get isTablet {
    final size = MediaQuery.sizeOf(this);
    return ResponsiveBreakpoints.isTablet(size.width);
  }

  /// Whether this context represents a desktop device.
  bool get isDesktop {
    final size = MediaQuery.sizeOf(this);
    return ResponsiveBreakpoints.isDesktop(size.width);
  }
}
