/// Chartify - A comprehensive, high-performance Flutter chart library.
///
/// Supports 25+ chart types with clean architecture, large datasets,
/// cross-platform compatibility, and both simple and advanced APIs.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:chartify/chartify.dart';
///
/// // Simple line chart
/// LineChart(
///   data: LineChartData(
///     series: [
///       LineSeries(data: [
///         DataPoint(x: 0, y: 10),
///         DataPoint(x: 1, y: 25),
///         DataPoint(x: 2, y: 15),
///       ]),
///     ],
///   ),
/// )
/// ```
///
/// ## Theming
///
/// ```dart
/// ChartTheme(
///   data: ChartThemeData.fromSeed(Colors.blue),
///   child: LineChart(...),
/// )
/// ```
///
/// ## Animation
///
/// ```dart
/// LineChart(
///   data: lineData,
///   animation: ChartAnimation(
///     duration: Duration(milliseconds: 800),
///     curve: Curves.easeOutCubic,
///   ),
/// )
/// ```
library chartify;

// Core - Data
export 'src/core/data/data_point.dart';

// Core - Base
export 'src/core/base/series.dart' hide PieSection, GaugeRange, FunnelSection;
export 'src/core/base/chart_data.dart';
export 'src/core/base/chart_controller.dart';
export 'src/core/base/chart_painter.dart';

// Animation
export 'src/animation/chart_animation.dart';

// Theme
export 'src/theme/chart_theme_data.dart';

// Gestures
export 'src/core/gestures/gesture_detector.dart';

// Components - Tooltip
export 'src/components/tooltip/chart_tooltip.dart';

// Charts - Cartesian - Line
export 'src/charts/cartesian/line/line_chart.dart';
export 'src/charts/cartesian/line/line_chart_data.dart';
export 'src/charts/cartesian/line/line_series.dart';

// Charts - Cartesian - Bar
export 'src/charts/cartesian/bar/bar_chart.dart';
export 'src/charts/cartesian/bar/bar_chart_data.dart';
export 'src/charts/cartesian/bar/bar_series.dart';

// Charts - Cartesian - Area
export 'src/charts/cartesian/area/area_chart.dart';

// Charts - Cartesian - Scatter
export 'src/charts/cartesian/scatter/scatter_chart.dart';

// Charts - Circular - Pie/Donut
export 'src/charts/circular/pie/pie_chart.dart';
export 'src/charts/circular/pie/pie_chart_data.dart';

// Charts - Circular - Gauge
export 'src/charts/circular/gauge/gauge_chart.dart';

// Charts - Polar - Radar
export 'src/charts/polar/radar/radar_chart.dart';

// Charts - Cartesian - Bubble
export 'src/charts/cartesian/bubble/bubble_chart.dart';

// Charts - Cartesian - Candlestick
export 'src/charts/cartesian/candlestick/candlestick_chart.dart';

// Charts - Cartesian - Histogram
export 'src/charts/cartesian/histogram/histogram_chart.dart';

// Charts - Cartesian - Waterfall
export 'src/charts/cartesian/waterfall/waterfall_chart.dart';

// Charts - Cartesian - Box Plot
export 'src/charts/cartesian/box_plot/box_plot_chart.dart';

// Charts - Circular - Radial Bar
export 'src/charts/circular/radial_bar/radial_bar_chart.dart';

// Charts - Circular - Sunburst
export 'src/charts/circular/sunburst/sunburst_chart.dart';

// Charts - Hierarchical - Funnel
export 'src/charts/hierarchical/funnel/funnel_chart.dart';

// Charts - Hierarchical - Pyramid
export 'src/charts/hierarchical/pyramid/pyramid_chart.dart';

// Charts - Hierarchical - Treemap
export 'src/charts/hierarchical/treemap/treemap_chart.dart';

// Charts - Specialty - Sparkline
export 'src/charts/specialty/sparkline/sparkline_chart.dart';

// Charts - Specialty - Heatmap
export 'src/charts/specialty/heatmap/heatmap_chart.dart';
