import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';
import '../../../components/tooltip/chart_tooltip.dart';
import '../../../core/base/chart_controller.dart';
import '../../../core/base/chart_painter.dart';
import '../../../core/gestures/gesture_detector.dart';
import '../../../theme/chart_theme_data.dart';
import '../../_base/chart_responsive_mixin.dart';
import 'treemap_chart_data.dart';

export 'treemap_chart_data.dart';

/// A treemap chart widget.
///
/// Displays hierarchical data as nested rectangles where
/// size represents value.
///
/// Example:
/// ```dart
/// TreemapChart(
///   data: TreemapChartData(
///     root: TreemapNode(
///       label: 'Root',
///       children: [
///         TreemapNode(label: 'A', value: 10),
///         TreemapNode(label: 'B', value: 20),
///         TreemapNode(label: 'C', value: 15),
///       ],
///     ),
///   ),
/// )
/// ```
class TreemapChart extends StatefulWidget {
  const TreemapChart({
    required this.data, super.key,
    this.controller,
    this.animation,
    this.interactions = const ChartInteractions(),
    this.tooltip = const TooltipConfig(),
    this.onNodeTap,
    this.onNodeHover,
    this.padding = EdgeInsets.zero,
  });

  final TreemapChartData data;
  final ChartController? controller;
  final ChartAnimation? animation;
  final ChartInteractions interactions;
  final TooltipConfig tooltip;
  final void Function(TreemapNode node, int depth)? onNodeTap;
  final void Function(TreemapNode? node, int? depth)? onNodeHover;
  final EdgeInsets padding;

  @override
  State<TreemapChart> createState() => _TreemapChartState();
}

class _TreemapChartState extends State<TreemapChart>
    with SingleTickerProviderStateMixin, ChartResponsiveMixin {
  late ChartController _controller;
  bool _ownsController = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final ChartHitTester _hitTester = ChartHitTester();
  List<TreemapRect> _layoutCache = [];

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
  void didUpdateWidget(TreemapChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      _initController();
    }

    if (widget.data != oldWidget.data) {
      _layoutCache = [];
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
      final idx = hitInfo.pointIndex;
      if (idx >= 0 && idx < _layoutCache.length) {
        final rect = _layoutCache[idx];
        widget.onNodeHover?.call(rect.node, rect.depth);
      }
    } else {
      _controller.clearHoveredPoint();
      widget.onNodeHover?.call(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = getResponsivePadding(context, constraints, override: widget.padding);
        final labelFontSize = getScaledFontSize(context, 11.0);
        final hitRadius = getHitTestRadius(context, constraints);

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
              if (hitInfo != null && widget.onNodeTap != null) {
                final idx = hitInfo.pointIndex;
                if (idx >= 0 && idx < _layoutCache.length) {
                  final rect = _layoutCache[idx];
                  widget.onNodeTap!(rect.node, rect.depth);
                }
              }
            },
            onHover: _handleHover,
            onExit: (_) {
              _controller.clearHoveredPoint();
              widget.onNodeHover?.call(null, null);
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _TreemapChartPainter(
                  data: widget.data,
                  theme: theme,
                  animationValue: _animation?.value ?? 1.0,
                  controller: _controller,
                  hitTester: _hitTester,
                  padding: responsivePadding,
                  labelFontSize: labelFontSize,
                  onLayoutComplete: (rects) => _layoutCache = rects,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }

  TooltipData _buildTooltipData(DataPointInfo info, ChartThemeData theme) {
    final idx = info.pointIndex;
    if (idx < 0 || idx >= _layoutCache.length) {
      return TooltipData(position: info.position, entries: const []);
    }

    final rect = _layoutCache[idx];
    final node = rect.node;
    final color = node.color ?? theme.getSeriesColor(rect.depth);

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: color,
          label: node.label,
          value: node.computedValue,
          formattedValue: node.computedValue.toStringAsFixed(1),
        ),
      ],
      xLabel: 'Depth: ${rect.depth}',
    );
  }
}

class _TreemapChartPainter extends ChartPainter {
  _TreemapChartPainter({
    required this.data,
    required super.theme,
    required super.animationValue,
    required this.controller,
    required this.hitTester,
    required this.padding,
    required this.labelFontSize,
    required this.onLayoutComplete,
  }) : super(repaint: controller);

  final TreemapChartData data;
  final ChartController controller;
  final ChartHitTester hitTester;
  final EdgeInsets padding;
  final double labelFontSize;
  final void Function(List<TreemapRect>) onLayoutComplete;

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

    if (data.root.computedValue <= 0) return;

    // Compute layout
    final rects = _computeLayout(chartArea);
    onLayoutComplete(rects);

    // Draw rectangles
    for (var i = 0; i < rects.length; i++) {
      final treemapRect = rects[i];
      final isHovered = controller.hoveredPoint?.pointIndex == i;

      _drawNode(canvas, treemapRect, i, isHovered);

      // Register hit target
      hitTester.addRect(
        rect: treemapRect.rect,
        info: DataPointInfo(
          seriesIndex: treemapRect.depth,
          pointIndex: i,
          position: treemapRect.rect.center,
          xValue: treemapRect.depth,
          yValue: treemapRect.node.computedValue,
        ),
      );
    }
  }

  List<TreemapRect> _computeLayout(Rect bounds) {
    final result = <TreemapRect>[];

    void layoutNode(TreemapNode node, Rect rect, int depth, TreemapRect? parent) {
      if (data.maxDepth != null && depth > data.maxDepth!) return;

      final treemapRect = TreemapRect(
        node: node,
        rect: rect,
        depth: depth,
        parent: parent,
      );

      // Only add leaf nodes or nodes at max depth
      if (node.isLeaf || (data.maxDepth != null && depth == data.maxDepth)) {
        result.add(treemapRect);
        return;
      }

      // For non-leaf nodes, layout children
      final children = node.children!;
      if (children.isEmpty) return;

      // Add this node if we're showing groups
      if (data.headerHeight > 0) {
        result.add(treemapRect);
      }

      // Calculate content area (minus header and padding)
      // Ensure a minimum cell padding of 4px for visual clarity
      final effectivePadding = data.padding < 4.0 ? 4.0 : data.padding;
      final contentRect = Rect.fromLTRB(
        rect.left + effectivePadding,
        rect.top + data.headerHeight + effectivePadding,
        rect.right - effectivePadding,
        rect.bottom - effectivePadding,
      );

      if (contentRect.width <= 0 || contentRect.height <= 0) return;

      // Layout children using selected algorithm
      final childRects = _layoutChildren(children, contentRect);

      for (var i = 0; i < children.length; i++) {
        layoutNode(children[i], childRects[i], depth + 1, treemapRect);
      }
    }

    layoutNode(data.root, bounds, 0, null);
    return result;
  }

  List<Rect> _layoutChildren(List<TreemapNode> children, Rect bounds) {
    switch (data.algorithm) {
      case TreemapLayoutAlgorithm.squarified:
        return _squarifiedLayout(children, bounds);
      case TreemapLayoutAlgorithm.slice:
        return _sliceLayout(children, bounds, true);
      case TreemapLayoutAlgorithm.dice:
        return _sliceLayout(children, bounds, false);
      case TreemapLayoutAlgorithm.binary:
        return _binaryLayout(children, bounds);
    }
  }

  List<Rect> _squarifiedLayout(List<TreemapNode> nodes, Rect bounds) {
    if (nodes.isEmpty) return [];
    if (nodes.length == 1) return [bounds];

    final totalValue = nodes.fold<double>(0, (sum, n) => sum + n.computedValue);
    if (totalValue <= 0) return List.filled(nodes.length, Rect.zero);

    // Sort by value descending for better layout
    final sortedNodes = List<TreemapNode>.from(nodes)
      ..sort((a, b) => b.computedValue.compareTo(a.computedValue));

    final rects = <TreemapNode, Rect>{};
    var remaining = bounds;

    var i = 0;
    while (i < sortedNodes.length) {
      final isVertical = remaining.width >= remaining.height;
      final side = isVertical ? remaining.height : remaining.width;

      // Find the best row
      final row = <TreemapNode>[];
      var rowValue = 0.0;
      var bestRatio = double.infinity;

      while (i < sortedNodes.length) {
        final node = sortedNodes[i];
        final testRow = [...row, node];
        final testValue = rowValue + node.computedValue;

        final remainingValue =
            sortedNodes.skip(i).fold<double>(0, (sum, n) => sum + n.computedValue);
        final rowWidth = (testValue / remainingValue) *
            (isVertical ? remaining.width : remaining.height);

        var worstRatio = 0.0;
        for (final n in testRow) {
          final nodeHeight = (n.computedValue / testValue) * side;
          final ratio = nodeHeight > rowWidth
              ? nodeHeight / rowWidth
              : rowWidth / nodeHeight;
          worstRatio = ratio > worstRatio ? ratio : worstRatio;
        }

        if (worstRatio > bestRatio && row.isNotEmpty) break;

        row.add(node);
        rowValue = testValue;
        bestRatio = worstRatio;
        i++;
      }

      // Calculate row dimensions
      final remainingValue =
          sortedNodes.skip(i - row.length).fold<double>(0, (sum, n) => sum + n.computedValue);
      final rowWidth = (rowValue / remainingValue) *
          (isVertical ? remaining.width : remaining.height);

      // Layout row
      var offset = 0.0;
      for (final node in row) {
        final nodeSize = (node.computedValue / rowValue) * side;

        Rect nodeRect;
        if (isVertical) {
          nodeRect = Rect.fromLTWH(
            remaining.left,
            remaining.top + offset,
            rowWidth,
            nodeSize,
          );
        } else {
          nodeRect = Rect.fromLTWH(
            remaining.left + offset,
            remaining.top,
            nodeSize,
            rowWidth,
          );
        }

        rects[node] = nodeRect;
        offset += nodeSize;
      }

      // Update remaining area
      if (isVertical) {
        remaining = Rect.fromLTRB(
          remaining.left + rowWidth,
          remaining.top,
          remaining.right,
          remaining.bottom,
        );
      } else {
        remaining = Rect.fromLTRB(
          remaining.left,
          remaining.top + rowWidth,
          remaining.right,
          remaining.bottom,
        );
      }
    }

    // Return in original order
    return nodes.map((n) => rects[n] ?? Rect.zero).toList();
  }

  List<Rect> _sliceLayout(List<TreemapNode> nodes, Rect bounds, bool horizontal) {
    if (nodes.isEmpty) return [];

    final totalValue = nodes.fold<double>(0, (sum, n) => sum + n.computedValue);
    if (totalValue <= 0) return List.filled(nodes.length, Rect.zero);

    final result = <Rect>[];
    var offset = horizontal ? bounds.top : bounds.left;

    for (final node in nodes) {
      final ratio = node.computedValue / totalValue;
      final size = ratio * (horizontal ? bounds.height : bounds.width);

      if (horizontal) {
        result.add(Rect.fromLTWH(bounds.left, offset, bounds.width, size));
        offset += size;
      } else {
        result.add(Rect.fromLTWH(offset, bounds.top, size, bounds.height));
        offset += size;
      }
    }

    return result;
  }

  List<Rect> _binaryLayout(List<TreemapNode> nodes, Rect bounds) {
    if (nodes.isEmpty) return [];
    if (nodes.length == 1) return [bounds];

    final totalValue = nodes.fold<double>(0, (sum, n) => sum + n.computedValue);
    if (totalValue <= 0) return List.filled(nodes.length, Rect.zero);

    // Find split point closest to half
    var leftValue = 0.0;
    var splitIndex = 0;
    final halfValue = totalValue / 2;

    for (var i = 0; i < nodes.length; i++) {
      leftValue += nodes[i].computedValue;
      if (leftValue >= halfValue) {
        splitIndex = i + 1;
        break;
      }
    }

    if (splitIndex == 0) splitIndex = 1;
    if (splitIndex >= nodes.length) splitIndex = nodes.length - 1;

    final leftNodes = nodes.sublist(0, splitIndex);
    final rightNodes = nodes.sublist(splitIndex);

    final leftTotalValue = leftNodes.fold<double>(0, (sum, n) => sum + n.computedValue);
    final ratio = leftTotalValue / totalValue;

    final isVertical = bounds.width >= bounds.height;
    Rect leftBounds;
    Rect rightBounds;

    if (isVertical) {
      final splitX = bounds.left + bounds.width * ratio;
      leftBounds = Rect.fromLTRB(bounds.left, bounds.top, splitX, bounds.bottom);
      rightBounds = Rect.fromLTRB(splitX, bounds.top, bounds.right, bounds.bottom);
    } else {
      final splitY = bounds.top + bounds.height * ratio;
      leftBounds = Rect.fromLTRB(bounds.left, bounds.top, bounds.right, splitY);
      rightBounds = Rect.fromLTRB(bounds.left, splitY, bounds.right, bounds.bottom);
    }

    return [
      ..._binaryLayout(leftNodes, leftBounds),
      ..._binaryLayout(rightNodes, rightBounds),
    ];
  }

  void _drawNode(Canvas canvas, TreemapRect treemapRect, int index, bool isHovered) {
    final node = treemapRect.node;
    final rect = treemapRect.rect;
    final depth = treemapRect.depth;

    if (rect.width <= 0 || rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(theme.barCornerRadius));

    // Determine color
    Color color;
    if (node.color != null) {
      color = node.color!;
    } else if (data.colorByDepth) {
      color = theme.getSeriesColor(depth);
    } else {
      color = theme.getSeriesColor(index % 10);
    }

    // Animate opacity
    final opacity = animationValue;
    var fillColor = color.withValues(alpha: color.a * opacity);

    if (isHovered) {
      fillColor = color.withValues(alpha: 1);
    }

    // Draw fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((theme.shadowOpacity * 255 * 0.4).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, theme.shadowBlurRadius * 0.3)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(rrect.shift(Offset(0, theme.shadowBlurRadius * 0.1)), shadowPaint);

    canvas.drawRRect(rrect, fillPaint);

    // Draw border
    if (data.border.showAt(depth)) {
      final borderColor = data.border.color ?? theme.gridLineColor;
      final borderPaint = Paint()
        ..color = borderColor.withValues(alpha: borderColor.a * opacity)
        ..strokeWidth = isHovered ? data.border.width + 1 : data.border.width
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw hover highlight
    if (isHovered) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRRect(rrect, highlightPaint);
    }

    // Draw label
    if (data.showLabels && data.labelPosition != TreemapLabelPosition.none) {
      if (rect.width >= data.minLabelWidth && rect.height >= data.minLabelHeight) {
        _drawLabel(canvas, rect, node.label, color);
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String label, Color bgColor) {
    final textColor = _getContrastColor(bgColor);
    final textStyle = theme.labelStyle.copyWith(
      fontSize: labelFontSize,
      color: textColor,
    );

    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - 8);

    Offset offset;
    switch (data.labelPosition) {
      case TreemapLabelPosition.topLeft:
        offset = Offset(rect.left + 4, rect.top + 4);
      case TreemapLabelPosition.center:
        offset = Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        );
      case TreemapLabelPosition.none:
        return;
    }

    textPainter.paint(canvas, offset);
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _TreemapChartPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      data != oldDelegate.data ||
      controller.hoveredPoint != oldDelegate.controller.hoveredPoint;
}
