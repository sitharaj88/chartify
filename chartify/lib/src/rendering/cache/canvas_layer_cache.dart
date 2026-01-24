import 'dart:ui';

/// Identifies different rendering layers that can be cached.
enum RenderLayer {
  /// Background fill and patterns.
  background,

  /// Grid lines and bands.
  grid,

  /// Axis lines and ticks (not labels).
  axisLines,

  /// Reference lines and annotations.
  annotations,

  /// Static data series (non-animated).
  staticSeries,
}

/// Cached rendering layer containing a Picture and invalidation state.
class CachedLayer {
  CachedLayer({
    required this.picture,
    required this.size,
    required this.configHash,
  }) : createdAt = DateTime.now();

  /// The cached Picture.
  final Picture picture;

  /// Size the picture was rendered at.
  final Size size;

  /// Hash of the configuration used to generate this picture.
  final int configHash;

  /// When this cache entry was created.
  final DateTime createdAt;

  /// Whether this cached layer is valid for the given size and config hash.
  bool isValid(Size currentSize, int currentConfigHash) {
    return size == currentSize && configHash == currentConfigHash;
  }

  /// Disposes the picture.
  void dispose() {
    picture.dispose();
  }
}

/// Cache for canvas rendering layers.
///
/// Caches static rendering elements (grids, backgrounds, axis lines) as
/// Pictures for improved rendering performance. Particularly effective for:
/// - Charts with complex grid patterns
/// - Charts that update frequently (tooltips, hover states)
/// - Animated series on top of static elements
///
/// Example:
/// ```dart
/// class MyChartPainter extends CustomPainter {
///   final CanvasLayerCache _cache = CanvasLayerCache();
///
///   @override
///   void paint(Canvas canvas, Size size) {
///     // Draw cached grid layer
///     _cache.drawCachedLayer(
///       canvas,
///       RenderLayer.grid,
///       size: size,
///       configHash: gridConfig.hashCode,
///       painter: (canvas) => _paintGrid(canvas, size),
///     );
///
///     // Draw dynamic series on top
///     _paintSeries(canvas, size);
///   }
///
///   @override
///   void dispose() {
///     _cache.dispose();
///     super.dispose();
///   }
/// }
/// ```
class CanvasLayerCache {
  CanvasLayerCache({
    this.maxCacheSize = 5,
    this.maxCacheAge = const Duration(minutes: 5),
  });

  /// Maximum number of cached layers.
  final int maxCacheSize;

  /// Maximum age before cache entries are considered stale.
  final Duration maxCacheAge;

  final Map<RenderLayer, CachedLayer> _cache = {};

  /// Whether caching is currently enabled.
  bool _enabled = true;

  /// Whether caching is enabled.
  bool get enabled => _enabled;

  /// Enables or disables caching.
  set enabled(bool value) {
    if (!value && _enabled) {
      clear();
    }
    _enabled = value;
  }

  /// Gets the number of cached layers.
  int get cacheCount => _cache.length;

  /// Whether a layer is cached and valid.
  bool isCached(RenderLayer layer, Size size, int configHash) {
    final cached = _cache[layer];
    return cached != null && cached.isValid(size, configHash);
  }

  /// Draws a layer, using cache if available or generating and caching if not.
  ///
  /// [canvas] - The canvas to draw on.
  /// [layer] - The layer type to draw.
  /// [size] - The size to render at.
  /// [configHash] - Hash of the configuration (for invalidation).
  /// [painter] - Function to paint the layer if not cached.
  void drawCachedLayer(
    Canvas canvas,
    RenderLayer layer, {
    required Size size,
    required int configHash,
    required void Function(Canvas canvas) painter,
  }) {
    if (!_enabled) {
      painter(canvas);
      return;
    }

    // Check if we have a valid cached version
    final cached = _cache[layer];
    if (cached != null && cached.isValid(size, configHash)) {
      // Check age
      if (DateTime.now().difference(cached.createdAt) < maxCacheAge) {
        canvas.drawPicture(cached.picture);
        return;
      }
      // Cache is stale, remove it
      _cache.remove(layer)?.dispose();
    }

    // Generate new picture
    final recorder = PictureRecorder();
    final recordingCanvas = Canvas(recorder);

    painter(recordingCanvas);

    final picture = recorder.endRecording();

    // Evict old entries if needed
    _evictIfNeeded();

    // Cache the new picture
    _cache[layer] = CachedLayer(
      picture: picture,
      size: size,
      configHash: configHash,
    );

    // Draw to the original canvas
    canvas.drawPicture(picture);
  }

  /// Invalidates a specific layer.
  void invalidate(RenderLayer layer) {
    _cache.remove(layer)?.dispose();
  }

  /// Invalidates all layers.
  void invalidateAll() {
    for (final cached in _cache.values) {
      cached.dispose();
    }
    _cache.clear();
  }

  /// Clears all cached layers.
  void clear() {
    invalidateAll();
  }

  /// Evicts oldest entries if cache is full.
  void _evictIfNeeded() {
    while (_cache.length >= maxCacheSize) {
      // Find and remove oldest entry
      RenderLayer? oldestLayer;
      DateTime? oldestTime;

      for (final entry in _cache.entries) {
        if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
          oldestLayer = entry.key;
          oldestTime = entry.value.createdAt;
        }
      }

      if (oldestLayer != null) {
        _cache.remove(oldestLayer)?.dispose();
      }
    }
  }

  /// Disposes all resources.
  void dispose() {
    clear();
  }
}

/// Mixin for painters that support layer caching.
mixin LayerCachingMixin {
  /// The layer cache instance.
  CanvasLayerCache? _layerCache;

  /// Gets or creates the layer cache.
  CanvasLayerCache get layerCache => _layerCache ??= CanvasLayerCache();

  /// Whether layer caching is enabled.
  bool get layerCachingEnabled => _layerCache?.enabled ?? false;

  /// Enables layer caching.
  void enableLayerCaching({int maxLayers = 5}) {
    _layerCache ??= CanvasLayerCache(maxCacheSize: maxLayers);
    _layerCache!.enabled = true;
  }

  /// Disables layer caching.
  void disableLayerCaching() {
    _layerCache?.enabled = false;
  }

  /// Invalidates a cached layer.
  void invalidateLayer(RenderLayer layer) {
    _layerCache?.invalidate(layer);
  }

  /// Invalidates all cached layers.
  void invalidateAllLayers() {
    _layerCache?.invalidateAll();
  }

  /// Disposes the layer cache.
  void disposeLayerCache() {
    _layerCache?.dispose();
    _layerCache = null;
  }

  /// Draws a layer with caching support.
  ///
  /// If caching is disabled, the painter is called directly.
  void drawLayer(
    Canvas canvas,
    RenderLayer layer, {
    required Size size,
    required int configHash,
    required void Function(Canvas canvas) painter,
  }) {
    if (_layerCache == null || !_layerCache!.enabled) {
      painter(canvas);
      return;
    }

    _layerCache!.drawCachedLayer(
      canvas,
      layer,
      size: size,
      configHash: configHash,
      painter: painter,
    );
  }
}

/// Extension for combining multiple config hashes.
extension ConfigHashCombiner on int {
  /// Combines this hash with another value's hash.
  int combineHash(Object? other) {
    return 0x1fffffff & (this + ((0x0007ffff & this) << 10)) ^ (other.hashCode);
  }
}
