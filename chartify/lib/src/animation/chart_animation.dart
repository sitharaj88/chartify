import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
    _animationController?.forward(from: 0.0);
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

    _animations = _controllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: curve);
    }).toList();

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
    for (int i = 0; i < _controllers.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(_staggerDelay);
      }
      _controllers[i].forward();
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
