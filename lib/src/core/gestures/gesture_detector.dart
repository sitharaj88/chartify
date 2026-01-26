import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../base/chart_controller.dart';
import 'spatial_index.dart';

/// Configuration for chart interactions.
@immutable
class ChartInteractions {
  /// Creates a chart interactions configuration.
  const ChartInteractions({
    this.enablePan = true,
    this.enableZoom = true,
    this.enableTap = true,
    this.enableDoubleTap = true,
    this.enableLongPress = false,
    this.enableHover = true,
    this.enableTooltip = true,
    this.enableCrosshair = false,
    this.enableSelection = true,
    this.multiSelect = false,
    this.panAxis = PanAxis.both,
    this.minZoom = 0.5,
    this.maxZoom = 5.0,
    this.zoomSensitivity = 1.0,
    this.panSensitivity = 1.0,
    this.tooltipBehavior = TooltipBehavior.onTap,
    this.hitTestRadius = 20.0,
  });

  /// Creates an interactions configuration with all interactions disabled.
  const ChartInteractions.none()
      : enablePan = false,
        enableZoom = false,
        enableTap = false,
        enableDoubleTap = false,
        enableLongPress = false,
        enableHover = false,
        enableTooltip = false,
        enableCrosshair = false,
        enableSelection = false,
        multiSelect = false,
        panAxis = PanAxis.both,
        minZoom = 1.0,
        maxZoom = 1.0,
        zoomSensitivity = 1.0,
        panSensitivity = 1.0,
        tooltipBehavior = TooltipBehavior.onTap,
        hitTestRadius = 20.0;

  /// Whether panning is enabled.
  final bool enablePan;

  /// Whether zooming is enabled.
  final bool enableZoom;

  /// Whether tap interactions are enabled.
  final bool enableTap;

  /// Whether double-tap to zoom is enabled.
  final bool enableDoubleTap;

  /// Whether long press interactions are enabled.
  final bool enableLongPress;

  /// Whether hover effects are enabled.
  final bool enableHover;

  /// Whether tooltips are enabled.
  final bool enableTooltip;

  /// Whether crosshair is enabled.
  final bool enableCrosshair;

  /// Whether data point selection is enabled.
  final bool enableSelection;

  /// Whether multiple selection is allowed.
  final bool multiSelect;

  /// The axis along which panning is allowed.
  final PanAxis panAxis;

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  /// Zoom sensitivity multiplier.
  final double zoomSensitivity;

  /// Pan sensitivity multiplier.
  final double panSensitivity;

  /// When tooltips are shown.
  final TooltipBehavior tooltipBehavior;

  /// Radius for hit testing (how close to a point counts as a hit).
  final double hitTestRadius;

  /// Creates a copy with the given values replaced.
  ChartInteractions copyWith({
    bool? enablePan,
    bool? enableZoom,
    bool? enableTap,
    bool? enableDoubleTap,
    bool? enableLongPress,
    bool? enableHover,
    bool? enableTooltip,
    bool? enableCrosshair,
    bool? enableSelection,
    bool? multiSelect,
    PanAxis? panAxis,
    double? minZoom,
    double? maxZoom,
    double? zoomSensitivity,
    double? panSensitivity,
    TooltipBehavior? tooltipBehavior,
    double? hitTestRadius,
  }) =>
      ChartInteractions(
        enablePan: enablePan ?? this.enablePan,
        enableZoom: enableZoom ?? this.enableZoom,
        enableTap: enableTap ?? this.enableTap,
        enableDoubleTap: enableDoubleTap ?? this.enableDoubleTap,
        enableLongPress: enableLongPress ?? this.enableLongPress,
        enableHover: enableHover ?? this.enableHover,
        enableTooltip: enableTooltip ?? this.enableTooltip,
        enableCrosshair: enableCrosshair ?? this.enableCrosshair,
        enableSelection: enableSelection ?? this.enableSelection,
        multiSelect: multiSelect ?? this.multiSelect,
        panAxis: panAxis ?? this.panAxis,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        zoomSensitivity: zoomSensitivity ?? this.zoomSensitivity,
        panSensitivity: panSensitivity ?? this.panSensitivity,
        tooltipBehavior: tooltipBehavior ?? this.tooltipBehavior,
        hitTestRadius: hitTestRadius ?? this.hitTestRadius,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartInteractions &&
          runtimeType == other.runtimeType &&
          enablePan == other.enablePan &&
          enableZoom == other.enableZoom &&
          enableTap == other.enableTap &&
          enableDoubleTap == other.enableDoubleTap &&
          enableLongPress == other.enableLongPress &&
          enableHover == other.enableHover &&
          enableTooltip == other.enableTooltip &&
          enableCrosshair == other.enableCrosshair &&
          enableSelection == other.enableSelection &&
          multiSelect == other.multiSelect &&
          panAxis == other.panAxis &&
          minZoom == other.minZoom &&
          maxZoom == other.maxZoom &&
          zoomSensitivity == other.zoomSensitivity &&
          panSensitivity == other.panSensitivity &&
          tooltipBehavior == other.tooltipBehavior &&
          hitTestRadius == other.hitTestRadius;

  @override
  int get hashCode => Object.hash(
        enablePan,
        enableZoom,
        enableTap,
        enableDoubleTap,
        enableLongPress,
        enableHover,
        enableTooltip,
        enableCrosshair,
        enableSelection,
        multiSelect,
        panAxis,
        minZoom,
        maxZoom,
        zoomSensitivity,
        panSensitivity,
        tooltipBehavior,
        hitTestRadius,
      );
}

/// Axes along which panning can occur.
enum PanAxis {
  /// Pan along both axes.
  both,

  /// Pan only horizontally.
  horizontal,

  /// Pan only vertically.
  vertical,
}

/// Behavior for showing tooltips.
enum TooltipBehavior {
  /// Show tooltip on tap.
  onTap,

  /// Show tooltip on hover.
  onHover,

  /// Show tooltip following the pointer.
  followPointer,

  /// Never show tooltip automatically.
  manual,
}

/// Widget that handles chart gesture detection.
class ChartGestureDetector extends StatefulWidget {
  /// Creates a chart gesture detector.
  const ChartGestureDetector({
    super.key,
    required this.child,
    required this.controller,
    this.interactions = const ChartInteractions(),
    this.hitTester,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onHover,
    this.onExit,
  });

  /// The chart widget.
  final Widget child;

  /// The chart controller.
  final ChartController controller;

  /// Interaction configuration.
  final ChartInteractions interactions;

  /// Hit tester for finding data points.
  final ChartHitTester? hitTester;

  /// Called when the chart is tapped.
  final void Function(TapDownDetails details)? onTap;

  /// Called when the chart is double-tapped.
  final void Function(TapDownDetails details)? onDoubleTap;

  /// Called when the chart is long-pressed.
  final void Function(LongPressStartDetails details)? onLongPress;

  /// Called when panning starts.
  final void Function(DragStartDetails details)? onPanStart;

  /// Called when panning updates.
  final void Function(DragUpdateDetails details)? onPanUpdate;

  /// Called when panning ends.
  final void Function(DragEndDetails details)? onPanEnd;

  /// Called when scaling starts.
  final void Function(ScaleStartDetails details)? onScaleStart;

  /// Called when scaling updates.
  final void Function(ScaleUpdateDetails details)? onScaleUpdate;

  /// Called when scaling ends.
  final void Function(ScaleEndDetails details)? onScaleEnd;

  /// Called when hovering over the chart.
  final void Function(PointerHoverEvent event)? onHover;

  /// Called when the pointer exits the chart.
  final void Function(PointerExitEvent event)? onExit;

  @override
  State<ChartGestureDetector> createState() => _ChartGestureDetectorState();
}

class _ChartGestureDetectorState extends State<ChartGestureDetector> {
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;
  bool _isTouching = false;
  Timer? _tooltipHideTimer;

  @override
  void dispose() {
    _tooltipHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // Add hover detection for desktop/web
    if (widget.interactions.enableHover ||
        widget.interactions.tooltipBehavior == TooltipBehavior.onHover ||
        widget.interactions.tooltipBehavior == TooltipBehavior.followPointer) {
      child = MouseRegion(
        onHover: _handleHover,
        onExit: _handleExit,
        child: child,
      );
    }

    // Wrap with Listener for instant touch response (tooltip scrubbing)
    // This doesn't interfere with other gestures
    if (widget.interactions.enableTooltip) {
      child = Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: child,
      );
    }

    // Add gesture detection
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.interactions.enableTap ? _handleTap : null,
      onDoubleTapDown: widget.interactions.enableDoubleTap ? _handleDoubleTap : null,
      onLongPressStart: widget.interactions.enableLongPress ? _handleLongPress : null,
      onScaleStart:
          (widget.interactions.enablePan || widget.interactions.enableZoom)
              ? _handleScaleStart
              : null,
      onScaleUpdate:
          (widget.interactions.enablePan || widget.interactions.enableZoom)
              ? _handleScaleUpdate
              : null,
      onScaleEnd:
          (widget.interactions.enablePan || widget.interactions.enableZoom)
              ? _handleScaleEnd
              : null,
      child: child,
    );
  }

  // ============== Instant Touch Tooltip (no long press needed) ==============

  void _handlePointerDown(PointerDownEvent event) {
    // Only handle touch events, not mouse (mouse uses hover)
    if (event.kind == PointerDeviceKind.touch) {
      _isTouching = true;
      _updateTooltipForPosition(event.localPosition);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isTouching && event.kind == PointerDeviceKind.touch) {
      _updateTooltipForPosition(event.localPosition);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isTouching) {
      _isTouching = false;
      // Keep tooltip visible briefly after lifting finger
      _tooltipHideTimer?.cancel();
      _tooltipHideTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (!_isTouching) {
          widget.controller.clearHoveredPoint();
          widget.controller.hideTooltip();
        }
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isTouching) {
      _isTouching = false;
      _tooltipHideTimer?.cancel();
      widget.controller.clearHoveredPoint();
      widget.controller.hideTooltip();
    }
  }

  void _updateTooltipForPosition(Offset position) {
    if (widget.hitTester == null) return;

    final hitInfo = widget.hitTester!.hitTest(
      position,
      radius: widget.interactions.hitTestRadius * 2.0, // Generous touch radius
    );

    if (hitInfo != null) {
      widget.controller.setHoveredPoint(hitInfo);
      widget.controller.showTooltip(hitInfo);
    }
  }

  // ============== Standard Gesture Handlers ==============

  void _handleTap(TapDownDetails details) {
    widget.onTap?.call(details);

    if (widget.hitTester != null && widget.interactions.enableSelection) {
      final hitInfo = widget.hitTester!.hitTest(
        details.localPosition,
        radius: widget.interactions.hitTestRadius,
      );

      if (hitInfo != null) {
        if (widget.interactions.multiSelect) {
          widget.controller.togglePoint(hitInfo.seriesIndex, hitInfo.pointIndex);
        } else {
          widget.controller.clearSelection();
          widget.controller.selectPoint(hitInfo.seriesIndex, hitInfo.pointIndex);
        }

        if (widget.interactions.enableTooltip &&
            widget.interactions.tooltipBehavior == TooltipBehavior.onTap) {
          // Set both hoveredPoint and tooltipPoint for smooth animation
          widget.controller.setHoveredPoint(hitInfo);
          widget.controller.showTooltip(hitInfo);
        }
      } else {
        widget.controller.clearSelection();
        widget.controller.hideTooltip();
      }
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    widget.onDoubleTap?.call(details);

    // Reset zoom on double-tap
    if (widget.interactions.enableZoom) {
      widget.controller.resetViewport();
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    widget.onLongPress?.call(details);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScale = 1.0;
    widget.controller.startInteraction();
    widget.onScaleStart?.call(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle zooming
    if (widget.interactions.enableZoom && details.scale != 1.0) {
      final scaleChange = details.scale / _lastScale;
      final clampedScale = scaleChange.clamp(
        widget.interactions.minZoom / widget.controller.viewport.scaleX,
        widget.interactions.maxZoom / widget.controller.viewport.scaleX,
      );

      widget.controller.zoom(
        clampedScale * widget.interactions.zoomSensitivity,
        details.focalPoint,
      );

      _lastScale = details.scale;
    }

    // Handle panning
    if (widget.interactions.enablePan && _lastFocalPoint != null) {
      var delta = details.focalPoint - _lastFocalPoint!;
      delta = delta * widget.interactions.panSensitivity;

      switch (widget.interactions.panAxis) {
        case PanAxis.horizontal:
          delta = Offset(delta.dx, 0);
        case PanAxis.vertical:
          delta = Offset(0, delta.dy);
        case PanAxis.both:
          break;
      }

      widget.controller.pan(delta);
      _lastFocalPoint = details.focalPoint;
    }

    widget.onScaleUpdate?.call(details);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _lastScale = 1.0;
    widget.controller.endInteraction();
    widget.onScaleEnd?.call(details);
  }

  void _handleHover(PointerHoverEvent event) {
    widget.onHover?.call(event);

    if (widget.hitTester != null) {
      final hitInfo = widget.hitTester!.hitTest(
        event.localPosition,
        radius: widget.interactions.hitTestRadius,
      );

      widget.controller.setHoveredPoint(hitInfo);

      if (widget.interactions.enableTooltip) {
        if (widget.interactions.tooltipBehavior == TooltipBehavior.onHover ||
            widget.interactions.tooltipBehavior == TooltipBehavior.followPointer) {
          if (hitInfo != null) {
            widget.controller.showTooltip(hitInfo);
          } else {
            widget.controller.hideTooltip();
          }
        }
      }
    }
  }

  void _handleExit(PointerExitEvent event) {
    widget.onExit?.call(event);
    widget.controller.clearHover();
    if (widget.interactions.tooltipBehavior != TooltipBehavior.onTap) {
      widget.controller.hideTooltip();
    }
  }
}

/// Hit tester for finding data points at a position.
///
/// Uses spatial indexing (QuadTree) for O(log n) hit testing performance
/// with large numbers of data points.
class ChartHitTester {
  /// Creates a hit tester.
  ///
  /// Optionally provide [bounds] for the chart area to optimize spatial indexing.
  /// If not provided, bounds will be computed from added targets.
  ChartHitTester({Rect? bounds}) : _bounds = bounds;

  final List<_HitTarget> _targets = [];
  Rect? _bounds;
  QuadTree<_HitTarget>? _spatialIndex;
  bool _indexDirty = true;

  /// Sets the bounds for spatial indexing.
  ///
  /// Call this before adding targets for optimal performance.
  void setBounds(Rect bounds) {
    _bounds = bounds;
    _indexDirty = true;
  }

  /// Adds a circular hit target.
  void addCircle({
    required Offset center,
    required double radius,
    required DataPointInfo info,
  }) {
    final target = _CircleHitTarget(center: center, radius: radius, info: info);
    _targets.add(target);
    _indexDirty = true;
  }

  /// Adds a rectangular hit target.
  void addRect({
    required Rect rect,
    required DataPointInfo info,
  }) {
    final target = _RectHitTarget(rect: rect, info: info);
    _targets.add(target);
    _indexDirty = true;
  }

  /// Adds a path-based hit target.
  void addPath({
    required Path path,
    required DataPointInfo info,
    double strokeWidth = 10.0,
  }) {
    final target = _PathHitTarget(path: path, info: info, strokeWidth: strokeWidth);
    _targets.add(target);
    _indexDirty = true;
  }

  /// Adds an arc/sector hit target (for pie charts).
  void addArc({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
    required DataPointInfo info,
  }) {
    final target = _ArcHitTarget(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      info: info,
    );
    _targets.add(target);
    _indexDirty = true;
  }

  /// Clears all hit targets.
  void clear() {
    _targets.clear();
    _spatialIndex?.clear();
    _indexDirty = true;
  }

  /// Rebuilds the spatial index if needed.
  void _ensureIndex() {
    if (!_indexDirty && _spatialIndex != null) return;
    if (_targets.isEmpty) {
      _spatialIndex = null;
      _indexDirty = false;
      return;
    }

    // Compute bounds if not provided
    final bounds = _bounds ?? _computeBounds();
    if (bounds.isEmpty) {
      _spatialIndex = null;
      _indexDirty = false;
      return;
    }

    // Rebuild spatial index
    _spatialIndex = QuadTree<_HitTarget>(bounds: bounds);
    for (final target in _targets) {
      final targetBounds = _getTargetBounds(target);
      _spatialIndex!.insert(target, targetBounds);
    }

    _indexDirty = false;
  }

  /// Computes bounding rectangle from all targets.
  Rect _computeBounds() {
    if (_targets.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final target in _targets) {
      final bounds = _getTargetBounds(target);
      if (bounds.left < minX) minX = bounds.left;
      if (bounds.top < minY) minY = bounds.top;
      if (bounds.right > maxX) maxX = bounds.right;
      if (bounds.bottom > maxY) maxY = bounds.bottom;
    }

    // Add padding for query radius
    const padding = 50.0;
    return Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  /// Gets the bounding rectangle for a hit target.
  Rect _getTargetBounds(_HitTarget target) {
    if (target is _CircleHitTarget) {
      return Rect.fromCenter(
        center: target.center,
        width: target.radius * 2,
        height: target.radius * 2,
      );
    } else if (target is _RectHitTarget) {
      return target.rect;
    } else if (target is _PathHitTarget) {
      return target.path.getBounds().inflate(target.strokeWidth);
    } else if (target is _ArcHitTarget) {
      // Bounding box of the arc
      return Rect.fromCenter(
        center: target.center,
        width: target.outerRadius * 2,
        height: target.outerRadius * 2,
      );
    }
    return Rect.zero;
  }

  /// Tests if the given position hits any target.
  ///
  /// Uses O(log n) spatial query when possible.
  DataPointInfo? hitTest(Offset position, {double radius = 20.0}) {
    _ensureIndex();

    // Use spatial index for large datasets (>20 targets)
    if (_spatialIndex != null && _targets.length > 20) {
      return _hitTestSpatial(position, radius);
    }

    // Fall back to linear search for small datasets
    return _hitTestLinear(position, radius);
  }

  /// Spatial O(log n) hit testing.
  DataPointInfo? _hitTestSpatial(Offset position, double radius) {
    // Query candidates from spatial index
    final queryRect = Rect.fromCenter(
      center: position,
      width: radius * 2,
      height: radius * 2,
    );
    final candidates = _spatialIndex!.queryRect(queryRect);

    // Find closest among candidates
    DataPointInfo? closest;
    double closestDistance = double.infinity;

    for (final target in candidates) {
      final distance = target.distanceTo(position);
      if (distance <= radius && distance < closestDistance) {
        closestDistance = distance;
        closest = target.info;
      }
    }

    return closest;
  }

  /// Linear O(n) hit testing for small datasets.
  DataPointInfo? _hitTestLinear(Offset position, double radius) {
    DataPointInfo? closest;
    double closestDistance = double.infinity;

    for (final target in _targets) {
      final distance = target.distanceTo(position);
      if (distance <= radius && distance < closestDistance) {
        closestDistance = distance;
        closest = target.info;
      }
    }

    return closest;
  }

  /// Returns all targets within the given radius.
  ///
  /// Uses O(log n) spatial query when possible.
  List<DataPointInfo> hitTestAll(Offset position, {double radius = 20.0}) {
    _ensureIndex();

    // Use spatial index for large datasets
    if (_spatialIndex != null && _targets.length > 20) {
      return _hitTestAllSpatial(position, radius);
    }

    // Fall back to linear search
    return _hitTestAllLinear(position, radius);
  }

  /// Spatial O(log n) all-targets hit testing.
  List<DataPointInfo> _hitTestAllSpatial(Offset position, double radius) {
    final queryRect = Rect.fromCenter(
      center: position,
      width: radius * 2,
      height: radius * 2,
    );
    final candidates = _spatialIndex!.queryRect(queryRect);
    final results = <DataPointInfo>[];

    for (final target in candidates) {
      if (target.distanceTo(position) <= radius) {
        results.add(target.info);
      }
    }

    return results;
  }

  /// Linear O(n) all-targets hit testing.
  List<DataPointInfo> _hitTestAllLinear(Offset position, double radius) {
    final results = <DataPointInfo>[];

    for (final target in _targets) {
      if (target.distanceTo(position) <= radius) {
        results.add(target.info);
      }
    }

    return results;
  }

  /// Number of registered hit targets.
  int get length => _targets.length;
}

abstract class _HitTarget {
  DataPointInfo get info;
  double distanceTo(Offset position);
}

class _CircleHitTarget implements _HitTarget {
  const _CircleHitTarget({
    required this.center,
    required this.radius,
    required this.info,
  });

  final Offset center;
  final double radius;
  @override
  final DataPointInfo info;

  @override
  double distanceTo(Offset position) {
    final distance = (position - center).distance - radius;
    return distance < 0 ? 0 : distance;
  }
}

class _RectHitTarget implements _HitTarget {
  const _RectHitTarget({
    required this.rect,
    required this.info,
  });

  final Rect rect;
  @override
  final DataPointInfo info;

  @override
  double distanceTo(Offset position) {
    if (rect.contains(position)) return 0;

    final dx = position.dx < rect.left
        ? rect.left - position.dx
        : (position.dx > rect.right ? position.dx - rect.right : 0.0);
    final dy = position.dy < rect.top
        ? rect.top - position.dy
        : (position.dy > rect.bottom ? position.dy - rect.bottom : 0.0);

    return Offset(dx, dy).distance;
  }
}

class _PathHitTarget implements _HitTarget {
  const _PathHitTarget({
    required this.path,
    required this.info,
    required this.strokeWidth,
  });

  final Path path;
  @override
  final DataPointInfo info;
  final double strokeWidth;

  @override
  double distanceTo(Offset position) {
    // Simplified hit testing - check if point is near the path
    // For more accurate hit testing, would need to compute actual distance to path
    if (path.contains(position)) return 0;

    // Check inflated path
    final inflatedPath = Path()
      ..addPath(path, Offset.zero);
    // Note: For production, use path.computeMetrics() to calculate actual distance

    return double.infinity;
  }
}

class _ArcHitTarget implements _HitTarget {
  const _ArcHitTarget({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.info,
  });

  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sweepAngle;
  @override
  final DataPointInfo info;

  @override
  double distanceTo(Offset position) {
    // Check if point is within the arc sector
    final delta = position - center;
    final distance = delta.distance;

    // Check radius bounds
    if (distance < innerRadius || distance > outerRadius) {
      return double.infinity;
    }

    // Check angle bounds
    var angle = delta.direction; // Returns angle in radians from -pi to pi

    // Normalize angles to 0 to 2*pi range
    var normalizedStart = startAngle;
    while (normalizedStart < 0) {
      normalizedStart += 2 * 3.14159265359;
    }
    while (normalizedStart >= 2 * 3.14159265359) {
      normalizedStart -= 2 * 3.14159265359;
    }

    var normalizedAngle = angle;
    while (normalizedAngle < 0) {
      normalizedAngle += 2 * 3.14159265359;
    }
    while (normalizedAngle >= 2 * 3.14159265359) {
      normalizedAngle -= 2 * 3.14159265359;
    }

    // Check if angle is within sweep
    final endAngle = normalizedStart + sweepAngle;

    bool inSector;
    if (sweepAngle >= 0) {
      if (endAngle <= 2 * 3.14159265359) {
        inSector = normalizedAngle >= normalizedStart && normalizedAngle <= endAngle;
      } else {
        // Sector crosses the 0/2pi boundary
        inSector = normalizedAngle >= normalizedStart ||
            normalizedAngle <= (endAngle - 2 * 3.14159265359);
      }
    } else {
      // Negative sweep (clockwise)
      if (endAngle >= 0) {
        inSector = normalizedAngle <= normalizedStart && normalizedAngle >= endAngle;
      } else {
        inSector = normalizedAngle <= normalizedStart ||
            normalizedAngle >= (endAngle + 2 * 3.14159265359);
      }
    }

    return inSector ? 0 : double.infinity;
  }
}
