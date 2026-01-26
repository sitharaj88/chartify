import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Modern easing curves inspired by Material Design 3.
///
/// These curves provide smooth, natural-feeling animations that are
/// more engaging than standard Flutter curves.
///
/// Example:
/// ```dart
/// ChartAnimation(
///   duration: Duration(milliseconds: 600),
///   curve: ChartCurves.emphasized,
/// )
/// ```
class ChartCurves {
  ChartCurves._();

  /// Emphasized curve - slow start, fast middle, slow end.
  /// Best for: Primary animations, transitions, data series entry.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Emphasized decelerate - for entering elements.
  /// Best for: Elements appearing on screen, tooltips appearing.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Emphasized accelerate - for exiting elements.
  /// Best for: Elements leaving screen, tooltips disappearing.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Standard curve - balanced movement.
  /// Best for: General purpose animations.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// Standard decelerate - natural slow down.
  /// Best for: Data point highlights, hover effects.
  static const Curve standardDecelerate = Cubic(0, 0, 0, 1);

  /// Standard accelerate - natural speed up.
  /// Best for: Hiding elements, exiting animations.
  static const Curve standardAccelerate = Cubic(0.3, 0, 1, 1);

  /// Spring effect for responsive, bouncy feedback.
  /// Best for: Interactive elements, selection feedback.
  static const Curve spring = _SpringCurve(0.4);

  /// Overshoot effect - goes past target then returns.
  /// Best for: Playful interactions, emphasis animations.
  static const Curve overshoot = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Snappy curve - quick and responsive.
  /// Best for: Hover effects, micro-interactions.
  static const Curve snappy = Cubic(0.4, 0, 0.2, 1);

  /// Smooth curve - gentle and flowing.
  /// Best for: Background animations, ambient effects.
  static const Curve smooth = Cubic(0.4, 0, 0.6, 1);

  /// Elastic curve - bouncy spring effect.
  /// Best for: Celebratory animations, achievement indicators.
  static const Curve elastic = ElasticOutCurve();

  /// Bounce curve - multiple bounces at end.
  /// Best for: Playful data reveals, fun interactions.
  static const Curve bounce = Curves.bounceOut;
}

/// Custom spring curve for natural, physics-based animation.
class _SpringCurve extends Curve {
  const _SpringCurve(this.damping);

  final double damping;

  @override
  double transformInternal(double t) {
    // Spring physics simulation
    final omega = 2 * math.pi / damping;
    return 1 - math.exp(-t * 5) * math.cos(omega * t);
  }
}

/// Configuration for chart animations.
///
/// Controls how charts animate when they first appear and when data changes.
///
/// Example:
/// ```dart
/// LineChart(
///   data: lineData,
///   animation: ChartAnimation(
///     duration: Duration(milliseconds: 800),
///     curve: Curves.easeOutCubic,
///     type: AnimationType.draw,
///   ),
/// )
/// ```
@immutable
class ChartAnimation {
  /// Creates an animation configuration.
  const ChartAnimation({
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.animateOnLoad = true,
    this.animateOnDataChange = true,
    this.type = AnimationType.draw,
    this.staggerDelay,
  });

  /// Creates a disabled animation configuration.
  const ChartAnimation.none()
      : duration = Duration.zero,
        curve = Curves.linear,
        animateOnLoad = false,
        animateOnDataChange = false,
        type = AnimationType.none,
        staggerDelay = null;

  /// Creates a fast animation configuration.
  const ChartAnimation.fast()
      : duration = const Duration(milliseconds: 300),
        curve = Curves.easeOut,
        animateOnLoad = true,
        animateOnDataChange = true,
        type = AnimationType.draw,
        staggerDelay = null;

  /// Creates a slow, dramatic animation configuration.
  const ChartAnimation.slow()
      : duration = const Duration(milliseconds: 1200),
        curve = Curves.easeInOutCubic,
        animateOnLoad = true,
        animateOnDataChange = true,
        type = AnimationType.draw,
        staggerDelay = null;

  /// Creates a staggered animation where series animate one after another.
  const ChartAnimation.staggered({
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    Duration? delay,
  })  : animateOnLoad = true,
        animateOnDataChange = true,
        type = AnimationType.stagger,
        staggerDelay = delay ?? const Duration(milliseconds: 100);

  /// The duration of the animation.
  final Duration duration;

  /// The easing curve for the animation.
  final Curve curve;

  /// Whether to animate when the chart first appears.
  final bool animateOnLoad;

  /// Whether to animate when the data changes.
  final bool animateOnDataChange;

  /// The type of animation to use.
  final AnimationType type;

  /// Delay between staggered series animations.
  final Duration? staggerDelay;

  /// Whether animations are enabled.
  bool get enabled => duration > Duration.zero;

  /// Creates a copy with the given values replaced.
  ChartAnimation copyWith({
    Duration? duration,
    Curve? curve,
    bool? animateOnLoad,
    bool? animateOnDataChange,
    AnimationType? type,
    Duration? staggerDelay,
  }) =>
      ChartAnimation(
        duration: duration ?? this.duration,
        curve: curve ?? this.curve,
        animateOnLoad: animateOnLoad ?? this.animateOnLoad,
        animateOnDataChange: animateOnDataChange ?? this.animateOnDataChange,
        type: type ?? this.type,
        staggerDelay: staggerDelay ?? this.staggerDelay,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartAnimation &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          curve == other.curve &&
          animateOnLoad == other.animateOnLoad &&
          animateOnDataChange == other.animateOnDataChange &&
          type == other.type &&
          staggerDelay == other.staggerDelay;

  @override
  int get hashCode => Object.hash(
        duration,
        curve,
        animateOnLoad,
        animateOnDataChange,
        type,
        staggerDelay,
      );

  @override
  String toString() => 'ChartAnimation('
      'duration: $duration, '
      'type: $type, '
      'enabled: $enabled)';
}

/// Types of chart animations.
enum AnimationType {
  /// No animation.
  none,

  /// Draw animation - line/area grows from start to end.
  draw,

  /// Fade animation - chart fades in from transparent.
  fade,

  /// Scale animation - chart scales from center.
  scale,

  /// Slide up animation - chart slides up from bottom.
  slideUp,

  /// Slide down animation - chart slides down from top.
  slideDown,

  /// Stagger animation - series animate one after another.
  stagger,

  /// Reveal animation - sections reveal one by one (for pie/donut).
  reveal,

  /// Grow animation - bars/sections grow from zero.
  grow,
}

/// Mixin for widgets that support chart animations.
mixin ChartAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  AnimationController? _animationController;
  Animation<double>? _animation;

  /// The current animation controller.
  AnimationController? get animationController => _animationController;

  /// The current animation value (0.0 to 1.0).
  double get animationValue => _animation?.value ?? 1.0;

  /// Whether the animation is currently running.
  bool get isAnimating => _animationController?.isAnimating ?? false;

  /// Initializes the animation with the given configuration.
  void initAnimation(ChartAnimation config) {
    if (!config.enabled) return;

    _animationController = AnimationController(
      vsync: this,
      duration: config.duration,
    );

    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: config.curve,
    );

    _animationController!.addListener(_onAnimationTick);
  }

  /// Starts the animation from the beginning.
  void startAnimation() {
    _animationController?.forward(from: 0);
  }

  /// Starts the animation from the current value.
  void resumeAnimation() {
    _animationController?.forward();
  }

  /// Reverses the animation.
  void reverseAnimation() {
    _animationController?.reverse();
  }

  /// Stops the animation.
  void stopAnimation() {
    _animationController?.stop();
  }

  /// Resets the animation to the beginning.
  void resetAnimation() {
    _animationController?.reset();
  }

  void _onAnimationTick() {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }

  /// Disposes the animation controller.
  void disposeAnimation() {
    _animationController?.removeListener(_onAnimationTick);
    _animationController?.dispose();
    _animationController = null;
    _animation = null;
  }

  @override
  void dispose() {
    disposeAnimation();
    super.dispose();
  }
}

/// Controller for managing multiple staggered animations.
class StaggeredAnimationController {
  /// Creates a staggered animation controller.
  StaggeredAnimationController({
    required TickerProvider vsync,
    required int itemCount,
    required Duration itemDuration,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Curve curve = Curves.easeOutCubic,
  }) {
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        vsync: vsync,
        duration: itemDuration,
      ),
    );

    _animations = _controllers.map((controller) => CurvedAnimation(parent: controller, curve: curve)).toList();

    _staggerDelay = staggerDelay;
  }

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  late final Duration _staggerDelay;

  /// Gets the animation for a specific index.
  Animation<double> operator [](int index) => _animations[index];

  /// The number of animations.
  int get length => _controllers.length;

  /// Gets the animation value for a specific index.
  double valueAt(int index) => _animations[index].value;

  /// Starts all animations with staggered delay.
  Future<void> forward() async {
    for (var i = 0; i < _controllers.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(_staggerDelay);
      }
      unawaited(_controllers[i].forward());
    }
  }

  /// Reverses all animations.
  void reverse() {
    for (final controller in _controllers.reversed) {
      controller.reverse();
    }
  }

  /// Resets all animations.
  void reset() {
    for (final controller in _controllers) {
      controller.reset();
    }
  }

  /// Adds a listener to all animations.
  void addListener(VoidCallback listener) {
    for (final controller in _controllers) {
      controller.addListener(listener);
    }
  }

  /// Removes a listener from all animations.
  void removeListener(VoidCallback listener) {
    for (final controller in _controllers) {
      controller.removeListener(listener);
    }
  }

  /// Disposes all animation controllers.
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }
}

/// Mixin for hover micro-interactions on chart elements.
///
/// Provides smooth scale, glow, and lift effects when hovering
/// over data points, bars, or other interactive elements.
///
/// Example:
/// ```dart
/// class _MyChartState extends State<MyChart>
///     with SingleTickerProviderStateMixin, ChartHoverAnimationMixin {
///
///   @override
///   void initState() {
///     super.initState();
///     initHoverAnimation();
///   }
///
///   void _onHover(bool isHovered) {
///     if (isHovered) {
///       animateHoverIn();
///     } else {
///       animateHoverOut();
///     }
///   }
/// }
/// ```
mixin ChartHoverAnimationMixin<T extends StatefulWidget> on State<T> {
  AnimationController? _hoverController;
  Animation<double>? _hoverScaleAnimation;
  Animation<double>? _hoverGlowAnimation;
  Animation<double>? _hoverLiftAnimation;

  /// The current scale value for hover effect (1.0 to 1.15).
  double get hoverScale => _hoverScaleAnimation?.value ?? 1.0;

  /// The current glow opacity for hover effect (0.0 to 0.3).
  double get hoverGlow => _hoverGlowAnimation?.value ?? 0.0;

  /// The current lift offset for hover effect (0.0 to 4.0).
  double get hoverLift => _hoverLiftAnimation?.value ?? 0.0;

  /// Whether the hover animation is currently active.
  bool get isHovered =>
      _hoverController != null && _hoverController!.value > 0;

  /// Initializes the hover animation controller.
  ///
  /// Must be called in [initState] and requires [TickerProvider].
  /// The [vsync] parameter should typically be `this` when mixed with
  /// [SingleTickerProviderStateMixin] or [TickerProviderStateMixin].
  void initHoverAnimation(TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 150),
    double maxScale = 1.15,
    double maxGlow = 0.3,
    double maxLift = 4.0,
  }) {
    _hoverController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    _hoverScaleAnimation = Tween<double>(
      begin: 1,
      end: maxScale,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: ChartCurves.snappy,
    ),);

    _hoverGlowAnimation = Tween<double>(
      begin: 0,
      end: maxGlow,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: ChartCurves.standardDecelerate,
    ),);

    _hoverLiftAnimation = Tween<double>(
      begin: 0,
      end: maxLift,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: ChartCurves.emphasized,
    ),);

    _hoverController!.addListener(_onHoverAnimationTick);
  }

  /// Animate hover in with scale, glow, and lift effects.
  void animateHoverIn() {
    _hoverController?.forward();
  }

  /// Animate hover out - reverses all effects smoothly.
  void animateHoverOut() {
    _hoverController?.reverse();
  }

  /// Immediately sets hover state without animation.
  void setHoverState(bool hovered) {
    if (hovered) {
      _hoverController?.value = 1.0;
    } else {
      _hoverController?.value = 0.0;
    }
  }

  void _onHoverAnimationTick() {
    if (mounted) {
      // Trigger rebuild for animation
      (this as dynamic).setState(() {});
    }
  }

  /// Disposes the hover animation controller.
  /// Call this in your [dispose] method.
  void disposeHoverAnimation() {
    _hoverController?.removeListener(_onHoverAnimationTick);
    _hoverController?.dispose();
    _hoverController = null;
    _hoverScaleAnimation = null;
    _hoverGlowAnimation = null;
    _hoverLiftAnimation = null;
  }
}

/// Helper class for creating hover effect painters.
///
/// Use this to apply consistent hover effects across different chart types.
class HoverEffectPainter {
  HoverEffectPainter._();

  /// Calculates shadow blur radius based on hover animation value.
  static double getGlowRadius(double hoverValue, {double maxRadius = 12.0}) => hoverValue * maxRadius;

  /// Calculates shadow color with animated opacity.
  static Color getGlowColor(Color baseColor, double hoverValue) => baseColor.withValues(alpha: 0.3 * hoverValue);

  /// Creates a shadow list for hover glow effect.
  static List<BoxShadow> createGlowShadows(
    Color color,
    double hoverValue, {
    double maxBlur = 12.0,
    double maxSpread = 2.0,
  }) {
    if (hoverValue <= 0) return [];

    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3 * hoverValue),
        blurRadius: maxBlur * hoverValue,
        spreadRadius: maxSpread * hoverValue,
      ),
    ];
  }

  /// Applies scale transform for hover effect.
  static Matrix4 createScaleTransform(
    double scale,
    Offset center,
  ) => Matrix4.identity()
      ..translateByVector3(Vector3(center.dx, center.dy, 0))
      ..scaleByVector3(Vector3(scale, scale, 1))
      ..translateByVector3(Vector3(-center.dx, -center.dy, 0));

  /// Applies lift transform (Y offset) for hover effect.
  static Matrix4 createLiftTransform(double lift) =>
      Matrix4.identity()..translateByVector3(Vector3(0, -lift, 0));

  /// Combines scale and lift transforms for full hover effect.
  static Matrix4 createHoverTransform(
    double scale,
    double lift,
    Offset center,
  ) => Matrix4.identity()
      ..translateByVector3(Vector3(center.dx, center.dy - lift, 0))
      ..scaleByVector3(Vector3(scale, scale, 1))
      ..translateByVector3(Vector3(-center.dx, -center.dy, 0));
}

/// Preset animation configurations for common use cases.
class ChartAnimationPresets {
  ChartAnimationPresets._();

  /// Modern emphasized animation - best for primary data series.
  static const ChartAnimation emphasized = ChartAnimation(
    duration: Duration(milliseconds: 600),
    curve: ChartCurves.emphasized,
  );

  /// Quick responsive animation - best for hover effects and tooltips.
  static const ChartAnimation responsive = ChartAnimation(
    duration: Duration(milliseconds: 200),
    curve: ChartCurves.snappy,
    type: AnimationType.scale,
  );

  /// Smooth flowing animation - best for ambient effects.
  static const ChartAnimation smooth = ChartAnimation(
    duration: Duration(milliseconds: 800),
    curve: ChartCurves.smooth,
    type: AnimationType.fade,
  );

  /// Playful bouncy animation - best for celebratory moments.
  static const ChartAnimation playful = ChartAnimation(
    duration: Duration(milliseconds: 700),
    curve: ChartCurves.elastic,
    type: AnimationType.scale,
  );

  /// Staggered entry animation - best for multiple data series.
  static const ChartAnimation staggeredEntry = ChartAnimation(
    duration: Duration(milliseconds: 400),
    curve: ChartCurves.emphasizedDecelerate,
    type: AnimationType.stagger,
    staggerDelay: Duration(milliseconds: 80),
  );

  /// Data change morphing animation - best for updating values.
  static const ChartAnimation morph = ChartAnimation(
    duration: Duration(milliseconds: 350),
    curve: ChartCurves.standard,
    animateOnLoad: false,
  );
}
