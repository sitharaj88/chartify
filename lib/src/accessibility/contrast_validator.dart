import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// WCAG 2.1 contrast level requirements.
enum ContrastLevel {
  /// Minimum contrast (3:1) for large text and UI components.
  aa3,

  /// Standard contrast (4.5:1) for normal text.
  aa,

  /// Enhanced contrast (7:1) for better readability.
  aaa,
}

/// Validates color contrast ratios for accessibility compliance.
///
/// Implements WCAG 2.1 contrast ratio calculations and provides
/// methods to check if color combinations meet accessibility standards.
///
/// Example:
/// ```dart
/// final isAccessible = ContrastValidator.meetsWcagAA(
///   foreground: Colors.blue,
///   background: Colors.white,
/// );
/// ```
class ContrastValidator {
  ContrastValidator._();

  /// Minimum contrast ratios for each WCAG level.
  static const Map<ContrastLevel, double> _minRatios = {
    ContrastLevel.aa3: 3.0,
    ContrastLevel.aa: 4.5,
    ContrastLevel.aaa: 7.0,
  };

  /// Calculates the contrast ratio between two colors.
  ///
  /// Returns a value between 1 and 21, where:
  /// - 1 = no contrast (same color)
  /// - 21 = maximum contrast (black/white)
  ///
  /// Formula follows WCAG 2.1 relative luminance calculation.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);

    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculates the relative luminance of a color.
  ///
  /// Uses the WCAG 2.1 formula for sRGB colors.
  static double _relativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Converts an sRGB color component to linear RGB.
  static double _linearize(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    }
    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Checks if a color combination meets a specific WCAG level.
  static bool meetsLevel(
    Color foreground,
    Color background,
    ContrastLevel level,
  ) {
    final ratio = contrastRatio(foreground, background);
    return ratio >= _minRatios[level]!;
  }

  /// Checks if a color combination meets WCAG AA for normal text.
  static bool meetsWcagAA(Color foreground, Color background) =>
      meetsLevel(foreground, background, ContrastLevel.aa);

  /// Checks if a color combination meets WCAG AAA for normal text.
  static bool meetsWcagAAA(Color foreground, Color background) =>
      meetsLevel(foreground, background, ContrastLevel.aaa);

  /// Checks if a color combination meets WCAG AA for large text/UI components.
  static bool meetsWcagAA3(Color foreground, Color background) =>
      meetsLevel(foreground, background, ContrastLevel.aa3);

  /// Suggests an adjusted color that meets the target contrast level.
  ///
  /// Returns the original color if it already meets the requirement,
  /// or adjusts the lightness to meet the target contrast.
  static Color suggestAccessibleColor(
    Color foreground,
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) {
    if (meetsLevel(foreground, background, level)) {
      return foreground;
    }

    final targetRatio = _minRatios[level]!;
    final bgLuminance = _relativeLuminance(background);

    // Determine if we should lighten or darken
    final shouldLighten = bgLuminance < 0.5;

    // Binary search for the right lightness
    final hsl = HSLColor.fromColor(foreground);
    var low = shouldLighten ? hsl.lightness : 0.0;
    var high = shouldLighten ? 1.0 : hsl.lightness;

    for (var i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final testColor = hsl.withLightness(mid).toColor();
      final ratio = contrastRatio(testColor, background);

      if (ratio >= targetRatio) {
        if (shouldLighten) {
          high = mid;
        } else {
          low = mid;
        }
      } else {
        if (shouldLighten) {
          low = mid;
        } else {
          high = mid;
        }
      }
    }

    final finalLightness = shouldLighten ? high : low;
    return hsl.withLightness(finalLightness.clamp(0.0, 1.0)).toColor();
  }

  /// Validates a color palette against a background.
  ///
  /// Returns a map of colors that fail to meet the specified contrast level.
  static Map<int, ContrastIssue> validatePalette(
    List<Color> colors,
    Color background, {
    ContrastLevel level = ContrastLevel.aa,
  }) {
    final issues = <int, ContrastIssue>{};

    for (var i = 0; i < colors.length; i++) {
      final ratio = contrastRatio(colors[i], background);
      final required = _minRatios[level]!;

      if (ratio < required) {
        issues[i] = ContrastIssue(
          color: colors[i],
          actualRatio: ratio,
          requiredRatio: required,
          suggestedColor: suggestAccessibleColor(
            colors[i],
            background,
            level: level,
          ),
        );
      }
    }

    return issues;
  }

  /// Gets a readable description of a contrast ratio.
  static String describeRatio(double ratio) {
    if (ratio >= 7.0) return 'Excellent (AAA compliant)';
    if (ratio >= 4.5) return 'Good (AA compliant)';
    if (ratio >= 3.0) return 'Acceptable for large text';
    if (ratio >= 2.0) return 'Poor contrast';
    return 'Very poor contrast';
  }
}

/// Represents a contrast issue found during validation.
class ContrastIssue {
  const ContrastIssue({
    required this.color,
    required this.actualRatio,
    required this.requiredRatio,
    required this.suggestedColor,
  });

  /// The original color that failed validation.
  final Color color;

  /// The actual contrast ratio.
  final double actualRatio;

  /// The required contrast ratio.
  final double requiredRatio;

  /// A suggested replacement color that meets requirements.
  final Color suggestedColor;

  @override
  String toString() =>
      'ContrastIssue(ratio: ${actualRatio.toStringAsFixed(2)}, '
      'required: ${requiredRatio.toStringAsFixed(2)})';
}

/// Extension for easy contrast checking on colors.
extension ColorContrastExtension on Color {
  /// Calculates the contrast ratio against another color.
  double contrastWith(Color other) =>
      ContrastValidator.contrastRatio(this, other);

  /// Checks if this color has sufficient contrast against another.
  bool hasContrastWith(Color other, {ContrastLevel level = ContrastLevel.aa}) =>
      ContrastValidator.meetsLevel(this, other, level);

  /// Adjusts this color to meet contrast requirements against a background.
  Color adjustForContrast(Color background,
          {ContrastLevel level = ContrastLevel.aa,}) =>
      ContrastValidator.suggestAccessibleColor(this, background, level: level);
}
