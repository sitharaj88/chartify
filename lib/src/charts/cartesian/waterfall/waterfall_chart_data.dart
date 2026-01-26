import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Type of waterfall item.
enum WaterfallItemType {
  /// Increase from previous value.
  increase,

  /// Decrease from previous value.
  decrease,

  /// Total/running sum (bar starts from zero).
  total,

  /// Subtotal (bar starts from zero, resets running sum).
  subtotal,
}

/// A single item in the waterfall chart.
@immutable
class WaterfallItem {
  const WaterfallItem({
    required this.label,
    required this.value,
    this.type,
    this.color,
  });

  /// Label for this item.
  final String label;

  /// Value (positive or negative).
  final double value;

  /// Type of item (auto-detected if null based on value sign).
  final WaterfallItemType? type;

  /// Custom color for this item.
  final Color? color;

  /// Get the effective type.
  WaterfallItemType get effectiveType {
    if (type != null) return type!;
    return value >= 0 ? WaterfallItemType.increase : WaterfallItemType.decrease;
  }
}

/// Data configuration for waterfall chart.
@immutable
class WaterfallChartData {
  const WaterfallChartData({
    required this.items,
    this.startValue = 0,
    this.increaseColor = const Color(0xFF26A69A),
    this.decreaseColor = const Color(0xFFEF5350),
    this.totalColor = const Color(0xFF42A5F5),
    this.subtotalColor = const Color(0xFF78909C),
    this.showConnectors = true,
    this.connectorColor,
    this.connectorWidth = 1,
    this.connectorDash = const [4, 2],
    this.showValues = true,
    this.valuePosition = WaterfallValuePosition.above,
    this.barWidth = 0.7,
    this.borderRadius = 2,
    this.animation,
  });

  /// List of waterfall items.
  final List<WaterfallItem> items;

  /// Starting value (default 0).
  final double startValue;

  /// Color for increase items.
  final Color increaseColor;

  /// Color for decrease items.
  final Color decreaseColor;

  /// Color for total items.
  final Color totalColor;

  /// Color for subtotal items.
  final Color subtotalColor;

  /// Whether to show connector lines between bars.
  final bool showConnectors;

  /// Color for connector lines.
  final Color? connectorColor;

  /// Width of connector lines.
  final double connectorWidth;

  /// Dash pattern for connectors.
  final List<double> connectorDash;

  /// Whether to show value labels on bars.
  final bool showValues;

  /// Position of value labels.
  final WaterfallValuePosition valuePosition;

  /// Width of bars as ratio of available space.
  final double barWidth;

  /// Border radius of bars.
  final double borderRadius;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Get color for an item.
  Color getItemColor(WaterfallItem item) {
    if (item.color != null) return item.color!;
    switch (item.effectiveType) {
      case WaterfallItemType.increase:
        return increaseColor;
      case WaterfallItemType.decrease:
        return decreaseColor;
      case WaterfallItemType.total:
        return totalColor;
      case WaterfallItemType.subtotal:
        return subtotalColor;
    }
  }
}

/// Position of value labels on waterfall bars.
enum WaterfallValuePosition {
  /// Above the bar.
  above,

  /// Inside the bar.
  inside,

  /// Below the bar.
  below,
}
