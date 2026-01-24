import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../animation/chart_animation.dart';
import '../../core/base/chart_controller.dart';
import '../../theme/chart_theme_data.dart';

/// Configuration for chart tooltips.
@immutable
class TooltipConfig {
  const TooltipConfig({
    this.enabled = true,
    this.showOnHover = true,
    this.showOnTap = true,
    this.position = TooltipPosition.auto,
    this.offset = const Offset(0, -8),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.hideDelay = const Duration(milliseconds: 50),
    this.builder,
    this.decoration,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.showIndicatorLine = false,
    this.showIndicatorDot = true,
    this.indicatorLineWidth = 1.0,
    this.indicatorDotSize = 8.0,
    this.screenMargin = const EdgeInsets.all(8),
    this.showArrow = true,
    this.arrowSize = 8.0,
    this.touchFriendly = true,
  });

  final bool enabled;
  final bool showOnHover;
  final bool showOnTap;
  final TooltipPosition position;
  final Offset offset;
  final Duration animationDuration;
  final Curve animationCurve;
  final Duration hideDelay;
  final Widget Function(BuildContext context, TooltipData data)? builder;
  final BoxDecoration? decoration;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final bool showIndicatorLine;
  final bool showIndicatorDot;
  final double indicatorLineWidth;
  final double indicatorDotSize;
  final EdgeInsets screenMargin;
  final bool showArrow;
  final double arrowSize;

  /// When true, tooltip prefers horizontal positioning (left/right) on touch
  /// devices to stay out of the way of the user's finger. The tooltip will
  /// appear on the opposite side of where the user touches.
  final bool touchFriendly;

  TooltipConfig copyWith({
    bool? enabled,
    bool? showOnHover,
    bool? showOnTap,
    TooltipPosition? position,
    Offset? offset,
    Duration? animationDuration,
    Curve? animationCurve,
    Duration? hideDelay,
    Widget Function(BuildContext context, TooltipData data)? builder,
    BoxDecoration? decoration,
    TextStyle? textStyle,
    EdgeInsets? padding,
    bool? showIndicatorLine,
    bool? showIndicatorDot,
    double? indicatorLineWidth,
    double? indicatorDotSize,
    EdgeInsets? screenMargin,
    bool? showArrow,
    double? arrowSize,
    bool? touchFriendly,
  }) {
    return TooltipConfig(
      enabled: enabled ?? this.enabled,
      showOnHover: showOnHover ?? this.showOnHover,
      showOnTap: showOnTap ?? this.showOnTap,
      position: position ?? this.position,
      offset: offset ?? this.offset,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      hideDelay: hideDelay ?? this.hideDelay,
      builder: builder ?? this.builder,
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      showIndicatorLine: showIndicatorLine ?? this.showIndicatorLine,
      showIndicatorDot: showIndicatorDot ?? this.showIndicatorDot,
      indicatorLineWidth: indicatorLineWidth ?? this.indicatorLineWidth,
      indicatorDotSize: indicatorDotSize ?? this.indicatorDotSize,
      screenMargin: screenMargin ?? this.screenMargin,
      showArrow: showArrow ?? this.showArrow,
      arrowSize: arrowSize ?? this.arrowSize,
      touchFriendly: touchFriendly ?? this.touchFriendly,
    );
  }
}

enum TooltipPosition { auto, top, bottom, left, right }

/// Result of tooltip positioning calculation.
@immutable
class TooltipPositionResult {
  const TooltipPositionResult({
    required this.tooltipOffset,
    required this.resolvedPosition,
    required this.arrowOffset,
  });

  /// The calculated offset for the tooltip widget
  final Offset tooltipOffset;
  /// The resolved position direction (top, bottom, left, right)
  final TooltipPosition resolvedPosition;
  /// Offset for the arrow tip relative to tooltip's top-left
  final Offset arrowOffset;
}

/// Modern tooltip positioner with smart edge detection and 100% accurate arrow.
class TooltipPositioner {
  TooltipPositioner._();

  /// Layout constants
  static const double _tooltipGap = 8;
  /// Minimum margin from tooltip edge for arrow (matches arrow base half-width)
  static const double _minArrowMargin = 6;

  /// Calculate optimal tooltip position with smart edge detection.
  ///
  /// Returns position that:
  /// 1. Keeps tooltip fully within screen bounds
  /// 2. Points arrow exactly at data point
  /// 3. For touch devices: prefers horizontal positioning (left/right) to keep
  ///    tooltip away from the user's finger
  /// 4. For desktop: prefers vertical positioning (top/bottom)
  static TooltipPositionResult calculate({
    required Offset dataPoint,
    required Size tooltipSize,
    required Size screenSize,
    required Rect chartArea,
    EdgeInsets margin = const EdgeInsets.all(8),
    TooltipPosition preferredPosition = TooltipPosition.auto,
    double arrowSize = 8.0,
    bool preferHorizontal = false,
  }) {
    final safeArea = Rect.fromLTRB(
      margin.left,
      margin.top,
      screenSize.width - margin.right,
      screenSize.height - margin.bottom,
    );

    final tooltipWidth = tooltipSize.width;
    final tooltipHeight = tooltipSize.height;
    final gap = _tooltipGap + arrowSize;

    // Calculate space available in each direction from data point
    final spaceAbove = dataPoint.dy - safeArea.top;
    final spaceBelow = safeArea.bottom - dataPoint.dy;
    final spaceLeft = dataPoint.dx - safeArea.left;
    final spaceRight = safeArea.right - dataPoint.dx;

    // Determine best position
    TooltipPosition resolved;
    if (preferredPosition != TooltipPosition.auto) {
      resolved = preferredPosition;
    } else {
      // Check if tooltip fits in each direction
      final fitsAbove = spaceAbove >= tooltipHeight + gap;
      final fitsBelow = spaceBelow >= tooltipHeight + gap;
      final fitsLeft = spaceLeft >= tooltipWidth + gap;
      final fitsRight = spaceRight >= tooltipWidth + gap;

      if (preferHorizontal) {
        // Mobile-friendly: prefer horizontal positioning to stay away from finger
        // Show on opposite side of where the user is touching
        final isOnRightHalf = dataPoint.dx > screenSize.width / 2;

        if (isOnRightHalf && fitsLeft) {
          // Point is on right, show tooltip on left
          resolved = TooltipPosition.left;
        } else if (!isOnRightHalf && fitsRight) {
          // Point is on left, show tooltip on right
          resolved = TooltipPosition.right;
        } else if (fitsLeft) {
          resolved = TooltipPosition.left;
        } else if (fitsRight) {
          resolved = TooltipPosition.right;
        } else if (fitsAbove) {
          resolved = TooltipPosition.top;
        } else if (fitsBelow) {
          resolved = TooltipPosition.bottom;
        } else {
          // Fallback: use side with most space
          resolved = spaceLeft >= spaceRight
              ? TooltipPosition.left
              : TooltipPosition.right;
        }
      } else {
        // Desktop-friendly: prefer vertical positioning (top/bottom)
        if (fitsAbove) {
          resolved = TooltipPosition.top;
        } else if (fitsBelow) {
          resolved = TooltipPosition.bottom;
        } else if (fitsRight && spaceRight >= spaceLeft) {
          resolved = TooltipPosition.right;
        } else if (fitsLeft) {
          resolved = TooltipPosition.left;
        } else {
          // Nothing fits perfectly, use direction with most space
          resolved = spaceAbove >= spaceBelow
              ? TooltipPosition.top
              : TooltipPosition.bottom;
        }
      }
    }

    // Calculate tooltip position and arrow offset
    Offset tooltipOffset;
    Offset arrowOffset;

    switch (resolved) {
      case TooltipPosition.top:
        // Tooltip above data point
        var x = dataPoint.dx - tooltipWidth / 2;
        final y = dataPoint.dy - tooltipHeight - gap;

        // Clamp X to keep tooltip within safe area
        x = x.clamp(safeArea.left, safeArea.right - tooltipWidth);

        tooltipOffset = Offset(x, math.max(safeArea.top, y));

        // Arrow points down, positioned at data point X relative to tooltip
        final arrowX = (dataPoint.dx - x).clamp(
          _minArrowMargin,
          tooltipWidth - _minArrowMargin,
        );
        arrowOffset = Offset(arrowX, tooltipHeight);

      case TooltipPosition.bottom:
        // Tooltip below data point
        var x = dataPoint.dx - tooltipWidth / 2;
        final y = dataPoint.dy + gap;

        x = x.clamp(safeArea.left, safeArea.right - tooltipWidth);

        tooltipOffset = Offset(x, math.min(safeArea.bottom - tooltipHeight, y));

        // Arrow points up
        final arrowX = (dataPoint.dx - x).clamp(
          _minArrowMargin,
          tooltipWidth - _minArrowMargin,
        );
        arrowOffset = Offset(arrowX, -arrowSize);

      case TooltipPosition.left:
        // Tooltip left of data point
        final x = dataPoint.dx - tooltipWidth - gap;
        var y = dataPoint.dy - tooltipHeight / 2;

        y = y.clamp(safeArea.top, safeArea.bottom - tooltipHeight);

        tooltipOffset = Offset(math.max(safeArea.left, x), y);

        // Arrow points right
        final arrowY = (dataPoint.dy - y).clamp(
          _minArrowMargin,
          tooltipHeight - _minArrowMargin,
        );
        arrowOffset = Offset(tooltipWidth, arrowY);

      case TooltipPosition.right:
        // Tooltip right of data point
        final x = dataPoint.dx + gap;
        var y = dataPoint.dy - tooltipHeight / 2;

        y = y.clamp(safeArea.top, safeArea.bottom - tooltipHeight);

        tooltipOffset = Offset(math.min(safeArea.right - tooltipWidth, x), y);

        // Arrow points left
        final arrowY = (dataPoint.dy - y).clamp(
          _minArrowMargin,
          tooltipHeight - _minArrowMargin,
        );
        arrowOffset = Offset(-arrowSize, arrowY);

      case TooltipPosition.auto:
        // Should not reach here
        tooltipOffset = Offset(
          dataPoint.dx - tooltipWidth / 2,
          dataPoint.dy - tooltipHeight - gap,
        );
        arrowOffset = Offset(tooltipWidth / 2, tooltipHeight);
    }

    return TooltipPositionResult(
      tooltipOffset: tooltipOffset,
      resolvedPosition: resolved,
      arrowOffset: arrowOffset,
    );
  }
}

@immutable
class TooltipData {
  const TooltipData({
    required this.position,
    required this.entries,
    this.xLabel,
  });

  final Offset position;
  final List<TooltipEntry> entries;
  final String? xLabel;
}

@immutable
class TooltipEntry {
  const TooltipEntry({
    required this.color,
    required this.label,
    required this.value,
    this.formattedValue,
  });

  final Color color;
  final String label;
  final dynamic value;
  final String? formattedValue;

  String get displayValue => formattedValue ?? _formatValue(value);

  static String _formatValue(dynamic value) {
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
    if (value is DateTime) {
      return '${value.month}/${value.day}';
    }
    return value.toString();
  }
}

/// Modern tooltip overlay with smooth animations and accurate positioning.
class ChartTooltipOverlay extends StatefulWidget {
  const ChartTooltipOverlay({
    super.key,
    required this.child,
    required this.controller,
    required this.config,
    required this.theme,
    required this.chartArea,
    this.tooltipDataBuilder,
  });

  final Widget child;
  final ChartController controller;
  final TooltipConfig config;
  final ChartThemeData theme;
  final Rect chartArea;
  final TooltipData? Function(DataPointInfo info)? tooltipDataBuilder;

  @override
  State<ChartTooltipOverlay> createState() => _ChartTooltipOverlayState();
}

class _ChartTooltipOverlayState extends State<ChartTooltipOverlay>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _visibilityController;
  late AnimationController _moveController;

  // Animations
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // Position tracking with smooth interpolation
  Offset _currentDataPoint = Offset.zero;
  Offset _targetDataPoint = Offset.zero;
  Offset _displayDataPoint = Offset.zero;

  // Tooltip state
  TooltipData? _tooltipData;
  bool _isShowing = false;
  Size _tooltipSize = const Size(140, 60);
  TooltipPositionResult? _positionResult;

  // Scrubbing mode for smooth touch drag
  bool _isScrubbing = false;
  Ticker? _scrubbingTicker;

  // Debounce
  int _updateCounter = 0;
  Timer? _hideDebounceTimer;

  // Keys for measurement
  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    widget.controller.addListener(_onControllerChanged);
  }

  void _setupAnimations() {
    // Visibility animation (fade + scale)
    _visibilityController = AnimationController(
      vsync: this,
      duration: widget.config.animationDuration,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: ChartCurves.emphasizedDecelerate,
      reverseCurve: ChartCurves.emphasizedAccelerate,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: ChartCurves.emphasizedDecelerate,
        reverseCurve: ChartCurves.emphasizedAccelerate,
      ),
    );

    // Movement animation (for smooth position updates when scrubbing)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Smooth but responsive
    );

    _moveController.addListener(_onMoveAnimation);
  }

  @override
  void didUpdateWidget(ChartTooltipOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _hideDebounceTimer?.cancel();
    _stopScrubbingTicker();
    widget.controller.removeListener(_onControllerChanged);
    _visibilityController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Check both hoveredPoint (for hover/desktop) and tooltipPoint (for tap/mobile)
    final point = widget.controller.hoveredPoint ?? widget.controller.tooltipPoint;
    final counter = ++_updateCounter;

    if (point != null) {
      final data = _buildTooltipData(point);
      if (data != null) {
        _showTooltip(data, counter);
      }
    } else {
      _hideTooltip(counter);
    }
  }

  void _showTooltip(TooltipData data, int counter) {
    if (!mounted || counter != _updateCounter) return;

    // Cancel any pending hide - we're showing now
    _hideDebounceTimer?.cancel();
    _hideDebounceTimer = null;

    final newPoint = data.position;

    setState(() {
      _tooltipData = data;
      _targetDataPoint = newPoint;

      if (!_isShowing) {
        // First show - jump immediately to position
        _currentDataPoint = newPoint;
        _displayDataPoint = newPoint;
        _isShowing = true;
        _isScrubbing = false;
        _visibilityController.forward();
      } else {
        // Already showing - enable smooth scrubbing mode
        if (!_isScrubbing) {
          _isScrubbing = true;
          _startScrubbingTicker();
        }

        // CRITICAL: If visibility controller was reversing (fading out),
        // re-forward it to keep tooltip visible
        if (_visibilityController.status == AnimationStatus.reverse) {
          _visibilityController.forward();
        }
      }
    });

    // Measure tooltip size after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && counter == _updateCounter) {
        _measureTooltip();
      }
    });
  }

  /// Start a ticker that smoothly interpolates position during touch drag.
  void _startScrubbingTicker() {
    _scrubbingTicker?.stop();
    _scrubbingTicker = createTicker(_onScrubbingTick);
    _scrubbingTicker!.start();
  }

  /// Called every frame during scrubbing to smoothly move tooltip.
  void _onScrubbingTick(Duration elapsed) {
    if (!mounted || !_isScrubbing) {
      _scrubbingTicker?.stop();
      return;
    }

    // Smooth lerp factor - higher = faster response (0.3-0.5 feels smooth but responsive)
    const lerpFactor = 0.35;

    final dx = _targetDataPoint.dx - _displayDataPoint.dx;
    final dy = _targetDataPoint.dy - _displayDataPoint.dy;

    // If we're close enough, snap to target
    if (dx.abs() < 0.5 && dy.abs() < 0.5) {
      if (_displayDataPoint != _targetDataPoint) {
        setState(() {
          _displayDataPoint = _targetDataPoint;
        });
      }
      return;
    }

    // Smoothly interpolate towards target
    setState(() {
      _displayDataPoint = Offset(
        _displayDataPoint.dx + dx * lerpFactor,
        _displayDataPoint.dy + dy * lerpFactor,
      );
    });
  }

  void _stopScrubbingTicker() {
    _scrubbingTicker?.stop();
    _scrubbingTicker?.dispose();
    _scrubbingTicker = null;
    _isScrubbing = false;
  }

  void _hideTooltip(int counter) {
    if (!mounted || !_isShowing) return;

    // Stop scrubbing animation
    _stopScrubbingTicker();

    // Use debounce delay to prevent flicker when moving between data points
    // This gives time for a new point to be hovered before hiding
    _hideDebounceTimer?.cancel();
    _hideDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!mounted || counter != _updateCounter) return;

      _visibilityController.reverse().then((_) {
        if (mounted && counter == _updateCounter) {
          setState(() {
            _isShowing = false;
            _tooltipData = null;
          });
        }
      });
    });
  }

  void _onMoveAnimation() {
    if (!mounted) return;

    final t = ChartCurves.snappy.transform(_moveController.value);
    setState(() {
      _displayDataPoint = Offset.lerp(_currentDataPoint, _targetDataPoint, t)!;
    });
  }

  void _measureTooltip() {
    final renderBox = _tooltipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newSize = renderBox.size;
      if (newSize != _tooltipSize && newSize.width > 0 && newSize.height > 0) {
        setState(() => _tooltipSize = newSize);
      }
    }
  }

  TooltipData? _buildTooltipData(DataPointInfo info) {
    if (widget.tooltipDataBuilder != null) {
      return widget.tooltipDataBuilder!(info);
    }

    return TooltipData(
      position: info.position,
      entries: [
        TooltipEntry(
          color: widget.theme.getSeriesColor(info.seriesIndex),
          label: info.seriesName ?? 'Series ${info.seriesIndex + 1}',
          value: info.yValue,
        ),
      ],
      xLabel: _formatXValue(info.xValue),
    );
  }

  String _formatXValue(dynamic value) {
    if (value is DateTime) {
      return '${value.month}/${value.day}';
    }
    if (value is double) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_isShowing && _tooltipData != null)
              ..._buildTooltipElements(screenSize),
          ],
        );
      },
    );
  }

  List<Widget> _buildTooltipElements(Size screenSize) {
    // Detect if we're on a touch-friendly platform (mobile)
    final isTouchPlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    // Calculate position with current display point
    _positionResult = TooltipPositioner.calculate(
      dataPoint: _displayDataPoint,
      tooltipSize: _tooltipSize,
      screenSize: screenSize,
      chartArea: widget.chartArea,
      margin: widget.config.screenMargin,
      preferredPosition: widget.config.position,
      arrowSize: widget.config.arrowSize,
      preferHorizontal: widget.config.touchFriendly && isTouchPlatform,
    );

    final pos = _positionResult!;
    final isDark = widget.theme.brightness == Brightness.dark;

    // IMPORTANT: All tooltip elements must ignore pointer events
    // to prevent them from intercepting hover and causing flicker
    return [
      // Vertical indicator line
      if (widget.config.showIndicatorLine)
        Positioned(
          left: _displayDataPoint.dx - widget.config.indicatorLineWidth / 2,
          top: widget.chartArea.top,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                width: widget.config.indicatorLineWidth,
                height: widget.chartArea.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0),
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

      // Indicator dot at data point
      if (widget.config.showIndicatorDot && _tooltipData!.entries.isNotEmpty)
        Positioned(
          left: _displayDataPoint.dx - (widget.config.indicatorDotSize + 6) / 2,
          top: _displayDataPoint.dy - (widget.config.indicatorDotSize + 6) / 2,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: _ModernIndicatorDot(
                color: _tooltipData!.entries.first.color,
                size: widget.config.indicatorDotSize,
                isDark: isDark,
              ),
            ),
          ),
        ),

      // Tooltip with arrow
      Positioned(
        left: pos.tooltipOffset.dx,
        top: pos.tooltipOffset.dy,
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: _getScaleAlignment(pos.resolvedPosition),
              child: _ModernTooltip(
                key: _tooltipKey,
                data: _tooltipData!,
                config: widget.config,
                theme: widget.theme,
                position: pos.resolvedPosition,
                arrowOffset: pos.arrowOffset,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Alignment _getScaleAlignment(TooltipPosition position) {
    switch (position) {
      case TooltipPosition.top:
        return Alignment.bottomCenter;
      case TooltipPosition.bottom:
        return Alignment.topCenter;
      case TooltipPosition.left:
        return Alignment.centerRight;
      case TooltipPosition.right:
        return Alignment.centerLeft;
      case TooltipPosition.auto:
        return Alignment.center;
    }
  }
}

/// Modern glowing indicator dot.
class _ModernIndicatorDot extends StatelessWidget {
  const _ModernIndicatorDot({
    required this.color,
    required this.size,
    required this.isDark,
  });

  final Color color;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Modern tooltip with accurate arrow pointing.
class _ModernTooltip extends StatelessWidget {
  const _ModernTooltip({
    super.key,
    required this.data,
    required this.config,
    required this.theme,
    required this.position,
    required this.arrowOffset,
  });

  final TooltipData data;
  final TooltipConfig config;
  final ChartThemeData theme;
  final TooltipPosition position;
  final Offset arrowOffset;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return CustomPaint(
      painter: _TooltipPainter(
        backgroundColor: bgColor,
        borderColor: borderColor,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
        position: position,
        arrowOffset: arrowOffset,
        arrowSize: config.arrowSize,
        borderRadius: 8,
      ),
      child: Padding(
        padding: _getPaddingWithArrow(),
        child: _TooltipContent(
          data: data,
          config: config,
          theme: theme,
        ),
      ),
    );
  }

  EdgeInsets _getPaddingWithArrow() {
    final arrowSpace = config.showArrow ? config.arrowSize : 0.0;

    switch (position) {
      case TooltipPosition.top:
        return config.padding.copyWith(bottom: config.padding.bottom + arrowSpace);
      case TooltipPosition.bottom:
        return config.padding.copyWith(top: config.padding.top + arrowSpace);
      case TooltipPosition.left:
        return config.padding.copyWith(right: config.padding.right + arrowSpace);
      case TooltipPosition.right:
        return config.padding.copyWith(left: config.padding.left + arrowSpace);
      case TooltipPosition.auto:
        return config.padding;
    }
  }
}

/// Custom painter for tooltip background with arrow.
class _TooltipPainter extends CustomPainter {
  _TooltipPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.position,
    required this.arrowOffset,
    required this.arrowSize,
    required this.borderRadius,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final TooltipPosition position;
  final Offset arrowOffset;
  final double arrowSize;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildPath(rect);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path.shift(const Offset(0, 4)), shadowPaint);

    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  Path _buildPath(Rect rect) {
    final path = Path();
    final r = borderRadius;
    final arrowHalf = arrowSize * 0.7;

    // Adjust rect based on arrow position
    Rect cardRect;
    switch (position) {
      case TooltipPosition.top:
        cardRect = Rect.fromLTWH(0, 0, rect.width, rect.height - arrowSize);
      case TooltipPosition.bottom:
        cardRect = Rect.fromLTWH(0, arrowSize, rect.width, rect.height - arrowSize);
      case TooltipPosition.left:
        cardRect = Rect.fromLTWH(0, 0, rect.width - arrowSize, rect.height);
      case TooltipPosition.right:
        cardRect = Rect.fromLTWH(arrowSize, 0, rect.width - arrowSize, rect.height);
      case TooltipPosition.auto:
        cardRect = rect;
    }

    // Start path
    path.moveTo(cardRect.left + r, cardRect.top);

    // Top edge with arrow if position is bottom
    if (position == TooltipPosition.bottom) {
      final arrowX = arrowOffset.dx.clamp(r + arrowHalf, cardRect.width - r - arrowHalf);
      path.lineTo(arrowX - arrowHalf, cardRect.top);
      path.lineTo(arrowX, cardRect.top - arrowSize);
      path.lineTo(arrowX + arrowHalf, cardRect.top);
    }
    path.lineTo(cardRect.right - r, cardRect.top);

    // Top-right corner
    path.quadraticBezierTo(cardRect.right, cardRect.top, cardRect.right, cardRect.top + r);

    // Right edge with arrow if position is left
    if (position == TooltipPosition.left) {
      final arrowY = arrowOffset.dy.clamp(r + arrowHalf, cardRect.height - r - arrowHalf);
      path.lineTo(cardRect.right, arrowY - arrowHalf);
      path.lineTo(cardRect.right + arrowSize, arrowY);
      path.lineTo(cardRect.right, arrowY + arrowHalf);
    }
    path.lineTo(cardRect.right, cardRect.bottom - r);

    // Bottom-right corner
    path.quadraticBezierTo(cardRect.right, cardRect.bottom, cardRect.right - r, cardRect.bottom);

    // Bottom edge with arrow if position is top
    if (position == TooltipPosition.top) {
      final arrowX = arrowOffset.dx.clamp(r + arrowHalf, cardRect.width - r - arrowHalf);
      path.lineTo(arrowX + arrowHalf, cardRect.bottom);
      path.lineTo(arrowX, cardRect.bottom + arrowSize);
      path.lineTo(arrowX - arrowHalf, cardRect.bottom);
    }
    path.lineTo(cardRect.left + r, cardRect.bottom);

    // Bottom-left corner
    path.quadraticBezierTo(cardRect.left, cardRect.bottom, cardRect.left, cardRect.bottom - r);

    // Left edge with arrow if position is right
    if (position == TooltipPosition.right) {
      final arrowY = arrowOffset.dy.clamp(r + arrowHalf, cardRect.height - r - arrowHalf);
      path.lineTo(cardRect.left, arrowY + arrowHalf);
      path.lineTo(cardRect.left - arrowSize, arrowY);
      path.lineTo(cardRect.left, arrowY - arrowHalf);
    }
    path.lineTo(cardRect.left, cardRect.top + r);

    // Top-left corner
    path.quadraticBezierTo(cardRect.left, cardRect.top, cardRect.left + r, cardRect.top);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _TooltipPainter oldDelegate) =>
      backgroundColor != oldDelegate.backgroundColor ||
      borderColor != oldDelegate.borderColor ||
      position != oldDelegate.position ||
      arrowOffset != oldDelegate.arrowOffset ||
      arrowSize != oldDelegate.arrowSize;
}

/// Tooltip content widget.
class _TooltipContent extends StatelessWidget {
  const _TooltipContent({
    required this.data,
    required this.config,
    required this.theme,
  });

  final TooltipData data;
  final TooltipConfig config;
  final ChartThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Container(
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.xLabel != null) ...[
            Text(
              data.xLabel!,
              style: TextStyle(
                color: subtextColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
          ],
          ...data.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: entry.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.displayValue,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
