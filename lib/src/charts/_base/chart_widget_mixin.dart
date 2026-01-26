import 'package:flutter/material.dart';

import '../../animation/chart_animation.dart';
import '../../core/gestures/spatial_index.dart';
import '../../rendering/painters/series_painter.dart';
import '../../theme/chart_theme_data.dart';

/// Mixin providing common chart widget functionality.
///
/// This mixin provides:
/// - Theme integration
/// - Animation support
/// - Hit testing infrastructure
/// - Common layout helpers
mixin ChartWidgetMixin<T extends StatefulWidget> on State<T> {
  /// The chart theme.
  ChartThemeData get theme => ChartTheme.of(context);

  /// Animation controller for chart animations.
  AnimationController? _animationController;

  /// Current animation progress (0.0 to 1.0).
  double get animationProgress => _animationController?.value ?? 1.0;

  /// Whether animation is currently running.
  bool get isAnimating => _animationController?.isAnimating ?? false;

  /// Spatial index for hit testing.
  ChartSpatialIndex? spatialIndex;

  /// Initializes animation with the given configuration.
  void initAnimation(ChartAnimation? animation, TickerProvider vsync) {
    if (animation == null || animation.duration == Duration.zero) {
      return;
    }

    _animationController = AnimationController(
      vsync: vsync,
      duration: animation.duration,
    );

    // Apply curve
    final curvedAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: animation.curve,
    );

    curvedAnimation.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Start animation
    _animationController!.forward();
  }

  /// Restarts the animation.
  void restartAnimation() {
    _animationController?.reset();
    _animationController?.forward();
  }

  /// Disposes animation resources.
  void disposeAnimation() {
    _animationController?.dispose();
    _animationController = null;
  }

  /// Initializes spatial index for hit testing.
  void initSpatialIndex(Rect bounds) {
    spatialIndex = ChartSpatialIndex(bounds: bounds);
  }

  /// Performs hit testing at the given point.
  DataPointInfo? hitTest(Offset point) {
    final result = spatialIndex?.hitTest(point);
    return result?.item as DataPointInfo?;
  }

  /// Clears the spatial index.
  void clearSpatialIndex() {
    spatialIndex?.clear();
  }
}

/// Mixin for charts that need gesture handling.
mixin ChartGestureMixin<T extends StatefulWidget> on State<T> {
  /// Currently hovered data point.
  DataPointInfo? hoveredPoint;

  /// Currently selected data point.
  DataPointInfo? selectedPoint;

  /// Callback for hover events.
  void Function(DataPointInfo?)? onHover;

  /// Callback for tap events.
  void Function(DataPointInfo?)? onTap;

  /// Handles pointer hover.
  void handlePointerHover(Offset position, DataPointInfo? Function(Offset) hitTest) {
    final hit = hitTest(position);
    if (hit != hoveredPoint) {
      setState(() {
        hoveredPoint = hit;
      });
      onHover?.call(hit);
    }
  }

  /// Handles pointer exit.
  void handlePointerExit() {
    if (hoveredPoint != null) {
      setState(() {
        hoveredPoint = null;
      });
      onHover?.call(null);
    }
  }

  /// Handles tap.
  void handleTap(Offset position, DataPointInfo? Function(Offset) hitTest) {
    final hit = hitTest(position);
    setState(() {
      selectedPoint = hit;
    });
    onTap?.call(hit);
  }
}

/// Mixin for charts with tooltip support.
mixin ChartTooltipMixin<T extends StatefulWidget> on State<T> {
  /// Overlay entry for tooltip.
  OverlayEntry? _tooltipOverlay;

  /// Shows tooltip at the given position.
  void showTooltip(
    BuildContext context,
    Offset position,
    Widget content, {
    Offset offset = const Offset(10, 10),
  }) {
    hideTooltip();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final globalPosition = renderBox.localToGlobal(position);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: globalPosition.dx + offset.dx,
        top: globalPosition.dy + offset.dy,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      ),
    );

    overlay.insert(_tooltipOverlay!);
  }

  /// Hides the tooltip.
  void hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  /// Disposes tooltip resources.
  void disposeTooltip() {
    hideTooltip();
  }
}

/// Common chart layout calculations.
class ChartLayoutHelper {
  ChartLayoutHelper._();

  /// Calculates the chart area after accounting for padding and axes.
  static Rect calculateChartArea(
    Size size, {
    EdgeInsets padding = EdgeInsets.zero,
    double leftAxisWidth = 0,
    double rightAxisWidth = 0,
    double topAxisHeight = 0,
    double bottomAxisHeight = 0,
    double legendHeight = 0,
    bool legendAtBottom = true,
  }) {
    final left = padding.left + leftAxisWidth;
    final right = padding.right + rightAxisWidth;
    final top = padding.top + topAxisHeight + (legendAtBottom ? 0 : legendHeight);
    final bottom = padding.bottom + bottomAxisHeight + (legendAtBottom ? legendHeight : 0);

    return Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
  }

  /// Calculates optimal tick count based on available space.
  static int calculateTickCount(double availableSpace, {double minSpacing = 50}) {
    return (availableSpace / minSpacing).floor().clamp(2, 20);
  }

  /// Determines if labels should be rotated based on available space.
  static bool shouldRotateLabels(
    double availableWidth,
    int labelCount,
    double avgLabelWidth,
  ) {
    final spacingPerLabel = availableWidth / labelCount;
    return spacingPerLabel < avgLabelWidth * 1.2;
  }
}

/// Base class for chart painters with common functionality.
abstract class BaseChartPainter extends CustomPainter {
  BaseChartPainter({
    required this.theme,
    this.animationProgress = 1.0,
  });

  final ChartThemeData theme;
  final double animationProgress;

  /// The chart area (set during paint).
  Rect chartArea = Rect.zero;

  /// Calculates the chart area from size and insets.
  Rect calculateChartArea(Size size, EdgeInsets insets) {
    return Rect.fromLTRB(
      insets.left,
      insets.top,
      size.width - insets.right,
      size.height - insets.bottom,
    );
  }

  /// Interpolates a value based on animation progress.
  double animatedValue(double target, {double start = 0}) {
    return start + (target - start) * animationProgress;
  }

  /// Interpolates an offset based on animation progress.
  Offset animatedOffset(Offset target, {Offset start = Offset.zero}) {
    return Offset(
      animatedValue(target.dx, start: start.dx),
      animatedValue(target.dy, start: start.dy),
    );
  }
}
