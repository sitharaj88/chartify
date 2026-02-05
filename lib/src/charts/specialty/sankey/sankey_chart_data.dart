import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A node in the Sankey diagram.
@immutable
class SankeyNode {
  const SankeyNode({
    required this.id,
    required this.label,
    this.color,
  });

  /// Unique identifier.
  final String id;

  /// Display label.
  final String label;

  /// Optional custom color.
  final Color? color;
}

/// A link/flow between two nodes.
@immutable
class SankeyLink {
  const SankeyLink({
    required this.sourceId,
    required this.targetId,
    required this.value,
    this.color,
  });

  /// ID of the source node.
  final String sourceId;

  /// ID of the target node.
  final String targetId;

  /// Flow value (determines link width).
  final double value;

  /// Optional custom color (defaults to source color).
  final Color? color;
}

/// Alignment options for Sankey nodes.
enum SankeyAlignment {
  /// Align nodes to the left.
  left,

  /// Align nodes to the right.
  right,

  /// Center nodes.
  center,

  /// Justify nodes (spread evenly).
  justify,
}

/// Data configuration for Sankey chart.
@immutable
class SankeyChartData {
  const SankeyChartData({
    required this.nodes,
    required this.links,
    this.nodeWidth = 20.0,
    this.nodePadding = 10.0,
    this.linkOpacity = 0.4,
    this.showLabels = true,
    this.showValues = true,
    this.alignment = SankeyAlignment.justify,
    this.iterations = 32,
    this.animation,
  });

  /// List of nodes.
  final List<SankeyNode> nodes;

  /// List of links between nodes.
  final List<SankeyLink> links;

  /// Width of node rectangles.
  final double nodeWidth;

  /// Vertical padding between nodes.
  final double nodePadding;

  /// Opacity of links (0.0 to 1.0).
  final double linkOpacity;

  /// Whether to show node labels.
  final bool showLabels;

  /// Whether to show values on links.
  final bool showValues;

  /// Node alignment.
  final SankeyAlignment alignment;

  /// Number of relaxation iterations for layout.
  final int iterations;

  /// Animation configuration.
  final ChartAnimation? animation;

  /// Total value of all links.
  double get totalValue => links.fold(0, (sum, link) => sum + link.value);
}

/// Computed position for a Sankey node.
class SankeyNodePosition {
  SankeyNodePosition({
    required this.node,
    required this.x,
    required this.y,
    required this.height,
    required this.column,
  });

  final SankeyNode node;
  double x;
  double y;
  double height;
  final int column;

  double get centerY => y + height / 2;
}

/// Computed position for a Sankey link.
class SankeyLinkPosition {
  SankeyLinkPosition({
    required this.link,
    required this.sourceY,
    required this.targetY,
    required this.width,
    required this.originalIndex,
  });

  final SankeyLink link;
  double sourceY;
  double targetY;
  final double width;

  /// The original index of this link in the data.links list.
  /// Used for reliable tooltip lookup without indexOf().
  final int originalIndex;
}
