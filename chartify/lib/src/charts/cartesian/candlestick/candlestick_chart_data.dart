import 'package:flutter/material.dart';

import '../../../animation/chart_animation.dart';

/// A single candlestick data point (OHLC).
@immutable
class CandlestickDataPoint {
  const CandlestickDataPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  /// Date/time for this candlestick.
  final DateTime date;

  /// Opening price.
  final double open;

  /// Highest price.
  final double high;

  /// Lowest price.
  final double low;

  /// Closing price.
  final double close;

  /// Optional trading volume.
  final double? volume;

  /// Whether this is a bullish (green) candle.
  bool get isBullish => close >= open;

  /// The body height (absolute difference between open and close).
  double get bodyHeight => (close - open).abs();

  /// The upper wick height.
  double get upperWickHeight => high - (isBullish ? close : open);

  /// The lower wick height.
  double get lowerWickHeight => (isBullish ? open : close) - low;
}

/// Style for candlestick rendering.
enum CandlestickStyle {
  /// Filled candles (bullish filled with bullish color).
  filled,

  /// Hollow candles (bullish has hollow body).
  hollow,

  /// OHLC bars (no body, just lines).
  ohlc,
}

/// Data configuration for candlestick chart.
@immutable
class CandlestickChartData {
  const CandlestickChartData({
    required this.data,
    this.bullishColor = const Color(0xFF26A69A),
    this.bearishColor = const Color(0xFFEF5350),
    this.style = CandlestickStyle.filled,
    this.candleWidth = 0.8,
    this.wickWidth = 1.0,
    this.showVolume = false,
    this.volumeHeightRatio = 0.2,
    this.volumeColor,
    this.showGrid = true,
    this.animation,
  });

  /// List of candlestick data points.
  final List<CandlestickDataPoint> data;

  /// Color for bullish (up) candles.
  final Color bullishColor;

  /// Color for bearish (down) candles.
  final Color bearishColor;

  /// Style of candlestick rendering.
  final CandlestickStyle style;

  /// Width of candle body as ratio of available space (0-1).
  final double candleWidth;

  /// Width of wick lines.
  final double wickWidth;

  /// Whether to show volume bars.
  final bool showVolume;

  /// Height ratio of volume section (0-1).
  final double volumeHeightRatio;

  /// Color for volume bars (uses candle colors if null).
  final Color? volumeColor;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Animation configuration.
  final ChartAnimation? animation;
}
