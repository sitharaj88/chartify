import 'dart:ui';

/// Tracks which regions of the chart need to be repainted.
///
/// Enables incremental rendering by only repainting regions that have changed,
/// significantly improving performance for large datasets and animations.
///
/// Example:
/// ```dart
/// final tracker = DirtyRegionTracker(fullBounds: chartArea);
///
/// // Mark specific region dirty on data update
/// tracker.markDirty(affectedRegion);
///
/// // During paint, check if full repaint needed
/// if (tracker.needsFullRepaint) {
///   paintEverything(canvas);
/// } else {
///   final region = tracker.getDirtyRegion();
///   if (region != null) {
///     paintRegion(canvas, region);
///   }
/// }
///
/// // After paint
/// tracker.reset();
/// ```
class DirtyRegionTracker {
  /// Creates a dirty region tracker for the given chart bounds.
  DirtyRegionTracker({required this.fullBounds});

  /// The full bounds of the chart area.
  final Rect fullBounds;

  Rect? _dirtyRegion;
  bool _needsFullRepaint = true;
  final List<DirtyChange> _changes = [];

  /// Whether the entire chart needs to be repainted.
  bool get needsFullRepaint => _needsFullRepaint;

  /// Whether any region needs repainting.
  bool get hasDirtyRegions => _needsFullRepaint || _dirtyRegion != null;

  /// Gets the accumulated dirty region, or null if clean.
  Rect? getDirtyRegion() {
    if (_needsFullRepaint) return fullBounds;
    return _dirtyRegion;
  }

  /// Gets the list of individual changes for fine-grained updates.
  List<DirtyChange> get changes => List.unmodifiable(_changes);

  /// Marks a rectangular region as needing repaint.
  void markDirty(Rect region) {
    if (_needsFullRepaint) return; // Already need full repaint

    _changes.add(DirtyChange(type: DirtyChangeType.region, region: region));

    if (_dirtyRegion == null) {
      _dirtyRegion = region.intersect(fullBounds);
    } else {
      _dirtyRegion = _dirtyRegion!.expandToInclude(region).intersect(fullBounds);
    }

    // If dirty region covers most of the chart, just do full repaint
    if (_dirtyRegion != null) {
      final dirtyArea = _dirtyRegion!.width * _dirtyRegion!.height;
      final fullArea = fullBounds.width * fullBounds.height;
      if (dirtyArea > fullArea * 0.7) {
        _needsFullRepaint = true;
      }
    }
  }

  /// Marks specific data points as needing repaint.
  ///
  /// Use this when only specific data points have changed.
  void markDataDirty({
    required int startIndex,
    required int endIndex,
    required Rect Function(int index) getBounds,
  }) {
    if (_needsFullRepaint) return;

    _changes.add(DirtyChange(
      type: DirtyChangeType.dataRange,
      startIndex: startIndex,
      endIndex: endIndex,
    ));

    for (var i = startIndex; i <= endIndex; i++) {
      final bounds = getBounds(i);
      if (_dirtyRegion == null) {
        _dirtyRegion = bounds.intersect(fullBounds);
      } else {
        _dirtyRegion = _dirtyRegion!.expandToInclude(bounds).intersect(fullBounds);
      }
    }
  }

  /// Marks a specific layer as needing repaint.
  void markLayerDirty(RenderLayer layer) {
    _changes.add(DirtyChange(type: DirtyChangeType.layer, layer: layer));

    // Layer changes usually require full repaint of that layer
    // but not necessarily the entire chart
    if (layer == RenderLayer.grid || layer == RenderLayer.axis) {
      // Background layers affect everything
      _needsFullRepaint = true;
    }
  }

  /// Marks the entire chart as needing repaint.
  void markFullRepaint() {
    _needsFullRepaint = true;
    _dirtyRegion = null;
    _changes.clear();
    _changes.add(DirtyChange(type: DirtyChangeType.full));
  }

  /// Resets the tracker after painting.
  void reset() {
    _dirtyRegion = null;
    _needsFullRepaint = false;
    _changes.clear();
  }

  /// Updates the full bounds (e.g., on resize).
  void updateBounds(Rect newBounds) {
    if (newBounds != fullBounds) {
      markFullRepaint();
    }
  }

  /// Checks if a specific rect intersects with dirty regions.
  bool isRectDirty(Rect rect) {
    if (_needsFullRepaint) return true;
    if (_dirtyRegion == null) return false;
    return _dirtyRegion!.overlaps(rect);
  }

  /// Creates a clip rect for efficient rendering.
  ///
  /// Returns the dirty region expanded slightly to avoid edge artifacts.
  Rect? getClipRect({double padding = 2.0}) {
    final dirty = getDirtyRegion();
    if (dirty == null) return null;
    return dirty.inflate(padding).intersect(fullBounds);
  }
}

/// Types of dirty changes for fine-grained tracking.
enum DirtyChangeType {
  /// Full chart needs repaint.
  full,

  /// Specific rectangular region.
  region,

  /// Specific data index range.
  dataRange,

  /// Specific render layer.
  layer,

  /// Animation frame.
  animation,
}

/// Represents a single dirty change for tracking.
class DirtyChange {
  const DirtyChange({
    required this.type,
    this.region,
    this.startIndex,
    this.endIndex,
    this.layer,
  });

  final DirtyChangeType type;
  final Rect? region;
  final int? startIndex;
  final int? endIndex;
  final RenderLayer? layer;

  @override
  String toString() {
    switch (type) {
      case DirtyChangeType.full:
        return 'DirtyChange.full';
      case DirtyChangeType.region:
        return 'DirtyChange.region($region)';
      case DirtyChangeType.dataRange:
        return 'DirtyChange.dataRange($startIndex-$endIndex)';
      case DirtyChangeType.layer:
        return 'DirtyChange.layer($layer)';
      case DirtyChangeType.animation:
        return 'DirtyChange.animation';
    }
  }
}

/// Render layers for layer-based dirty tracking.
enum RenderLayer {
  /// Background (chart area fill).
  background,

  /// Grid lines.
  grid,

  /// Axis lines and labels.
  axis,

  /// Data series (lines, bars, etc.).
  series,

  /// Data point markers.
  markers,

  /// Selection highlights.
  selection,

  /// Crosshair overlay.
  crosshair,

  /// Tooltip overlay.
  tooltip,

  /// Annotations.
  annotations,
}

/// Extension to optimize canvas operations based on dirty regions.
extension DirtyRegionCanvas on Canvas {
  /// Clips the canvas to the dirty region if one exists.
  ///
  /// Returns true if clipping was applied (call restore later).
  bool clipToDirtyRegion(DirtyRegionTracker tracker, {double padding = 2.0}) {
    final region = tracker.getClipRect(padding: padding);
    if (region != null && !tracker.needsFullRepaint) {
      save();
      clipRect(region);
      return true;
    }
    return false;
  }
}

/// Manages dirty regions across multiple chart layers.
class LayeredDirtyRegionTracker {
  LayeredDirtyRegionTracker({required Rect fullBounds})
      : _trackers = {
          for (final layer in RenderLayer.values)
            layer: DirtyRegionTracker(fullBounds: fullBounds),
        };

  final Map<RenderLayer, DirtyRegionTracker> _trackers;

  /// Gets the tracker for a specific layer.
  DirtyRegionTracker operator [](RenderLayer layer) => _trackers[layer]!;

  /// Marks a region dirty on a specific layer.
  void markDirty(RenderLayer layer, Rect region) {
    _trackers[layer]!.markDirty(region);
  }

  /// Marks a layer as needing full repaint.
  void markLayerDirty(RenderLayer layer) {
    _trackers[layer]!.markFullRepaint();
  }

  /// Checks if a layer needs repainting.
  bool layerNeedsPaint(RenderLayer layer) => _trackers[layer]!.hasDirtyRegions;

  /// Resets all layers.
  void resetAll() {
    for (final tracker in _trackers.values) {
      tracker.reset();
    }
  }

  /// Updates bounds for all layers.
  void updateBounds(Rect newBounds) {
    for (final tracker in _trackers.values) {
      tracker.updateBounds(newBounds);
    }
  }

  /// Gets layers that need repainting, in render order.
  List<RenderLayer> getDirtyLayers() {
    return RenderLayer.values.where((layer) => layerNeedsPaint(layer)).toList();
  }
}

/// Tracks viewport changes for intelligent cache invalidation.
class ViewportChangeTracker {
  double? _lastXMin;
  double? _lastXMax;
  double? _lastYMin;
  double? _lastYMax;
  double? _lastScaleX;
  double? _lastScaleY;

  /// Checks what changed between viewport updates.
  ViewportChange checkChange({
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    required double scaleX,
    required double scaleY,
  }) {
    final change = ViewportChange(
      xPanned: _lastXMin != null && (_lastXMin != xMin || _lastXMax != xMax),
      yPanned: _lastYMin != null && (_lastYMin != yMin || _lastYMax != yMax),
      xZoomed: _lastScaleX != null && _lastScaleX != scaleX,
      yZoomed: _lastScaleY != null && _lastScaleY != scaleY,
      isInitial: _lastXMin == null,
    );

    _lastXMin = xMin;
    _lastXMax = xMax;
    _lastYMin = yMin;
    _lastYMax = yMax;
    _lastScaleX = scaleX;
    _lastScaleY = scaleY;

    return change;
  }

  /// Resets the tracker.
  void reset() {
    _lastXMin = null;
    _lastXMax = null;
    _lastYMin = null;
    _lastYMax = null;
    _lastScaleX = null;
    _lastScaleY = null;
  }
}

/// Describes what changed in a viewport update.
class ViewportChange {
  const ViewportChange({
    required this.xPanned,
    required this.yPanned,
    required this.xZoomed,
    required this.yZoomed,
    required this.isInitial,
  });

  final bool xPanned;
  final bool yPanned;
  final bool xZoomed;
  final bool yZoomed;
  final bool isInitial;

  /// Whether any change occurred.
  bool get hasChange => xPanned || yPanned || xZoomed || yZoomed || isInitial;

  /// Whether only panning occurred (no zoom).
  bool get isPanOnly => (xPanned || yPanned) && !xZoomed && !yZoomed;

  /// Whether zoom occurred.
  bool get hasZoom => xZoomed || yZoomed;

  @override
  String toString() {
    if (isInitial) return 'ViewportChange.initial';
    final parts = <String>[];
    if (xPanned) parts.add('xPan');
    if (yPanned) parts.add('yPan');
    if (xZoomed) parts.add('xZoom');
    if (yZoomed) parts.add('yZoom');
    return 'ViewportChange(${parts.join(', ')})';
  }
}
