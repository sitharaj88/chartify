import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    this.offset = const Offset(0, -12),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.hideDelay = const Duration(milliseconds: 100),
    this.builder,
    this.decoration,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.showIndicatorLine = false,
    this.showIndicatorDot = false,
    this.indicatorLineWidth = 1.0,
    this.indicatorDotSize = 10.0,
    this.screenMargin = const EdgeInsets.all(8),
    this.showArrow = true,
    this.arrowSize = 8.0,
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
  /// Minimum margin from screen edges
  final EdgeInsets screenMargin;
  /// Whether to show arrow pointing to data point
  final bool showArrow;
  /// Size of the arrow
  final double arrowSize;

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
    );
  }
}

enum TooltipPosition { auto, top, bottom, left, right }

/// Result of tooltip positioning calculation
@immutable
class TooltipPositionResult {
  const TooltipPositionResult({
    required this.position,
    required this.resolvedPosition,
    required this.arrowPosition,
    required this.arrowAlignment,
  });

  /// The calculated position for the tooltip
  final Offset position;
  /// The resolved position direction (top, bottom, left, right)
  final TooltipPosition resolvedPosition;
  /// Position for the arrow relative to tooltip
  final double arrowPosition;
  /// Alignment of arrow (0.0 = start, 0.5 = center, 1.0 = end)
  final double arrowAlignment;
}

/// Smart tooltip positioner with edge detection and auto-flip.
class TooltipPositioner {
  /// Default tooltip dimensions for calculation
  static const double defaultTooltipWidth = 140.0;
  static const double defaultTooltipHeight = 70.0;
  static const double tooltipOffset = 12.0;
  static const double arrowSize = 8.0;

  /// Calculate optimal tooltip position with smart edge detection.
  ///
  /// Priority order:
  /// 1. Above data point (preferred)
  /// 2. Below data point (if above overflows)
  /// 3. Right of data point (if vertical overflows)
  /// 4. Left of data point (if right overflows)
  /// 5. Clamped to nearest valid position (last resort)
  static TooltipPositionResult calculatePosition({
    required Offset dataPoint,
    required Size tooltipSize,
    required Size screenSize,
    required Rect chartArea,
    EdgeInsets margin = const EdgeInsets.all(8),
    TooltipPosition preferredPosition = TooltipPosition.auto,
    Offset offset = Offset.zero,
  }) {
    final safeArea = Rect.fromLTRB(
      margin.left,
      margin.top,
      screenSize.width - margin.right,
      screenSize.height - margin.bottom,
    );

    // Calculate available space in each direction
    final spaceAbove = dataPoint.dy - chartArea.top;
    final spaceBelow = chartArea.bottom - dataPoint.dy;
    final spaceLeft = dataPoint.dx - chartArea.left;
    final spaceRight = chartArea.right - dataPoint.dx;

    // Determine best position based on available space
    TooltipPosition resolvedPosition;
    if (preferredPosition != TooltipPosition.auto) {
      resolvedPosition = preferredPosition;
    } else {
      // Auto-detect best position
      if (_fitsAbove(dataPoint, tooltipSize, safeArea, offset)) {
        resolvedPosition = TooltipPosition.top;
      } else if (_fitsBelow(dataPoint, tooltipSize, safeArea, offset)) {
        resolvedPosition = TooltipPosition.bottom;
      } else if (spaceRight >= spaceLeft &&
                 _fitsRight(dataPoint, tooltipSize, safeArea, offset)) {
        resolvedPosition = TooltipPosition.right;
      } else if (_fitsLeft(dataPoint, tooltipSize, safeArea, offset)) {
        resolvedPosition = TooltipPosition.left;
      } else {
        // Default to top if nothing fits well, will be clamped
        resolvedPosition = spaceAbove >= spaceBelow
            ? TooltipPosition.top
            : TooltipPosition.bottom;
      }
    }

    // Calculate position based on resolved direction
    Offset tooltipPosition;
    double arrowAlignment = 0.5; // Center by default

    switch (resolvedPosition) {
      case TooltipPosition.top:
        tooltipPosition = Offset(
          dataPoint.dx - tooltipSize.width / 2,
          dataPoint.dy - tooltipSize.height - tooltipOffset - arrowSize + offset.dy,
        );
        break;
      case TooltipPosition.bottom:
        tooltipPosition = Offset(
          dataPoint.dx - tooltipSize.width / 2,
          dataPoint.dy + tooltipOffset + arrowSize - offset.dy,
        );
        break;
      case TooltipPosition.left:
        tooltipPosition = Offset(
          dataPoint.dx - tooltipSize.width - tooltipOffset - arrowSize + offset.dx,
          dataPoint.dy - tooltipSize.height / 2,
        );
        break;
      case TooltipPosition.right:
        tooltipPosition = Offset(
          dataPoint.dx + tooltipOffset + arrowSize - offset.dx,
          dataPoint.dy - tooltipSize.height / 2,
        );
        break;
      case TooltipPosition.auto:
        // Should not reach here, but fallback to top
        tooltipPosition = Offset(
          dataPoint.dx - tooltipSize.width / 2,
          dataPoint.dy - tooltipSize.height - tooltipOffset - arrowSize,
        );
        resolvedPosition = TooltipPosition.top;
    }

    // Clamp to safe area and calculate arrow offset
    final clampedPosition = _clampToSafeArea(
      tooltipPosition,
      tooltipSize,
      safeArea,
    );

    // Calculate arrow alignment based on how much tooltip was shifted
    if (resolvedPosition == TooltipPosition.top ||
        resolvedPosition == TooltipPosition.bottom) {
      final shift = clampedPosition.dx - tooltipPosition.dx;
      final tooltipCenter = tooltipSize.width / 2;
      arrowAlignment = ((tooltipCenter - shift) / tooltipSize.width)
          .clamp(0.15, 0.85);
    } else {
      final shift = clampedPosition.dy - tooltipPosition.dy;
      final tooltipCenter = tooltipSize.height / 2;
      arrowAlignment = ((tooltipCenter - shift) / tooltipSize.height)
          .clamp(0.15, 0.85);
    }

    // Calculate arrow position relative to data point
    final arrowPos = _calculateArrowPosition(
      dataPoint,
      clampedPosition,
      tooltipSize,
      resolvedPosition,
    );

    return TooltipPositionResult(
      position: clampedPosition,
      resolvedPosition: resolvedPosition,
      arrowPosition: arrowPos,
      arrowAlignment: arrowAlignment,
    );
  }

  static bool _fitsAbove(
    Offset dataPoint,
    Size tooltipSize,
    Rect safeArea,
    Offset offset,
  ) {
    final neededHeight = tooltipSize.height + tooltipOffset + arrowSize;
    return dataPoint.dy - neededHeight + offset.dy >= safeArea.top;
  }

  static bool _fitsBelow(
    Offset dataPoint,
    Size tooltipSize,
    Rect safeArea,
    Offset offset,
  ) {
    final neededHeight = tooltipSize.height + tooltipOffset + arrowSize;
    return dataPoint.dy + neededHeight - offset.dy <= safeArea.bottom;
  }

  static bool _fitsLeft(
    Offset dataPoint,
    Size tooltipSize,
    Rect safeArea,
    Offset offset,
  ) {
    final neededWidth = tooltipSize.width + tooltipOffset + arrowSize;
    return dataPoint.dx - neededWidth + offset.dx >= safeArea.left;
  }

  static bool _fitsRight(
    Offset dataPoint,
    Size tooltipSize,
    Rect safeArea,
    Offset offset,
  ) {
    final neededWidth = tooltipSize.width + tooltipOffset + arrowSize;
    return dataPoint.dx + neededWidth - offset.dx <= safeArea.right;
  }

  static Offset _clampToSafeArea(
    Offset position,
    Size tooltipSize,
    Rect safeArea,
  ) {
    return Offset(
      position.dx.clamp(
        safeArea.left,
        safeArea.right - tooltipSize.width,
      ),
      position.dy.clamp(
        safeArea.top,
        safeArea.bottom - tooltipSize.height,
      ),
    );
  }

  static double _calculateArrowPosition(
    Offset dataPoint,
    Offset tooltipPosition,
    Size tooltipSize,
    TooltipPosition direction,
  ) {
    switch (direction) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        // Horizontal arrow position
        final relativeX = dataPoint.dx - tooltipPosition.dx;
        return relativeX.clamp(12.0, tooltipSize.width - 12.0);
      case TooltipPosition.left:
      case TooltipPosition.right:
        // Vertical arrow position
        final relativeY = dataPoint.dy - tooltipPosition.dy;
        return relativeY.clamp(12.0, tooltipSize.height - 12.0);
      case TooltipPosition.auto:
        return tooltipSize.width / 2;
    }
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
      return value.toStringAsFixed(2);
    }
    if (value is DateTime) {
      return '${value.month}/${value.day}/${value.year}';
    }
    return value.toString();
  }
}

/// Smooth tooltip overlay with smart positioning and proper animation handling.
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
  late AnimationController _fadeController;
  late AnimationController _positionController;

  // Current animated values
  late Animation<double> _fadeAnimation;
  Offset _startPosition = Offset.zero;
  Offset _currentPosition = Offset.zero;
  Offset _targetPosition = Offset.zero;

  // State tracking
  TooltipData? _currentData;
  bool _isVisible = false;
  TooltipPositionResult? _positionResult;
  Size _tooltipSize = const Size(140, 70);
  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.config.animationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: widget.config.animationCurve,
    );

    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _positionController.addListener(_onPositionAnimationTick);

    // Listen to controller changes
    widget.controller.addListener(_onControllerChanged);
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
    widget.controller.removeListener(_onControllerChanged);
    _fadeController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final hoveredPoint = widget.controller.hoveredPoint;

    if (hoveredPoint != null) {
      final tooltipData = _buildTooltipData(hoveredPoint);
      if (tooltipData != null) {
        _showTooltip(tooltipData);
      }
    } else {
      _hideTooltip();
    }
  }

  void _showTooltip(TooltipData data) {
    final newPosition = data.position;

    setState(() {
      _currentData = data;

      if (!_isVisible) {
        // First show - jump to position immediately
        _startPosition = newPosition;
        _currentPosition = newPosition;
        _targetPosition = newPosition;
        _isVisible = true;
        _fadeController.forward();
      } else {
        // Already visible - animate to new position
        _startPosition = _currentPosition;
        _targetPosition = newPosition;
        _positionController.forward(from: 0);
      }
    });

    // Measure tooltip after first frame to get actual size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTooltipSize();
    });
  }

  void _measureTooltipSize() {
    final renderBox = _tooltipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      if (size != _tooltipSize) {
        setState(() {
          _tooltipSize = size;
        });
      }
    }
  }

  void _hideTooltip() {
    if (_isVisible) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _currentData = null;
            _positionResult = null;
          });
        }
      });
    }
  }

  void _onPositionAnimationTick() {
    if (!mounted) return;

    final t = Curves.easeOut.transform(_positionController.value);
    setState(() {
      _currentPosition = Offset.lerp(_startPosition, _targetPosition, t)!;
    });
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
      return '${value.month}/${value.day}/${value.year}';
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
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
            if (_isVisible && _currentData != null)
              _buildTooltipWidget(screenSize),
          ],
        );
      },
    );
  }

  Widget _buildTooltipWidget(Size screenSize) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final entries = _currentData!.entries;

    // Calculate smart position
    _positionResult = TooltipPositioner.calculatePosition(
      dataPoint: _currentPosition,
      tooltipSize: _tooltipSize,
      screenSize: screenSize,
      chartArea: widget.chartArea,
      margin: widget.config.screenMargin,
      preferredPosition: widget.config.position,
      offset: widget.config.offset,
    );

    final tooltipPosition = _positionResult!.position;
    final resolvedPosition = _positionResult!.resolvedPosition;
    final arrowAlignment = _positionResult!.arrowAlignment;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Indicator line
          if (widget.config.showIndicatorLine)
            Positioned(
              left: _currentPosition.dx - widget.config.indicatorLineWidth / 2,
              top: widget.chartArea.top,
              width: widget.config.indicatorLineWidth,
              height: widget.chartArea.height,
              child: Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),

          // Indicator dot with glow
          if (widget.config.showIndicatorDot && entries.isNotEmpty)
            Positioned(
              left: _currentPosition.dx - 16,
              top: _currentPosition.dy - 16,
              child: _IndicatorDot(
                color: entries.first.color,
                size: widget.config.indicatorDotSize,
                isDark: isDark,
              ),
            ),

          // Tooltip card with arrow
          Positioned(
            left: tooltipPosition.dx,
            top: tooltipPosition.dy,
            child: _TooltipCardWithArrow(
              key: _tooltipKey,
              data: _currentData!,
              config: widget.config,
              theme: widget.theme,
              resolvedPosition: resolvedPosition,
              arrowAlignment: arrowAlignment,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing indicator dot.
class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({
    required this.color,
    required this.size,
    required this.isDark,
  });

  final Color color;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: size + 14,
              height: size + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
            ),
            // White/dark border
            Container(
              width: size + 6,
              height: size + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Colored center
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tooltip card widget with arrow pointer.
class _TooltipCardWithArrow extends StatelessWidget {
  const _TooltipCardWithArrow({
    super.key,
    required this.data,
    required this.config,
    required this.theme,
    required this.resolvedPosition,
    required this.arrowAlignment,
  });

  final TooltipData data;
  final TooltipConfig config;
  final ChartThemeData theme;
  final TooltipPosition resolvedPosition;
  final double arrowAlignment;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arrow on top
        if (config.showArrow && resolvedPosition == TooltipPosition.bottom)
          _buildArrow(bgColor, isTop: true),

        // Main tooltip content
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arrow on left
            if (config.showArrow && resolvedPosition == TooltipPosition.right)
              _buildArrow(bgColor, isLeft: true),

            // Tooltip card
            _TooltipCard(
              data: data,
              config: config,
              theme: theme,
            ),

            // Arrow on right
            if (config.showArrow && resolvedPosition == TooltipPosition.left)
              _buildArrow(bgColor, isRight: true),
          ],
        ),

        // Arrow on bottom
        if (config.showArrow && resolvedPosition == TooltipPosition.top)
          _buildArrow(bgColor, isBottom: true),
      ],
    );
  }

  Widget _buildArrow(
    Color color, {
    bool isTop = false,
    bool isBottom = false,
    bool isLeft = false,
    bool isRight = false,
  }) {
    final size = config.arrowSize;

    if (isTop || isBottom) {
      return Padding(
        padding: EdgeInsets.only(
          left: math.max(0, arrowAlignment * 100 - size),
        ),
        child: CustomPaint(
          size: Size(size * 2, size),
          painter: _ArrowPainter(
            color: color,
            direction: isTop ? AxisDirection.up : AxisDirection.down,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: math.max(0, arrowAlignment * 50 - size),
      ),
      child: CustomPaint(
        size: Size(size, size * 2),
        painter: _ArrowPainter(
          color: color,
          direction: isLeft ? AxisDirection.left : AxisDirection.right,
        ),
      ),
    );
  }
}

/// Arrow painter for tooltip
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.color,
    required this.direction,
  });

  final Color color;
  final AxisDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case AxisDirection.up:
        path.moveTo(0, size.height);
        path.lineTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        break;
      case AxisDirection.down:
        path.moveTo(0, 0);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(size.width, 0);
        break;
      case AxisDirection.left:
        path.moveTo(size.width, 0);
        path.lineTo(0, size.height / 2);
        path.lineTo(size.width, size.height);
        break;
      case AxisDirection.right:
        path.moveTo(0, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(0, size.height);
        break;
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      color != oldDelegate.color || direction != oldDelegate.direction;
}

/// Tooltip card widget.
class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
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

    final decoration = config.decoration ??
        BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        );

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF888888);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
        decoration: decoration,
        padding: config.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.xLabel != null) ...[
              Text(
                data.xLabel!,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
            ],
            ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          entry.label,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.displayValue,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
