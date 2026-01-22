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
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeOutCubic,
    this.hideDelay = const Duration(milliseconds: 200),
    this.builder,
    this.decoration,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.showIndicatorLine = true,
    this.showIndicatorDot = true,
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

/// Smooth tooltip overlay using ListenableBuilder to avoid rebuilds.
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

class _ChartTooltipOverlayState extends State<ChartTooltipOverlay> {
  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        // Use ListenableBuilder to only rebuild the tooltip, not the chart
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final hoveredPoint = widget.controller.hoveredPoint;
            if (hoveredPoint == null) {
              return const SizedBox.shrink();
            }

            final tooltipData = _buildTooltipData(hoveredPoint);
            if (tooltipData == null) {
              return const SizedBox.shrink();
            }

            return _SmoothTooltip(
              key: const ValueKey('tooltip'),
              data: tooltipData,
              config: widget.config,
              theme: widget.theme,
              chartArea: widget.chartArea,
            );
          },
        ),
      ],
    );
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
}

/// The actual tooltip widget with smooth animations.
class _SmoothTooltip extends StatefulWidget {
  const _SmoothTooltip({
    super.key,
    required this.data,
    required this.config,
    required this.theme,
    required this.chartArea,
  });

  final TooltipData data;
  final TooltipConfig config;
  final ChartThemeData theme;
  final Rect chartArea;

  @override
  State<_SmoothTooltip> createState() => _SmoothTooltipState();
}

class _SmoothTooltipState extends State<_SmoothTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final position = widget.data.position;
    final entries = widget.data.entries;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Indicator line - use TweenAnimationBuilder for smooth movement
          if (widget.config.showIndicatorLine)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: position.dx, end: position.dx),
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              builder: (context, x, _) {
                return Positioned(
                  left: x,
                  top: widget.chartArea.top,
                  bottom: MediaQuery.of(context).size.height - widget.chartArea.bottom,
                  child: Container(
                    width: widget.config.indicatorLineWidth,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                );
              },
            ),

          // Indicator dot with glow
          if (widget.config.showIndicatorDot && entries.isNotEmpty)
            TweenAnimationBuilder<Offset>(
              tween: Tween(begin: position, end: position),
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              builder: (context, pos, _) {
                return Positioned(
                  left: pos.dx - 16,
                  top: pos.dy - 16,
                  child: _IndicatorDot(
                    color: entries.first.color,
                    size: widget.config.indicatorDotSize,
                    isDark: isDark,
                  ),
                );
              },
            ),

          // Tooltip card - smoothly animated position
          TweenAnimationBuilder<Offset>(
            tween: Tween(begin: position, end: position),
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOut,
            builder: (context, pos, child) {
              final tooltipY = _calculateTooltipY(pos);
              final tooltipX = pos.dx - 70 + widget.config.offset.dx;

              return Positioned(
                left: tooltipX,
                top: tooltipY,
                child: child!,
              );
            },
            child: _TooltipCard(
              data: widget.data,
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
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
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
