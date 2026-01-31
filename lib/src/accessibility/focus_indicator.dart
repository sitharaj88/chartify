import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Renders visual focus indicators for accessibility.
///
/// Provides high-visibility focus rings around chart elements
/// to support keyboard navigation.
class FocusIndicatorRenderer {
  FocusIndicatorRenderer({
    FocusIndicatorStyle? style,
  }) : style = style ?? const FocusIndicatorStyle();

  /// The style for focus indicators.
  final FocusIndicatorStyle style;

  /// Cached paint object for efficiency.
  Paint? _paint;

  /// Gets or creates the paint for the current style.
  Paint get _focusPaint {
    _paint ??= Paint()
      ..color = style.color
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    return _paint!;
  }

  /// Renders a focus ring around a data point.
  ///
  /// Creates a circular focus indicator with optional animation.
  void renderPointFocus(
    Canvas canvas,
    Offset center,
    double radius, {
    double animationValue = 1.0,
  }) {
    final paint = _focusPaint;

    // Apply animation scale
    final animatedRadius = radius + (style.focusRingOffset * animationValue);
    final animatedStroke = style.strokeWidth * animationValue;
    paint.strokeWidth = animatedStroke;

    // Draw outer focus ring
    canvas.drawCircle(center, animatedRadius, paint);

    // Draw inner glow for better visibility
    if (style.showInnerGlow) {
      final glowPaint = Paint()
        ..color = style.color.withValues(alpha: 0.3)
        ..strokeWidth = animatedStroke * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(center, animatedRadius, glowPaint);
    }
  }

  /// Renders a focus outline around a bar element.
  ///
  /// Creates a rounded rectangle focus indicator.
  void renderBarFocus(
    Canvas canvas,
    Rect barRect, {
    double cornerRadius = 4.0,
    double animationValue = 1.0,
  }) {
    final paint = _focusPaint;
    paint.strokeWidth = style.strokeWidth * animationValue;

    // Expand rect for focus ring
    final focusRect = barRect.inflate(style.focusRingOffset);
    final rrect = RRect.fromRectAndRadius(
      focusRect,
      Radius.circular(cornerRadius + style.focusRingOffset / 2),
    );

    canvas.drawRRect(rrect, paint);

    // Draw inner glow
    if (style.showInnerGlow) {
      final glowPaint = Paint()
        ..color = style.color.withValues(alpha: 0.3)
        ..strokeWidth = style.strokeWidth * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(rrect, glowPaint);
    }
  }

  /// Renders focus highlight for a pie/donut slice.
  ///
  /// Draws a focus outline around the slice path.
  void renderSliceFocus(
    Canvas canvas,
    Path slicePath, {
    double animationValue = 1.0,
  }) {
    final paint = _focusPaint;
    paint.strokeWidth = style.strokeWidth * animationValue;

    // Draw the path outline
    canvas.drawPath(slicePath, paint);

    // Add glow effect
    if (style.showInnerGlow) {
      final glowPaint = Paint()
        ..color = style.color.withValues(alpha: 0.3)
        ..strokeWidth = style.strokeWidth * 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(slicePath, glowPaint);
    }
  }

  /// Renders focus for scatter/bubble points.
  ///
  /// Uses a larger ring for bubbles with variable sizes.
  void renderBubbleFocus(
    Canvas canvas,
    Offset center,
    double radius, {
    double animationValue = 1.0,
  }) {
    // Bubbles get a proportionally larger focus ring
    final focusRadius = radius + style.focusRingOffset + (radius * 0.1);
    renderPointFocus(
      canvas,
      center,
      focusRadius,
      animationValue: animationValue,
    );
  }

  /// Renders focus for heatmap cells.
  ///
  /// Creates a rectangular focus indicator with strong contrast.
  void renderCellFocus(
    Canvas canvas,
    Rect cellRect, {
    double animationValue = 1.0,
  }) {
    renderBarFocus(
      canvas,
      cellRect,
      cornerRadius: 2.0,
      animationValue: animationValue,
    );
  }

  /// Renders focus for a line segment.
  ///
  /// Highlights a specific segment of a line chart.
  void renderLineFocus(
    Canvas canvas,
    Offset start,
    Offset end, {
    double animationValue = 1.0,
  }) {
    final paint = _focusPaint;
    paint.strokeWidth = style.strokeWidth * animationValue * 1.5;

    canvas.drawLine(start, end, paint);

    // Draw endpoint circles
    final pointRadius = style.strokeWidth * 2;
    canvas.drawCircle(start, pointRadius, paint);
    canvas.drawCircle(end, pointRadius, paint);
  }

  /// Renders focus for an area region.
  ///
  /// Highlights the boundary of an area chart section.
  void renderAreaFocus(
    Canvas canvas,
    Path areaPath, {
    double animationValue = 1.0,
  }) {
    renderSliceFocus(canvas, areaPath, animationValue: animationValue);
  }

  /// Renders a pulsing animation frame.
  ///
  /// Call this repeatedly to create a pulsing focus effect.
  void renderPulsingFocus(
    Canvas canvas,
    Offset center,
    double radius,
    double pulsePhase, // 0.0 to 1.0
  ) {
    // Calculate pulse scale (1.0 to pulseScale and back)
    final pulseValue =
        1.0 + (math.sin(pulsePhase * math.pi * 2) + 1) / 2 * (style.pulseScale - 1.0);

    renderPointFocus(
      canvas,
      center,
      radius * pulseValue,
      animationValue: pulseValue,
    );
  }

  /// Updates the style and clears cached paint.
  void updateStyle(FocusIndicatorStyle newStyle) {
    if (newStyle != style) {
      _paint = null;
    }
  }
}

/// Style configuration for focus indicators.
class FocusIndicatorStyle {
  const FocusIndicatorStyle({
    this.color = const Color(0xFF2196F3), // Material Blue
    this.strokeWidth = 3.0,
    this.focusRingOffset = 4.0,
    this.showInnerGlow = true,
    this.pulseScale = 1.15,
    this.pulseDuration = const Duration(milliseconds: 1000),
  });

  /// The color of the focus indicator.
  final Color color;

  /// The stroke width of the focus ring.
  final double strokeWidth;

  /// The offset/gap between element and focus ring.
  final double focusRingOffset;

  /// Whether to show an inner glow effect.
  final bool showInnerGlow;

  /// Scale factor for pulse animation (1.0 to this value).
  final double pulseScale;

  /// Duration of one pulse cycle.
  final Duration pulseDuration;

  /// Default style with blue focus ring.
  static const FocusIndicatorStyle defaultStyle = FocusIndicatorStyle();

  /// High contrast style with thicker, more visible ring.
  static const FocusIndicatorStyle highContrast = FocusIndicatorStyle(
    color: Color(0xFFFFFF00), // Yellow for high contrast
    strokeWidth: 4.0,
    focusRingOffset: 5.0,
    showInnerGlow: true,
    pulseScale: 1.2,
  );

  /// Subtle style for less intrusive focus indication.
  static const FocusIndicatorStyle subtle = FocusIndicatorStyle(
    color: Color(0xFF90CAF9), // Light blue
    strokeWidth: 2.0,
    focusRingOffset: 3.0,
    showInnerGlow: false,
    pulseScale: 1.1,
  );

  /// Creates a copy with updated values.
  FocusIndicatorStyle copyWith({
    Color? color,
    double? strokeWidth,
    double? focusRingOffset,
    bool? showInnerGlow,
    double? pulseScale,
    Duration? pulseDuration,
  }) =>
      FocusIndicatorStyle(
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        focusRingOffset: focusRingOffset ?? this.focusRingOffset,
        showInnerGlow: showInnerGlow ?? this.showInnerGlow,
        pulseScale: pulseScale ?? this.pulseScale,
        pulseDuration: pulseDuration ?? this.pulseDuration,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusIndicatorStyle &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.focusRingOffset == focusRingOffset &&
        other.showInnerGlow == showInnerGlow &&
        other.pulseScale == pulseScale &&
        other.pulseDuration == pulseDuration;
  }

  @override
  int get hashCode => Object.hash(
        color,
        strokeWidth,
        focusRingOffset,
        showInnerGlow,
        pulseScale,
        pulseDuration,
      );
}

/// Provider for focus indicator style.
class FocusIndicatorProvider extends InheritedWidget {
  const FocusIndicatorProvider({
    required this.style,
    required super.child,
    super.key,
  });

  /// The focus indicator style.
  final FocusIndicatorStyle style;

  /// Gets the style from context.
  static FocusIndicatorStyle of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FocusIndicatorProvider>();
    return provider?.style ?? const FocusIndicatorStyle();
  }

  /// Gets the style from context, or null if not found.
  static FocusIndicatorStyle? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FocusIndicatorProvider>();
    return provider?.style;
  }

  @override
  bool updateShouldNotify(FocusIndicatorProvider oldWidget) =>
      style != oldWidget.style;
}

/// Animated focus indicator widget.
///
/// Wraps a child widget with an animated focus ring when focused.
class AnimatedFocusIndicator extends StatefulWidget {
  const AnimatedFocusIndicator({
    required this.child,
    super.key,
    this.focusNode,
    this.style,
    this.shape = FocusShape.rounded,
    this.borderRadius,
    this.enablePulse = true,
  });

  /// The child widget.
  final Widget child;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Style for the focus indicator.
  final FocusIndicatorStyle? style;

  /// Shape of the focus indicator.
  final FocusShape shape;

  /// Border radius for rounded shape.
  final BorderRadius? borderRadius;

  /// Whether to enable pulse animation.
  final bool enablePulse;

  @override
  State<AnimatedFocusIndicator> createState() => _AnimatedFocusIndicatorState();
}

class _AnimatedFocusIndicatorState extends State<AnimatedFocusIndicator>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _pulseController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _pulseController = AnimationController(
      vsync: this,
      duration: widget.style?.pulseDuration ?? const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    _pulseController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused && widget.enablePulse) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? FocusIndicatorProvider.of(context);

    return Focus(
      focusNode: _focusNode,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _isFocused
                ? _FocusIndicatorPainter(
                    style: style,
                    shape: widget.shape,
                    borderRadius: widget.borderRadius,
                    pulseValue: widget.enablePulse
                        ? _pulseController.value
                        : 1.0,
                  )
                : null,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Shape options for focus indicators.
enum FocusShape {
  /// Circular focus ring.
  circle,

  /// Rounded rectangle focus ring.
  rounded,

  /// Rectangle focus ring.
  rectangle,
}

class _FocusIndicatorPainter extends CustomPainter {
  _FocusIndicatorPainter({
    required this.style,
    required this.shape,
    this.borderRadius,
    this.pulseValue = 1.0,
  });

  final FocusIndicatorStyle style;
  final FocusShape shape;
  final BorderRadius? borderRadius;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final renderer = FocusIndicatorRenderer(style: style);

    switch (shape) {
      case FocusShape.circle:
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) / 2;
        renderer.renderPointFocus(
          canvas,
          center,
          radius,
          animationValue: 1.0 + (pulseValue * (style.pulseScale - 1.0)),
        );

      case FocusShape.rounded:
        final rect = Offset.zero & size;
        renderer.renderBarFocus(
          canvas,
          rect,
          cornerRadius: borderRadius?.topLeft.x ?? 8.0,
          animationValue: 1.0 + (pulseValue * (style.pulseScale - 1.0)),
        );

      case FocusShape.rectangle:
        final rect = Offset.zero & size;
        renderer.renderBarFocus(
          canvas,
          rect,
          cornerRadius: 0.0,
          animationValue: 1.0 + (pulseValue * (style.pulseScale - 1.0)),
        );
    }
  }

  @override
  bool shouldRepaint(_FocusIndicatorPainter oldDelegate) =>
      style != oldDelegate.style ||
      shape != oldDelegate.shape ||
      pulseValue != oldDelegate.pulseValue;
}
