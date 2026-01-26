import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../plugin.dart';

/// Plugin for zooming and panning charts.
///
/// Supports pinch-to-zoom, scroll wheel zoom, and pan gestures.
///
/// Example:
/// ```dart
/// // Register the plugin
/// PluginRegistry.instance.register(ZoomPlugin());
///
/// // Attach to chart
/// pluginManager.attach('chartify.zoom');
///
/// // Zoom programmatically
/// final zoom = pluginManager.getPlugin<ZoomPlugin>();
/// zoom?.zoomIn(center: Offset(100, 100));
/// ```
class ZoomPlugin extends ChartPlugin {
  ZoomPlugin({
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
    this.zoomSpeed = 0.1,
    this.enablePinchZoom = true,
    this.enableScrollZoom = true,
    this.enablePan = true,
    this.constrainToBounds = true,
  });

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  /// Zoom speed multiplier.
  final double zoomSpeed;

  /// Whether pinch-to-zoom is enabled.
  final bool enablePinchZoom;

  /// Whether scroll wheel zoom is enabled.
  final bool enableScrollZoom;

  /// Whether panning is enabled.
  final bool enablePan;

  /// Whether to constrain view to chart bounds.
  final bool constrainToBounds;

  // Current state
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _focalPoint = Offset.zero;
  double _baseScale = 1.0;
  Rect _chartArea = Rect.zero;
  Size _chartSize = Size.zero;

  // Listeners
  final List<ZoomChangeCallback> _listeners = [];

  @override
  String get id => 'chartify.zoom';

  @override
  String get displayName => 'Zoom Plugin';

  @override
  int get priority => 100; // Run before other plugins for gesture handling

  /// Current zoom scale.
  double get scale => _scale;

  /// Current pan offset.
  Offset get offset => _offset;

  /// Current viewport transform.
  Matrix4 get transform {
    return Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
  }

  /// Inverse of the current viewport transform.
  Matrix4 get inverseTransform {
    final invScale = 1.0 / _scale;
    return Matrix4.identity()
      ..scale(invScale)
      ..translate(-_offset.dx * invScale, -_offset.dy * invScale);
  }

  /// Adds a listener for zoom changes.
  void addListener(ZoomChangeCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a listener.
  void removeListener(ZoomChangeCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_scale, _offset);
    }
  }

  @override
  void onAttach(PluginContext context) {
    super.onAttach(context);
    reset();
  }

  @override
  void onResize(Size oldSize, Size newSize) {
    _chartSize = newSize;
    if (constrainToBounds) {
      _constrainOffset();
    }
  }

  @override
  void onBeforePaint(PluginPaintContext context) {
    _chartArea = context.chartArea;
    _chartSize = context.size;

    // Apply transform to canvas
    context.canvas.save();
    context.canvas.translate(_offset.dx, _offset.dy);
    context.canvas.scale(_scale);
  }

  @override
  void onAfterPaint(PluginPaintContext context) {
    // Restore canvas
    context.canvas.restore();
  }

  @override
  bool onScaleUpdate(ScaleUpdateDetails details) {
    if (!enabled) return false;

    final didZoom = enablePinchZoom && details.scale != 1.0;
    final didPan = enablePan && details.focalPointDelta != Offset.zero;

    if (!didZoom && !didPan) return false;

    if (didZoom) {
      _focalPoint = details.localFocalPoint;
      final newScale = (_baseScale * details.scale).clamp(minZoom, maxZoom);
      _zoomTo(newScale, _focalPoint);
    }

    if (didPan) {
      _offset += details.focalPointDelta;
      if (constrainToBounds) {
        _constrainOffset();
      }
    }

    _notifyListeners();
    return true;
  }

  @override
  bool onScaleEnd(ScaleEndDetails details) {
    _baseScale = _scale;
    return enablePinchZoom || enablePan;
  }

  @override
  bool onPointerEvent(PointerEvent event) {
    if (!enabled || !enableScrollZoom) return false;

    if (event is PointerScrollEvent) {
      final zoomDelta = -event.scrollDelta.dy * zoomSpeed * 0.01;
      final newScale = (_scale * (1 + zoomDelta)).clamp(minZoom, maxZoom);
      _zoomTo(newScale, event.localPosition);
      _notifyListeners();
      return true;
    }

    return false;
  }

  void _zoomTo(double newScale, Offset focalPoint) {
    // Calculate the point in data space before zoom
    final beforeX = (focalPoint.dx - _offset.dx) / _scale;
    final beforeY = (focalPoint.dy - _offset.dy) / _scale;

    _scale = newScale;

    // Calculate new offset to keep focal point stationary
    _offset = Offset(
      focalPoint.dx - beforeX * _scale,
      focalPoint.dy - beforeY * _scale,
    );

    if (constrainToBounds) {
      _constrainOffset();
    }
  }

  void _constrainOffset() {
    if (_chartSize == Size.zero) return;

    final scaledWidth = _chartSize.width * _scale;
    final scaledHeight = _chartSize.height * _scale;

    // Calculate bounds
    final minX = math.min(0.0, _chartSize.width - scaledWidth);
    final maxX = math.max(0.0, _chartSize.width - scaledWidth);
    final minY = math.min(0.0, _chartSize.height - scaledHeight);
    final maxY = math.max(0.0, _chartSize.height - scaledHeight);

    _offset = Offset(
      _offset.dx.clamp(minX, maxX),
      _offset.dy.clamp(minY, maxY),
    );
  }

  /// Zooms in by one step.
  void zoomIn({Offset? center}) {
    final focalPoint = center ?? _chartArea.center;
    final newScale = (_scale * (1 + zoomSpeed)).clamp(minZoom, maxZoom);
    _zoomTo(newScale, focalPoint);
    _baseScale = _scale;
    _notifyListeners();
  }

  /// Zooms out by one step.
  void zoomOut({Offset? center}) {
    final focalPoint = center ?? _chartArea.center;
    final newScale = (_scale * (1 - zoomSpeed)).clamp(minZoom, maxZoom);
    _zoomTo(newScale, focalPoint);
    _baseScale = _scale;
    _notifyListeners();
  }

  /// Zooms to a specific scale.
  void zoomToScale(double scale, {Offset? center}) {
    final focalPoint = center ?? _chartArea.center;
    final newScale = scale.clamp(minZoom, maxZoom);
    _zoomTo(newScale, focalPoint);
    _baseScale = _scale;
    _notifyListeners();
  }

  /// Zooms to fit a specific area.
  void zoomToFit(Rect area) {
    if (_chartSize == Size.zero) return;

    final scaleX = _chartArea.width / area.width;
    final scaleY = _chartArea.height / area.height;
    final newScale = math.min(scaleX, scaleY).clamp(minZoom, maxZoom);

    _scale = newScale;
    _baseScale = newScale;

    _offset = Offset(
      _chartArea.left - area.left * _scale,
      _chartArea.top - area.top * _scale,
    );

    if (constrainToBounds) {
      _constrainOffset();
    }

    _notifyListeners();
  }

  /// Pans by the given delta.
  void pan(Offset delta) {
    _offset += delta;
    if (constrainToBounds) {
      _constrainOffset();
    }
    _notifyListeners();
  }

  /// Pans to center on a specific point.
  void panTo(Offset point) {
    _offset = Offset(
      _chartArea.center.dx - point.dx * _scale,
      _chartArea.center.dy - point.dy * _scale,
    );
    if (constrainToBounds) {
      _constrainOffset();
    }
    _notifyListeners();
  }

  /// Resets zoom and pan to default.
  void reset() {
    _scale = 1.0;
    _baseScale = 1.0;
    _offset = Offset.zero;
    _notifyListeners();
  }

  /// Transforms a screen point to data coordinates.
  Offset screenToData(Offset screenPoint) {
    return Offset(
      (screenPoint.dx - _offset.dx) / _scale,
      (screenPoint.dy - _offset.dy) / _scale,
    );
  }

  /// Transforms a data point to screen coordinates.
  Offset dataToScreen(Offset dataPoint) {
    return Offset(
      dataPoint.dx * _scale + _offset.dx,
      dataPoint.dy * _scale + _offset.dy,
    );
  }

  /// Gets the visible area in data coordinates.
  Rect get visibleArea {
    final topLeft = screenToData(_chartArea.topLeft);
    final bottomRight = screenToData(_chartArea.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  @override
  void dispose() {
    _listeners.clear();
    super.dispose();
  }
}

/// Callback for zoom changes.
typedef ZoomChangeCallback = void Function(double scale, Offset offset);

/// Configuration for zoom behavior.
class ZoomConfig {
  const ZoomConfig({
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
    this.zoomSpeed = 0.1,
    this.enablePinchZoom = true,
    this.enableScrollZoom = true,
    this.enablePan = true,
    this.constrainToBounds = true,
    this.animateZoom = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
  });

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  /// Zoom speed multiplier.
  final double zoomSpeed;

  /// Whether pinch-to-zoom is enabled.
  final bool enablePinchZoom;

  /// Whether scroll wheel zoom is enabled.
  final bool enableScrollZoom;

  /// Whether panning is enabled.
  final bool enablePan;

  /// Whether to constrain view to chart bounds.
  final bool constrainToBounds;

  /// Whether to animate zoom transitions.
  final bool animateZoom;

  /// Duration for zoom animations.
  final Duration animationDuration;

  /// Curve for zoom animations.
  final Curve animationCurve;

  /// Creates a copy with updated values.
  ZoomConfig copyWith({
    double? minZoom,
    double? maxZoom,
    double? zoomSpeed,
    bool? enablePinchZoom,
    bool? enableScrollZoom,
    bool? enablePan,
    bool? constrainToBounds,
    bool? animateZoom,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return ZoomConfig(
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      zoomSpeed: zoomSpeed ?? this.zoomSpeed,
      enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
      enableScrollZoom: enableScrollZoom ?? this.enableScrollZoom,
      enablePan: enablePan ?? this.enablePan,
      constrainToBounds: constrainToBounds ?? this.constrainToBounds,
      animateZoom: animateZoom ?? this.animateZoom,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}

/// Widget that adds zoom controls to a chart.
class ZoomControls extends StatelessWidget {
  const ZoomControls({
    super.key,
    required this.zoomPlugin,
    this.showResetButton = true,
    this.iconSize = 24.0,
    this.buttonSpacing = 8.0,
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.all(8.0),
  });

  /// The zoom plugin to control.
  final ZoomPlugin zoomPlugin;

  /// Whether to show the reset button.
  final bool showResetButton;

  /// Size of control icons.
  final double iconSize;

  /// Spacing between buttons.
  final double buttonSpacing;

  /// Alignment of controls.
  final Alignment alignment;

  /// Padding around controls.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(
              icon: const Icon(IconData(0x002B)), // Plus sign
              onPressed: zoomPlugin.zoomIn,
              size: iconSize,
            ),
            SizedBox(height: buttonSpacing),
            _ZoomButton(
              icon: const Icon(IconData(0x2212)), // Minus sign
              onPressed: zoomPlugin.zoomOut,
              size: iconSize,
            ),
            if (showResetButton) ...[
              SizedBox(height: buttonSpacing),
              _ZoomButton(
                icon: const Icon(IconData(0x21BA)), // Reset icon
                onPressed: zoomPlugin.reset,
                size: iconSize,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.size,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              size: size,
              color: const Color(0xFF333333),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

/// Extension for easy zoom plugin access.
extension ZoomExtension on BuildContext {
  /// Gets the zoom plugin if available.
  ZoomPlugin? get zoomPlugin {
    return PluginRegistry.instance.getByType<ZoomPlugin>();
  }
}
