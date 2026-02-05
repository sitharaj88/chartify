import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'sankey_chart_data.dart';

export 'sankey_chart_data.dart';

/// A Sankey diagram widget.
///
/// Displays flow between nodes with link width proportional to value.
///
/// Example:
/// ```dart
/// SankeyChart(
///   data: SankeyChartData(
///     nodes: [
///       SankeyNode(id: 'a', label: 'Source A'),
///       SankeyNode(id: 'b', label: 'Source B'),
///       SankeyNode(id: 'c', label: 'Target'),
///     ],
///     links: [
///       SankeyLink(sourceId: 'a', targetId: 'c', value: 100),
///       SankeyLink(sourceId: 'b', targetId: 'c', value: 50),
///     ],
///   ),
/// )
/// ```
class SankeyChart extends StatefulWidget {
  const SankeyChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onNodeTap,
    this.onLinkTap,
    this.padding = const EdgeInsets.all(24),
  });

  final SankeyChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(SankeyNode node)? onNodeTap;
  final void Function(SankeyLink link)? onLinkTap;
  final EdgeInsets padding;

  @override
  State<SankeyChart> createState() => _SankeyChartState();
}

class _SankeyChartState extends State<SankeyChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();

  ChartAnimation get _animationConfig =>
      widget.animation ?? widget.data.animation ?? const ChartAnimation();

  @override
  void initState() {
    super.initState();
    _initController();
    _initAnimation();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ChartController();
      _ownsController = true;
    }
  }

  void _initAnimation() {
    if (_animationConfig.enabled && _animationConfig.animateOnLoad) {
      _animationController = AnimationController(
        vsync: this,
        duration: _animationConfig.duration,
      );

      _animation = CurvedAnimation(
        parent: _animationController!,
        curve: _animationConfig.curve,
      );

      _animationController!.addListener(() {
        if (mounted) setState(() {});
      });

      _animationController!.forward();
    }
  }

  @override
  void didUpdateWidget(SankeyChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      if (_animationConfig.enabled && _animationConfig.animateOnDataChange) {
        _animationController?.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleHover(PointerEvent event) {
    final hitInfo = _hitTester.hitTest(event.localPosition, radius: 0);
    if (hitInfo != null) {
      _controller.setHoveredPoint(hitInfo);
    } else {
      _controller.clearHoveredPoint();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);
        // Note: hitRadius not used - Sankey charts use rect-based hit testing for nodes/links

        final chartArea = Rect.fromLTRB(
          responsivePadding.left,
          responsivePadding.top,
          constraints.maxWidth - responsivePadding.right,
          constraints.maxHeight - responsivePadding.bottom,
        );

        return ChartTooltipOverlay(
          controller: _controller,
          config: widget.tooltip,
          theme: theme,
          chartArea: chartArea,
          tooltipDataBuilder: (info) => _buildTooltipData(info, theme),
          child: ChartGestureDetector(
            controller: _controller,
            interactions: widget.interactions,
            hitTester: _hitTester,
            onTap: (details) {
              final hitInfo =
                  _hitTester.hitTest(details.localPosition, radius: 0);
              if (hitInfo != null) {
                // seriesIndex 0 = nodes, 1 = links
                if (hitInfo.seriesIndex == 0 && widget.onNodeTap != null) {
                  final idx = hitInfo.pointIndex;
                  if (idx >= 0 && idx < widget.data.nodes.length) {
                    widget.onNodeTap!(widget.data.nodes[idx]);
                  }
                } else if (hitInfo.seriesIndex == 1 && widget.onLinkTap != null) {
                  final idx = hitInfo.pointIndex;
                  if (idx >= 0 && idx < widget.data.links.length) {
                    widget.onLinkTap!(widget.data.links[idx]);
                  }
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) => _controller.clearHoveredPoint(),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SankeyChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: responsivePadding,
                  labelFontSize: labelFontSize,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }

  TooltipData? _buildTooltipData(DataPointInfo info, ChartThemeData theme) {
    if (info.seriesIndex == 0) {
      // Node
      final idx = info.pointIndex;
      if (idx < 0 || idx >= widget.data.nodes.length) {
        return null; // Invalid index - no tooltip
      }

      final node = widget.data.nodes[idx];
      final color = node.color ?? theme.getSeriesColor(idx);

      // Calculate total flow through node
      final inflow = widget.data.links
          .where((l) => l.targetId == node.id)
          .fold<double>(0, (sum, l) => sum + l.value);
      final outflow = widget.data.links
          .where((l) => l.sourceId == node.id)
          .fold<double>(0, (sum, l) => sum + l.value);
      final total = math.max(inflow, outflow);

      return TooltipData(
        position: info.position,
        entries: [
          TooltipEntry(
            color: color,
            label: 'Total',
            value: total,
            formattedValue: total.toStringAsFixed(0),
          ),
        ],
        xLabel: node.label,
      );
    } else {
      // Link
      final idx = info.pointIndex;
      if (idx < 0 || idx >= widget.data.links.length) {
        return null; // Invalid index - no tooltip
      }

      final link = widget.data.links[idx];
      final sourceNode = widget.data.nodes.where((n) => n.id == link.sourceId).firstOrNull;
      final targetNode = widget.data.nodes.where((n) => n.id == link.targetId).firstOrNull;

      // Handle missing nodes gracefully
      if (sourceNode == null || targetNode == null) {
        return null; // Missing node reference - no tooltip
      }

      final color = link.color ?? sourceNode.color ?? theme.getSeriesColor(0);

      return TooltipData(
        position: info.position,
        entries: [
          TooltipEntry(
            color: color,
            label: 'Flow',
            value: link.value,
            formattedValue: link.value.toStringAsFixed(0),
          ),
        ],
        xLabel: '${sourceNode.label} → ${targetNode.label}',
      );
    }
  }
}

class _SankeyChartPainter extends ChartPainter {
  _SankeyChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
  }) : super(repaint: controller);

  final SankeyChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;

  @override
  Rect getChartArea(Size size) => Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );

  @override
  void paintSeries(Canvas canvas, Size size, Rect chartArea) {
    hitTester.clear();

    if (data.nodes.isEmpty || data.links.isEmpty) return;

    // Calculate layout
    final layout = _calculateLayout(chartArea);
    final nodePositions = layout.$1;
    final linkPositions = layout.$2;

    // Build lookup maps for O(1) access
    final nodeMap = <String, SankeyNode>{};
    for (final node in data.nodes) {
      nodeMap[node.id] = node;
    }
    final positionMap = <String, SankeyNodePosition>{};
    for (final pos in nodePositions) {
      positionMap[pos.node.id] = pos;
    }

    // Draw links first (behind nodes)
    for (var i = 0; i < linkPositions.length; i++) {
      final linkPos = linkPositions[i];
      final link = linkPos.link;

      // Use stored original index for reliable tooltip lookup
      final originalLinkIndex = linkPos.originalIndex;

      final isHovered =
          controller.hoveredPoint?.seriesIndex == 1 &&
          controller.hoveredPoint?.pointIndex == originalLinkIndex;

      final sourceNode = nodeMap[link.sourceId];
      final targetNode = nodeMap[link.targetId];
      final sourcePos = positionMap[link.sourceId];
      final targetPos = positionMap[link.targetId];

      // Skip links with missing nodes
      if (sourceNode == null || targetNode == null || sourcePos == null || targetPos == null) continue;

      final sourceColor = link.color ?? sourceNode.color ?? theme.getSeriesColor(
          data.nodes.indexOf(sourceNode),);
      final targetColor = link.color ?? targetNode.color ?? theme.getSeriesColor(
          data.nodes.indexOf(targetNode),);

      _drawLink(
        canvas,
        sourcePos,
        targetPos,
        linkPos,
        sourceColor,
        targetColor,
        isHovered,
        chartArea,
      );

      // Register link hit target
      // sourceY and targetY are CENTER positions, so account for width/2 on each side
      final midX = (sourcePos.x + data.nodeWidth + targetPos.x) / 2;

      // Account for bezier curve bulge - curves can extend beyond straight line bounds
      // The bulge amount depends on the vertical displacement between source and target
      final verticalDisplacement = (linkPos.targetY - linkPos.sourceY).abs();
      final curveBulge = verticalDisplacement * 0.15; // ~15% bulge for bezier curve

      final linkTop = math.min(linkPos.sourceY, linkPos.targetY) -
          linkPos.width / 2 - curveBulge;
      final linkBottom = math.max(linkPos.sourceY, linkPos.targetY) +
          linkPos.width / 2 + curveBulge;

      // Ensure minimum hit target height for thin links (WCAG compliance)
      const minHitHeight = 24.0; // Minimum touch target
      final hitHeight = math.max(linkBottom - linkTop, minHitHeight);
      final hitTop = (linkTop + linkBottom) / 2 - hitHeight / 2;

      hitTester.addRect(
        rect: Rect.fromLTWH(
          sourcePos.x + data.nodeWidth,
          hitTop,
          targetPos.x - sourcePos.x - data.nodeWidth,
          hitHeight,
        ),
        info: DataPointInfo(
          seriesIndex: 1,
          pointIndex: originalLinkIndex,
          position: Offset(midX, (linkPos.sourceY + linkPos.targetY) / 2),
          xValue: originalLinkIndex,
          yValue: link.value,
        ),
      );
    }

    // Draw nodes
    for (var i = 0; i < nodePositions.length; i++) {
      final nodePos = nodePositions[i];
      final isHovered =
          controller.hoveredPoint?.seriesIndex == 0 &&
          controller.hoveredPoint?.pointIndex == i;

      final color = nodePos.node.color ?? theme.getSeriesColor(i);

      _drawNode(canvas, nodePos, color, isHovered, i);

      // Draw label
      if (data.showLabels) {
        _drawLabel(canvas, nodePos, chartArea);
      }
    }
  }

  (List<SankeyNodePosition>, List<SankeyLinkPosition>) _calculateLayout(
      Rect chartArea,) {
    // Build graph structure with maps for O(1) lookups
    final nodeMap = <String, SankeyNode>{};
    for (final node in data.nodes) {
      nodeMap[node.id] = node;
    }

    // Filter links to only include those with valid source and target nodes
    final validLinks = data.links.where(
      (l) => nodeMap.containsKey(l.sourceId) && nodeMap.containsKey(l.targetId),
    ).toList();

    // Detect circular dependencies using DFS with path tracking
    // The detection is used to ensure the layout algorithm handles cycles gracefully
    _detectCycle(validLinks, nodeMap.keys.toSet());

    // Calculate node columns (depth)
    final nodeDepth = <String, int>{};
    final visited = <String>{};
    final inProgress = <String>{}; // Track nodes in current DFS path

    void calculateDepth(String nodeId, int depth) {
      // Skip if we've completed processing this node
      if (visited.contains(nodeId)) return;

      // Cycle detected - skip to prevent infinite recursion
      if (inProgress.contains(nodeId)) return;

      inProgress.add(nodeId);
      nodeDepth[nodeId] = math.max(nodeDepth[nodeId] ?? 0, depth);

      for (final link in validLinks.where((l) => l.sourceId == nodeId)) {
        calculateDepth(link.targetId, depth + 1);
      }

      inProgress.remove(nodeId);
      visited.add(nodeId);
    }

    // Find source nodes (no incoming links from valid links)
    final sourceNodes = data.nodes.where((n) =>
        !validLinks.any((l) => l.targetId == n.id),).toList();

    // If graph has cycles and no clear source nodes, start from first node
    if (sourceNodes.isEmpty && data.nodes.isNotEmpty) {
      calculateDepth(data.nodes.first.id, 0);
    } else {
      for (final node in sourceNodes) {
        calculateDepth(node.id, 0);
      }
    }

    // Handle disconnected nodes
    for (final node in data.nodes) {
      nodeDepth.putIfAbsent(node.id, () => 0);
    }

    // Group nodes by column
    final columns = <int, List<SankeyNode>>{};
    for (final node in data.nodes) {
      final depth = nodeDepth[node.id]!;
      columns.putIfAbsent(depth, () => []).add(node);
    }

    final maxColumn = columns.keys.reduce((a, b) => a > b ? a : b);

    // Calculate node heights based on flow
    final nodeFlow = <String, double>{};
    for (final node in data.nodes) {
      final inflow = data.links
          .where((l) => l.targetId == node.id)
          .fold<double>(0, (sum, l) => sum + l.value);
      final outflow = data.links
          .where((l) => l.sourceId == node.id)
          .fold<double>(0, (sum, l) => sum + l.value);
      nodeFlow[node.id] = math.max(inflow, outflow);
    }

    final totalFlow = nodeFlow.values.fold<double>(0, (sum, v) => sum + v);

    // Calculate positions
    final nodePositions = <SankeyNodePosition>[];
    final columnWidth =
        (chartArea.width - data.nodeWidth) / math.max(maxColumn, 1);

    for (final entry in columns.entries) {
      final column = entry.key;
      final nodes = entry.value;

      final x = chartArea.left + column * columnWidth;

      // Calculate total height needed for this column
      final columnFlow = nodes.fold<double>(0, (sum, n) => sum + nodeFlow[n.id]!);
      final availableHeight =
          chartArea.height - (nodes.length - 1) * data.nodePadding;

      var y = chartArea.top;

      for (final node in nodes) {
        final flow = nodeFlow[node.id]!;
        final height = totalFlow > 0
            ? (flow / columnFlow) * availableHeight * animationValue
            : availableHeight / nodes.length * animationValue;

        nodePositions.add(SankeyNodePosition(
          node: node,
          x: x,
          y: y,
          height: height,
          column: column,
        ),);

        y += height + data.nodePadding;
      }
    }

    // Calculate link positions using map for O(1) lookup
    final linkPositions = <SankeyLinkPosition>[];
    final sourceOffsets = <String, double>{};
    final targetOffsets = <String, double>{};

    // Build position map
    final posMap = <String, SankeyNodePosition>{};
    for (final pos in nodePositions) {
      posMap[pos.node.id] = pos;
    }

    // Process all links, storing original indices for reliable tooltip lookup
    for (var i = 0; i < data.links.length; i++) {
      final link = data.links[i];

      // Skip invalid links (those with missing source/target nodes)
      if (!nodeMap.containsKey(link.sourceId) ||
          !nodeMap.containsKey(link.targetId)) {
        continue;
      }

      final sourcePos = posMap[link.sourceId];
      final targetPos = posMap[link.targetId];

      // Skip if positions not found
      if (sourcePos == null || targetPos == null) continue;

      final sourceOffset = sourceOffsets[link.sourceId] ?? 0.0;
      final targetOffset = targetOffsets[link.targetId] ?? 0.0;

      final width = totalFlow > 0
          ? (link.value / totalFlow) * chartArea.height * 0.8 * animationValue
          : 10.0;

      linkPositions.add(SankeyLinkPosition(
        link: link,
        sourceY: sourcePos.y + sourceOffset + width / 2,
        targetY: targetPos.y + targetOffset + width / 2,
        width: width,
        originalIndex: i,
      ),);

      sourceOffsets[link.sourceId] = sourceOffset + width;
      targetOffsets[link.targetId] = targetOffset + width;
    }

    return (nodePositions, linkPositions);
  }

  void _drawNode(Canvas canvas, SankeyNodePosition pos, Color color,
      bool isHovered, int index,) {
    final rect = Rect.fromLTWH(pos.x, pos.y, data.nodeWidth, pos.height);

    final paint = Paint()
      ..color = isHovered ? color : color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRect(rect, paint);

    if (isHovered) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      canvas.drawRect(rect, borderPaint);
    }

    // Register hit target
    hitTester.addRect(
      rect: rect,
      info: DataPointInfo(
        seriesIndex: 0,
        pointIndex: index,
        position: rect.center,
        xValue: index,
        yValue: pos.height,
      ),
    );
  }

  void _drawLink(
    Canvas canvas,
    SankeyNodePosition sourcePos,
    SankeyNodePosition targetPos,
    SankeyLinkPosition linkPos,
    Color sourceColor,
    Color targetColor,
    bool isHovered,
    Rect chartArea,
  ) {
    final startX = sourcePos.x + data.nodeWidth;
    final endX = targetPos.x;

    final path = Path();

    // Create curved path
    final controlOffset = (endX - startX) * 0.5;

    path.moveTo(startX, linkPos.sourceY - linkPos.width / 2);
    path.cubicTo(
      startX + controlOffset,
      linkPos.sourceY - linkPos.width / 2,
      endX - controlOffset,
      linkPos.targetY - linkPos.width / 2,
      endX,
      linkPos.targetY - linkPos.width / 2,
    );
    path.lineTo(endX, linkPos.targetY + linkPos.width / 2);
    path.cubicTo(
      endX - controlOffset,
      linkPos.targetY + linkPos.width / 2,
      startX + controlOffset,
      linkPos.sourceY + linkPos.width / 2,
      startX,
      linkPos.sourceY + linkPos.width / 2,
    );
    path.close();

    final opacity = isHovered ? 0.8 : data.linkOpacity;
    final gradient = LinearGradient(
      colors: [
        sourceColor.withValues(alpha: opacity),
        targetColor.withValues(alpha: opacity),
      ],
    );

    final gradientRect = Rect.fromLTRB(
      startX,
      math.min(linkPos.sourceY, linkPos.targetY) - linkPos.width / 2,
      endX,
      math.max(linkPos.sourceY, linkPos.targetY) + linkPos.width / 2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(gradientRect)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, SankeyNodePosition pos, Rect chartArea) {
    final isLeftSide = pos.x < chartArea.center.dx;

    final textSpan = TextSpan(
      text: pos.node.label,
      style: theme.labelStyle.copyWith(fontSize: labelFontSize),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    double x;
    if (isLeftSide) {
      x = pos.x + data.nodeWidth + 4;
    } else {
      x = pos.x - textPainter.width - 4;
    }

    final y = pos.y + (pos.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  /// Detects if the graph contains any cycles using DFS.
  /// Returns true if a cycle is detected.
  bool _detectCycle(List<SankeyLink> links, Set<String> nodeIds) {
    final adjacency = <String, List<String>>{};
    for (final nodeId in nodeIds) {
      adjacency[nodeId] = [];
    }
    for (final link in links) {
      adjacency[link.sourceId]?.add(link.targetId);
    }

    final visited = <String>{};
    final inStack = <String>{};

    bool dfs(String nodeId) {
      if (inStack.contains(nodeId)) return true; // Cycle found
      if (visited.contains(nodeId)) return false;

      visited.add(nodeId);
      inStack.add(nodeId);

      for (final neighbor in adjacency[nodeId] ?? <String>[]) {
        if (dfs(neighbor)) return true;
      }

      inStack.remove(nodeId);
      return false;
    }

    for (final nodeId in nodeIds) {
      if (dfs(nodeId)) return true;
    }

    return false;
  }

  @override
  bool shouldRepaint(covariant _SankeyChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
