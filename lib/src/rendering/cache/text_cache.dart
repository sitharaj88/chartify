import 'package:flutter/painting.dart';

import '../../core/utils/cache_manager.dart';

/// Cache key for text layouts.
class TextLayoutKey {
  TextLayoutKey({
    required this.text,
    required this.style,
    this.maxWidth,
    this.maxLines,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double? maxWidth;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextLayoutKey &&
          text == other.text &&
          style == other.style &&
          maxWidth == other.maxWidth &&
          maxLines == other.maxLines &&
          textAlign == other.textAlign;

  @override
  int get hashCode => Object.hash(
        text,
        style,
        maxWidth,
        maxLines,
        textAlign,
      );
}

/// Cached text layout with precomputed metrics.
class CachedTextLayout {
  CachedTextLayout({
    required this.painter,
    required this.width,
    required this.height,
  });

  /// The text painter ready for rendering.
  final TextPainter painter;

  /// Computed width of the text.
  final double width;

  /// Computed height of the text.
  final double height;

  /// Size as an object.
  Size get size => Size(width, height);
}

/// Specialized cache for TextPainter objects.
///
/// TextPainter creation and layout is expensive, so caching
/// dramatically improves axis label and tooltip rendering.
class TextCache {
  TextCache({
    int maxSize = 200,
  }) : _cache = LRUCache<TextLayoutKey, CachedTextLayout>(
          maxSize: maxSize,
          onEvict: (_, layout) {
            layout.painter.dispose();
          },
        );

  final LRUCache<TextLayoutKey, CachedTextLayout> _cache;

  /// Gets a cached text layout or creates and caches one.
  CachedTextLayout getOrCompute(
    TextLayoutKey key, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    var cached = _cache.get(key);
    if (cached != null) return cached;

    final painter = TextPainter(
      text: TextSpan(text: key.text, style: key.style),
      textDirection: textDirection,
      maxLines: key.maxLines,
      textAlign: key.textAlign ?? TextAlign.start,
    );

    painter.layout(
      maxWidth: key.maxWidth ?? double.infinity,
    );

    cached = CachedTextLayout(
      painter: painter,
      width: painter.width,
      height: painter.height,
    );

    _cache.put(key, cached);
    return cached;
  }

  /// Convenience method for simple text caching.
  CachedTextLayout layoutText(
    String text,
    TextStyle style, {
    double? maxWidth,
    int? maxLines,
    TextAlign? textAlign,
    TextDirection textDirection = TextDirection.ltr,
  }) => getOrCompute(
      TextLayoutKey(
        text: text,
        style: style,
        maxWidth: maxWidth,
        maxLines: maxLines,
        textAlign: textAlign,
      ),
      textDirection: textDirection,
    );

  /// Gets the size of text without caching.
  ///
  /// Useful for one-off measurements.
  static Size measureText(
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
    );
    painter.layout(maxWidth: maxWidth);
    final size = Size(painter.width, painter.height);
    painter.dispose();
    return size;
  }

  /// Clears all cached text layouts.
  void clear() => _cache.clear();

  /// Number of cached layouts.
  int get length => _cache.length;
}

/// Manages text rendering with automatic caching.
class TextRenderer {
  TextRenderer({TextCache? cache}) : _cache = cache ?? TextCache();

  final TextCache _cache;

  /// Renders text at a position.
  void render(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    Alignment alignment = Alignment.topLeft,
    double? maxWidth,
    int? maxLines,
    TextAlign textAlign = TextAlign.start,
  }) {
    final layout = _cache.layoutText(
      text,
      style,
      maxWidth: maxWidth,
      maxLines: maxLines,
      textAlign: textAlign,
    );

    final offset = _calculateOffset(position, layout.size, alignment);
    layout.painter.paint(canvas, offset);
  }

  /// Renders text rotated around a point.
  void renderRotated(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style,
    double angle, {
    Alignment alignment = Alignment.center,
    double? maxWidth,
  }) {
    final layout = _cache.layoutText(
      text,
      style,
      maxWidth: maxWidth,
    );

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final offset = _calculateOffset(Offset.zero, layout.size, alignment);
    layout.painter.paint(canvas, offset);

    canvas.restore();
  }

  Offset _calculateOffset(Offset position, Size size, Alignment alignment) => Offset(
      position.dx - (alignment.x + 1) / 2 * size.width,
      position.dy - (alignment.y + 1) / 2 * size.height,
    );

  /// Gets the size of text.
  Size getTextSize(String text, TextStyle style, {double? maxWidth}) {
    final layout = _cache.layoutText(text, style, maxWidth: maxWidth);
    return layout.size;
  }

  /// Clears the cache.
  void clear() => _cache.clear();
}

/// Formats and caches number labels for axes.
class NumberLabelCache {
  NumberLabelCache({
    this.precision = 2,
    this.locale,
  });

  final int precision;
  final String? locale;

  final _formattedCache = LRUCache<double, String>();

  /// Formats a number for display.
  String format(double value) => _formattedCache.getOrPut(value, () {
      // Smart formatting based on value
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      }

      final absValue = value.abs();
      if (absValue >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (absValue >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else if (absValue < 0.01 && absValue > 0) {
        return value.toStringAsExponential(1);
      } else {
        return value.toStringAsFixed(precision);
      }
    });

  /// Formats with custom suffix.
  String formatWithSuffix(double value, String suffix) => '${format(value)}$suffix';

  /// Clears the format cache.
  void clear() => _formattedCache.clear();
}

/// Global text cache instance.
class ChartTextCache {
  ChartTextCache._();

  static final instance = ChartTextCache._();

  /// Cache for axis labels.
  final axisLabels = TextCache();

  /// Cache for data labels.
  final dataLabels = TextCache(maxSize: 300);

  /// Cache for legend labels.
  final legendLabels = TextCache(maxSize: 50);

  /// Cache for tooltip text.
  final tooltipText = TextCache(maxSize: 20);

  /// Number formatter.
  final numberFormatter = NumberLabelCache();

  /// Clears all text caches.
  void clearAll() {
    axisLabels.clear();
    dataLabels.clear();
    legendLabels.clear();
    tooltipText.clear();
    numberFormatter.clear();
  }
}
