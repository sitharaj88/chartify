import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Label position for sunburst arcs.
enum SunburstLabelPosition {
  /// Label along the arc (tangential).
  tangential,

  /// Label pointing outward (radial).
  radial,

  /// No labels shown.
  none,
}

/// A node in the sunburst hierarchy.
@immutable
class SunburstNode {
  const SunburstNode({
    required this.label,
    this.value,
    this.color,
    this.children,
    this.metadata,
  }) : assert(
          value != null || (children != null && children.length > 0),
          'Node must have either a value or children',
        );

  /// Display label for this node.
  final String label;

  /// Value of this node (leaf nodes only).
  /// If null, the value is computed from children.
  final double? value;

  /// Custom color for this node.
  final Color? color;

  /// Child nodes (for hierarchical data).
  final List<SunburstNode>? children;

  /// Optional metadata for this node.
  final Map<String, dynamic>? metadata;

  /// Whether this is a leaf node (no children).
  bool get isLeaf => children == null || children!.isEmpty;

  /// Computed value including all descendants.
  double get computedValue {
    if (value != null) return value!;
    if (children == null || children!.isEmpty) return 0;
    return children!.fold(0, (sum, child) => sum + child.computedValue);
  }

  /// Get all leaf nodes in this subtree.
  List<SunburstNode> get leafNodes {
    if (isLeaf) return [this];
    return children!.expand((child) => child.leafNodes).toList();
  }

  /// Get the depth of this subtree.
  int get depth {
    if (isLeaf) return 0;
    return 1 + children!.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
  }
}

/// Represents a positioned arc in the sunburst.
@immutable
class SunburstArc {
  const SunburstArc({
    required this.node,
    required this.startAngle,
    required this.sweepAngle,
    required this.innerRadius,
    required this.outerRadius,
    required this.depth,
    this.parent,
  });

  /// The sunburst node this arc represents.
  final SunburstNode node;

  /// Start angle in radians.
  final double startAngle;

  /// Sweep angle in radians.
  final double sweepAngle;

  /// Inner radius of the arc.
  final double innerRadius;

  /// Outer radius of the arc.
  final double outerRadius;

  /// Depth in the hierarchy (0 = root/center).
  final int depth;

  /// Parent arc (null for root).
  final SunburstArc? parent;

  /// End angle in radians.
  double get endAngle => startAngle + sweepAngle;

  /// Middle angle in radians.
  double get midAngle => startAngle + sweepAngle / 2;

  /// Middle radius.
  double get midRadius => (innerRadius + outerRadius) / 2;
}

/// Data configuration for sunburst chart.
@immutable
class SunburstChartData {
  const SunburstChartData({
    required this.root,
    this.innerRadius = 0.0,
    this.ringWidth = 40.0,
    this.startAngle = -1.5707963267948966, // -pi/2 (top)
    this.gap = 0.5,
    this.cornerRadius = 0.0,
    this.showLabels = true,
    this.labelPosition = SunburstLabelPosition.tangential,
    this.minLabelAngle = 0.1,
    this.colorByDepth = false,
    this.maxDepth,
    this.showCenterLabel = true,
    this.centerLabelStyle,
    this.animation,
  });

  /// Root node of the sunburst hierarchy.
  final SunburstNode root;

  /// Inner radius of the center hole (0 for no hole).
  final double innerRadius;

  /// Width of each ring level.
  final double ringWidth;

  /// Start angle in radians (-pi/2 = top).
  final double startAngle;

  /// Gap between arcs in degrees.
  final double gap;

  /// Corner radius for arcs.
  final double cornerRadius;

  /// Whether to show labels on arcs.
  final bool showLabels;

  /// Position of labels.
  final SunburstLabelPosition labelPosition;

  /// Minimum sweep angle (in radians) to show label.
  final double minLabelAngle;

  /// Whether to color arcs by depth level.
  final bool colorByDepth;

  /// Maximum depth to render (null for all).
  final int? maxDepth;

  /// Whether to show label in center.
  final bool showCenterLabel;

  /// Style for center label.
  final TextStyle? centerLabelStyle;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Convert degrees to radians.
  static double degreesToRadians(double degrees) => degrees * 3.141592653589793 / 180;

  /// Get the gap in radians.
  double get gapRadians => degreesToRadians(gap);
}
