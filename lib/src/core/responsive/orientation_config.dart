import 'package:flutter/widgets.dart';

import '../../accessibility/chart_semantics.dart';
import 'responsive_config.dart';

/// Configuration utilities for orientation-aware chart layouts.
///
/// Provides optimal settings for portrait and landscape orientations,
/// ensuring charts display well regardless of device orientation.
class OrientationAwareConfig {
  OrientationAwareConfig._();

  /// Gets the optimal legend position based on orientation.
  ///
  /// - Portrait: Legend at bottom (saves horizontal space)
  /// - Landscape: Legend at right (utilizes extra width)
  static LegendPosition getOptimalLegendPosition(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        return LegendPosition.bottom;
      case Orientation.landscape:
        return LegendPosition.right;
    }
  }

  /// Gets the optimal legend position for a specific chart type.
  ///
  /// Some chart types have specific preferences regardless of orientation.
  static LegendPosition getOptimalLegendPositionForChart(
    Orientation orientation,
    ChartType chartType,
  ) {
    // Circular charts often look better with right legend
    switch (chartType) {
      case ChartType.pie:
      case ChartType.donut:
      case ChartType.gauge:
        return orientation == Orientation.portrait
            ? LegendPosition.bottom
            : LegendPosition.right;

      case ChartType.radar:
        // Radar charts need space around them
        return LegendPosition.bottom;

      default:
        return getOptimalLegendPosition(orientation);
    }
  }

  /// Gets the maximum number of axis labels based on orientation and space.
  ///
  /// In landscape, more labels can fit horizontally.
  /// In portrait, vertical space allows more Y-axis labels.
  static int getMaxAxisLabels(
    Orientation orientation,
    double availableSpace, {
    double minLabelSpacing = 40.0,
  }) {
    final maxFromSpace = (availableSpace / minLabelSpacing).floor();

    switch (orientation) {
      case Orientation.portrait:
        // Portrait has less horizontal space, fewer X-axis labels
        return maxFromSpace.clamp(3, 8);
      case Orientation.landscape:
        // Landscape has more horizontal space, more X-axis labels
        return maxFromSpace.clamp(5, 15);
    }
  }

  /// Gets the optimal aspect ratio for a chart type in given orientation.
  ///
  /// Returns the width/height ratio that works best for the combination.
  static double getAspectRatio(ChartType chartType, Orientation orientation) {
    switch (chartType) {
      // Circular charts prefer square aspect ratio
      case ChartType.pie:
      case ChartType.donut:
      case ChartType.gauge:
      case ChartType.radar:
        return orientation == Orientation.portrait ? 1.0 : 1.2;

      // Line/area charts benefit from wider aspect ratios
      case ChartType.line:
      case ChartType.area:
        return orientation == Orientation.portrait ? 1.2 : 1.8;

      // Bar charts adjust based on orientation
      case ChartType.bar:
        return orientation == Orientation.portrait ? 0.8 : 1.5;

      // Heatmap prefers wider layouts
      case ChartType.heatmap:
        return orientation == Orientation.portrait ? 1.0 : 1.6;

      // Default aspect ratio
      default:
        return orientation == Orientation.portrait ? 1.0 : 1.5;
    }
  }

  /// Gets the optimal padding multiplier for orientation.
  ///
  /// Landscape mode can have tighter horizontal padding.
  static double getPaddingMultiplier(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        return 1.0;
      case Orientation.landscape:
        return 0.85; // Slightly tighter in landscape
    }
  }

  /// Gets font size adjustment factor for orientation.
  ///
  /// Text may need to be slightly smaller in portrait to fit.
  static double getFontSizeMultiplier(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        return 0.95; // Slightly smaller in portrait
      case Orientation.landscape:
        return 1.0;
    }
  }

  /// Determines if axis labels should rotate based on orientation.
  ///
  /// In portrait mode, X-axis labels often need rotation to fit.
  static bool shouldRotateAxisLabels(
    Orientation orientation,
    int labelCount,
    double availableWidth,
  ) {
    // Estimate label width (average 6 characters, ~7px per character)
    const avgLabelWidth = 42.0;
    final totalLabelWidth = labelCount * avgLabelWidth;
    final spaceAvailable = availableWidth * 0.9; // Leave some margin

    if (orientation == Orientation.portrait) {
      // More likely to rotate in portrait
      return totalLabelWidth > spaceAvailable;
    } else {
      // Less likely to rotate in landscape
      return totalLabelWidth > spaceAvailable * 1.2;
    }
  }

  /// Gets the optimal label rotation angle.
  static double getOptimalLabelRotation(
    Orientation orientation,
    int labelCount,
    double availableWidth,
  ) {
    if (!shouldRotateAxisLabels(orientation, labelCount, availableWidth)) {
      return 0.0;
    }

    // Calculate overcrowding factor
    const avgLabelWidth = 42.0;
    final totalLabelWidth = labelCount * avgLabelWidth;
    final overcrowdingFactor = totalLabelWidth / availableWidth;

    if (overcrowdingFactor > 2.5) {
      return -90.0; // Vertical labels
    } else if (overcrowdingFactor > 1.5) {
      return -45.0; // Diagonal labels
    } else {
      return -30.0; // Slight angle
    }
  }
}

/// Widget that rebuilds when orientation changes.
///
/// Provides orientation-specific configuration to child widgets.
class OrientationAwareBuilder extends StatelessWidget {
  const OrientationAwareBuilder({
    required this.builder,
    super.key,
  });

  /// Builder that receives the current orientation.
  final Widget Function(BuildContext context, Orientation orientation) builder;

  @override
  Widget build(BuildContext context) => OrientationBuilder(
        builder: (context, orientation) => builder(context, orientation),
      );
}

/// Configuration that combines responsive and orientation settings.
class OrientationResponsiveConfig {
  const OrientationResponsiveConfig({
    required this.orientation,
    required this.responsiveConfig,
    required this.legendPosition,
    required this.maxXAxisLabels,
    required this.maxYAxisLabels,
    required this.aspectRatio,
    required this.rotateXLabels,
    required this.xLabelRotation,
  });

  /// Current orientation.
  final Orientation orientation;

  /// Responsive configuration.
  final ResponsiveChartConfig responsiveConfig;

  /// Optimal legend position.
  final LegendPosition legendPosition;

  /// Maximum X-axis labels.
  final int maxXAxisLabels;

  /// Maximum Y-axis labels.
  final int maxYAxisLabels;

  /// Optimal aspect ratio.
  final double aspectRatio;

  /// Whether to rotate X-axis labels.
  final bool rotateXLabels;

  /// X-axis label rotation angle.
  final double xLabelRotation;

  /// Creates a configuration from context and chart type.
  factory OrientationResponsiveConfig.fromContext(
    BuildContext context, {
    ChartType chartType = ChartType.line,
    int xLabelCount = 10,
    int yLabelCount = 5,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;
    final size = mediaQuery.size;

    final responsiveConfig = ResponsiveChartConfig.fromWidth(size.width);

    // Calculate available space for axes
    final chartWidth = size.width - responsiveConfig.padding.horizontal;
    final chartHeight = size.height - responsiveConfig.padding.vertical;

    return OrientationResponsiveConfig(
      orientation: orientation,
      responsiveConfig: responsiveConfig,
      legendPosition:
          OrientationAwareConfig.getOptimalLegendPositionForChart(
        orientation,
        chartType,
      ),
      maxXAxisLabels: OrientationAwareConfig.getMaxAxisLabels(
        orientation,
        chartWidth,
      ),
      maxYAxisLabels: OrientationAwareConfig.getMaxAxisLabels(
        orientation,
        chartHeight,
        minLabelSpacing: 30.0, // Tighter vertical spacing
      ),
      aspectRatio: OrientationAwareConfig.getAspectRatio(chartType, orientation),
      rotateXLabels: OrientationAwareConfig.shouldRotateAxisLabels(
        orientation,
        xLabelCount,
        chartWidth,
      ),
      xLabelRotation: OrientationAwareConfig.getOptimalLabelRotation(
        orientation,
        xLabelCount,
        chartWidth,
      ),
    );
  }

  /// Whether this is portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;

  /// Whether this is landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Gets adjusted padding based on orientation.
  EdgeInsets get adjustedPadding {
    final multiplier =
        OrientationAwareConfig.getPaddingMultiplier(orientation);
    final base = responsiveConfig.padding;
    return EdgeInsets.only(
      left: base.left * multiplier,
      top: base.top,
      right: base.right * multiplier,
      bottom: base.bottom,
    );
  }

  /// Gets adjusted font size based on orientation.
  double get adjustedLabelFontSize {
    final multiplier = OrientationAwareConfig.getFontSizeMultiplier(orientation);
    return responsiveConfig.labelFontSize * multiplier;
  }
}

/// Provider for orientation-responsive configuration.
class OrientationResponsiveProvider extends InheritedWidget {
  const OrientationResponsiveProvider({
    required this.config,
    required super.child,
    super.key,
  });

  /// The orientation-responsive configuration.
  final OrientationResponsiveConfig config;

  /// Gets the configuration from context.
  static OrientationResponsiveConfig of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<OrientationResponsiveProvider>();
    assert(provider != null,
        'No OrientationResponsiveProvider found in context');
    return provider!.config;
  }

  /// Gets the configuration from context, or null if not found.
  static OrientationResponsiveConfig? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<OrientationResponsiveProvider>();
    return provider?.config;
  }

  @override
  bool updateShouldNotify(OrientationResponsiveProvider oldWidget) =>
      config.orientation != oldWidget.config.orientation ||
      config.responsiveConfig != oldWidget.config.responsiveConfig;
}

/// Extension for orientation utilities on BuildContext.
extension OrientationContextExtension on BuildContext {
  /// Gets the current orientation.
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// Whether the current orientation is portrait.
  bool get isPortrait => orientation == Orientation.portrait;

  /// Whether the current orientation is landscape.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Gets optimal legend position for current orientation.
  LegendPosition get optimalLegendPosition =>
      OrientationAwareConfig.getOptimalLegendPosition(orientation);
}
