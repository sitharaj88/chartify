import 'dart:ui';

import 'package:flutter/painting.dart';

/// Base interface for all chart renderers.
///
/// Renderers are responsible for drawing specific chart components
/// (axes, grids, legends, series) in a reusable and composable way.
abstract class ChartRenderer<T> {
  /// Configuration for this renderer.
  T get config;

  /// Updates the renderer configuration.
  void update(T newConfig);

  /// Renders the component to the canvas.
  ///
  /// [canvas] - The canvas to draw on.
  /// [size] - The total available size.
  /// [chartArea] - The area designated for data rendering.
  void render(Canvas canvas, Size size, Rect chartArea);

  /// Calculates the insets required by this renderer.
  ///
  /// Used to reserve space for axes, legends, etc.
  EdgeInsets calculateInsets(Size availableSize);

  /// Releases any cached resources.
  void dispose();

  /// Whether this renderer needs a repaint.
  bool get needsRepaint;

  /// Marks this renderer as needing a repaint.
  void markNeedsRepaint();
}

/// Mixin providing common renderer functionality.
mixin RendererMixin<T> {
  bool _needsRepaint = true;

  bool get needsRepaint => _needsRepaint;

  void markNeedsRepaint() {
    _needsRepaint = true;
  }

  void markPainted() {
    _needsRepaint = false;
  }
}

/// Configuration for visual elements.
abstract class RendererConfig {
  const RendererConfig();

  /// Whether this component is visible.
  bool get visible;
}

/// Position options for chart components.
enum ChartPosition {
  /// Top position (for horizontal axes, legends).
  top,

  /// Bottom position (for horizontal axes, legends).
  bottom,

  /// Left position (for vertical axes, legends).
  left,

  /// Right position (for vertical axes, legends).
  right,

  /// Center position (for legends, titles).
  center,
}

/// Alignment options within a position.
enum ChartAlignment {
  /// Start alignment (left for horizontal, top for vertical).
  start,

  /// Center alignment.
  center,

  /// End alignment (right for horizontal, bottom for vertical).
  end,
}

/// Result of hit testing on a renderer.
class RendererHitResult {
  const RendererHitResult({
    required this.hit,
    this.componentType,
    this.componentIndex,
    this.data,
  });

  /// Whether something was hit.
  final bool hit;

  /// Type of component that was hit (e.g., 'axis', 'legend', 'dataPoint').
  final String? componentType;

  /// Index of the component if applicable.
  final int? componentIndex;

  /// Additional data about the hit.
  final Map<String, dynamic>? data;

  static const none = RendererHitResult(hit: false);
}

/// Interface for renderers that support hit testing.
abstract class HitTestableRenderer {
  /// Performs hit testing at the given point.
  RendererHitResult hitTest(Offset point, Rect chartArea);
}

/// Interface for renderers that support interaction.
abstract class InteractiveRenderer {
  /// Called when the pointer enters this component.
  void onPointerEnter(Offset point);

  /// Called when the pointer exits this component.
  void onPointerExit();

  /// Called when this component is tapped.
  void onTap(Offset point);

  /// Called when this component is long-pressed.
  void onLongPress(Offset point);
}

/// A composable group of renderers.
class RendererGroup implements ChartRenderer<List<ChartRenderer<dynamic>>> {
  RendererGroup({List<ChartRenderer<dynamic>>? renderers})
      : _renderers = renderers ?? [];

  final List<ChartRenderer<dynamic>> _renderers;

  @override
  List<ChartRenderer<dynamic>> get config => _renderers;

  /// Adds a renderer to the group.
  void add(ChartRenderer<dynamic> renderer) {
    _renderers.add(renderer);
  }

  /// Removes a renderer from the group.
  void remove(ChartRenderer<dynamic> renderer) {
    _renderers.remove(renderer);
  }

  /// Gets a renderer by type.
  T? getRenderer<T extends ChartRenderer<dynamic>>() {
    for (final renderer in _renderers) {
      if (renderer is T) return renderer;
    }
    return null;
  }

  @override
  void update(List<ChartRenderer<dynamic>> newConfig) {
    _renderers
      ..clear()
      ..addAll(newConfig);
  }

  @override
  void render(Canvas canvas, Size size, Rect chartArea) {
    for (final renderer in _renderers) {
      renderer.render(canvas, size, chartArea);
    }
  }

  @override
  EdgeInsets calculateInsets(Size availableSize) {
    var insets = EdgeInsets.zero;
    for (final renderer in _renderers) {
      final rendererInsets = renderer.calculateInsets(availableSize);
      insets = EdgeInsets.only(
        left: insets.left + rendererInsets.left,
        top: insets.top + rendererInsets.top,
        right: insets.right + rendererInsets.right,
        bottom: insets.bottom + rendererInsets.bottom,
      );
    }
    return insets;
  }

  @override
  void dispose() {
    for (final renderer in _renderers) {
      renderer.dispose();
    }
    _renderers.clear();
  }

  @override
  bool get needsRepaint => _renderers.any((r) => r.needsRepaint);

  @override
  void markNeedsRepaint() {
    for (final renderer in _renderers) {
      renderer.markNeedsRepaint();
    }
  }
}

/// Render layer ordering for proper z-index.
enum RenderLayer {
  /// Background elements (gradients, images).
  background(0),

  /// Grid lines and areas.
  grid(1),

  /// Data series (lines, bars, areas).
  series(2),

  /// Data points and markers.
  markers(3),

  /// Axes and their labels.
  axes(4),

  /// Annotations and reference lines.
  annotations(5),

  /// Interactive elements (tooltips, crosshairs).
  interactive(6),

  /// Foreground overlays.
  foreground(7);

  const RenderLayer(this.zIndex);
  final int zIndex;
}

/// A layered rendering system for proper z-ordering.
class LayeredRenderer {
  LayeredRenderer();

  final Map<RenderLayer, List<ChartRenderer<dynamic>>> _layers = {};

  /// Adds a renderer to a specific layer.
  void addToLayer(RenderLayer layer, ChartRenderer<dynamic> renderer) {
    _layers.putIfAbsent(layer, () => []).add(renderer);
  }

  /// Removes a renderer from its layer.
  void removeFromLayer(RenderLayer layer, ChartRenderer<dynamic> renderer) {
    _layers[layer]?.remove(renderer);
  }

  /// Renders all layers in order.
  void render(Canvas canvas, Size size, Rect chartArea) {
    final sortedLayers = _layers.entries.toList()
      ..sort((a, b) => a.key.zIndex.compareTo(b.key.zIndex));

    for (final entry in sortedLayers) {
      for (final renderer in entry.value) {
        renderer.render(canvas, size, chartArea);
      }
    }
  }

  /// Calculates combined insets from all layers.
  EdgeInsets calculateInsets(Size availableSize) {
    var insets = EdgeInsets.zero;
    for (final renderers in _layers.values) {
      for (final renderer in renderers) {
        final rendererInsets = renderer.calculateInsets(availableSize);
        insets = EdgeInsets.only(
          left: insets.left.clamp(0, double.infinity) > rendererInsets.left
              ? insets.left
              : rendererInsets.left,
          top: insets.top.clamp(0, double.infinity) > rendererInsets.top
              ? insets.top
              : rendererInsets.top,
          right: insets.right.clamp(0, double.infinity) > rendererInsets.right
              ? insets.right
              : rendererInsets.right,
          bottom:
              insets.bottom.clamp(0, double.infinity) > rendererInsets.bottom
                  ? insets.bottom
                  : rendererInsets.bottom,
        );
      }
    }
    return insets;
  }

  /// Disposes all renderers.
  void dispose() {
    for (final renderers in _layers.values) {
      for (final renderer in renderers) {
        renderer.dispose();
      }
    }
    _layers.clear();
  }

  /// Clears all layers.
  void clear() {
    _layers.clear();
  }
}
