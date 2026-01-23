import 'dart:ui';

import 'package:flutter/painting.dart';

import '../cache/text_cache.dart';
import 'marker_renderer.dart';
import 'renderer.dart';

/// A single item in the legend.
class LegendItem {
  const LegendItem({
    required this.label,
    required this.color,
    this.shape = MarkerShape.square,
    this.isVisible = true,
    this.value,
    this.percentage,
  });

  /// Display label for this item.
  final String label;

  /// Color representing this item.
  final Color color;

  /// Shape of the legend marker.
  final MarkerShape shape;

  /// Whether this item is currently visible in the chart.
  final bool isVisible;

  /// Optional value to display.
  final String? value;

  /// Optional percentage to display.
  final double? percentage;
}

/// Layout style for the legend.
enum LegendLayout {
  /// Items arranged horizontally.
  horizontal,

  /// Items arranged vertically.
  vertical,

  /// Items wrap to fit available space.
  wrap,
}

/// Configuration for legend rendering.
class LegendConfig extends RendererConfig {
  const LegendConfig({
    this.visible = true,
    this.position = ChartPosition.bottom,
    this.alignment = ChartAlignment.center,
    this.layout = LegendLayout.horizontal,
    this.itemSpacing = 16.0,
    this.lineSpacing = 8.0,
    this.markerSize = 12.0,
    this.markerLabelSpacing = 6.0,
    this.labelStyle,
    this.valueStyle,
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 4.0,
    this.showValues = false,
    this.showPercentages = false,
    this.maxLines,
    this.interactive = true,
  });

  @override
  final bool visible;

  /// Position of the legend relative to the chart.
  final ChartPosition position;

  /// Alignment within the position.
  final ChartAlignment alignment;

  /// Layout style for legend items.
  final LegendLayout layout;

  /// Spacing between items.
  final double itemSpacing;

  /// Spacing between lines (for wrapped layout).
  final double lineSpacing;

  /// Size of legend markers.
  final double markerSize;

  /// Spacing between marker and label.
  final double markerLabelSpacing;

  /// Style for legend labels.
  final TextStyle? labelStyle;

  /// Style for legend values.
  final TextStyle? valueStyle;

  /// Padding around the legend.
  final EdgeInsets padding;

  /// Background color of the legend.
  final Color? backgroundColor;

  /// Border color of the legend.
  final Color? borderColor;

  /// Width of the border.
  final double borderWidth;

  /// Border radius.
  final double borderRadius;

  /// Whether to show values.
  final bool showValues;

  /// Whether to show percentages.
  final bool showPercentages;

  /// Maximum number of lines (for wrapped layout).
  final int? maxLines;

  /// Whether legend items are interactive.
  final bool interactive;

  /// Whether this is a horizontal position.
  bool get isHorizontalPosition =>
      position == ChartPosition.top || position == ChartPosition.bottom;

  /// Creates a copy with updated values.
  LegendConfig copyWith({
    bool? visible,
    ChartPosition? position,
    ChartAlignment? alignment,
    LegendLayout? layout,
    double? itemSpacing,
    double? lineSpacing,
    double? markerSize,
    double? markerLabelSpacing,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    bool? showValues,
    bool? showPercentages,
    int? maxLines,
    bool? interactive,
  }) {
    return LegendConfig(
      visible: visible ?? this.visible,
      position: position ?? this.position,
      alignment: alignment ?? this.alignment,
      layout: layout ?? this.layout,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      markerSize: markerSize ?? this.markerSize,
      markerLabelSpacing: markerLabelSpacing ?? this.markerLabelSpacing,
      labelStyle: labelStyle ?? this.labelStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      showValues: showValues ?? this.showValues,
      showPercentages: showPercentages ?? this.showPercentages,
      maxLines: maxLines ?? this.maxLines,
      interactive: interactive ?? this.interactive,
    );
  }
}

/// Renderer for chart legends.
///
/// Displays legend items with markers and labels, supporting
/// multiple layouts and interactive toggling.
class LegendRenderer
    with RendererMixin<LegendConfig>
    implements ChartRenderer<LegendConfig>, HitTestableRenderer {
  LegendRenderer({
    required LegendConfig config,
    required this.items,
    this.onItemTap,
    TextCache? textCache,
  })  : _config = config,
        _textCache = textCache ?? ChartTextCache.instance.legendLabels;

  LegendConfig _config;
  List<LegendItem> items;
  final void Function(int index)? onItemTap;
  final TextCache _textCache;
  final MarkerRenderer _markerRenderer = MarkerRenderer(
    config: const MarkerConfig(),
  );

  // Cached layout information
  List<_LegendItemLayout>? _cachedItemLayouts;
  Size? _cachedLegendSize;
  Rect? _lastChartArea;

  @override
  LegendConfig get config => _config;

  @override
  void update(LegendConfig newConfig) {
    if (_config != newConfig) {
      _config = newConfig;
      _invalidateCache();
      markNeedsRepaint();
    }
  }

  /// Updates the legend items.
  void updateItems(List<LegendItem> newItems) {
    items = newItems;
    _invalidateCache();
    markNeedsRepaint();
  }

  void _invalidateCache() {
    _cachedItemLayouts = null;
    _cachedLegendSize = null;
  }

  @override
  void render(Canvas canvas, Size size, Rect chartArea) {
    if (!_config.visible || items.isEmpty) return;

    _lastChartArea = chartArea;
    final layouts = _computeLayouts(size, chartArea);
    final legendRect = _computeLegendRect(size, chartArea, layouts);

    // Draw background
    if (_config.backgroundColor != null) {
      final bgPaint = Paint()
        ..color = _config.backgroundColor!
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        legendRect.deflate(-_config.padding.horizontal / 2),
        Radius.circular(_config.borderRadius),
      );
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw border
    if (_config.borderWidth > 0 && _config.borderColor != null) {
      final borderPaint = Paint()
        ..color = _config.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = _config.borderWidth;

      final rrect = RRect.fromRectAndRadius(
        legendRect.deflate(-_config.padding.horizontal / 2),
        Radius.circular(_config.borderRadius),
      );
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw items
    for (var i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      final item = items[i];

      _drawItem(canvas, item, layout);
    }

    markPainted();
  }

  void _drawItem(Canvas canvas, LegendItem item, _LegendItemLayout layout) {
    final opacity = item.isVisible ? 1.0 : 0.4;

    // Draw marker
    _markerRenderer.drawMarker(
      canvas,
      layout.markerCenter,
      overrideConfig: MarkerConfig(
        shape: item.shape,
        size: _config.markerSize,
        fillColor: item.color.withOpacity(opacity),
      ),
    );

    // Draw label
    final labelStyle = (_config.labelStyle ??
            const TextStyle(fontSize: 12, color: Color(0xFF333333)))
        .copyWith(
      color: (_config.labelStyle?.color ?? const Color(0xFF333333))
          .withOpacity(opacity),
    );

    final labelLayout = _textCache.layoutText(item.label, labelStyle);
    labelLayout.painter.paint(canvas, layout.labelOffset);

    // Draw value/percentage
    if (_config.showValues && item.value != null) {
      final valueStyle = (_config.valueStyle ??
              const TextStyle(fontSize: 11, color: Color(0xFF666666)))
          .copyWith(
        color: (_config.valueStyle?.color ?? const Color(0xFF666666))
            .withOpacity(opacity),
      );

      final valueLayout = _textCache.layoutText(item.value!, valueStyle);
      final valueOffset = Offset(
        layout.labelOffset.dx + labelLayout.width + 4,
        layout.labelOffset.dy + (labelLayout.height - valueLayout.height) / 2,
      );
      valueLayout.painter.paint(canvas, valueOffset);
    }

    if (_config.showPercentages && item.percentage != null) {
      final percentText = '${item.percentage!.toStringAsFixed(1)}%';
      final valueStyle = (_config.valueStyle ??
              const TextStyle(fontSize: 11, color: Color(0xFF666666)))
          .copyWith(
        color: (_config.valueStyle?.color ?? const Color(0xFF666666))
            .withOpacity(opacity),
      );

      final percentLayout = _textCache.layoutText(percentText, valueStyle);
      final percentOffset = Offset(
        layout.labelOffset.dx + labelLayout.width + 4,
        layout.labelOffset.dy + (labelLayout.height - percentLayout.height) / 2,
      );
      percentLayout.painter.paint(canvas, percentOffset);
    }
  }

  List<_LegendItemLayout> _computeLayouts(Size size, Rect chartArea) {
    if (_cachedItemLayouts != null) return _cachedItemLayouts!;

    final layouts = <_LegendItemLayout>[];
    final labelStyle = _config.labelStyle ??
        const TextStyle(fontSize: 12, color: Color(0xFF333333));

    var x = 0.0;
    var y = 0.0;
    var lineHeight = 0.0;
    var currentLine = 0;

    final availableWidth = _config.isHorizontalPosition
        ? chartArea.width
        : (_config.position == ChartPosition.left
            ? chartArea.left - _config.padding.horizontal
            : size.width - chartArea.right - _config.padding.horizontal);

    for (final item in items) {
      final labelLayout = _textCache.layoutText(item.label, labelStyle);

      var itemWidth = _config.markerSize +
          _config.markerLabelSpacing +
          labelLayout.width;

      if (_config.showValues && item.value != null) {
        final valueStyle = _config.valueStyle ??
            const TextStyle(fontSize: 11, color: Color(0xFF666666));
        final valueLayout = _textCache.layoutText(item.value!, valueStyle);
        itemWidth += 4 + valueLayout.width;
      }

      if (_config.showPercentages && item.percentage != null) {
        final valueStyle = _config.valueStyle ??
            const TextStyle(fontSize: 11, color: Color(0xFF666666));
        final percentText = '${item.percentage!.toStringAsFixed(1)}%';
        final percentLayout = _textCache.layoutText(percentText, valueStyle);
        itemWidth += 4 + percentLayout.width;
      }

      final itemHeight = _config.markerSize > labelLayout.height
          ? _config.markerSize
          : labelLayout.height;

      // Check if we need to wrap
      if (_config.layout == LegendLayout.wrap ||
          (_config.layout == LegendLayout.horizontal &&
           x + itemWidth > availableWidth && x > 0)) {
        if (_config.maxLines != null && currentLine >= _config.maxLines! - 1) {
          break; // Stop adding items
        }
        x = 0;
        y += lineHeight + _config.lineSpacing;
        lineHeight = 0;
        currentLine++;
      }

      // For vertical layout, each item goes on its own line
      if (_config.layout == LegendLayout.vertical && layouts.isNotEmpty) {
        x = 0;
        y += lineHeight + _config.lineSpacing;
        lineHeight = 0;
      }

      layouts.add(_LegendItemLayout(
        markerCenter: Offset(x + _config.markerSize / 2, y + itemHeight / 2),
        labelOffset: Offset(
          x + _config.markerSize + _config.markerLabelSpacing,
          y + (itemHeight - labelLayout.height) / 2,
        ),
        bounds: Rect.fromLTWH(x, y, itemWidth, itemHeight),
      ));

      x += itemWidth + _config.itemSpacing;
      lineHeight = lineHeight > itemHeight ? lineHeight : itemHeight;
    }

    _cachedItemLayouts = layouts;
    return layouts;
  }

  Rect _computeLegendRect(
    Size size,
    Rect chartArea,
    List<_LegendItemLayout> layouts,
  ) {
    if (layouts.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final layout in layouts) {
      minX = minX < layout.bounds.left ? minX : layout.bounds.left;
      minY = minY < layout.bounds.top ? minY : layout.bounds.top;
      maxX = maxX > layout.bounds.right ? maxX : layout.bounds.right;
      maxY = maxY > layout.bounds.bottom ? maxY : layout.bounds.bottom;
    }

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    double left;
    double top;

    switch (_config.position) {
      case ChartPosition.top:
        top = _config.padding.top;
        left = _getHorizontalOffset(chartArea, contentWidth);
      case ChartPosition.bottom:
        top = chartArea.bottom + _config.padding.top;
        left = _getHorizontalOffset(chartArea, contentWidth);
      case ChartPosition.left:
        left = _config.padding.left;
        top = _getVerticalOffset(chartArea, contentHeight);
      case ChartPosition.right:
        left = chartArea.right + _config.padding.left;
        top = _getVerticalOffset(chartArea, contentHeight);
      case ChartPosition.center:
        left = chartArea.center.dx - contentWidth / 2;
        top = chartArea.center.dy - contentHeight / 2;
    }

    // Offset all layouts to the computed position
    for (var i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      layouts[i] = _LegendItemLayout(
        markerCenter: layout.markerCenter.translate(left, top),
        labelOffset: layout.labelOffset.translate(left, top),
        bounds: layout.bounds.translate(left, top),
      );
    }

    _cachedLegendSize = Size(contentWidth, contentHeight);
    return Rect.fromLTWH(left, top, contentWidth, contentHeight);
  }

  double _getHorizontalOffset(Rect chartArea, double contentWidth) {
    switch (_config.alignment) {
      case ChartAlignment.start:
        return chartArea.left;
      case ChartAlignment.center:
        return chartArea.center.dx - contentWidth / 2;
      case ChartAlignment.end:
        return chartArea.right - contentWidth;
    }
  }

  double _getVerticalOffset(Rect chartArea, double contentHeight) {
    switch (_config.alignment) {
      case ChartAlignment.start:
        return chartArea.top;
      case ChartAlignment.center:
        return chartArea.center.dy - contentHeight / 2;
      case ChartAlignment.end:
        return chartArea.bottom - contentHeight;
    }
  }

  @override
  RendererHitResult hitTest(Offset point, Rect chartArea) {
    if (!_config.visible || !_config.interactive || items.isEmpty) {
      return RendererHitResult.none;
    }

    final layouts = _cachedItemLayouts;
    if (layouts == null) return RendererHitResult.none;

    for (var i = 0; i < layouts.length; i++) {
      if (layouts[i].bounds.contains(point)) {
        return RendererHitResult(
          hit: true,
          componentType: 'legend',
          componentIndex: i,
          data: {'item': items[i]},
        );
      }
    }

    return RendererHitResult.none;
  }

  @override
  EdgeInsets calculateInsets(Size availableSize) {
    if (!_config.visible || items.isEmpty) return EdgeInsets.zero;

    // Compute layouts to get size
    final dummyChartArea = Rect.fromLTWH(
      50,
      50,
      availableSize.width - 100,
      availableSize.height - 100,
    );
    final layouts = _computeLayouts(availableSize, dummyChartArea);

    if (layouts.isEmpty) return EdgeInsets.zero;

    var maxY = 0.0;
    var maxX = 0.0;
    for (final layout in layouts) {
      maxY = maxY > layout.bounds.bottom ? maxY : layout.bounds.bottom;
      maxX = maxX > layout.bounds.right ? maxX : layout.bounds.right;
    }

    final contentHeight = maxY + _config.padding.vertical;
    final contentWidth = maxX + _config.padding.horizontal;

    switch (_config.position) {
      case ChartPosition.top:
        return EdgeInsets.only(top: contentHeight);
      case ChartPosition.bottom:
        return EdgeInsets.only(bottom: contentHeight);
      case ChartPosition.left:
        return EdgeInsets.only(left: contentWidth);
      case ChartPosition.right:
        return EdgeInsets.only(right: contentWidth);
      case ChartPosition.center:
        return EdgeInsets.zero;
    }
  }

  @override
  void dispose() {
    _invalidateCache();
    _markerRenderer.dispose();
  }
}

class _LegendItemLayout {
  _LegendItemLayout({
    required this.markerCenter,
    required this.labelOffset,
    required this.bounds,
  });

  final Offset markerCenter;
  final Offset labelOffset;
  final Rect bounds;
}

/// Factory for creating common legend configurations.
class LegendFactory {
  LegendFactory._();

  /// Creates a standard bottom legend.
  static LegendConfig bottom({
    LegendLayout layout = LegendLayout.horizontal,
    TextStyle? labelStyle,
  }) {
    return LegendConfig(
      position: ChartPosition.bottom,
      layout: layout,
      labelStyle: labelStyle,
    );
  }

  /// Creates a standard right legend.
  static LegendConfig right({
    TextStyle? labelStyle,
    bool showValues = false,
  }) {
    return LegendConfig(
      position: ChartPosition.right,
      layout: LegendLayout.vertical,
      labelStyle: labelStyle,
      showValues: showValues,
    );
  }

  /// Creates a compact legend with wrap.
  static LegendConfig compact({
    ChartPosition position = ChartPosition.bottom,
    int maxLines = 2,
  }) {
    return LegendConfig(
      position: position,
      layout: LegendLayout.wrap,
      maxLines: maxLines,
      itemSpacing: 12,
      markerSize: 10,
    );
  }

  /// Creates a legend with a background card.
  static LegendConfig card({
    ChartPosition position = ChartPosition.right,
    Color backgroundColor = const Color(0xFFFAFAFA),
    Color borderColor = const Color(0xFFE0E0E0),
  }) {
    return LegendConfig(
      position: position,
      layout: LegendLayout.vertical,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: 1,
      borderRadius: 8,
      padding: const EdgeInsets.all(12),
    );
  }

  /// Creates a hidden legend.
  static LegendConfig hidden() {
    return const LegendConfig(visible: false);
  }
}
