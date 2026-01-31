import 'package:flutter/material.dart';

import '../../core/base/chart_controller.dart';

/// Position of zoom controls within the chart.
enum ZoomControlPosition {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,
}

/// Orientation of zoom controls.
enum ZoomControlOrientation {
  /// Horizontal layout.
  horizontal,

  /// Vertical layout.
  vertical,
}

/// Style configuration for zoom controls.
@immutable
class ZoomControlStyle {
  /// Creates a zoom control style.
  const ZoomControlStyle({
    this.backgroundColor,
    this.iconColor,
    this.disabledIconColor,
    this.hoverColor,
    this.borderRadius = 8.0,
    this.iconSize = 20.0,
    this.buttonSize = 36.0,
    this.spacing = 4.0,
    this.padding = const EdgeInsets.all(8.0),
    this.elevation = 2.0,
    this.showBorder = false,
    this.borderColor,
  });

  /// Default light theme style.
  static const light = ZoomControlStyle(
    backgroundColor: Colors.white,
    iconColor: Color(0xFF424242),
    disabledIconColor: Color(0xFFBDBDBD),
  );

  /// Default dark theme style.
  static const dark = ZoomControlStyle(
    backgroundColor: Color(0xFF424242),
    iconColor: Colors.white,
    disabledIconColor: Color(0xFF757575),
  );

  /// Background color of the control container.
  final Color? backgroundColor;

  /// Color of the icons.
  final Color? iconColor;

  /// Color of disabled icons.
  final Color? disabledIconColor;

  /// Hover color for buttons.
  final Color? hoverColor;

  /// Border radius of the control container.
  final double borderRadius;

  /// Size of the icons.
  final double iconSize;

  /// Size of each button.
  final double buttonSize;

  /// Spacing between buttons.
  final double spacing;

  /// Padding around the control container.
  final EdgeInsets padding;

  /// Elevation of the control container.
  final double elevation;

  /// Whether to show a border.
  final bool showBorder;

  /// Border color (uses iconColor if null).
  final Color? borderColor;

  /// Creates a copy with the given values replaced.
  ZoomControlStyle copyWith({
    Color? backgroundColor,
    Color? iconColor,
    Color? disabledIconColor,
    Color? hoverColor,
    double? borderRadius,
    double? iconSize,
    double? buttonSize,
    double? spacing,
    EdgeInsets? padding,
    double? elevation,
    bool? showBorder,
    Color? borderColor,
  }) =>
      ZoomControlStyle(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        iconColor: iconColor ?? this.iconColor,
        disabledIconColor: disabledIconColor ?? this.disabledIconColor,
        hoverColor: hoverColor ?? this.hoverColor,
        borderRadius: borderRadius ?? this.borderRadius,
        iconSize: iconSize ?? this.iconSize,
        buttonSize: buttonSize ?? this.buttonSize,
        spacing: spacing ?? this.spacing,
        padding: padding ?? this.padding,
        elevation: elevation ?? this.elevation,
        showBorder: showBorder ?? this.showBorder,
        borderColor: borderColor ?? this.borderColor,
      );
}

/// A widget that provides zoom control buttons for a chart.
///
/// Displays buttons for zooming in, zooming out, and resetting the viewport.
/// Can optionally show a zoom slider.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     LineChart(data: lineData, controller: controller),
///     ChartZoomControls(
///       controller: controller,
///       position: ZoomControlPosition.topRight,
///     ),
///   ],
/// )
/// ```
class ChartZoomControls extends StatefulWidget {
  /// Creates chart zoom controls.
  const ChartZoomControls({
    required this.controller,
    super.key,
    this.position = ZoomControlPosition.topRight,
    this.orientation = ZoomControlOrientation.vertical,
    this.style,
    this.showZoomIn = true,
    this.showZoomOut = true,
    this.showReset = true,
    this.showSlider = false,
    this.showZoomLevel = false,
    this.zoomStep = 0.5,
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
    this.margin = const EdgeInsets.all(12.0),
    this.zoomInIcon = Icons.add,
    this.zoomOutIcon = Icons.remove,
    this.resetIcon = Icons.refresh,
    this.onZoomIn,
    this.onZoomOut,
    this.onReset,
  });

  /// The chart controller to control.
  final ChartController controller;

  /// Position of the controls within the chart.
  final ZoomControlPosition position;

  /// Orientation of the control buttons.
  final ZoomControlOrientation orientation;

  /// Style configuration.
  final ZoomControlStyle? style;

  /// Whether to show zoom in button.
  final bool showZoomIn;

  /// Whether to show zoom out button.
  final bool showZoomOut;

  /// Whether to show reset button.
  final bool showReset;

  /// Whether to show zoom slider.
  final bool showSlider;

  /// Whether to show current zoom level.
  final bool showZoomLevel;

  /// Zoom step for each button press.
  final double zoomStep;

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  /// Margin from chart edges.
  final EdgeInsets margin;

  /// Icon for zoom in button.
  final IconData zoomInIcon;

  /// Icon for zoom out button.
  final IconData zoomOutIcon;

  /// Icon for reset button.
  final IconData resetIcon;

  /// Callback when zoom in is pressed.
  final VoidCallback? onZoomIn;

  /// Callback when zoom out is pressed.
  final VoidCallback? onZoomOut;

  /// Callback when reset is pressed.
  final VoidCallback? onReset;

  @override
  State<ChartZoomControls> createState() => _ChartZoomControlsState();
}

class _ChartZoomControlsState extends State<ChartZoomControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ChartZoomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  ZoomControlStyle get _effectiveStyle {
    if (widget.style != null) return widget.style!;

    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ZoomControlStyle.dark
        : ZoomControlStyle.light;
  }

  bool get _canZoomIn {
    return widget.controller.viewport.scaleX < widget.maxZoom;
  }

  bool get _canZoomOut {
    return widget.controller.viewport.scaleX > widget.minZoom;
  }

  bool get _canReset {
    final viewport = widget.controller.viewport;
    return viewport.scaleX != 1.0 ||
        viewport.scaleY != 1.0 ||
        viewport.translateX != 0.0 ||
        viewport.translateY != 0.0;
  }

  void _handleZoomIn() {
    if (!_canZoomIn) return;

    widget.onZoomIn?.call();

    // Zoom around center
    final currentScale = widget.controller.viewport.scaleX;
    final targetScale = (currentScale + widget.zoomStep).clamp(
      widget.minZoom,
      widget.maxZoom,
    );

    widget.controller.animateZoom(
      targetScale,
      Offset.zero, // Will be adjusted by controller
    );
  }

  void _handleZoomOut() {
    if (!_canZoomOut) return;

    widget.onZoomOut?.call();

    final currentScale = widget.controller.viewport.scaleX;
    final targetScale = (currentScale - widget.zoomStep).clamp(
      widget.minZoom,
      widget.maxZoom,
    );

    widget.controller.animateZoom(
      targetScale,
      Offset.zero,
    );
  }

  void _handleReset() {
    widget.onReset?.call();
    widget.controller.animateReset();
  }

  void _handleSliderChanged(double value) {
    widget.controller.animateZoom(value, Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final style = _effectiveStyle;

    final controls = _buildControls(style);

    return Positioned(
      top: _getTopPosition(),
      bottom: _getBottomPosition(),
      left: _getLeftPosition(),
      right: _getRightPosition(),
      child: Material(
        elevation: style.elevation,
        borderRadius: BorderRadius.circular(style.borderRadius),
        color: style.backgroundColor,
        child: Container(
          padding: style.padding,
          decoration: style.showBorder
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(style.borderRadius),
                  border: Border.all(
                    color: style.borderColor ?? style.iconColor ?? Colors.grey,
                  ),
                )
              : null,
          child: controls,
        ),
      ),
    );
  }

  Widget _buildControls(ZoomControlStyle style) {
    final buttons = <Widget>[];

    if (widget.showZoomIn) {
      buttons.add(_buildButton(
        icon: widget.zoomInIcon,
        onPressed: _canZoomIn ? _handleZoomIn : null,
        style: style,
        tooltip: 'Zoom in',
      ));
    }

    if (widget.showZoomOut) {
      buttons.add(_buildButton(
        icon: widget.zoomOutIcon,
        onPressed: _canZoomOut ? _handleZoomOut : null,
        style: style,
        tooltip: 'Zoom out',
      ));
    }

    if (widget.showReset) {
      buttons.add(_buildButton(
        icon: widget.resetIcon,
        onPressed: _canReset ? _handleReset : null,
        style: style,
        tooltip: 'Reset zoom',
      ));
    }

    if (widget.showZoomLevel) {
      final zoomPercent = (widget.controller.viewport.scaleX * 100).round();
      buttons.add(
        SizedBox(
          width: style.buttonSize,
          height: style.buttonSize,
          child: Center(
            child: Text(
              '$zoomPercent%',
              style: TextStyle(
                fontSize: 10,
                color: style.iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.showSlider) {
      buttons.add(_buildSlider(style));
    }

    if (widget.orientation == ZoomControlOrientation.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: _addSpacing(buttons, style.spacing),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _addSpacing(buttons, style.spacing),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(SizedBox(width: spacing, height: spacing));
      }
    }
    return result;
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ZoomControlStyle style,
    required String tooltip,
  }) {
    final isDisabled = onPressed == null;
    final iconColor = isDisabled ? style.disabledIconColor : style.iconColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(style.borderRadius / 2),
        hoverColor: style.hoverColor ?? style.iconColor?.withValues(alpha: 0.1),
        child: SizedBox(
          width: style.buttonSize,
          height: style.buttonSize,
          child: Icon(
            icon,
            size: style.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(ZoomControlStyle style) {
    final currentScale = widget.controller.viewport.scaleX;

    if (widget.orientation == ZoomControlOrientation.horizontal) {
      return SizedBox(
        width: 100,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: style.iconColor,
            inactiveTrackColor: style.iconColor?.withValues(alpha: 0.3),
            thumbColor: style.iconColor,
          ),
          child: Slider(
            value: currentScale.clamp(widget.minZoom, widget.maxZoom),
            min: widget.minZoom,
            max: widget.maxZoom,
            onChanged: _handleSliderChanged,
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 100,
        child: RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: style.iconColor,
              inactiveTrackColor: style.iconColor?.withValues(alpha: 0.3),
              thumbColor: style.iconColor,
            ),
            child: Slider(
              value: currentScale.clamp(widget.minZoom, widget.maxZoom),
              min: widget.minZoom,
              max: widget.maxZoom,
              onChanged: _handleSliderChanged,
            ),
          ),
        ),
      );
    }
  }

  double? _getTopPosition() {
    switch (widget.position) {
      case ZoomControlPosition.topLeft:
      case ZoomControlPosition.topRight:
        return widget.margin.top;
      case ZoomControlPosition.bottomLeft:
      case ZoomControlPosition.bottomRight:
        return null;
    }
  }

  double? _getBottomPosition() {
    switch (widget.position) {
      case ZoomControlPosition.topLeft:
      case ZoomControlPosition.topRight:
        return null;
      case ZoomControlPosition.bottomLeft:
      case ZoomControlPosition.bottomRight:
        return widget.margin.bottom;
    }
  }

  double? _getLeftPosition() {
    switch (widget.position) {
      case ZoomControlPosition.topLeft:
      case ZoomControlPosition.bottomLeft:
        return widget.margin.left;
      case ZoomControlPosition.topRight:
      case ZoomControlPosition.bottomRight:
        return null;
    }
  }

  double? _getRightPosition() {
    switch (widget.position) {
      case ZoomControlPosition.topLeft:
      case ZoomControlPosition.bottomLeft:
        return null;
      case ZoomControlPosition.topRight:
      case ZoomControlPosition.bottomRight:
        return widget.margin.right;
    }
  }
}

/// A compact mini zoom control with just +/- buttons.
class MiniZoomControls extends StatelessWidget {
  /// Creates mini zoom controls.
  const MiniZoomControls({
    required this.controller,
    super.key,
    this.size = 28.0,
    this.iconSize = 16.0,
    this.backgroundColor,
    this.iconColor,
    this.zoomStep = 0.5,
    this.minZoom = 0.5,
    this.maxZoom = 10.0,
  });

  /// The chart controller.
  final ChartController controller;

  /// Size of each button.
  final double size;

  /// Size of the icons.
  final double iconSize;

  /// Background color.
  final Color? backgroundColor;

  /// Icon color.
  final Color? iconColor;

  /// Zoom step per click.
  final double zoomStep;

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.cardColor;
    final fgColor = iconColor ?? theme.iconTheme.color ?? Colors.grey;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scale = controller.viewport.scaleX;
        final canZoomIn = scale < maxZoom;
        final canZoomOut = scale > minZoom;

        return Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(size / 2),
          color: bgColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniButton(
                icon: Icons.remove,
                size: size,
                iconSize: iconSize,
                color: canZoomOut ? fgColor : fgColor.withValues(alpha: 0.3),
                onTap: canZoomOut
                    ? () => controller.animateZoom(
                          (scale - zoomStep).clamp(minZoom, maxZoom),
                          Offset.zero,
                        )
                    : null,
              ),
              Container(
                width: 1,
                height: size * 0.6,
                color: fgColor.withValues(alpha: 0.2),
              ),
              _MiniButton(
                icon: Icons.add,
                size: size,
                iconSize: iconSize,
                color: canZoomIn ? fgColor : fgColor.withValues(alpha: 0.3),
                onTap: canZoomIn
                    ? () => controller.animateZoom(
                          (scale + zoomStep).clamp(minZoom, maxZoom),
                          Offset.zero,
                        )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
