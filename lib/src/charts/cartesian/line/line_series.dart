import 'dart:ui' show Color, StrokeCap, StrokeJoin;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Gradient;

import '../../../core/base/series.dart';
import '../../../core/data/data_point.dart';

/// A series for line charts.
///
/// Example:
/// ```dart
/// LineSeries(
///   name: 'Revenue',
///   data: [
///     DataPoint(x: 0, y: 10),
///     DataPoint(x: 1, y: 25),
///     DataPoint(x: 2, y: 15),
///   ],
///   color: Colors.blue,
///   strokeWidth: 2.5,
///   curved: true,
/// )
/// ```
@immutable
class LineSeries<X, Y extends num> extends CartesianSeries<DataPoint<X, Y>> {
  /// Creates a line series.
  const LineSeries({
    required super.data,
    super.name,
    super.color,
    super.visible,
    super.xAxisId,
    super.yAxisId,
    this.strokeWidth = 2.0,
    this.curved = false,
    this.curveType = CurveType.monotone,
    this.tension = 0.4,
    this.showMarkers = false,
    this.markerSize = 6.0,
    this.markerShape = MarkerShape.circle,
    this.fillArea = false,
    this.areaOpacity = 0.3,
    this.areaGradient,
    this.dashPattern,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
  });

  /// The width of the line.
  final double strokeWidth;

  /// Whether to draw a curved line.
  final bool curved;

  /// The type of curve to use.
  final CurveType curveType;

  /// Tension for Bezier curves (0.0 to 1.0).
  final double tension;

  /// Whether to show markers at data points.
  final bool showMarkers;

  /// Size of the markers.
  final double markerSize;

  /// Shape of the markers.
  final MarkerShape markerShape;

  /// Whether to fill the area under the line.
  final bool fillArea;

  /// Opacity of the area fill (0.0 to 1.0).
  final double areaOpacity;

  /// Optional gradient for the area fill.
  final Gradient? areaGradient;

  /// Dash pattern for the line (null = solid).
  final List<double>? dashPattern;

  /// The stroke cap style.
  final StrokeCap strokeCap;

  /// The stroke join style.
  final StrokeJoin strokeJoin;

  @override
  LineSeries<X, Y> copyWith({
    List<DataPoint<X, Y>>? data,
    String? name,
    Color? color,
    bool? visible,
    String? xAxisId,
    String? yAxisId,
    double? strokeWidth,
    bool? curved,
    CurveType? curveType,
    double? tension,
    bool? showMarkers,
    double? markerSize,
    MarkerShape? markerShape,
    bool? fillArea,
    double? areaOpacity,
    Gradient? areaGradient,
    List<double>? dashPattern,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
  }) =>
      LineSeries<X, Y>(
        data: data ?? this.data,
        name: name ?? this.name,
        color: color ?? this.color,
        visible: visible ?? this.visible,
        xAxisId: xAxisId ?? this.xAxisId,
        yAxisId: yAxisId ?? this.yAxisId,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        curved: curved ?? this.curved,
        curveType: curveType ?? this.curveType,
        tension: tension ?? this.tension,
        showMarkers: showMarkers ?? this.showMarkers,
        markerSize: markerSize ?? this.markerSize,
        markerShape: markerShape ?? this.markerShape,
        fillArea: fillArea ?? this.fillArea,
        areaOpacity: areaOpacity ?? this.areaOpacity,
        areaGradient: areaGradient ?? this.areaGradient,
        dashPattern: dashPattern ?? this.dashPattern,
        strokeCap: strokeCap ?? this.strokeCap,
        strokeJoin: strokeJoin ?? this.strokeJoin,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is LineSeries<X, Y> &&
          strokeWidth == other.strokeWidth &&
          curved == other.curved &&
          curveType == other.curveType &&
          tension == other.tension &&
          showMarkers == other.showMarkers &&
          markerSize == other.markerSize &&
          markerShape == other.markerShape &&
          fillArea == other.fillArea &&
          areaOpacity == other.areaOpacity &&
          areaGradient == other.areaGradient &&
          listEquals(dashPattern, other.dashPattern) &&
          strokeCap == other.strokeCap &&
          strokeJoin == other.strokeJoin;

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        strokeWidth,
        curved,
        curveType,
        tension,
        showMarkers,
        markerSize,
        markerShape,
        fillArea,
        areaOpacity,
        areaGradient,
        dashPattern,
        strokeCap,
        strokeJoin,
      );
}

/// Types of curve interpolation.
enum CurveType {
  /// Monotone cubic interpolation (prevents overshooting).
  monotone,

  /// Catmull-Rom spline.
  catmullRom,

  /// Cardinal spline.
  cardinal,

  /// Natural cubic spline.
  natural,

  /// Simple quadratic Bezier.
  bezier,

  /// Step function (horizontal then vertical).
  stepBefore,

  /// Step function (vertical then horizontal).
  stepAfter,

  /// Step function (step in the middle).
  stepMiddle,
}

/// Shapes for data point markers.
enum MarkerShape {
  /// Circular marker.
  circle,

  /// Square marker.
  square,

  /// Diamond (rotated square) marker.
  diamond,

  /// Triangle marker.
  triangle,

  /// Inverted triangle marker.
  triangleDown,

  /// Cross (+) marker.
  cross,

  /// X marker.
  x,

  /// Star marker.
  star,
}
