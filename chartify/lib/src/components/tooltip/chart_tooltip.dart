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
    );
  }
}

enum TooltipPosition { auto, top, bottom, left, right }

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

/// Smooth tooltip overlay with proper animation handling.
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
  }

  void _hideTooltip() {
    if (_isVisible) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _currentData = null;
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_isVisible && _currentData != null)
          _buildTooltipWidget(),
      ],
    );
  }

  Widget _buildTooltipWidget() {
    final isDark = widget.theme.brightness == Brightness.dark;
    final entries = _currentData!.entries;

    // Calculate tooltip position
    final tooltipY = _calculateTooltipY(_currentPosition);
    final tooltipX = _currentPosition.dx - 70 + widget.config.offset.dx;

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

          // Tooltip card
          Positioned(
            left: tooltipX,
            top: tooltipY,
            child: _TooltipCard(
              data: _currentData!,
              config: widget.config,
              theme: widget.theme,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTooltipY(Offset position) {
    final preferredPosition = widget.config.position == TooltipPosition.auto
        ? (position.dy > widget.chartArea.center.dy
            ? TooltipPosition.top
            : TooltipPosition.bottom)
        : widget.config.position;

    switch (preferredPosition) {
      case TooltipPosition.top:
        return position.dy - 85 + widget.config.offset.dy;
      case TooltipPosition.bottom:
        return position.dy + 25 - widget.config.offset.dy;
      default:
        return position.dy - 45 + widget.config.offset.dy;
    }
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
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
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
