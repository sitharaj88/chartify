import 'package:flutter/widgets.dart';

import '../../core/base/chart_controller.dart';
import '../../rendering/renderers/legend_renderer.dart';
import '../../rendering/renderers/marker_renderer.dart';
import '../../rendering/renderers/renderer.dart';
import '../../theme/chart_theme_data.dart';

/// Configuration for filterable legend behavior.
class FilterableLegendConfig {
  const FilterableLegendConfig({
    this.enableFiltering = true,
    this.enableIsolation = true,
    this.showHiddenAsGrayed = true,
    this.hiddenOpacity = 0.3,
    this.animateVisibilityChanges = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Whether clicking toggles series visibility.
  final bool enableFiltering;

  /// Whether double-clicking isolates a series (hides all others).
  final bool enableIsolation;

  /// Whether to show hidden series as grayed out (vs completely hidden).
  final bool showHiddenAsGrayed;

  /// Opacity for hidden series in the legend.
  final double hiddenOpacity;

  /// Whether to animate visibility changes.
  final bool animateVisibilityChanges;

  /// Duration for visibility animations.
  final Duration animationDuration;

  /// Creates a copy with updated values.
  FilterableLegendConfig copyWith({
    bool? enableFiltering,
    bool? enableIsolation,
    bool? showHiddenAsGrayed,
    double? hiddenOpacity,
    bool? animateVisibilityChanges,
    Duration? animationDuration,
  }) =>
      FilterableLegendConfig(
        enableFiltering: enableFiltering ?? this.enableFiltering,
        enableIsolation: enableIsolation ?? this.enableIsolation,
        showHiddenAsGrayed: showHiddenAsGrayed ?? this.showHiddenAsGrayed,
        hiddenOpacity: hiddenOpacity ?? this.hiddenOpacity,
        animateVisibilityChanges:
            animateVisibilityChanges ?? this.animateVisibilityChanges,
        animationDuration: animationDuration ?? this.animationDuration,
      );
}

/// A legend widget that allows filtering series visibility.
///
/// Integrates with [ChartController] to toggle series visibility when
/// legend items are clicked. Double-clicking isolates a series (hides all others).
///
/// Example:
/// ```dart
/// FilterableLegend(
///   controller: chartController,
///   items: [
///     LegendItem(label: 'Series A', color: Colors.blue),
///     LegendItem(label: 'Series B', color: Colors.red),
///   ],
///   onVisibilityChanged: (index, isVisible) {
///     print('Series $index is now ${isVisible ? "visible" : "hidden"}');
///   },
/// )
/// ```
class FilterableLegend extends StatefulWidget {
  const FilterableLegend({
    required this.controller,
    required this.items,
    super.key,
    this.config,
    this.filterConfig = const FilterableLegendConfig(),
    this.position = ChartPosition.bottom,
    this.layout = LegendLayout.horizontal,
    this.onVisibilityChanged,
    this.onIsolate,
    this.itemSpacing = 16.0,
    this.markerSize = 12.0,
    this.labelStyle,
    this.showValues = false,
  });

  /// The chart controller to sync visibility state with.
  final ChartController controller;

  /// Legend items to display.
  final List<LegendItem> items;

  /// Optional legend configuration.
  final LegendConfig? config;

  /// Configuration for filtering behavior.
  final FilterableLegendConfig filterConfig;

  /// Position of the legend.
  final ChartPosition position;

  /// Layout style.
  final LegendLayout layout;

  /// Callback when a series visibility changes.
  final void Function(int index, bool isVisible)? onVisibilityChanged;

  /// Callback when a series is isolated.
  final void Function(int index)? onIsolate;

  /// Spacing between items.
  final double itemSpacing;

  /// Size of markers.
  final double markerSize;

  /// Style for labels.
  final TextStyle? labelStyle;

  /// Whether to show values.
  final bool showValues;

  @override
  State<FilterableLegend> createState() => _FilterableLegendState();
}

class _FilterableLegendState extends State<FilterableLegend> {
  int? _hoveredIndex;
  DateTime? _lastTapTime;
  int? _lastTapIndex;

  static const _doubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(FilterableLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTap(int index) {
    if (!widget.filterConfig.enableFiltering) return;

    final now = DateTime.now();

    // Check for double-tap
    if (widget.filterConfig.enableIsolation &&
        _lastTapIndex == index &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapThreshold) {
      _handleDoubleTap(index);
      _lastTapTime = null;
      _lastTapIndex = null;
      return;
    }

    _lastTapTime = now;
    _lastTapIndex = index;

    // Single tap toggles visibility
    widget.controller.toggleSeriesVisibility(index);
    final isNowVisible = widget.controller.isSeriesVisible(index);
    widget.onVisibilityChanged?.call(index, isNowVisible);
  }

  void _handleDoubleTap(int index) {
    // If this series is the only visible one, show all
    final visibleCount = widget.items.length -
        widget.controller.hiddenSeriesIndices.length;

    if (visibleCount == 1 && widget.controller.isSeriesVisible(index)) {
      widget.controller.showAllSeries();
    } else {
      // Isolate this series
      widget.controller.isolateSeries(index, widget.items.length);
      widget.onIsolate?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);

    final effectiveConfig = widget.config ??
        LegendConfig(
          position: widget.position,
          layout: widget.layout,
          itemSpacing: widget.itemSpacing,
          markerSize: widget.markerSize,
          labelStyle: widget.labelStyle ?? theme.legendTextStyle,
          showValues: widget.showValues,
          interactive: true,
        );

    final items = _buildItems(effectiveConfig);

    if (effectiveConfig.layout == LegendLayout.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    } else if (effectiveConfig.layout == LegendLayout.wrap) {
      return Wrap(
        spacing: effectiveConfig.itemSpacing,
        runSpacing: effectiveConfig.lineSpacing,
        children: items,
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      );
    }
  }

  List<Widget> _buildItems(LegendConfig config) {
    return List.generate(widget.items.length, (index) {
      final item = widget.items[index];
      final isVisible = widget.controller.isSeriesVisible(index);
      final isHovered = _hoveredIndex == index;

      // Update item visibility based on controller state
      final effectiveItem = LegendItem(
        label: item.label,
        color: item.color,
        shape: item.shape,
        isVisible: isVisible,
        value: item.value,
        percentage: item.percentage,
      );

      return _FilterableLegendItem(
        item: effectiveItem,
        config: config,
        filterConfig: widget.filterConfig,
        isHovered: isHovered,
        onTap: () => _handleTap(index),
        onHover: (hovered) => setState(() => _hoveredIndex = hovered ? index : null),
      );
    });
  }
}

class _FilterableLegendItem extends StatelessWidget {
  const _FilterableLegendItem({
    required this.item,
    required this.config,
    required this.filterConfig,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  final LegendItem item;
  final LegendConfig config;
  final FilterableLegendConfig filterConfig;
  final bool isHovered;
  final VoidCallback onTap;
  final void Function(bool) onHover;

  @override
  Widget build(BuildContext context) {
    final opacity = item.isVisible ? 1.0 : filterConfig.hiddenOpacity;
    final scale = isHovered ? 1.05 : 1.0;

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: config.itemSpacing / 2,
        vertical: config.lineSpacing / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMarker(opacity),
          SizedBox(width: config.markerLabelSpacing),
          _buildLabel(opacity),
          if (config.showValues && item.value != null) ...[
            const SizedBox(width: 4),
            _buildValue(opacity),
          ],
        ],
      ),
    );

    // Add strikethrough for hidden items
    if (!item.isVisible && !filterConfig.showHiddenAsGrayed) {
      return const SizedBox.shrink();
    }

    content = MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: filterConfig.animateVisibilityChanges
            ? AnimatedScale(
                scale: scale,
                duration: filterConfig.animationDuration,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: filterConfig.animationDuration,
                  child: _buildContent(opacity),
                ),
              )
            : Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _buildContent(1.0), // Use full opacity since parent handles it
                ),
              ),
      ),
    );

    return content;
  }

  Widget _buildContent(double opacity) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: config.itemSpacing / 2,
        vertical: config.lineSpacing / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMarker(1.0), // Marker handles its own opacity
          SizedBox(width: config.markerLabelSpacing),
          _buildLabel(1.0),
          if (config.showValues && item.value != null) ...[
            const SizedBox(width: 4),
            _buildValue(1.0),
          ],
        ],
      ),
    );
  }

  Widget _buildMarker(double opacity) {
    return CustomPaint(
      size: Size(config.markerSize, config.markerSize),
      painter: _MarkerPainter(
        shape: item.shape,
        color: item.color,
        size: config.markerSize,
      ),
    );
  }

  Widget _buildLabel(double opacity) {
    final style = config.labelStyle ??
        const TextStyle(fontSize: 12, color: Color(0xFF333333));

    return Text(
      item.label,
      style: style.copyWith(
        decoration: item.isVisible ? null : TextDecoration.lineThrough,
      ),
    );
  }

  Widget _buildValue(double opacity) {
    final style = config.valueStyle ??
        const TextStyle(fontSize: 11, color: Color(0xFF666666));

    return Text(item.value!, style: style);
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({
    required this.shape,
    required this.color,
    required this.size,
  });

  final MarkerShape shape;
  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final renderer = MarkerRenderer(
      config: MarkerConfig(
        shape: shape,
        size: size,
        fillColor: color,
      ),
    );

    renderer.drawMarker(
      canvas,
      Offset(canvasSize.width / 2, canvasSize.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      color != oldDelegate.color ||
      size != oldDelegate.size;
}

/// Extension for creating filterable legends from chart data.
extension FilterableLegendExtension on ChartController {
  /// Creates legend items from series data.
  ///
  /// Helper method to generate [LegendItem]s from a list of series names and colors.
  List<LegendItem> createLegendItems(
    List<String> names,
    List<Color> colors, {
    MarkerShape shape = MarkerShape.square,
  }) {
    return List.generate(
      names.length,
      (i) => LegendItem(
        label: names[i],
        color: i < colors.length ? colors[i] : const Color(0xFF999999),
        shape: shape,
        isVisible: isSeriesVisible(i),
      ),
    );
  }
}
