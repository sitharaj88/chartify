import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// Layout algorithm for treemap.
enum TreemapLayoutAlgorithm {
  /// Squarified layout - optimizes for square-like rectangles.
  squarified,

  /// Slice layout - alternates horizontal/vertical slicing.
  slice,

  /// Dice layout - alternates vertical/horizontal slicing.
  dice,

  /// Binary layout - recursively divides in half.
  binary,
}

/// Label position for treemap nodes.
enum TreemapLabelPosition {
  /// Label at top-left corner.
  topLeft,

  /// Label centered in node.
  center,

  /// No label shown.
  none,
}

/// A node in the treemap hierarchy.
@immutable
class TreemapNode {
  const TreemapNode({
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
  final List<TreemapNode>? children;

  /// Optional metadata for this node.
  final Map<String, dynamic>? metadata;

  /// Whether this is a leaf node (no children).
  bool get isLeaf => children == null || children!.isEmpty;

  /// Computed value including all descendants.
  double get computedValue {
    if (value != null) return value!;
    if (children == null || children!.isEmpty) return 0;
    return children!.fold(0.0, (sum, child) => sum + child.computedValue);
  }

  /// Get all leaf nodes in this subtree.
  List<TreemapNode> get leafNodes {
    if (isLeaf) return [this];
    return children!.expand((child) => child.leafNodes).toList();
  }

  /// Get the depth of this subtree.
  int get depth {
    if (isLeaf) return 0;
    return 1 + children!.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
  }
}

/// Represents a positioned rectangle in the treemap.
@immutable
class TreemapRect {
  const TreemapRect({
    required this.node,
    required this.rect,
    required this.depth,
    this.parent,
  });

  /// The treemap node this rectangle represents.
  final TreemapNode node;

  /// The positioned rectangle.
  final Rect rect;

  /// Depth in the hierarchy (0 = root).
  final int depth;

  /// Parent rectangle (null for root).
  final TreemapRect? parent;
}

/// Configuration for treemap borders.
@immutable
class TreemapBorderConfig {
  const TreemapBorderConfig({
    this.color,
    this.width = 1.0,
    this.showAtDepth,
  });

  /// Border color (uses theme if null).
  final Color? color;

  /// Border width.
  final double width;

  /// Only show borders at these depths (all if null).
  final List<int>? showAtDepth;

  /// Whether to show border at given depth.
  bool showAt(int depth) {
    if (showAtDepth == null) return true;
    return showAtDepth!.contains(depth);
  }
}

/// Data configuration for treemap chart.
@immutable
class TreemapChartData {
  const TreemapChartData({
    required this.root,
    this.algorithm = TreemapLayoutAlgorithm.squarified,
    this.padding = 2.0,
    this.headerHeight = 0.0,
    this.border = const TreemapBorderConfig(),
    this.labelPosition = TreemapLabelPosition.topLeft,
    this.showLabels = true,
    this.minLabelWidth = 30.0,
    this.minLabelHeight = 20.0,
    this.colorByDepth = false,
    this.maxDepth,
    this.animation,
  });

  /// Root node of the treemap hierarchy.
  final TreemapNode root;

  /// Layout algorithm to use.
  final TreemapLayoutAlgorithm algorithm;

  /// Padding between nodes (in pixels).
  final double padding;

  /// Height reserved for group headers.
  final double headerHeight;

  /// Border configuration.
  final TreemapBorderConfig border;

  /// Position of labels within nodes.
  final TreemapLabelPosition labelPosition;

  /// Whether to show labels.
  final bool showLabels;

  /// Minimum width to show label.
  final double minLabelWidth;

  /// Minimum height to show label.
  final double minLabelHeight;

  /// Whether to color nodes by depth level.
  final bool colorByDepth;

  /// Maximum depth to render (null for all).
  final int? maxDepth;

  /// Animation configuration.
  final ChartAnimation? animation;
}
