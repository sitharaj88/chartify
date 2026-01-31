import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Chart density levels for different use cases.
///
/// Controls spacing, padding, and sizing throughout the chart.
enum ChartDensity {
  /// Compact density with minimal spacing.
  ///
  /// Best for:
  /// - Data-dense dashboards
  /// - Small chart widgets
  /// - Displaying many charts simultaneously
  compact,

  /// Normal density with standard spacing.
  ///
  /// Best for:
  /// - General purpose charts
  /// - Default usage
  normal,

  /// Spacious density with generous spacing.
  ///
  /// Best for:
  /// - Presentation mode
  /// - Single chart focus
  /// - Touch-friendly interfaces
  spacious,
}

/// Configuration for chart density and spacing.
///
/// Provides multipliers for various chart dimensions to create
/// consistent density across all chart elements.
class DensityConfig {
  const DensityConfig({
    required this.density,
    required this.paddingMultiplier,
    required this.spacingMultiplier,
    required this.markerSizeMultiplier,
    required this.labelSpacingMultiplier,
    required this.strokeWidthMultiplier,
    required this.touchTargetMultiplier,
  });

  /// The density level.
  final ChartDensity density;

  /// Multiplier for padding values.
  final double paddingMultiplier;

  /// Multiplier for spacing between elements.
  final double spacingMultiplier;

  /// Multiplier for marker/point sizes.
  final double markerSizeMultiplier;

  /// Multiplier for label spacing.
  final double labelSpacingMultiplier;

  /// Multiplier for stroke widths.
  final double strokeWidthMultiplier;

  /// Multiplier for touch target sizes.
  final double touchTargetMultiplier;

  /// Creates a compact density configuration.
  ///
  /// All multipliers are reduced to create a dense layout.
  const DensityConfig.compact()
      : density = ChartDensity.compact,
        paddingMultiplier = 0.75,
        spacingMultiplier = 0.75,
        markerSizeMultiplier = 0.85,
        labelSpacingMultiplier = 0.8,
        strokeWidthMultiplier = 0.9,
        touchTargetMultiplier = 1.0; // Keep touch targets accessible

  /// Creates a normal density configuration.
  ///
  /// All multipliers are 1.0 (no change).
  const DensityConfig.normal()
      : density = ChartDensity.normal,
        paddingMultiplier = 1.0,
        spacingMultiplier = 1.0,
        markerSizeMultiplier = 1.0,
        labelSpacingMultiplier = 1.0,
        strokeWidthMultiplier = 1.0,
        touchTargetMultiplier = 1.0;

  /// Creates a spacious density configuration.
  ///
  /// All multipliers are increased for generous spacing.
  const DensityConfig.spacious()
      : density = ChartDensity.spacious,
        paddingMultiplier = 1.5,
        spacingMultiplier = 1.4,
        markerSizeMultiplier = 1.25,
        labelSpacingMultiplier = 1.3,
        strokeWidthMultiplier = 1.1,
        touchTargetMultiplier = 1.2;

  /// Creates a density configuration from the platform's visual density.
  ///
  /// Maps Flutter's [VisualDensity] to chart density:
  /// - Negative density → compact
  /// - Zero density → normal
  /// - Positive density → spacious
  factory DensityConfig.fromPlatform(BuildContext context) {
    final visualDensity = Theme.of(context).visualDensity;
    return DensityConfig.fromVisualDensity(visualDensity);
  }

  /// Creates a density configuration from [VisualDensity].
  factory DensityConfig.fromVisualDensity(VisualDensity visualDensity) {
    final average = (visualDensity.horizontal + visualDensity.vertical) / 2;

    if (average < -1.0) {
      return const DensityConfig.compact();
    } else if (average > 1.0) {
      return const DensityConfig.spacious();
    }
    return const DensityConfig.normal();
  }

  /// Creates a density configuration for a specific density level.
  factory DensityConfig.fromDensity(ChartDensity density) {
    switch (density) {
      case ChartDensity.compact:
        return const DensityConfig.compact();
      case ChartDensity.normal:
        return const DensityConfig.normal();
      case ChartDensity.spacious:
        return const DensityConfig.spacious();
    }
  }

  /// Creates a custom density configuration with specified multipliers.
  factory DensityConfig.custom({
    double paddingMultiplier = 1.0,
    double spacingMultiplier = 1.0,
    double markerSizeMultiplier = 1.0,
    double labelSpacingMultiplier = 1.0,
    double strokeWidthMultiplier = 1.0,
    double touchTargetMultiplier = 1.0,
  }) {
    // Determine density level based on average multiplier
    final average = (paddingMultiplier +
            spacingMultiplier +
            markerSizeMultiplier +
            labelSpacingMultiplier) /
        4;

    ChartDensity density;
    if (average < 0.9) {
      density = ChartDensity.compact;
    } else if (average > 1.2) {
      density = ChartDensity.spacious;
    } else {
      density = ChartDensity.normal;
    }

    return DensityConfig(
      density: density,
      paddingMultiplier: paddingMultiplier,
      spacingMultiplier: spacingMultiplier,
      markerSizeMultiplier: markerSizeMultiplier,
      labelSpacingMultiplier: labelSpacingMultiplier,
      strokeWidthMultiplier: strokeWidthMultiplier,
      touchTargetMultiplier: touchTargetMultiplier,
    );
  }

  /// Applies the padding multiplier to a value.
  double applyPadding(double value) => value * paddingMultiplier;

  /// Applies the padding multiplier to EdgeInsets.
  EdgeInsets applyPaddingInsets(EdgeInsets insets) => EdgeInsets.only(
        left: insets.left * paddingMultiplier,
        top: insets.top * paddingMultiplier,
        right: insets.right * paddingMultiplier,
        bottom: insets.bottom * paddingMultiplier,
      );

  /// Applies the spacing multiplier to a value.
  double applySpacing(double value) => value * spacingMultiplier;

  /// Applies the marker size multiplier to a value.
  double applyMarkerSize(double value) => value * markerSizeMultiplier;

  /// Applies the label spacing multiplier to a value.
  double applyLabelSpacing(double value) => value * labelSpacingMultiplier;

  /// Applies the stroke width multiplier to a value.
  double applyStrokeWidth(double value) => value * strokeWidthMultiplier;

  /// Applies the touch target multiplier to a value.
  ///
  /// Also ensures the result meets minimum touch target size.
  double applyTouchTarget(double value, {double minSize = 44.0}) =>
      math.max(value * touchTargetMultiplier, minSize);

  /// Creates a copy with updated values.
  DensityConfig copyWith({
    ChartDensity? density,
    double? paddingMultiplier,
    double? spacingMultiplier,
    double? markerSizeMultiplier,
    double? labelSpacingMultiplier,
    double? strokeWidthMultiplier,
    double? touchTargetMultiplier,
  }) =>
      DensityConfig(
        density: density ?? this.density,
        paddingMultiplier: paddingMultiplier ?? this.paddingMultiplier,
        spacingMultiplier: spacingMultiplier ?? this.spacingMultiplier,
        markerSizeMultiplier: markerSizeMultiplier ?? this.markerSizeMultiplier,
        labelSpacingMultiplier:
            labelSpacingMultiplier ?? this.labelSpacingMultiplier,
        strokeWidthMultiplier:
            strokeWidthMultiplier ?? this.strokeWidthMultiplier,
        touchTargetMultiplier:
            touchTargetMultiplier ?? this.touchTargetMultiplier,
      );

  /// Interpolates between two density configurations.
  static DensityConfig lerp(DensityConfig a, DensityConfig b, double t) =>
      DensityConfig(
        density: t < 0.5 ? a.density : b.density,
        paddingMultiplier:
            a.paddingMultiplier + (b.paddingMultiplier - a.paddingMultiplier) * t,
        spacingMultiplier:
            a.spacingMultiplier + (b.spacingMultiplier - a.spacingMultiplier) * t,
        markerSizeMultiplier: a.markerSizeMultiplier +
            (b.markerSizeMultiplier - a.markerSizeMultiplier) * t,
        labelSpacingMultiplier: a.labelSpacingMultiplier +
            (b.labelSpacingMultiplier - a.labelSpacingMultiplier) * t,
        strokeWidthMultiplier: a.strokeWidthMultiplier +
            (b.strokeWidthMultiplier - a.strokeWidthMultiplier) * t,
        touchTargetMultiplier: a.touchTargetMultiplier +
            (b.touchTargetMultiplier - a.touchTargetMultiplier) * t,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DensityConfig &&
        other.density == density &&
        other.paddingMultiplier == paddingMultiplier &&
        other.spacingMultiplier == spacingMultiplier &&
        other.markerSizeMultiplier == markerSizeMultiplier &&
        other.labelSpacingMultiplier == labelSpacingMultiplier &&
        other.strokeWidthMultiplier == strokeWidthMultiplier &&
        other.touchTargetMultiplier == touchTargetMultiplier;
  }

  @override
  int get hashCode => Object.hash(
        density,
        paddingMultiplier,
        spacingMultiplier,
        markerSizeMultiplier,
        labelSpacingMultiplier,
        strokeWidthMultiplier,
        touchTargetMultiplier,
      );

  @override
  String toString() => 'DensityConfig($density, padding: $paddingMultiplier, '
      'spacing: $spacingMultiplier)';
}

/// Provider for density configuration to descendant widgets.
class DensityProvider extends InheritedWidget {
  const DensityProvider({
    required this.config,
    required super.child,
    super.key,
  });

  /// The density configuration.
  final DensityConfig config;

  /// Gets the density configuration from context.
  static DensityConfig of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DensityProvider>();
    return provider?.config ?? const DensityConfig.normal();
  }

  /// Gets the density configuration from context, or null if not found.
  static DensityConfig? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DensityProvider>();
    return provider?.config;
  }

  @override
  bool updateShouldNotify(DensityProvider oldWidget) =>
      config != oldWidget.config;
}

/// Extension for easy access to theme's visual density.
extension DensityContextExtension on BuildContext {
  /// Gets the density configuration based on platform settings.
  DensityConfig get densityConfig => DensityConfig.fromPlatform(this);

  /// Gets the chart density level based on platform settings.
  ChartDensity get chartDensity => densityConfig.density;
}
