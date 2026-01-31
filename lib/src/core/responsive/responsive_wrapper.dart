import 'package:flutter/widgets.dart';

import 'responsive_config.dart';

/// A widget that wraps charts with responsive configuration.
///
/// Uses [LayoutBuilder] to detect available space and provides
/// appropriate [ResponsiveChartConfig] to child charts.
///
/// Example:
/// ```dart
/// ResponsiveChartWrapper(
///   builder: (context, config) {
///     return LineChart(
///       padding: config.padding,
///       // Use config for responsive sizing
///     );
///   },
/// )
/// ```
class ResponsiveChartWrapper extends StatelessWidget {
  const ResponsiveChartWrapper({
    required this.builder,
    super.key,
    this.overrideConfig,
    this.enableSmoothing = false,
  });

  /// Builder function that receives the responsive configuration.
  final Widget Function(BuildContext context, ResponsiveChartConfig config)
      builder;

  /// Optional override configuration to use instead of auto-detection.
  final ResponsiveChartConfig? overrideConfig;

  /// Whether to smooth transitions between breakpoints.
  ///
  /// When true, interpolates between configurations at breakpoint boundaries.
  /// Defaults to false for cleaner breakpoint transitions.
  final bool enableSmoothing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final config = overrideConfig ??
              (enableSmoothing
                  ? _getSmoothedConfig(constraints.maxWidth)
                  : ResponsiveChartConfig.fromConstraints(constraints));

          return builder(context, config);
        },
      );

  /// Calculates smoothed configuration between breakpoints.
  ResponsiveChartConfig _getSmoothedConfig(double width) {
    // Near mobile/tablet boundary (550-650)
    if (width >= 550 && width <= 650) {
      final t = (width - 550) / 100;
      return ResponsiveChartConfig.lerp(
        ResponsiveChartConfig.mobile(),
        ResponsiveChartConfig.tablet(),
        t,
      );
    }

    // Near tablet/desktop boundary (1150-1250)
    if (width >= 1150 && width <= 1250) {
      final t = (width - 1150) / 100;
      return ResponsiveChartConfig.lerp(
        ResponsiveChartConfig.tablet(),
        ResponsiveChartConfig.desktop(),
        t,
      );
    }

    return ResponsiveChartConfig.fromWidth(width);
  }
}

/// A widget that provides responsive configuration to descendant widgets.
///
/// Use [ResponsiveChartProvider.of] to access the configuration from
/// any descendant widget.
///
/// Example:
/// ```dart
/// ResponsiveChartProvider(
///   config: ResponsiveChartConfig.mobile(),
///   child: MyChart(),
/// )
///
/// // In child widget:
/// final config = ResponsiveChartProvider.of(context);
/// ```
class ResponsiveChartProvider extends InheritedWidget {
  const ResponsiveChartProvider({
    required this.config,
    required super.child,
    super.key,
  });

  /// The responsive configuration to provide.
  final ResponsiveChartConfig config;

  /// Gets the responsive configuration from the nearest ancestor provider.
  ///
  /// Returns the configuration or null if no provider exists.
  static ResponsiveChartConfig? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ResponsiveChartProvider>();
    return provider?.config;
  }

  /// Gets the responsive configuration from the nearest ancestor provider.
  ///
  /// Throws if no provider exists. Use [maybeOf] for nullable access.
  static ResponsiveChartConfig of(BuildContext context) {
    final config = maybeOf(context);
    assert(config != null, 'No ResponsiveChartProvider found in context');
    return config!;
  }

  @override
  bool updateShouldNotify(ResponsiveChartProvider oldWidget) =>
      config != oldWidget.config;
}

/// A widget that automatically provides responsive configuration based on constraints.
///
/// Combines [ResponsiveChartWrapper] and [ResponsiveChartProvider] for
/// automatic configuration with inherited access.
///
/// Example:
/// ```dart
/// AutoResponsiveProvider(
///   child: Column(
///     children: [
///       LineChart(), // Can access config via ResponsiveChartProvider.of
///       BarChart(),  // Same configuration for all charts
///     ],
///   ),
/// )
/// ```
class AutoResponsiveProvider extends StatelessWidget {
  const AutoResponsiveProvider({
    required this.child,
    super.key,
    this.overrideConfig,
  });

  /// The child widget tree.
  final Widget child;

  /// Optional override configuration.
  final ResponsiveChartConfig? overrideConfig;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final config =
              overrideConfig ?? ResponsiveChartConfig.fromConstraints(constraints);

          return ResponsiveChartProvider(
            config: config,
            child: child,
          );
        },
      );
}

/// Mixin for widgets that need responsive configuration.
///
/// Provides convenient access to responsive configuration and device class.
///
/// Example:
/// ```dart
/// class _MyChartState extends State<MyChart> with ResponsiveChartMixin {
///   @override
///   Widget build(BuildContext context) {
///     final config = getResponsiveConfig(context);
///     return CustomPaint(
///       painter: MyPainter(config: config),
///     );
///   }
/// }
/// ```
mixin ResponsiveChartMixin<T extends StatefulWidget> on State<T> {
  /// Cached responsive configuration.
  ResponsiveChartConfig? _cachedConfig;

  /// The current device class.
  DeviceClass? _cachedDeviceClass;

  /// Returns the last cached configuration, if any.
  ResponsiveChartConfig? get cachedConfig => _cachedConfig;

  /// Gets the responsive configuration from context.
  ///
  /// First checks for a [ResponsiveChartProvider], then falls back to
  /// calculating from [MediaQuery].
  ResponsiveChartConfig getResponsiveConfig(BuildContext context) {
    // Try inherited provider first
    final inherited = ResponsiveChartProvider.maybeOf(context);
    if (inherited != null) {
      _cachedConfig = inherited;
      _cachedDeviceClass = inherited.deviceClass;
      return inherited;
    }

    // Fall back to MediaQuery
    final config = ResponsiveChartConfig.fromContext(context);
    _cachedConfig = config;
    _cachedDeviceClass = config.deviceClass;
    return config;
  }

  /// Gets the current device class.
  DeviceClass getDeviceClass(BuildContext context) {
    if (_cachedDeviceClass != null) return _cachedDeviceClass!;
    final config = getResponsiveConfig(context);
    return config.deviceClass;
  }

  /// Whether the current device is mobile.
  bool isMobile(BuildContext context) =>
      getDeviceClass(context) == DeviceClass.mobile;

  /// Whether the current device is tablet.
  bool isTablet(BuildContext context) =>
      getDeviceClass(context) == DeviceClass.tablet;

  /// Whether the current device is desktop.
  bool isDesktop(BuildContext context) =>
      getDeviceClass(context) == DeviceClass.desktop;

  /// Clears cached configuration (call when layout changes).
  void clearResponsiveCache() {
    _cachedConfig = null;
    _cachedDeviceClass = null;
  }
}

/// Builder widget that provides both constraints and responsive config.
///
/// Useful when you need access to both raw constraints and the
/// derived responsive configuration.
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    required this.builder,
    super.key,
  });

  /// Builder function that receives constraints and configuration.
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    ResponsiveChartConfig config,
  ) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveChartConfig.fromConstraints(constraints);
          return builder(context, constraints, config);
        },
      );
}

/// Helper for conditionally rendering widgets based on device class.
///
/// Example:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => CompactChart(),
///   tablet: (context) => MediumChart(),
///   desktop: (context) => FullChart(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  });

  /// Builder for mobile devices.
  final WidgetBuilder? mobile;

  /// Builder for tablet devices.
  final WidgetBuilder? tablet;

  /// Builder for desktop devices.
  final WidgetBuilder? desktop;

  /// Fallback builder when specific builder is not provided.
  final WidgetBuilder? fallback;

  @override
  Widget build(BuildContext context) {
    final deviceClass = context.deviceClass;

    WidgetBuilder? builder;
    switch (deviceClass) {
      case DeviceClass.mobile:
        builder = mobile ?? tablet ?? desktop ?? fallback;
      case DeviceClass.tablet:
        builder = tablet ?? desktop ?? mobile ?? fallback;
      case DeviceClass.desktop:
        builder = desktop ?? tablet ?? mobile ?? fallback;
    }

    if (builder == null) {
      return const SizedBox.shrink();
    }

    return builder(context);
  }
}
