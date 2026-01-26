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

// Accessibility
export 'src/accessibility/chart_accessibility.dart';
export 'src/accessibility/chart_semantics.dart' hide ChartType;
export 'src/accessibility/contrast_validator.dart';
export 'src/accessibility/high_contrast.dart';
// Animation
export 'src/animation/chart_animation.dart';
export 'src/charts/_base/cartesian_chart_base.dart' hide CartesianChartPainter;
// Charts - Base (hide duplicates from core)
export 'src/charts/_base/chart_widget_mixin.dart';
export 'src/charts/_base/circular_chart_base.dart' hide CircularChartPainter;
// Charts - Cartesian - Area
export 'src/charts/cartesian/area/area_chart.dart';
// Charts - Cartesian - Bar
export 'src/charts/cartesian/bar/bar_chart.dart';
export 'src/charts/cartesian/bar/bar_chart_data.dart';
export 'src/charts/cartesian/bar/bar_series.dart';
// Charts - Cartesian - Box Plot
export 'src/charts/cartesian/box_plot/box_plot_chart.dart';
// Charts - Cartesian - Bubble
export 'src/charts/cartesian/bubble/bubble_chart.dart';
// Charts - Cartesian - Bullet
export 'src/charts/cartesian/bullet/bullet_chart.dart';
// Charts - Cartesian - Bump
export 'src/charts/cartesian/bump/bump_chart.dart';
// Charts - Cartesian - Candlestick
export 'src/charts/cartesian/candlestick/candlestick_chart.dart';
// Charts - Cartesian - Dumbbell
export 'src/charts/cartesian/dumbbell/dumbbell_chart.dart';
// Charts - Cartesian - Gantt
export 'src/charts/cartesian/gantt/gantt_chart.dart';
export 'src/charts/cartesian/gantt/gantt_chart_data.dart';
export 'src/charts/cartesian/gantt/gantt_dependency.dart';
export 'src/charts/cartesian/gantt/gantt_interactions.dart';
export 'src/charts/cartesian/gantt/gantt_scheduler.dart';
export 'src/charts/cartesian/gantt/gantt_validator.dart';
export 'src/charts/cartesian/gantt/gantt_view_controller.dart';
// Charts - Cartesian - Histogram
export 'src/charts/cartesian/histogram/histogram_chart.dart';
// Charts - Cartesian - Line
export 'src/charts/cartesian/line/line_chart.dart';
export 'src/charts/cartesian/line/line_chart_data.dart';
export 'src/charts/cartesian/line/line_series.dart';
// Charts - Cartesian - Lollipop
export 'src/charts/cartesian/lollipop/lollipop_chart.dart';
// Charts - Cartesian - Range
export 'src/charts/cartesian/range/range_chart.dart';
// Charts - Cartesian - Scatter
export 'src/charts/cartesian/scatter/scatter_chart.dart';
// Charts - Cartesian - Slope
export 'src/charts/cartesian/slope/slope_chart.dart';
// Charts - Cartesian - Step
export 'src/charts/cartesian/step/step_chart.dart' hide StepType;
// Charts - Cartesian - Waterfall
export 'src/charts/cartesian/waterfall/waterfall_chart.dart';
// Charts - Circular - Gauge
export 'src/charts/circular/gauge/gauge_chart.dart';
// Charts - Circular - Pie/Donut
export 'src/charts/circular/pie/pie_chart.dart';
export 'src/charts/circular/pie/pie_chart_data.dart';
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
// Charts - Polar - Radar
export 'src/charts/polar/radar/radar_chart.dart';
// Charts - Polar - Rose
export 'src/charts/polar/rose/rose_chart.dart';
// Charts - Specialty - Calendar Heatmap
export 'src/charts/specialty/calendar_heatmap/calendar_heatmap_chart.dart';
// Charts - Specialty - Heatmap
export 'src/charts/specialty/heatmap/heatmap_chart.dart';
// Charts - Specialty - Sankey
export 'src/charts/specialty/sankey/sankey_chart.dart';
// Charts - Specialty - Sparkline
export 'src/charts/specialty/sparkline/sparkline_chart.dart';
// Components - Axis
export 'src/components/axis/axis_widget.dart';
// Components - Legend
export 'src/components/legend/legend_widget.dart';
// Components - Markers
export 'src/components/markers/marker_registry.dart';
// Components - Tooltip
export 'src/components/tooltip/chart_tooltip.dart';
export 'src/core/base/chart_controller.dart';
export 'src/core/base/chart_data.dart';
export 'src/core/base/chart_painter.dart';
// Core - Base
export 'src/core/base/series.dart' hide FunnelSection, GaugeRange, PieSection;
// Core - Data
export 'src/core/data/data_point.dart';
// Core - Error Handling
export 'src/core/errors/chart_error_boundary.dart';
// Gestures
export 'src/core/gestures/gesture_detector.dart';
export 'src/core/gestures/spatial_index.dart';
export 'src/core/math/geometry/bounds_calculator.dart';
export 'src/core/math/geometry/coordinate_transform.dart';
export 'src/core/math/interpolation/interpolator.dart';
// Core - Math
export 'src/core/math/scales/scale.dart';
// Core - Utilities
export 'src/core/utils/cache_manager.dart';
export 'src/core/utils/data_decimator.dart';
export 'src/core/utils/data_validator.dart';
export 'src/core/utils/object_pool.dart';
export 'src/plugins/built_in/export_plugin.dart';
export 'src/plugins/built_in/zoom_plugin.dart';
// Plugins
export 'src/plugins/plugin.dart';
export 'src/rendering/cache/canvas_layer_cache.dart' hide RenderLayer;
// Rendering - Cache (hide duplicates from core)
export 'src/rendering/cache/path_cache.dart' hide PathCache;
export 'src/rendering/cache/text_cache.dart';
export 'src/rendering/painters/arc_painter.dart';
export 'src/rendering/painters/bar_painter.dart';
export 'src/rendering/painters/line_painter.dart';
// Rendering - Painters (hide duplicates from core)
export 'src/rendering/painters/series_painter.dart' hide DataPointInfo;
export 'src/rendering/renderers/axis_renderer.dart' hide AxisConfig;
export 'src/rendering/renderers/grid_renderer.dart';
export 'src/rendering/renderers/legend_renderer.dart';
export 'src/rendering/renderers/marker_renderer.dart' hide MarkerShape;
// Rendering - Renderers (hide duplicates from core)
export 'src/rendering/renderers/renderer.dart';
// Theme
export 'src/theme/chart_theme_data.dart';
