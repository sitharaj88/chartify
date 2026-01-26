import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/math/geometry/coordinate_transform.dart';
import 'chart_widget_mixin.dart';

/// Base configuration for circular charts (pie, donut, radial, etc.).
class CircularChartConfig {
  const CircularChartConfig({
    this.padding = const EdgeInsets.all(16),
    this.startAngle = -90,
    this.sweepAngle = 360,
    this.innerRadiusFraction = 0.0,
    this.outerRadiusFraction = 0.9,
    this.strokeWidth = 0,
    this.strokeColor,
    this.gapAngle = 0,
    this.centerOffset = Offset.zero,
  });

  /// Padding around the chart.
  final EdgeInsets padding;

  /// Start angle in degrees (0 = right, -90 = top).
  final double startAngle;

  /// Total sweep angle in degrees.
  final double sweepAngle;

  /// Inner radius as fraction of available radius (0 = pie, >0 = donut).
  final double innerRadiusFraction;

  /// Outer radius as fraction of available radius.
  final double outerRadiusFraction;

  /// Stroke width for segment borders.
  final double strokeWidth;

  /// Stroke color for segment borders.
  final Color? strokeColor;

  /// Gap angle between segments in degrees.
  final double gapAngle;

  /// Offset of the center from the geometric center.
  final Offset centerOffset;

  /// Whether this is a donut chart (has inner hole).
  bool get isDonut => innerRadiusFraction > 0;

  /// Creates a copy with updated values.
  CircularChartConfig copyWith({
    EdgeInsets? padding,
    double? startAngle,
    double? sweepAngle,
    double? innerRadiusFraction,
    double? outerRadiusFraction,
    double? strokeWidth,
    Color? strokeColor,
    double? gapAngle,
    Offset? centerOffset,
  }) => CircularChartConfig(
      padding: padding ?? this.padding,
      startAngle: startAngle ?? this.startAngle,
      sweepAngle: sweepAngle ?? this.sweepAngle,
      innerRadiusFraction: innerRadiusFraction ?? this.innerRadiusFraction,
      outerRadiusFraction: outerRadiusFraction ?? this.outerRadiusFraction,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      gapAngle: gapAngle ?? this.gapAngle,
      centerOffset: centerOffset ?? this.centerOffset,
    );
}

/// Data for a circular chart segment.
class CircularSegment {
  const CircularSegment({
    required this.value,
    required this.color,
    this.label,
    this.startAngle = 0,
    this.sweepAngle = 0,
    this.isExploded = false,
    this.explodeOffset = 10,
  });

  /// The value of this segment.
  final double value;

  /// The color of this segment.
  final Color color;

  /// Optional label.
  final String? label;

  /// Start angle in degrees.
  final double startAngle;

  /// Sweep angle in degrees.
  final double sweepAngle;

  /// Whether this segment is exploded.
  final bool isExploded;

  /// Offset when exploded.
  final double explodeOffset;

  /// The mid angle of this segment.
  double get midAngle => startAngle + sweepAngle / 2;

  /// Creates a copy with computed angles.
  CircularSegment withAngles({
    required double startAngle,
    required double sweepAngle,
  }) => CircularSegment(
      value: value,
      color: color,
      label: label,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      isExploded: isExploded,
      explodeOffset: explodeOffset,
    );
}

/// Base painter for circular charts.
abstract class CircularChartPainter extends BaseChartPainter {
  CircularChartPainter({
    required super.theme,
    required this.config, required this.segments, super.animationProgress,
  });

  final CircularChartConfig config;
  final List<CircularSegment> segments;

  // Computed values
  late Offset center;
  late double radius;
  late double innerRadius;
  late PolarCoordinateTransform polarTransform;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate center and radius
    final availableSize = Size(
      size.width - config.padding.horizontal,
      size.height - config.padding.vertical,
    );

    radius = math.min(availableSize.width, availableSize.height) / 2 * config.outerRadiusFraction;
    innerRadius = radius * config.innerRadiusFraction;

    center = Offset(
      config.padding.left + availableSize.width / 2 + config.centerOffset.dx,
      config.padding.top + availableSize.height / 2 + config.centerOffset.dy,
    );

    chartArea = Rect.fromCircle(center: center, radius: radius);

    // Create polar transform
    polarTransform = PolarCoordinateTransform(
      center: center,
      radius: radius,
      innerRadius: innerRadius,
      startAngle: config.startAngle,
    );

    // Compute segment angles
    final computedSegments = _computeSegmentAngles();

    // Paint segments
    for (var i = 0; i < computedSegments.length; i++) {
      paintSegment(canvas, computedSegments[i], i);
    }

    // Paint additional elements (labels, center text, etc.)
    paintOverlay(canvas, size, computedSegments);
  }

  /// Computes angles for each segment based on values.
  List<CircularSegment> _computeSegmentAngles() {
    if (segments.isEmpty) return [];

    final total = segments.fold<double>(0, (sum, s) => sum + s.value.abs());
    if (total == 0) return [];

    final totalGap = config.gapAngle * segments.length;
    final availableSweep = config.sweepAngle - totalGap;
    final animatedSweep = availableSweep * animationProgress;

    var currentAngle = config.startAngle;
    final computed = <CircularSegment>[];

    for (final segment in segments) {
      final fraction = segment.value.abs() / total;
      final sweepAngle = animatedSweep * fraction;

      computed.add(segment.withAngles(
        startAngle: currentAngle,
        sweepAngle: sweepAngle,
      ),);

      currentAngle += sweepAngle + config.gapAngle;
    }

    return computed;
  }

  /// Paints a single segment. Override for custom rendering.
  void paintSegment(Canvas canvas, CircularSegment segment, int index) {
    if (segment.sweepAngle <= 0) return;

    // Calculate center offset for exploded segments
    var segmentCenter = center;
    if (segment.isExploded) {
      final midAngleRad = segment.midAngle * math.pi / 180;
      segmentCenter = Offset(
        center.dx + segment.explodeOffset * math.cos(midAngleRad),
        center.dy + segment.explodeOffset * math.sin(midAngleRad),
      );
    }

    // Build segment path
    final path = _buildSegmentPath(segmentCenter, segment);

    // Draw fill
    final fillPaint = Paint()
      ..color = segment.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw stroke
    if (config.strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = config.strokeColor ?? const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth;
      canvas.drawPath(path, strokePaint);
    }
  }

  Path _buildSegmentPath(Offset segmentCenter, CircularSegment segment) {
    final startRad = segment.startAngle * math.pi / 180;
    final sweepRad = segment.sweepAngle * math.pi / 180;
    final endRad = startRad + sweepRad;

    final path = Path();

    if (innerRadius > 0) {
      // Donut shape
      final outerStart = Offset(
        segmentCenter.dx + radius * math.cos(startRad),
        segmentCenter.dy + radius * math.sin(startRad),
      );
      final outerEnd = Offset(
        segmentCenter.dx + radius * math.cos(endRad),
        segmentCenter.dy + radius * math.sin(endRad),
      );
      final innerStart = Offset(
        segmentCenter.dx + innerRadius * math.cos(startRad),
        segmentCenter.dy + innerRadius * math.sin(startRad),
      );
      final innerEnd = Offset(
        segmentCenter.dx + innerRadius * math.cos(endRad),
        segmentCenter.dy + innerRadius * math.sin(endRad),
      );

      path.moveTo(outerStart.dx, outerStart.dy);
      path.arcToPoint(
        outerEnd,
        radius: Radius.circular(radius),
        largeArc: segment.sweepAngle > 180,
      );
      path.lineTo(innerEnd.dx, innerEnd.dy);
      path.arcToPoint(
        innerStart,
        radius: Radius.circular(innerRadius),
        clockwise: false,
        largeArc: segment.sweepAngle > 180,
      );
      path.close();
    } else {
      // Pie shape
      path.moveTo(segmentCenter.dx, segmentCenter.dy);
      path.lineTo(
        segmentCenter.dx + radius * math.cos(startRad),
        segmentCenter.dy + radius * math.sin(startRad),
      );
      path.arcToPoint(
        Offset(
          segmentCenter.dx + radius * math.cos(endRad),
          segmentCenter.dy + radius * math.sin(endRad),
        ),
        radius: Radius.circular(radius),
        largeArc: segment.sweepAngle > 180,
      );
      path.close();
    }

    return path;
  }

  /// Paints overlay elements. Override for labels, center content, etc.
  void paintOverlay(Canvas canvas, Size size, List<CircularSegment> segments) {
    // Default implementation does nothing
  }

  /// Gets the segment at the given screen position.
  int? hitTestSegment(Offset position, List<CircularSegment> computedSegments) {
    // Check if within radius bounds
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < innerRadius || distance > radius) {
      return null;
    }

    // Calculate angle
    var angle = math.atan2(dy, dx) * 180 / math.pi;
    angle = angle - config.startAngle;
    while (angle < 0) {
      angle += 360;
    }
    while (angle >= 360) {
      angle -= 360;
    }

    // Find segment
    for (var i = 0; i < computedSegments.length; i++) {
      final segment = computedSegments[i];
      final start = segment.startAngle - config.startAngle;
      final end = start + segment.sweepAngle;

      if (angle >= start && angle < end) {
        return i;
      }
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant CircularChartPainter oldDelegate) => animationProgress != oldDelegate.animationProgress ||
        segments != oldDelegate.segments;
}

/// Builder for circular chart configurations.
class CircularChartBuilder {
  CircularChartBuilder();

  EdgeInsets _padding = const EdgeInsets.all(16);
  double _startAngle = -90;
  double _sweepAngle = 360;
  double _innerRadiusFraction = 0;
  double _outerRadiusFraction = 0.9;
  double _strokeWidth = 0;
  Color? _strokeColor;
  double _gapAngle = 0;

  /// Sets padding.
  CircularChartBuilder padding(EdgeInsets padding) {
    _padding = padding;
    return this;
  }

  /// Sets start angle.
  CircularChartBuilder startAngle(double angle) {
    _startAngle = angle;
    return this;
  }

  /// Sets sweep angle.
  CircularChartBuilder sweepAngle(double angle) {
    _sweepAngle = angle;
    return this;
  }

  /// Makes it a donut chart.
  CircularChartBuilder donut({double innerFraction = 0.5}) {
    _innerRadiusFraction = innerFraction;
    return this;
  }

  /// Sets outer radius fraction.
  CircularChartBuilder outerRadius(double fraction) {
    _outerRadiusFraction = fraction;
    return this;
  }

  /// Adds stroke.
  CircularChartBuilder stroke({double width = 2, Color? color}) {
    _strokeWidth = width;
    _strokeColor = color;
    return this;
  }

  /// Sets gap between segments.
  CircularChartBuilder gap(double angle) {
    _gapAngle = angle;
    return this;
  }

  /// Makes it a semi-circle (gauge style).
  CircularChartBuilder semiCircle() {
    _startAngle = -180;
    _sweepAngle = 180;
    return this;
  }

  /// Builds the configuration.
  CircularChartConfig build() => CircularChartConfig(
      padding: _padding,
      startAngle: _startAngle,
      sweepAngle: _sweepAngle,
      innerRadiusFraction: _innerRadiusFraction,
      outerRadiusFraction: _outerRadiusFraction,
      strokeWidth: _strokeWidth,
      strokeColor: _strokeColor,
      gapAngle: _gapAngle,
    );
}
