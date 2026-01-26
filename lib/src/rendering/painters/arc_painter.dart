import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../core/math/geometry/bounds_calculator.dart';
import '../../core/math/geometry/coordinate_transform.dart';
import 'series_painter.dart';

/// Configuration for arc/pie series rendering.
class ArcSeriesConfig extends SeriesConfig {
  const ArcSeriesConfig({
    super.visible = true,
    super.animationProgress = 1.0,
    this.colors = const [
      Color(0xFF2196F3),
      Color(0xFFF44336),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFFEB3B),
      Color(0xFF795548),
    ],
    this.startAngle = -90.0,
    this.sweepAngle = 360.0,
    this.innerRadiusFraction = 0.0,
    this.strokeWidth = 0.0,
    this.strokeColor,
    this.gapAngle = 0.0,
    this.cornerRadius = 0.0,
    this.explodeIndex,
    this.explodeOffset = 10.0,
    this.showLabels = false,
    this.labelStyle,
    this.labelPosition = ArcLabelPosition.outside,
    this.showValues = false,
    this.valueFormatter,
  });

  /// Colors for each segment.
  final List<Color> colors;

  /// Start angle in degrees (0 = right, -90 = top).
  final double startAngle;

  /// Total sweep angle in degrees.
  final double sweepAngle;

  /// Inner radius as fraction of outer radius (0 = pie, >0 = donut).
  final double innerRadiusFraction;

  /// Stroke width for segment borders.
  final double strokeWidth;

  /// Stroke color for segment borders.
  final Color? strokeColor;

  /// Gap angle between segments in degrees.
  final double gapAngle;

  /// Corner radius for segments.
  final double cornerRadius;

  /// Index of segment to explode (pull out).
  final int? explodeIndex;

  /// Offset for exploded segment.
  final double explodeOffset;

  /// Whether to show labels.
  final bool showLabels;

  /// Style for labels.
  final TextStyle? labelStyle;

  /// Position of labels.
  final ArcLabelPosition labelPosition;

  /// Whether to show values.
  final bool showValues;

  /// Custom value formatter.
  final String Function(double value, double percentage)? valueFormatter;

  /// Creates a copy with updated values.
  ArcSeriesConfig copyWith({
    bool? visible,
    double? animationProgress,
    List<Color>? colors,
    double? startAngle,
    double? sweepAngle,
    double? innerRadiusFraction,
    double? strokeWidth,
    Color? strokeColor,
    double? gapAngle,
    double? cornerRadius,
    int? explodeIndex,
    double? explodeOffset,
    bool? showLabels,
    TextStyle? labelStyle,
    ArcLabelPosition? labelPosition,
    bool? showValues,
    String Function(double value, double percentage)? valueFormatter,
  }) => ArcSeriesConfig(
      visible: visible ?? this.visible,
      animationProgress: animationProgress ?? this.animationProgress,
      colors: colors ?? this.colors,
      startAngle: startAngle ?? this.startAngle,
      sweepAngle: sweepAngle ?? this.sweepAngle,
      innerRadiusFraction: innerRadiusFraction ?? this.innerRadiusFraction,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      gapAngle: gapAngle ?? this.gapAngle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      explodeIndex: explodeIndex ?? this.explodeIndex,
      explodeOffset: explodeOffset ?? this.explodeOffset,
      showLabels: showLabels ?? this.showLabels,
      labelStyle: labelStyle ?? this.labelStyle,
      labelPosition: labelPosition ?? this.labelPosition,
      showValues: showValues ?? this.showValues,
      valueFormatter: valueFormatter ?? this.valueFormatter,
    );
}

/// Position for arc labels.
enum ArcLabelPosition {
  /// Inside the segment.
  inside,

  /// Outside the segment.
  outside,

  /// On a connector line.
  connector,
}

/// Data for a single arc segment.
class ArcData {
  const ArcData({
    required this.value,
    this.label,
    this.color,
  });

  /// Value for this segment.
  final double value;

  /// Optional label.
  final String? label;

  /// Optional color override.
  final Color? color;
}

/// Computed segment information.
class _ComputedSegment {
  _ComputedSegment({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.path,
    required this.center,
    required this.labelPosition,
    required this.value,
    required this.percentage,
  });

  final double startAngle;
  final double sweepAngle;
  final Color color;
  final Path path;
  final Offset center;
  final Offset labelPosition;
  final double value;
  final double percentage;
}

/// Painter for arc/pie/donut series.
///
/// Renders pie and donut charts with support for exploded segments,
/// labels, and various visual effects.
class ArcPainter extends SeriesPainter<ArcSeriesConfig>
    with AnimatedSeriesMixin {
  ArcPainter({
    required super.config,
    required super.seriesIndex,
    required this.data,
  });

  /// Data points for this series.
  List<ArcData> data;

  // Cached computations
  List<_ComputedSegment>? _cachedSegments;
  int? _cachedDataHash;
  Offset? _center;
  double? _radius;

  /// Updates the data.
  void updateData(List<ArcData> newData) {
    data = newData;
    invalidateCache();
  }

  @override
  void invalidateCache() {
    _cachedSegments = null;
    _cachedDataHash = null;
  }

  int _computeDataHash() {
    var hash = 0;
    for (final item in data) {
      hash = hash ^ item.value.hashCode;
    }
    return hash;
  }

  @override
  void render(
    Canvas canvas,
    Rect chartArea,
    CoordinateTransform transform,
  ) {
    if (!config.visible || data.isEmpty) return;

    // Compute center and radius
    _center = chartArea.center;
    _radius = math.min(chartArea.width, chartArea.height) / 2 * 0.9;

    // Compute segments
    final currentHash = _computeDataHash();
    if (_cachedDataHash != currentHash || _cachedSegments == null) {
      _cachedSegments = _computeSegments();
      _cachedDataHash = currentHash;
    }

    final segments = _cachedSegments!;
    if (segments.isEmpty) return;

    // Build spatial index for hit testing
    buildSpatialIndex(chartArea);
    _registerHitRegions(segments);

    // Draw segments
    for (var i = 0; i < segments.length; i++) {
      _drawSegment(canvas, segments[i], i);
    }

    // Draw labels
    if (config.showLabels || config.showValues) {
      _drawLabels(canvas, segments);
    }
  }

  List<_ComputedSegment> _computeSegments() {
    final segments = <_ComputedSegment>[];

    // Calculate total
    final total = data.fold<double>(0, (sum, item) => sum + item.value.abs());
    if (total == 0) return segments;

    // Calculate total gap
    final totalGap = config.gapAngle * data.length;
    final availableSweep = config.sweepAngle - totalGap;

    var currentAngle = config.startAngle;
    final animatedSweep = availableSweep * config.animationProgress;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final percentage = item.value.abs() / total;
      final sweepAngle = animatedSweep * percentage;

      if (sweepAngle <= 0) continue;

      // Handle explosion
      var segmentCenter = _center!;
      if (config.explodeIndex == i) {
        final midAngle = currentAngle + sweepAngle / 2;
        final explodeX =
            config.explodeOffset * math.cos(midAngle * math.pi / 180);
        final explodeY =
            config.explodeOffset * math.sin(midAngle * math.pi / 180);
        segmentCenter = Offset(
          _center!.dx + explodeX,
          _center!.dy + explodeY,
        );
      }

      // Build path
      final path = _buildSegmentPath(
        segmentCenter,
        currentAngle,
        sweepAngle,
      );

      // Calculate label position
      final labelPos = _calculateLabelPosition(
        segmentCenter,
        currentAngle,
        sweepAngle,
      );

      segments.add(_ComputedSegment(
        startAngle: currentAngle,
        sweepAngle: sweepAngle,
        color: _getSegmentColor(i),
        path: path,
        center: segmentCenter,
        labelPosition: labelPos,
        value: item.value,
        percentage: percentage * 100,
      ),);

      currentAngle += sweepAngle + config.gapAngle;
    }

    return segments;
  }

  Path _buildSegmentPath(Offset center, double startAngle, double sweepAngle) {
    final path = Path();
    final outerRadius = _radius!;
    final innerRadius = outerRadius * config.innerRadiusFraction;

    final startRad = startAngle * math.pi / 180;
    final sweepRad = sweepAngle * math.pi / 180;
    final endRad = startRad + sweepRad;

    if (innerRadius > 0) {
      // Donut shape
      final outerStart = Offset(
        center.dx + outerRadius * math.cos(startRad),
        center.dy + outerRadius * math.sin(startRad),
      );
      final innerStart = Offset(
        center.dx + innerRadius * math.cos(startRad),
        center.dy + innerRadius * math.sin(startRad),
      );
      final outerEnd = Offset(
        center.dx + outerRadius * math.cos(endRad),
        center.dy + outerRadius * math.sin(endRad),
      );
      final innerEnd = Offset(
        center.dx + innerRadius * math.cos(endRad),
        center.dy + innerRadius * math.sin(endRad),
      );

      path.moveTo(outerStart.dx, outerStart.dy);
      path.arcToPoint(
        outerEnd,
        radius: Radius.circular(outerRadius),
        clockwise: sweepAngle > 0,
        largeArc: sweepAngle.abs() > 180,
      );
      path.lineTo(innerEnd.dx, innerEnd.dy);
      path.arcToPoint(
        innerStart,
        radius: Radius.circular(innerRadius),
        clockwise: sweepAngle < 0,
        largeArc: sweepAngle.abs() > 180,
      );
      path.close();
    } else {
      // Pie shape
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + outerRadius * math.cos(startRad),
        center.dy + outerRadius * math.sin(startRad),
      );
      path.arcToPoint(
        Offset(
          center.dx + outerRadius * math.cos(endRad),
          center.dy + outerRadius * math.sin(endRad),
        ),
        radius: Radius.circular(outerRadius),
        clockwise: sweepAngle > 0,
        largeArc: sweepAngle.abs() > 180,
      );
      path.close();
    }

    return path;
  }

  Offset _calculateLabelPosition(
    Offset center,
    double startAngle,
    double sweepAngle,
  ) {
    final midAngle = (startAngle + sweepAngle / 2) * math.pi / 180;
    final outerRadius = _radius!;
    final innerRadius = outerRadius * config.innerRadiusFraction;

    double labelRadius;
    switch (config.labelPosition) {
      case ArcLabelPosition.inside:
        labelRadius = (outerRadius + innerRadius) / 2;
      case ArcLabelPosition.outside:
        labelRadius = outerRadius * 1.1;
      case ArcLabelPosition.connector:
        labelRadius = outerRadius * 1.3;
    }

    return Offset(
      center.dx + labelRadius * math.cos(midAngle),
      center.dy + labelRadius * math.sin(midAngle),
    );
  }

  void _registerHitRegions(List<_ComputedSegment> segments) {
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final item = data[i];

      final info = DataPointInfo(
        seriesIndex: seriesIndex,
        dataIndex: i,
        screenPosition: segment.labelPosition,
        dataX: i,
        dataY: item.value,
        label: item.label,
        color: segment.color,
        value: '${segment.percentage.toStringAsFixed(1)}%',
        metadata: {
          'value': item.value,
          'percentage': segment.percentage,
        },
      );

      registerHitRegion(info, segment.path.getBounds());
    }
  }

  void _drawSegment(Canvas canvas, _ComputedSegment segment, int index) {
    // Draw fill
    final fillPaint = Paint()
      ..color = segment.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(segment.path, fillPaint);

    // Draw stroke
    if (config.strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = config.strokeColor ?? const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth;

      canvas.drawPath(segment.path, strokePaint);
    }
  }

  void _drawLabels(Canvas canvas, List<_ComputedSegment> segments) {
    final style = config.labelStyle ??
        TextStyle(
          fontSize: 12,
          color: config.labelPosition == ArcLabelPosition.inside
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF333333),
        );

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final item = data[i];

      String labelText;
      if (config.valueFormatter != null) {
        labelText = config.valueFormatter!(item.value, segment.percentage);
      } else if (config.showValues && config.showLabels && item.label != null) {
        labelText = '${item.label}: ${segment.percentage.toStringAsFixed(1)}%';
      } else if (config.showValues) {
        labelText = '${segment.percentage.toStringAsFixed(1)}%';
      } else if (item.label != null) {
        labelText = item.label!;
      } else {
        continue;
      }

      final textPainter = TextPainter(
        text: TextSpan(text: labelText, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final pos = segment.labelPosition;
      final offset = Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height / 2,
      );

      // Draw connector line for outside labels
      if (config.labelPosition == ArcLabelPosition.connector) {
        _drawConnectorLine(canvas, segment, offset, textPainter.width);
      }

      textPainter.paint(canvas, offset);
    }
  }

  void _drawConnectorLine(
    Canvas canvas,
    _ComputedSegment segment,
    Offset labelOffset,
    double labelWidth,
  ) {
    final midAngle =
        (segment.startAngle + segment.sweepAngle / 2) * math.pi / 180;
    final outerRadius = _radius!;

    final edgePoint = Offset(
      segment.center.dx + outerRadius * math.cos(midAngle),
      segment.center.dy + outerRadius * math.sin(midAngle),
    );

    final elbowPoint = Offset(
      segment.center.dx + outerRadius * 1.1 * math.cos(midAngle),
      segment.center.dy + outerRadius * 1.1 * math.sin(midAngle),
    );

    final linePaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(edgePoint.dx, edgePoint.dy)
      ..lineTo(elbowPoint.dx, elbowPoint.dy)
      ..lineTo(
        labelOffset.dx + (midAngle > math.pi / 2 && midAngle < 3 * math.pi / 2
            ? 0
            : labelWidth),
        elbowPoint.dy,
      );

    canvas.drawPath(path, linePaint);
  }

  Color _getSegmentColor(int index) {
    if (data[index].color != null) {
      return data[index].color!;
    }
    return config.colors[index % config.colors.length];
  }

  @override
  (Bounds, Bounds) calculateBounds() {
    // Arc charts don't use traditional bounds
    return (const Bounds(min: 0, max: 1), const Bounds(min: 0, max: 1));
  }
}

/// Factory for creating arc painters.
class ArcPainterFactory {
  ArcPainterFactory._();

  /// Creates a basic pie chart painter.
  static ArcPainter pie({
    required int seriesIndex,
    required List<ArcData> data,
    List<Color>? colors,
  }) => ArcPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: ArcSeriesConfig(
        colors: colors ?? const [
          Color(0xFF2196F3),
          Color(0xFFF44336),
          Color(0xFF4CAF50),
          Color(0xFFFF9800),
          Color(0xFF9C27B0),
        ],
      ),
    );

  /// Creates a donut chart painter.
  static ArcPainter donut({
    required int seriesIndex,
    required List<ArcData> data,
    List<Color>? colors,
    double innerRadiusFraction = 0.5,
  }) => ArcPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: ArcSeriesConfig(
        colors: colors ?? const [
          Color(0xFF2196F3),
          Color(0xFFF44336),
          Color(0xFF4CAF50),
          Color(0xFFFF9800),
          Color(0xFF9C27B0),
        ],
        innerRadiusFraction: innerRadiusFraction,
      ),
    );

  /// Creates a semi-circle (gauge) painter.
  static ArcPainter gauge({
    required int seriesIndex,
    required List<ArcData> data,
    List<Color>? colors,
  }) => ArcPainter(
      seriesIndex: seriesIndex,
      data: data,
      config: ArcSeriesConfig(
        colors: colors ?? const [
          Color(0xFF2196F3),
          Color(0xFFF44336),
          Color(0xFF4CAF50),
        ],
        startAngle: -180,
        sweepAngle: 180,
        innerRadiusFraction: 0.6,
      ),
    );
}
