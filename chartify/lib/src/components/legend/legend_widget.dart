import 'package:flutter/widgets.dart';

import '../../rendering/renderers/legend_renderer.dart';
import '../../rendering/renderers/marker_renderer.dart';
import '../../rendering/renderers/renderer.dart';
import '../../theme/chart_theme_data.dart';

/// A standalone legend widget for charts.
///
/// Displays legend items with markers and labels, supporting
/// horizontal, vertical, and wrapped layouts.
class ChartLegend extends StatefulWidget {
  const ChartLegend({
    super.key,
    required this.items,
    this.config,
    this.position = ChartPosition.bottom,
    this.layout = LegendLayout.horizontal,
    this.onItemTap,
    this.itemSpacing = 16.0,
    this.markerSize = 12.0,
    this.labelStyle,
    this.showValues = false,
    this.interactive = true,
  });

  /// Legend items to display.
  final List<LegendItem> items;

  /// Optional full configuration (overrides other properties).
  final LegendConfig? config;

  /// Position of the legend.
  final ChartPosition position;

  /// Layout style.
  final LegendLayout layout;

  /// Callback when an item is tapped.
  final void Function(int index)? onItemTap;

  /// Spacing between items.
  final double itemSpacing;

  /// Size of markers.
  final double markerSize;

  /// Style for labels.
  final TextStyle? labelStyle;

  /// Whether to show values.
  final bool showValues;

  /// Whether items are interactive.
  final bool interactive;

  @override
  State<ChartLegend> createState() => _ChartLegendState();
}

class _ChartLegendState extends State<ChartLegend> {
  int? _hoveredIndex;

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
          interactive: widget.interactive,
        );

    if (effectiveConfig.layout == LegendLayout.vertical) {
      return _buildVerticalLegend(effectiveConfig);
    } else if (effectiveConfig.layout == LegendLayout.wrap) {
      return _buildWrappedLegend(effectiveConfig);
    } else {
      return _buildHorizontalLegend(effectiveConfig);
    }
  }

  Widget _buildHorizontalLegend(LegendConfig config) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildItems(config),
      ),
    );
  }

  Widget _buildVerticalLegend(LegendConfig config) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildItems(config),
    );
  }

  Widget _buildWrappedLegend(LegendConfig config) {
    return Wrap(
      spacing: config.itemSpacing,
      runSpacing: config.lineSpacing,
      children: _buildItems(config),
    );
  }

  List<Widget> _buildItems(LegendConfig config) {
    return List.generate(widget.items.length, (index) {
      final item = widget.items[index];
      final isHovered = _hoveredIndex == index;

      return _LegendItemWidget(
        item: item,
        config: config,
        isHovered: isHovered,
        onTap: widget.interactive && widget.onItemTap != null
            ? () => widget.onItemTap!(index)
            : null,
        onHover: widget.interactive
            ? (hovered) => setState(() => _hoveredIndex = hovered ? index : null)
            : null,
      );
    });
  }
}

class _LegendItemWidget extends StatelessWidget {
  const _LegendItemWidget({
    required this.item,
    required this.config,
    required this.isHovered,
    this.onTap,
    this.onHover,
  });

  final LegendItem item;
  final LegendConfig config;
  final bool isHovered;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;

  @override
  Widget build(BuildContext context) {
    final opacity = item.isVisible ? 1.0 : 0.4;
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
          if (config.showPercentages && item.percentage != null) ...[
            const SizedBox(width: 4),
            _buildPercentage(opacity),
          ],
        ],
      ),
    );

    if (onTap != null || onHover != null) {
      content = MouseRegion(
        onEnter: onHover != null ? (_) => onHover!(true) : null,
        onExit: onHover != null ? (_) => onHover!(false) : null,
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTap,
          child: Transform.scale(
            scale: scale,
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildMarker(double opacity) {
    return CustomPaint(
      size: Size(config.markerSize, config.markerSize),
      painter: _MarkerPainter(
        shape: item.shape,
        color: item.color.withAlpha((item.color.alpha * opacity).round()),
        size: config.markerSize,
      ),
    );
  }

  Widget _buildLabel(double opacity) {
    final style = (config.labelStyle ??
            const TextStyle(fontSize: 12, color: Color(0xFF333333)))
        .copyWith(
      color: (config.labelStyle?.color ?? const Color(0xFF333333))
          .withAlpha((255 * opacity).round()),
    );

    return Text(item.label, style: style);
  }

  Widget _buildValue(double opacity) {
    final style = (config.valueStyle ??
            const TextStyle(fontSize: 11, color: Color(0xFF666666)))
        .copyWith(
      color: (config.valueStyle?.color ?? const Color(0xFF666666))
          .withAlpha((255 * opacity).round()),
    );

    return Text(item.value!, style: style);
  }

  Widget _buildPercentage(double opacity) {
    final style = (config.valueStyle ??
            const TextStyle(fontSize: 11, color: Color(0xFF666666)))
        .copyWith(
      color: (config.valueStyle?.color ?? const Color(0xFF666666))
          .withAlpha((255 * opacity).round()),
    );

    return Text('${item.percentage!.toStringAsFixed(1)}%', style: style);
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
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        color != oldDelegate.color ||
        size != oldDelegate.size;
  }
}

/// Builder for creating legends programmatically.
class LegendBuilder {
  LegendBuilder({this.position = ChartPosition.bottom});

  ChartPosition position;
  LegendLayout _layout = LegendLayout.horizontal;
  double _itemSpacing = 16.0;
  double _markerSize = 12.0;
  TextStyle? _labelStyle;
  bool _showValues = false;
  bool _interactive = true;
  final List<LegendItem> _items = [];
  void Function(int)? _onItemTap;

  /// Sets the layout.
  LegendBuilder layout(LegendLayout layout) {
    _layout = layout;
    return this;
  }

  /// Sets item spacing.
  LegendBuilder spacing(double spacing) {
    _itemSpacing = spacing;
    return this;
  }

  /// Sets marker size.
  LegendBuilder markerSize(double size) {
    _markerSize = size;
    return this;
  }

  /// Sets label style.
  LegendBuilder labelStyle(TextStyle style) {
    _labelStyle = style;
    return this;
  }

  /// Enables value display.
  LegendBuilder showValues() {
    _showValues = true;
    return this;
  }

  /// Disables interactivity.
  LegendBuilder nonInteractive() {
    _interactive = false;
    return this;
  }

  /// Adds an item.
  LegendBuilder addItem({
    required String label,
    required Color color,
    MarkerShape shape = MarkerShape.square,
    String? value,
    double? percentage,
    bool isVisible = true,
  }) {
    _items.add(LegendItem(
      label: label,
      color: color,
      shape: shape,
      value: value,
      percentage: percentage,
      isVisible: isVisible,
    ));
    return this;
  }

  /// Adds multiple items from a list of colors and labels.
  LegendBuilder addItems(List<String> labels, List<Color> colors) {
    for (var i = 0; i < labels.length && i < colors.length; i++) {
      addItem(label: labels[i], color: colors[i]);
    }
    return this;
  }

  /// Sets the tap callback.
  LegendBuilder onTap(void Function(int index) callback) {
    _onItemTap = callback;
    return this;
  }

  /// Builds the legend widget.
  ChartLegend build() {
    return ChartLegend(
      items: _items,
      position: position,
      layout: _layout,
      itemSpacing: _itemSpacing,
      markerSize: _markerSize,
      labelStyle: _labelStyle,
      showValues: _showValues,
      interactive: _interactive,
      onItemTap: _onItemTap,
    );
  }
}

/// Extension for creating legends from color lists.
extension ColorsLegendExtension on List<Color> {
  /// Creates a legend from colors and labels.
  LegendBuilder legend(List<String> labels) {
    return LegendBuilder().addItems(labels, this);
  }
}
