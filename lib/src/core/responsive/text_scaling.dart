import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Utilities for accessible text scaling in charts.
///
/// Respects system text size settings while maintaining chart usability.
class ChartTextScaling {
  ChartTextScaling._();

  /// Minimum font size for legibility (WCAG recommends 12sp minimum).
  static const double minFontSize = 10.0;

  /// Maximum scale factor to prevent layout overflow.
  static const double maxScaleFactor = 1.5;

  /// Default scale factor when no context is available.
  static const double defaultScaleFactor = 1.0;

  /// Applies system text scale factor to a base font size.
  ///
  /// Respects user accessibility settings while clamping to prevent
  /// extremely large or small text that could break layouts.
  ///
  /// Example:
  /// ```dart
  /// final fontSize = ChartTextScaling.scaledFontSize(context, 12.0);
  /// ```
  static double scaledFontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxScale,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(1.0);
    final effectiveMaxScale = maxScale ?? maxScaleFactor;
    final effectiveMinSize = minSize ?? minFontSize;

    // Clamp the scale factor
    final clampedScale = scaleFactor.clamp(1.0, effectiveMaxScale);

    // Apply scaling and ensure minimum size
    return math.max(baseSize * clampedScale, effectiveMinSize);
  }

  /// Gets the current text scale factor from context.
  ///
  /// Returns 1.0 if no MediaQuery is available.
  static double getScaleFactor(BuildContext context) {
    try {
      final textScaler = MediaQuery.textScalerOf(context);
      return textScaler.scale(1.0);
    } catch (_) {
      return defaultScaleFactor;
    }
  }

  /// Creates a scaled TextStyle from a base style.
  ///
  /// Applies text scaling to fontSize while preserving other properties.
  static TextStyle scaledStyle(
    BuildContext context,
    TextStyle base, {
    double? minSize,
    double? maxScale,
  }) {
    final baseFontSize = base.fontSize ?? 14.0;
    final scaledSize = scaledFontSize(
      context,
      baseFontSize,
      minSize: minSize,
      maxScale: maxScale,
    );

    return base.copyWith(fontSize: scaledSize);
  }

  /// Creates multiple scaled TextStyles efficiently.
  ///
  /// Calculates scale factor once and applies to all styles.
  static Map<String, TextStyle> scaledStyles(
    BuildContext context,
    Map<String, TextStyle> styles, {
    double? minSize,
    double? maxScale,
  }) {
    final scaleFactor = getScaleFactor(context);
    final effectiveMaxScale = maxScale ?? maxScaleFactor;
    final effectiveMinSize = minSize ?? minFontSize;
    final clampedScale = scaleFactor.clamp(1.0, effectiveMaxScale);

    return styles.map((key, style) {
      final baseFontSize = style.fontSize ?? 14.0;
      final scaledSize = math.max(baseFontSize * clampedScale, effectiveMinSize);
      return MapEntry(key, style.copyWith(fontSize: scaledSize));
    });
  }

  /// Calculates line height for scaled text.
  ///
  /// Returns appropriate line height to maintain readability.
  static double scaledLineHeight(
    BuildContext context,
    double baseFontSize, {
    double lineHeightFactor = 1.4,
  }) {
    final scaledSize = scaledFontSize(context, baseFontSize);
    return scaledSize * lineHeightFactor;
  }

  /// Estimates the width of text with scaling applied.
  ///
  /// Useful for layout calculations without building TextPainter.
  static double estimateTextWidth(
    BuildContext context,
    String text,
    double baseFontSize, {
    double characterWidthFactor = 0.6,
  }) {
    final scaledSize = scaledFontSize(context, baseFontSize);
    return text.length * scaledSize * characterWidthFactor;
  }

  /// Determines if text scaling is significantly increased.
  ///
  /// Returns true if scale factor > 1.2, indicating need for layout adjustments.
  static bool isLargeTextMode(BuildContext context) {
    final scaleFactor = getScaleFactor(context);
    return scaleFactor > 1.2;
  }

  /// Determines if text scaling is at maximum.
  ///
  /// Returns true if scale factor >= maxScaleFactor.
  static bool isMaxTextScale(BuildContext context) {
    final scaleFactor = getScaleFactor(context);
    return scaleFactor >= maxScaleFactor;
  }
}

/// Configuration for text scaling behavior.
class TextScalingConfig {
  const TextScalingConfig({
    this.enabled = true,
    this.minFontSize = ChartTextScaling.minFontSize,
    this.maxScaleFactor = ChartTextScaling.maxScaleFactor,
    this.scaleAxisLabels = true,
    this.scaleLegendText = true,
    this.scaleTooltipText = true,
    this.scaleTitle = true,
  });

  /// Whether text scaling is enabled.
  final bool enabled;

  /// Minimum font size allowed.
  final double minFontSize;

  /// Maximum scale factor allowed.
  final double maxScaleFactor;

  /// Whether to scale axis labels.
  final bool scaleAxisLabels;

  /// Whether to scale legend text.
  final bool scaleLegendText;

  /// Whether to scale tooltip text.
  final bool scaleTooltipText;

  /// Whether to scale chart title.
  final bool scaleTitle;

  /// Default configuration with scaling enabled.
  static const TextScalingConfig enabled_ = TextScalingConfig();

  /// Configuration with scaling disabled.
  static const TextScalingConfig disabled = TextScalingConfig(enabled: false);

  /// Applies scaling to a font size based on this configuration.
  double applyScaling(BuildContext context, double baseSize) {
    if (!enabled) return baseSize;
    return ChartTextScaling.scaledFontSize(
      context,
      baseSize,
      minSize: minFontSize,
      maxScale: maxScaleFactor,
    );
  }

  /// Creates a copy with updated values.
  TextScalingConfig copyWith({
    bool? enabled,
    double? minFontSize,
    double? maxScaleFactor,
    bool? scaleAxisLabels,
    bool? scaleLegendText,
    bool? scaleTooltipText,
    bool? scaleTitle,
  }) =>
      TextScalingConfig(
        enabled: enabled ?? this.enabled,
        minFontSize: minFontSize ?? this.minFontSize,
        maxScaleFactor: maxScaleFactor ?? this.maxScaleFactor,
        scaleAxisLabels: scaleAxisLabels ?? this.scaleAxisLabels,
        scaleLegendText: scaleLegendText ?? this.scaleLegendText,
        scaleTooltipText: scaleTooltipText ?? this.scaleTooltipText,
        scaleTitle: scaleTitle ?? this.scaleTitle,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextScalingConfig &&
        other.enabled == enabled &&
        other.minFontSize == minFontSize &&
        other.maxScaleFactor == maxScaleFactor &&
        other.scaleAxisLabels == scaleAxisLabels &&
        other.scaleLegendText == scaleLegendText &&
        other.scaleTooltipText == scaleTooltipText &&
        other.scaleTitle == scaleTitle;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        minFontSize,
        maxScaleFactor,
        scaleAxisLabels,
        scaleLegendText,
        scaleTooltipText,
        scaleTitle,
      );
}

/// Provider for text scaling configuration.
class TextScalingProvider extends InheritedWidget {
  const TextScalingProvider({
    required this.config,
    required super.child,
    super.key,
  });

  /// The text scaling configuration.
  final TextScalingConfig config;

  /// Gets the text scaling configuration from context.
  static TextScalingConfig of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TextScalingProvider>();
    return provider?.config ?? const TextScalingConfig();
  }

  /// Gets the text scaling configuration from context, or null if not found.
  static TextScalingConfig? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TextScalingProvider>();
    return provider?.config;
  }

  @override
  bool updateShouldNotify(TextScalingProvider oldWidget) =>
      config != oldWidget.config;
}

/// Extension for text scaling on BuildContext.
extension TextScalingContextExtension on BuildContext {
  /// Gets the text scaling configuration.
  TextScalingConfig get textScalingConfig => TextScalingProvider.of(this);

  /// Gets the current text scale factor.
  double get textScaleFactor => ChartTextScaling.getScaleFactor(this);

  /// Whether large text mode is active.
  bool get isLargeTextMode => ChartTextScaling.isLargeTextMode(this);

  /// Scales a font size according to current settings.
  double scaleFontSize(double baseSize) =>
      ChartTextScaling.scaledFontSize(this, baseSize);
}

/// Mixin for widgets that need text scaling support.
mixin TextScalingMixin<T extends StatefulWidget> on State<T> {
  /// Cached text scaling configuration.
  TextScalingConfig? _textScalingConfig;

  /// Cached scale factor.
  double? _scaleFactor;

  /// Gets the text scaling configuration.
  TextScalingConfig getTextScalingConfig(BuildContext context) {
    _textScalingConfig ??= TextScalingProvider.of(context);
    return _textScalingConfig!;
  }

  /// Gets the current scale factor.
  double getScaleFactor(BuildContext context) {
    _scaleFactor ??= ChartTextScaling.getScaleFactor(context);
    return _scaleFactor!;
  }

  /// Scales a font size using the current configuration.
  double scaleFont(BuildContext context, double baseSize) {
    final config = getTextScalingConfig(context);
    return config.applyScaling(context, baseSize);
  }

  /// Clears cached scaling values (call when configuration changes).
  void clearTextScalingCache() {
    _textScalingConfig = null;
    _scaleFactor = null;
  }
}

/// Helper class for calculating text metrics with scaling.
class ScaledTextMetrics {
  ScaledTextMetrics({
    required this.context,
    this.config,
  });

  /// The build context for accessing MediaQuery.
  final BuildContext context;

  /// Optional text scaling configuration override.
  final TextScalingConfig? config;

  TextScalingConfig get _config =>
      config ?? TextScalingProvider.of(context);

  /// Calculates the scaled font size.
  double scaledSize(double baseSize) => _config.applyScaling(context, baseSize);

  /// Creates a TextPainter with scaled font size.
  TextPainter createPainter(
    String text,
    TextStyle style, {
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
  }) {
    final scaledStyle = style.copyWith(
      fontSize: scaledSize(style.fontSize ?? 14.0),
    );

    return TextPainter(
      text: TextSpan(text: text, style: scaledStyle),
      textDirection: textDirection,
      maxLines: maxLines,
    );
  }

  /// Measures text size with scaling applied.
  Size measureText(
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) {
    final painter = createPainter(text, style);
    painter.layout(maxWidth: maxWidth);
    return Size(painter.width, painter.height);
  }
}
