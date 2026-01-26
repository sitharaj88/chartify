import 'package:flutter/widgets.dart';

import '../../core/math/geometry/bounds_calculator.dart';
import '../../core/math/geometry/coordinate_transform.dart';
import '../../core/math/scales/scale.dart';
import '../../rendering/renderers/axis_renderer.dart';
import '../../rendering/renderers/grid_renderer.dart';
import '../../rendering/renderers/renderer.dart';
import '../../theme/chart_theme_data.dart';
import 'chart_widget_mixin.dart';

/// Base configuration for cartesian charts.
class CartesianChartConfig {
  const CartesianChartConfig({
    this.padding = const EdgeInsets.all(16),
    this.showXAxis = true,
    this.showYAxis = true,
    this.showGrid = true,
    this.xAxisConfig,
    this.yAxisConfig,
    this.gridConfig,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.includeZero = false,
  });

  /// Padding around the chart.
  final EdgeInsets padding;

  /// Whether to show the X axis.
  final bool showXAxis;

  /// Whether to show the Y axis.
  final bool showYAxis;

  /// Whether to show grid lines.
  final bool showGrid;

  /// Configuration for X axis.
  final AxisConfig? xAxisConfig;

  /// Configuration for Y axis.
  final AxisConfig? yAxisConfig;

  /// Configuration for grid.
  final GridConfig? gridConfig;

  /// Override minimum X value.
  final double? xMin;

  /// Override maximum X value.
  final double? xMax;

  /// Override minimum Y value.
  final double? yMin;

  /// Override maximum Y value.
  final double? yMax;

  /// Whether to include zero in Y axis.
  final bool includeZero;
}

/// Base painter for cartesian charts.
///
/// Provides common functionality for charts with X and Y axes.
abstract class CartesianChartPainter extends BaseChartPainter {
  CartesianChartPainter({
    required super.theme,
    super.animationProgress,
    required this.config,
    this.xBounds,
    this.yBounds,
  });

  final CartesianChartConfig config;
  Bounds? xBounds;
  Bounds? yBounds;

  // Computed values
  late CoordinateTransform transform;
  late LinearScale xScale;
  late LinearScale yScale;
  AxisRenderer<double>? _xAxisRenderer;
  AxisRenderer<double>? _yAxisRenderer;
  GridRenderer<double, double>? _gridRenderer;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate bounds if not provided
    final effectiveXBounds = _calculateEffectiveXBounds();
    final effectiveYBounds = _calculateEffectiveYBounds();

    // Calculate insets for axes
    final insets = _calculateInsets(size, effectiveXBounds, effectiveYBounds);

    // Calculate chart area
    chartArea = calculateChartArea(size, insets);

    // Create scales
    xScale = LinearScale(
      domain: (effectiveXBounds.min, effectiveXBounds.max),
      range: (chartArea.left, chartArea.right),
    );

    yScale = LinearScale(
      domain: (effectiveYBounds.min, effectiveYBounds.max),
      range: (chartArea.bottom, chartArea.top), // Inverted for screen coordinates
    );

    // Create transform
    transform = CoordinateTransform(
      chartArea: chartArea,
      xBounds: effectiveXBounds,
      yBounds: effectiveYBounds,
    );

    // Draw grid
    if (config.showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw data (implemented by subclass)
    paintData(canvas, size);

    // Draw axes
    if (config.showXAxis) {
      _drawXAxis(canvas, size);
    }
    if (config.showYAxis) {
      _drawYAxis(canvas, size);
    }
  }

  /// Paints the chart data. Implemented by subclasses.
  void paintData(Canvas canvas, Size size);

  /// Calculates effective X bounds.
  Bounds _calculateEffectiveXBounds() {
    var bounds = xBounds ?? calculateXBounds();
    bounds = bounds.withOverrides(
      minOverride: config.xMin,
      maxOverride: config.xMax,
    );
    return bounds;
  }

  /// Calculates effective Y bounds.
  Bounds _calculateEffectiveYBounds() {
    var bounds = yBounds ?? calculateYBounds();
    if (config.includeZero) {
      bounds = Bounds.includingZero(bounds);
    }
    bounds = bounds.withOverrides(
      minOverride: config.yMin,
      maxOverride: config.yMax,
    );
    return bounds.nice();
  }

  /// Calculates X bounds from data. Override in subclass.
  Bounds calculateXBounds() => const Bounds(min: 0, max: 1);

  /// Calculates Y bounds from data. Override in subclass.
  Bounds calculateYBounds() => const Bounds(min: 0, max: 1);

  EdgeInsets _calculateInsets(Size size, Bounds xBounds, Bounds yBounds) {
    var left = config.padding.left;
    var right = config.padding.right;
    var top = config.padding.top;
    var bottom = config.padding.bottom;

    // Add space for Y axis
    if (config.showYAxis) {
      final yAxisConfig = config.yAxisConfig ?? const AxisConfig(position: ChartPosition.left);
      _yAxisRenderer = AxisRenderer<double>(
        config: yAxisConfig,
        scale: LinearScale(
          domain: (yBounds.min, yBounds.max),
          range: (size.height - bottom, top),
        ),
      );
      final yInsets = _yAxisRenderer!.calculateInsets(size);
      left += yInsets.left;
    }

    // Add space for X axis
    if (config.showXAxis) {
      final xAxisConfig = config.xAxisConfig ?? const AxisConfig(position: ChartPosition.bottom);
      _xAxisRenderer = AxisRenderer<double>(
        config: xAxisConfig,
        scale: LinearScale(
          domain: (xBounds.min, xBounds.max),
          range: (left, size.width - right),
        ),
      );
      final xInsets = _xAxisRenderer!.calculateInsets(size);
      bottom += xInsets.bottom;
    }

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridConfig = config.gridConfig ?? GridConfig(
      lineColor: theme.gridLineColor,
      lineWidth: theme.gridLineWidth,
    );

    _gridRenderer = GridRenderer<double, double>(
      config: gridConfig,
      xScale: xScale,
      yScale: yScale,
    );

    _gridRenderer!.render(canvas, size, chartArea);
  }

  void _drawXAxis(Canvas canvas, Size size) {
    if (_xAxisRenderer == null) return;

    // Update scale with final chart area
    _xAxisRenderer!.updateScale(xScale);

    canvas.save();
    canvas.translate(0, chartArea.bottom);
    _xAxisRenderer!.render(canvas, size, chartArea);
    canvas.restore();
  }

  void _drawYAxis(Canvas canvas, Size size) {
    if (_yAxisRenderer == null) return;

    // Update scale with final chart area
    _yAxisRenderer!.updateScale(yScale);

    canvas.save();
    canvas.translate(chartArea.left, 0);
    _yAxisRenderer!.render(canvas, size, chartArea);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CartesianChartPainter oldDelegate) {
    return animationProgress != oldDelegate.animationProgress ||
        xBounds != oldDelegate.xBounds ||
        yBounds != oldDelegate.yBounds;
  }
}

/// Builder for cartesian chart configurations.
class CartesianChartBuilder {
  CartesianChartBuilder();

  EdgeInsets _padding = const EdgeInsets.all(16);
  bool _showXAxis = true;
  bool _showYAxis = true;
  bool _showGrid = true;
  AxisConfig? _xAxisConfig;
  AxisConfig? _yAxisConfig;
  GridConfig? _gridConfig;
  double? _xMin;
  double? _xMax;
  double? _yMin;
  double? _yMax;
  bool _includeZero = false;

  /// Sets padding.
  CartesianChartBuilder padding(EdgeInsets padding) {
    _padding = padding;
    return this;
  }

  /// Hides X axis.
  CartesianChartBuilder hideXAxis() {
    _showXAxis = false;
    return this;
  }

  /// Hides Y axis.
  CartesianChartBuilder hideYAxis() {
    _showYAxis = false;
    return this;
  }

  /// Hides grid.
  CartesianChartBuilder hideGrid() {
    _showGrid = false;
    return this;
  }

  /// Sets X axis configuration.
  CartesianChartBuilder xAxis(AxisConfig config) {
    _xAxisConfig = config;
    return this;
  }

  /// Sets Y axis configuration.
  CartesianChartBuilder yAxis(AxisConfig config) {
    _yAxisConfig = config;
    return this;
  }

  /// Sets grid configuration.
  CartesianChartBuilder grid(GridConfig config) {
    _gridConfig = config;
    return this;
  }

  /// Sets X range.
  CartesianChartBuilder xRange(double min, double max) {
    _xMin = min;
    _xMax = max;
    return this;
  }

  /// Sets Y range.
  CartesianChartBuilder yRange(double min, double max) {
    _yMin = min;
    _yMax = max;
    return this;
  }

  /// Includes zero in Y axis.
  CartesianChartBuilder includeZero() {
    _includeZero = true;
    return this;
  }

  /// Builds the configuration.
  CartesianChartConfig build() {
    return CartesianChartConfig(
      padding: _padding,
      showXAxis: _showXAxis,
      showYAxis: _showYAxis,
      showGrid: _showGrid,
      xAxisConfig: _xAxisConfig,
      yAxisConfig: _yAxisConfig,
      gridConfig: _gridConfig,
      xMin: _xMin,
      xMax: _xMax,
      yMin: _yMin,
      yMax: _yMax,
      includeZero: _includeZero,
    );
  }
}
