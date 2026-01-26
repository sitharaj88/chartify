import 'package:flutter/foundation.dart';

/// A generic data point representing a single value in a chart.
///
/// [X] is the type of the x-axis value (commonly [num], [DateTime], or [String]).
/// [Y] is the type of the y-axis value (commonly [num]).
///
/// Example:
/// ```dart
/// // Numeric data point
/// final point = DataPoint<double, double>(x: 1.0, y: 10.5);
///
/// // Time series data point
/// final timePoint = DataPoint<DateTime, double>(
///   x: DateTime.now(),
///   y: 42.0,
/// );
///
/// // Categorical data point
/// final categoryPoint = DataPoint<String, int>(
///   x: 'January',
///   y: 100,
/// );
/// ```
@immutable
class DataPoint<X, Y> {
  /// Creates a data point with the given [x] and [y] values.
  const DataPoint({
    required this.x,
    required this.y,
    this.metadata,
  });

  /// The x-axis value of this data point.
  final X x;

  /// The y-axis value of this data point.
  final Y y;

  /// Optional metadata associated with this data point.
  ///
  /// Can be used to store additional information such as:
  /// - Labels or tooltips
  /// - Colors or styles
  /// - Original data references
  final Map<String, dynamic>? metadata;

  /// Creates a copy of this data point with the given values replaced.
  DataPoint<X, Y> copyWith({
    X? x,
    Y? y,
    Map<String, dynamic>? metadata,
  }) =>
      DataPoint<X, Y>(
        x: x ?? this.x,
        y: y ?? this.y,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPoint<X, Y> &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(x, y, metadata);

  @override
  String toString() => 'DataPoint($x, $y)';
}

/// A data point with additional numeric value for bubble/sized charts.
@immutable
class SizedDataPoint<X, Y extends num> extends DataPoint<X, Y> {
  /// Creates a sized data point with an additional [size] value.
  const SizedDataPoint({
    required super.x,
    required super.y,
    required this.size,
    super.metadata,
  });

  /// The size value for this data point (used for bubble size, etc.).
  final double size;

  @override
  SizedDataPoint<X, Y> copyWith({
    X? x,
    Y? y,
    double? size,
    Map<String, dynamic>? metadata,
  }) =>
      SizedDataPoint<X, Y>(
        x: x ?? this.x,
        y: y ?? this.y,
        size: size ?? this.size,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is SizedDataPoint<X, Y> && size == other.size;

  @override
  int get hashCode => Object.hash(super.hashCode, size);

  @override
  String toString() => 'SizedDataPoint($x, $y, size: $size)';
}

/// A data point for OHLC (Open-High-Low-Close) financial charts.
@immutable
class OHLCDataPoint<X> extends DataPoint<X, double> {
  /// Creates an OHLC data point.
  const OHLCDataPoint({
    required super.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
    super.metadata,
  }) : super(y: close);

  /// The opening price.
  final double open;

  /// The highest price.
  final double high;

  /// The lowest price.
  final double low;

  /// The closing price.
  final double close;

  /// Optional trading volume.
  final double? volume;

  /// Returns true if the close price is higher than the open price (bullish).
  bool get isBullish => close >= open;

  /// Returns true if the close price is lower than the open price (bearish).
  bool get isBearish => close < open;

  @override
  OHLCDataPoint<X> copyWith({
    X? x,
    double? y,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
    Map<String, dynamic>? metadata,
  }) =>
      OHLCDataPoint<X>(
        x: x ?? this.x,
        open: open ?? this.open,
        high: high ?? this.high,
        low: low ?? this.low,
        close: close ?? this.close,
        volume: volume ?? this.volume,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OHLCDataPoint<X> &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume;

  @override
  int get hashCode => Object.hash(super.hashCode, open, high, low, close, volume);

  @override
  String toString() =>
      'OHLCDataPoint($x, O: $open, H: $high, L: $low, C: $close)';
}

/// A data point for range/area charts with high and low values.
@immutable
class RangeDataPoint<X, Y extends num> extends DataPoint<X, Y> {
  /// Creates a range data point with high and low values.
  const RangeDataPoint({
    required super.x,
    required this.high,
    required this.low,
    super.metadata,
  }) : super(y: high);

  /// The high value of the range.
  final Y high;

  /// The low value of the range.
  final Y low;

  @override
  RangeDataPoint<X, Y> copyWith({
    X? x,
    Y? y,
    Y? high,
    Y? low,
    Map<String, dynamic>? metadata,
  }) =>
      RangeDataPoint<X, Y>(
        x: x ?? this.x,
        high: high ?? this.high,
        low: low ?? this.low,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is RangeDataPoint<X, Y> &&
          high == other.high &&
          low == other.low;

  @override
  int get hashCode => Object.hash(super.hashCode, high, low);

  @override
  String toString() => 'RangeDataPoint($x, high: $high, low: $low)';
}

/// A data point for box plot charts with statistical quartiles.
@immutable
class BoxPlotDataPoint<X> extends DataPoint<X, double> {
  /// Creates a box plot data point with quartile values.
  const BoxPlotDataPoint({
    required super.x,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    this.outliers = const [],
    this.mean,
    super.metadata,
  }) : super(y: median);

  /// The minimum value (lower whisker).
  final double min;

  /// The first quartile (25th percentile).
  final double q1;

  /// The median (50th percentile).
  final double median;

  /// The third quartile (75th percentile).
  final double q3;

  /// The maximum value (upper whisker).
  final double max;

  /// Optional list of outlier values.
  final List<double> outliers;

  /// Optional mean value.
  final double? mean;

  /// The interquartile range (Q3 - Q1).
  double get iqr => q3 - q1;

  @override
  BoxPlotDataPoint<X> copyWith({
    X? x,
    double? y,
    double? min,
    double? q1,
    double? median,
    double? q3,
    double? max,
    List<double>? outliers,
    double? mean,
    Map<String, dynamic>? metadata,
  }) =>
      BoxPlotDataPoint<X>(
        x: x ?? this.x,
        min: min ?? this.min,
        q1: q1 ?? this.q1,
        median: median ?? this.median,
        q3: q3 ?? this.q3,
        max: max ?? this.max,
        outliers: outliers ?? this.outliers,
        mean: mean ?? this.mean,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is BoxPlotDataPoint<X> &&
          min == other.min &&
          q1 == other.q1 &&
          median == other.median &&
          q3 == other.q3 &&
          max == other.max &&
          listEquals(outliers, other.outliers) &&
          mean == other.mean;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, min, q1, median, q3, max, outliers, mean);

  @override
  String toString() =>
      'BoxPlotDataPoint($x, min: $min, Q1: $q1, median: $median, Q3: $q3, max: $max)';
}

/// A data point for hierarchical charts (treemap, sunburst).
@immutable
class HierarchicalDataPoint<T> {
  /// Creates a hierarchical data point.
  const HierarchicalDataPoint({
    required this.id,
    required this.value,
    this.label,
    this.parentId,
    this.children = const [],
    this.metadata,
  });

  /// Unique identifier for this node.
  final String id;

  /// The value of this node.
  final T value;

  /// Optional display label.
  final String? label;

  /// Parent node ID (null for root nodes).
  final String? parentId;

  /// Child nodes.
  final List<HierarchicalDataPoint<T>> children;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Returns true if this is a leaf node (no children).
  bool get isLeaf => children.isEmpty;

  /// Returns true if this is a root node (no parent).
  bool get isRoot => parentId == null;

  /// Creates a copy with the given values replaced.
  HierarchicalDataPoint<T> copyWith({
    String? id,
    T? value,
    String? label,
    String? parentId,
    List<HierarchicalDataPoint<T>>? children,
    Map<String, dynamic>? metadata,
  }) =>
      HierarchicalDataPoint<T>(
        id: id ?? this.id,
        value: value ?? this.value,
        label: label ?? this.label,
        parentId: parentId ?? this.parentId,
        children: children ?? this.children,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HierarchicalDataPoint<T> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          label == other.label &&
          parentId == other.parentId &&
          listEquals(children, other.children);

  @override
  int get hashCode => Object.hash(id, value, label, parentId, children);

  @override
  String toString() =>
      'HierarchicalDataPoint($id, value: $value, children: ${children.length})';
}

/// A data point for heatmap charts.
@immutable
class HeatmapDataPoint<X, Y, V extends num> {
  /// Creates a heatmap data point.
  const HeatmapDataPoint({
    required this.x,
    required this.y,
    required this.value,
    this.metadata,
  });

  /// The x-axis coordinate.
  final X x;

  /// The y-axis coordinate.
  final Y y;

  /// The intensity/value at this coordinate.
  final V value;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a copy with the given values replaced.
  HeatmapDataPoint<X, Y, V> copyWith({
    X? x,
    Y? y,
    V? value,
    Map<String, dynamic>? metadata,
  }) =>
      HeatmapDataPoint<X, Y, V>(
        x: x ?? this.x,
        y: y ?? this.y,
        value: value ?? this.value,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDataPoint<X, Y, V> &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          value == other.value;

  @override
  int get hashCode => Object.hash(x, y, value);

  @override
  String toString() => 'HeatmapDataPoint($x, $y, value: $value)';
}
