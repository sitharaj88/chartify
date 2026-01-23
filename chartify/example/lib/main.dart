import 'dart:math' as math;

import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ChartifyExampleApp());
}

class ChartifyExampleApp extends StatelessWidget {
  const ChartifyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chartify Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        extensions: [ChartThemeData.fromSeed(Colors.indigo)],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        extensions: [
          ChartThemeData.fromSeed(Colors.indigo, brightness: Brightness.dark),
        ],
      ),
      home: const ChartGallery(),
    );
  }
}

class ChartGallery extends StatefulWidget {
  const ChartGallery({super.key});

  @override
  State<ChartGallery> createState() => _ChartGalleryState();
}

class _ChartGalleryState extends State<ChartGallery> {
  int _selectedIndex = 0;

  final List<ChartExample> _examples = [
    ChartExample(
      name: 'Interactive Chart',
      description: 'Hover/tap to see tooltips and crosshair',
      icon: Icons.touch_app,
      builder: (context) => const InteractiveChartExample(),
    ),
    ChartExample(
      name: 'Simple Line Chart',
      description: 'Basic line chart with markers',
      icon: Icons.show_chart,
      builder: (context) => const SimpleLineChartExample(),
    ),
    ChartExample(
      name: 'Multi-Series Line',
      description: 'Compare multiple data series',
      icon: Icons.stacked_line_chart,
      builder: (context) => const MultiSeriesLineChartExample(),
    ),
    ChartExample(
      name: 'Area Chart',
      description: 'Filled area with gradient',
      icon: Icons.area_chart,
      builder: (context) => const AreaChartExample(),
    ),
    ChartExample(
      name: 'Animated Chart',
      description: 'Dynamic data with animations',
      icon: Icons.animation,
      builder: (context) => const AnimatedLineChartExample(),
    ),
    ChartExample(
      name: 'Bar Chart',
      description: 'Grouped and stacked bars',
      icon: Icons.bar_chart,
      builder: (context) => const BarChartExample(),
    ),
    ChartExample(
      name: 'Pie Chart',
      description: 'Circular data visualization',
      icon: Icons.pie_chart,
      builder: (context) => const PieChartExample(),
    ),
    ChartExample(
      name: 'Scatter Chart',
      description: 'Point distribution plot',
      icon: Icons.scatter_plot,
      builder: (context) => const ScatterChartExample(),
    ),
    ChartExample(
      name: 'Radar Chart',
      description: 'Multi-axis comparison',
      icon: Icons.radar,
      builder: (context) => const RadarChartExample(),
    ),
    ChartExample(
      name: 'Gauge Chart',
      description: 'Single metric display',
      icon: Icons.speed,
      builder: (context) => const GaugeChartExample(),
    ),
    ChartExample(
      name: 'Sparkline Chart',
      description: 'Compact inline charts',
      icon: Icons.show_chart,
      builder: (context) => const SparklineChartExample(),
    ),
    ChartExample(
      name: 'Bubble Chart',
      description: 'Scatter with size dimension',
      icon: Icons.bubble_chart,
      builder: (context) => const BubbleChartExample(),
    ),
    ChartExample(
      name: 'Radial Bar Chart',
      description: 'Circular progress bars',
      icon: Icons.donut_large,
      builder: (context) => const RadialBarChartExample(),
    ),
    ChartExample(
      name: 'Candlestick Chart',
      description: 'Financial OHLC data',
      icon: Icons.candlestick_chart,
      builder: (context) => const CandlestickChartExample(),
    ),
    ChartExample(
      name: 'Histogram Chart',
      description: 'Distribution visualization',
      icon: Icons.bar_chart,
      builder: (context) => const HistogramChartExample(),
    ),
    ChartExample(
      name: 'Waterfall Chart',
      description: 'Running total changes',
      icon: Icons.waterfall_chart,
      builder: (context) => const WaterfallChartExample(),
    ),
    ChartExample(
      name: 'Box Plot Chart',
      description: 'Statistical distribution',
      icon: Icons.candlestick_chart,
      builder: (context) => const BoxPlotChartExample(),
    ),
    ChartExample(
      name: 'Funnel Chart',
      description: 'Conversion funnel',
      icon: Icons.filter_alt,
      builder: (context) => const FunnelChartExample(),
    ),
    ChartExample(
      name: 'Pyramid Chart',
      description: 'Hierarchical layers',
      icon: Icons.change_history,
      builder: (context) => const PyramidChartExample(),
    ),
    ChartExample(
      name: 'Heatmap Chart',
      description: 'Grid color intensity',
      icon: Icons.grid_on,
      builder: (context) => const HeatmapChartExample(),
    ),
    ChartExample(
      name: 'Treemap Chart',
      description: 'Hierarchical rectangles',
      icon: Icons.dashboard,
      builder: (context) => const TreemapChartExample(),
    ),
    ChartExample(
      name: 'Sunburst Chart',
      description: 'Hierarchical rings',
      icon: Icons.wb_sunny,
      builder: (context) => const SunburstChartExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          if (isWideScreen)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Chartify',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _examples.length,
                      itemBuilder: (context, index) {
                        final example = _examples[index];
                        final isSelected = index == _selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            leading: Icon(
                              example.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              example.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              example.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => setState(() => _selectedIndex = index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isWideScreen) ...[
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => _buildMobileNav(context),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _examples[_selectedIndex].name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _examples[_selectedIndex].description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _examples[_selectedIndex].builder(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _examples.length,
      itemBuilder: (context, index) {
        final example = _examples[index];
        return ListTile(
          leading: Icon(example.icon),
          title: Text(example.name),
          subtitle: Text(example.description),
          selected: index == _selectedIndex,
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class ChartExample {
  const ChartExample({
    required this.name,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String name;
  final String description;
  final IconData icon;
  final Widget Function(BuildContext context) builder;
}

// ============== Chart Examples ==============

class InteractiveChartExample extends StatefulWidget {
  const InteractiveChartExample({super.key});

  @override
  State<InteractiveChartExample> createState() => _InteractiveChartExampleState();
}

class _InteractiveChartExampleState extends State<InteractiveChartExample> {
  String _lastTapped = 'Tap or hover over data points';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _lastTapped,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            data: LineChartData(
              series: [
                LineSeries<int, double>(
                  name: 'Revenue',
                  data: const [
                    DataPoint(x: 0, y: 4200),
                    DataPoint(x: 1, y: 5800),
                    DataPoint(x: 2, y: 4900),
                    DataPoint(x: 3, y: 7200),
                    DataPoint(x: 4, y: 6100),
                    DataPoint(x: 5, y: 8500),
                    DataPoint(x: 6, y: 7800),
                  ],
                  color: const Color(0xFF6366F1),
                  strokeWidth: 3,
                  curved: true,
                  showMarkers: true,
                  markerSize: 8,
                  fillArea: true,
                  areaOpacity: 0.15,
                ),
              ],
              xAxis: AxisConfig(
                label: 'Month',
                labelFormatter: (value) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                  final index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    return months[index];
                  }
                  return '';
                },
              ),
              yAxis: AxisConfig(
                label: 'Revenue',
                min: 0,
                labelFormatter: (value) => '\$${(value / 1000).toStringAsFixed(1)}K',
              ),
            ),
            tooltip: const TooltipConfig(
              enabled: true,
              showIndicatorLine: true,
              showIndicatorDot: true,
            ),
            showCrosshair: true,
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
            onDataPointTap: (info) {
              setState(() {
                _lastTapped = 'Tapped: \$${info.yValue} at month ${info.xValue}';
              });
            },
          ),
        ),
      ],
    );
  }
}

class SimpleLineChartExample extends StatelessWidget {
  const SimpleLineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Sales',
            data: const [
              DataPoint(x: 0, y: 10),
              DataPoint(x: 1, y: 25),
              DataPoint(x: 2, y: 15),
              DataPoint(x: 3, y: 30),
              DataPoint(x: 4, y: 22),
              DataPoint(x: 5, y: 35),
              DataPoint(x: 6, y: 28),
            ],
            color: const Color(0xFF10B981),
            strokeWidth: 3,
            showMarkers: true,
            markerSize: 8,
          ),
        ],
        xAxis: const AxisConfig(label: 'Month'),
        yAxis: const AxisConfig(label: 'Sales (\$K)', min: 0),
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class MultiSeriesLineChartExample extends StatelessWidget {
  const MultiSeriesLineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Revenue',
            data: const [
              DataPoint(x: 0, y: 50),
              DataPoint(x: 1, y: 75),
              DataPoint(x: 2, y: 65),
              DataPoint(x: 3, y: 90),
              DataPoint(x: 4, y: 85),
              DataPoint(x: 5, y: 100),
            ],
            color: const Color(0xFF3B82F6),
            strokeWidth: 2.5,
            curved: true,
          ),
          LineSeries<int, double>(
            name: 'Costs',
            data: const [
              DataPoint(x: 0, y: 40),
              DataPoint(x: 1, y: 55),
              DataPoint(x: 2, y: 50),
              DataPoint(x: 3, y: 60),
              DataPoint(x: 4, y: 65),
              DataPoint(x: 5, y: 70),
            ],
            color: const Color(0xFFEF4444),
            strokeWidth: 2.5,
            curved: true,
          ),
          LineSeries<int, double>(
            name: 'Profit',
            data: const [
              DataPoint(x: 0, y: 10),
              DataPoint(x: 1, y: 20),
              DataPoint(x: 2, y: 15),
              DataPoint(x: 3, y: 30),
              DataPoint(x: 4, y: 20),
              DataPoint(x: 5, y: 30),
            ],
            color: const Color(0xFF22C55E),
            strokeWidth: 2.5,
            curved: true,
            dashPattern: const [8, 4],
          ),
        ],
        xAxis: const AxisConfig(label: 'Quarter'),
        yAxis: const AxisConfig(label: 'Amount (\$K)', min: 0),
        showLegend: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation.staggered(),
    );
  }
}

class AreaChartExample extends StatelessWidget {
  const AreaChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        series: [
          LineSeries<int, double>(
            name: 'Active Users',
            data: const [
              DataPoint(x: 0, y: 1200),
              DataPoint(x: 1, y: 2800),
              DataPoint(x: 2, y: 2100),
              DataPoint(x: 3, y: 3900),
              DataPoint(x: 4, y: 3200),
              DataPoint(x: 5, y: 4800),
              DataPoint(x: 6, y: 4200),
            ],
            color: const Color(0xFF8B5CF6),
            strokeWidth: 3,
            curved: true,
            fillArea: true,
            areaOpacity: 0.25,
            showMarkers: false,
          ),
        ],
        xAxis: AxisConfig(
          label: 'Day',
          labelFormatter: (value) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final index = value.toInt();
            if (index >= 0 && index < days.length) {
              return days[index];
            }
            return '';
          },
        ),
        yAxis: AxisConfig(
          label: 'Users',
          min: 0,
          labelFormatter: (value) => '${(value / 1000).toStringAsFixed(1)}K',
        ),
      ),
      tooltip: const TooltipConfig(enabled: true),
      showCrosshair: true,
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        type: AnimationType.draw,
      ),
    );
  }
}

class AnimatedLineChartExample extends StatefulWidget {
  const AnimatedLineChartExample({super.key});

  @override
  State<AnimatedLineChartExample> createState() =>
      _AnimatedLineChartExampleState();
}

class _AnimatedLineChartExampleState extends State<AnimatedLineChartExample> {
  late List<DataPoint<int, double>> _data;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    _data = List.generate(
      10,
      (i) => DataPoint<int, double>(
        x: i,
        y: 20 + _random.nextDouble() * 80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LineChart(
            key: ValueKey(_data.hashCode),
            data: LineChartData(
              series: [
                LineSeries<int, double>(
                  name: 'Random Data',
                  data: _data,
                  color: const Color(0xFFF59E0B),
                  strokeWidth: 3,
                  curved: true,
                  showMarkers: true,
                  markerSize: 10,
                  markerShape: MarkerShape.diamond,
                  fillArea: true,
                  areaOpacity: 0.1,
                ),
              ],
              yAxis: const AxisConfig(min: 0, max: 100),
            ),
            tooltip: const TooltipConfig(enabled: true),
            showCrosshair: true,
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _generateData();
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Generate New Data'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class BarChartExample extends StatelessWidget {
  const BarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      data: BarChartData(
        series: [
          BarSeries.fromValues<double>(
            name: 'Sales',
            values: const [45, 72, 53, 85, 61, 78],
            color: const Color(0xFF3B82F6),
          ),
          BarSeries.fromValues<double>(
            name: 'Expenses',
            values: const [32, 48, 41, 52, 38, 55],
            color: const Color(0xFFEF4444),
          ),
        ],
        xAxis: BarXAxisConfig(
          categories: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        ),
        yAxis: const BarYAxisConfig(min: 0),
        grouping: BarGrouping.grouped,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PieChartExample extends StatelessWidget {
  const PieChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      data: PieChartData(
        sections: [
          PieSection(
            value: 35,
            label: 'Mobile',
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowElevation: 6,
          ),
          const PieSection(
            value: 30,
            label: 'Desktop',
            color: Color(0xFF10B981),
            shadowElevation: 4,
          ),
          PieSection(
            value: 20,
            label: 'Tablet',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shadowElevation: 4,
          ),
          const PieSection(
            value: 15,
            label: 'Other',
            color: Color(0xFF8B5CF6),
            shadowElevation: 4,
          ),
        ],
        holeRadius: 0.5,
        showLabels: true,
        labelPosition: PieLabelPosition.outside,
        labelConnector: PieLabelConnector.elbow,
        segmentGap: 3,
        enableShadows: true,
        hoverDuration: const Duration(milliseconds: 200),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
      centerWidget: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            '100',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ScatterChartExample extends StatelessWidget {
  const ScatterChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ScatterChart(
      data: ScatterChartData(
        series: [
          ScatterSeries<double, double>(
            name: 'Group A',
            data: const [
              ScatterDataPoint(x: 10, y: 20, size: 12),
              ScatterDataPoint(x: 25, y: 35, size: 18),
              ScatterDataPoint(x: 40, y: 28, size: 10),
              ScatterDataPoint(x: 55, y: 45, size: 15),
              ScatterDataPoint(x: 70, y: 38, size: 22),
            ],
            color: const Color(0xFF6366F1),
            pointSize: 12,
          ),
          ScatterSeries<double, double>(
            name: 'Group B',
            data: const [
              ScatterDataPoint(x: 15, y: 50, size: 14),
              ScatterDataPoint(x: 30, y: 65, size: 10),
              ScatterDataPoint(x: 45, y: 55, size: 16),
              ScatterDataPoint(x: 60, y: 72, size: 12),
              ScatterDataPoint(x: 80, y: 60, size: 20),
            ],
            color: const Color(0xFFEC4899),
            pointSize: 12,
          ),
        ],
        xAxis: const AxisConfig(label: 'X Value', min: 0, max: 100),
        yAxis: const AxisConfig(label: 'Y Value', min: 0, max: 100),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class RadarChartExample extends StatelessWidget {
  const RadarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      data: const RadarChartData(
        axes: ['Speed', 'Power', 'Defense', 'Range', 'Accuracy', 'Mobility'],
        series: [
          RadarSeries(
            name: 'Player A',
            values: [85, 70, 60, 90, 75, 80],
            color: Color(0xFF3B82F6),
          ),
          RadarSeries(
            name: 'Player B',
            values: [70, 85, 75, 65, 90, 70],
            color: Color(0xFFEF4444),
          ),
        ],
        tickCount: 5,
        gridType: RadarGridType.polygon,
      ),
      tooltipConfig: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class GaugeChartExample extends StatefulWidget {
  const GaugeChartExample({super.key});

  @override
  State<GaugeChartExample> createState() => _GaugeChartExampleState();
}

class _GaugeChartExampleState extends State<GaugeChartExample> {
  double _value = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GaugeChart(
            data: GaugeChartData(
              value: _value,
              minValue: 0,
              maxValue: 100,
              ranges: const [
                GaugeRange(start: 0, end: 30, color: Color(0xFFEF4444)),
                GaugeRange(start: 30, end: 70, color: Color(0xFFF59E0B)),
                GaugeRange(start: 70, end: 100, color: Color(0xFF22C55E)),
              ],
              label: 'Performance',
              showTicks: true,
              majorTickCount: 5,
            ),
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Slider(
          value: _value,
          min: 0,
          max: 100,
          divisions: 100,
          label: _value.toStringAsFixed(0),
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
    );
  }
}

// ============== New Chart Examples ==============

class SparklineChartExample extends StatelessWidget {
  const SparklineChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Line Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [10, 25, 15, 30, 22, 35, 28, 40, 32, 45],
              type: SparklineType.line,
              color: Color(0xFF6366F1),
              showLastMarker: true,
              showMinMarker: true,
              showMaxMarker: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Area Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [5, 20, 12, 28, 18, 35, 25, 42, 30, 48],
              type: SparklineType.area,
              color: Color(0xFF10B981),
              areaOpacity: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Bar Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [15, -10, 25, -5, 30, 20, -15, 35, 10, 40],
              type: SparklineType.bar,
              color: Color(0xFF3B82F6),
              negativeColor: Color(0xFFEF4444),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Win/Loss Sparkline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SparklineChart(
            data: const SparklineChartData(
              values: [1, -1, 1, 1, -1, 1, -1, -1, 1, 1],
              type: SparklineType.winLoss,
              color: Color(0xFF22C55E),
              negativeColor: Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}

class BubbleChartExample extends StatelessWidget {
  const BubbleChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BubbleChart(
      data: BubbleChartData(
        series: [
          BubbleSeries<double, double>(
            name: 'Products',
            data: const [
              BubbleDataPoint(x: 10, y: 20, size: 100),
              BubbleDataPoint(x: 25, y: 45, size: 200),
              BubbleDataPoint(x: 40, y: 30, size: 150),
              BubbleDataPoint(x: 55, y: 60, size: 300),
              BubbleDataPoint(x: 70, y: 40, size: 180),
              BubbleDataPoint(x: 85, y: 70, size: 250),
            ],
            color: const Color(0xFF6366F1),
            opacity: 0.7,
          ),
          BubbleSeries<double, double>(
            name: 'Services',
            data: const [
              BubbleDataPoint(x: 15, y: 55, size: 120),
              BubbleDataPoint(x: 35, y: 25, size: 180),
              BubbleDataPoint(x: 50, y: 50, size: 220),
              BubbleDataPoint(x: 65, y: 35, size: 140),
              BubbleDataPoint(x: 80, y: 55, size: 200),
            ],
            color: const Color(0xFFEC4899),
            opacity: 0.7,
          ),
        ],
        xAxis: const AxisConfig(label: 'Revenue', min: 0, max: 100),
        yAxis: const AxisConfig(label: 'Growth', min: 0, max: 100),
        sizeConfig: const BubbleSizeConfig(
          minSize: 10,
          maxSize: 50,
          scaling: BubbleSizeScaling.sqrt,
        ),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class RadialBarChartExample extends StatelessWidget {
  const RadialBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RadialBarChart(
      data: const RadialBarChartData(
        bars: [
          RadialBarItem(
            label: 'Sales',
            value: 85,
            maxValue: 100,
            color: Color(0xFF6366F1),
          ),
          RadialBarItem(
            label: 'Marketing',
            value: 72,
            maxValue: 100,
            color: Color(0xFF10B981),
          ),
          RadialBarItem(
            label: 'Support',
            value: 60,
            maxValue: 100,
            color: Color(0xFFF59E0B),
          ),
          RadialBarItem(
            label: 'Development',
            value: 90,
            maxValue: 100,
            color: Color(0xFFEC4899),
          ),
        ],
        innerRadius: 0.3,
        trackGap: 8,
        strokeCap: StrokeCap.round,
        showLabels: true,
      ),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class CandlestickChartExample extends StatelessWidget {
  const CandlestickChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return CandlestickChart(
      data: CandlestickChartData(
        data: [
          CandlestickDataPoint(date: now.subtract(const Duration(days: 9)), open: 100, high: 110, low: 95, close: 105),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 8)), open: 105, high: 115, low: 100, close: 98),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 7)), open: 98, high: 108, low: 92, close: 106),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 6)), open: 106, high: 120, low: 104, close: 118),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 5)), open: 118, high: 125, low: 115, close: 112),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 4)), open: 112, high: 118, low: 105, close: 108),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 3)), open: 108, high: 122, low: 106, close: 120),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 2)), open: 120, high: 128, low: 118, close: 125),
          CandlestickDataPoint(date: now.subtract(const Duration(days: 1)), open: 125, high: 130, low: 120, close: 118),
          CandlestickDataPoint(date: now, open: 118, high: 126, low: 115, close: 124),
        ],
        bullishColor: const Color(0xFF22C55E),
        bearishColor: const Color(0xFFEF4444),
        style: CandlestickStyle.filled,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class HistogramChartExample extends StatelessWidget {
  const HistogramChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate sample data (normal distribution)
    final random = math.Random(42);
    final values = List.generate(200, (_) {
      // Box-Muller transform for normal distribution
      final u1 = random.nextDouble();
      final u2 = random.nextDouble();
      return 50 + 15 * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    });

    return HistogramChart(
      data: HistogramChartData(
        values: values,
        binCount: 15,
        color: const Color(0xFF6366F1),
        showDistributionCurve: true,
        distributionCurveColor: const Color(0xFFEC4899),
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class WaterfallChartExample extends StatelessWidget {
  const WaterfallChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return WaterfallChart(
      data: const WaterfallChartData(
        items: [
          WaterfallItem(label: 'Start', value: 100, type: WaterfallItemType.total),
          WaterfallItem(label: 'Sales', value: 50, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Services', value: 30, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Costs', value: -40, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Tax', value: -20, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Subtotal', value: 120, type: WaterfallItemType.subtotal),
          WaterfallItem(label: 'Investment', value: 25, type: WaterfallItemType.increase),
          WaterfallItem(label: 'Expenses', value: -15, type: WaterfallItemType.decrease),
          WaterfallItem(label: 'Final', value: 130, type: WaterfallItemType.total),
        ],
        increaseColor: Color(0xFF22C55E),
        decreaseColor: Color(0xFFEF4444),
        totalColor: Color(0xFF3B82F6),
        showConnectors: true,
        showValues: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

class BoxPlotChartExample extends StatelessWidget {
  const BoxPlotChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BoxPlotChart(
      data: const BoxPlotChartData(
        items: [
          BoxPlotItem(
            label: 'Q1',
            min: 10,
            q1: 25,
            median: 35,
            q3: 50,
            max: 70,
            outliers: [5, 80],
            mean: 38,
          ),
          BoxPlotItem(
            label: 'Q2',
            min: 15,
            q1: 30,
            median: 45,
            q3: 60,
            max: 75,
            outliers: [8],
            mean: 44,
          ),
          BoxPlotItem(
            label: 'Q3',
            min: 20,
            q1: 35,
            median: 50,
            q3: 65,
            max: 80,
            mean: 50,
          ),
          BoxPlotItem(
            label: 'Q4',
            min: 25,
            q1: 40,
            median: 55,
            q3: 70,
            max: 85,
            outliers: [15, 95],
            mean: 54,
          ),
        ],
        showOutliers: true,
        showMean: true,
        boxWidth: 0.6,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class FunnelChartExample extends StatelessWidget {
  const FunnelChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FunnelChart(
      data: const FunnelChartData(
        sections: [
          FunnelSection(label: 'Visitors', value: 10000, color: Color(0xFF6366F1)),
          FunnelSection(label: 'Leads', value: 6500, color: Color(0xFF8B5CF6)),
          FunnelSection(label: 'Prospects', value: 4200, color: Color(0xFFA855F7)),
          FunnelSection(label: 'Negotiations', value: 2100, color: Color(0xFFC084FC)),
          FunnelSection(label: 'Sales', value: 1200, color: Color(0xFFD8B4FE)),
        ],
        mode: FunnelMode.proportional,
        neckWidth: 0.3,
        gap: 4,
        showLabels: true,
        showValues: true,
        showConversionRate: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class PyramidChartExample extends StatelessWidget {
  const PyramidChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PyramidChart(
      data: const PyramidChartData(
        sections: [
          PyramidSection(label: 'Basic', value: 50, color: Color(0xFF22C55E)),
          PyramidSection(label: 'Standard', value: 35, color: Color(0xFF3B82F6)),
          PyramidSection(label: 'Premium', value: 25, color: Color(0xFF8B5CF6)),
          PyramidSection(label: 'Enterprise', value: 15, color: Color(0xFFF59E0B)),
          PyramidSection(label: 'Ultimate', value: 8, color: Color(0xFFEF4444)),
        ],
        mode: PyramidMode.proportional,
        gap: 3,
        showLabels: true,
        labelPosition: PyramidLabelPosition.right,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
}

class HeatmapChartExample extends StatelessWidget {
  const HeatmapChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatmapChart(
      data: HeatmapChartData(
        data: const [
          [1.0, 2.5, 3.2, 4.1, 2.8],
          [2.3, 4.5, 5.1, 3.8, 4.2],
          [3.1, 3.8, 6.2, 5.5, 3.9],
          [4.2, 5.1, 4.8, 7.2, 5.8],
          [2.9, 3.5, 5.2, 6.1, 8.0],
        ],
        rowLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        columnLabels: const ['9AM', '11AM', '1PM', '3PM', '5PM'],
        colorScale: HeatmapColorScale.viridis,
        showValues: true,
        cellPadding: 2,
        cellBorderRadius: 4,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class TreemapChartExample extends StatelessWidget {
  const TreemapChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return TreemapChart(
      data: TreemapChartData(
        root: TreemapNode(
          label: 'Portfolio',
          children: [
            TreemapNode(
              label: 'Technology',
              children: [
                const TreemapNode(label: 'Apple', value: 35, color: Color(0xFF6366F1)),
                const TreemapNode(label: 'Google', value: 28, color: Color(0xFF8B5CF6)),
                const TreemapNode(label: 'Microsoft', value: 22, color: Color(0xFFA855F7)),
              ],
            ),
            TreemapNode(
              label: 'Finance',
              children: [
                const TreemapNode(label: 'JPMorgan', value: 18, color: Color(0xFF22C55E)),
                const TreemapNode(label: 'Goldman', value: 12, color: Color(0xFF10B981)),
              ],
            ),
            TreemapNode(
              label: 'Healthcare',
              children: [
                const TreemapNode(label: 'Johnson', value: 15, color: Color(0xFF3B82F6)),
                const TreemapNode(label: 'Pfizer', value: 10, color: Color(0xFF0EA5E9)),
              ],
            ),
            const TreemapNode(label: 'Energy', value: 20, color: Color(0xFFF59E0B)),
          ],
        ),
        algorithm: TreemapLayoutAlgorithm.squarified,
        padding: 3,
        showLabels: true,
        labelPosition: TreemapLabelPosition.topLeft,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 800),
      ),
    );
  }
}

class SunburstChartExample extends StatelessWidget {
  const SunburstChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SunburstChart(
      data: SunburstChartData(
        root: SunburstNode(
          label: 'Total',
          children: [
            SunburstNode(
              label: 'Americas',
              color: const Color(0xFF6366F1),
              children: [
                const SunburstNode(label: 'USA', value: 40, color: Color(0xFF818CF8)),
                const SunburstNode(label: 'Canada', value: 15, color: Color(0xFFA5B4FC)),
                const SunburstNode(label: 'Brazil', value: 12, color: Color(0xFFC7D2FE)),
              ],
            ),
            SunburstNode(
              label: 'Europe',
              color: const Color(0xFF22C55E),
              children: [
                const SunburstNode(label: 'UK', value: 18, color: Color(0xFF4ADE80)),
                const SunburstNode(label: 'Germany', value: 16, color: Color(0xFF86EFAC)),
                const SunburstNode(label: 'France', value: 14, color: Color(0xFFBBF7D0)),
              ],
            ),
            SunburstNode(
              label: 'Asia',
              color: const Color(0xFFF59E0B),
              children: [
                const SunburstNode(label: 'China', value: 25, color: Color(0xFFFBBF24)),
                const SunburstNode(label: 'Japan', value: 18, color: Color(0xFFFCD34D)),
                const SunburstNode(label: 'India', value: 12, color: Color(0xFFFDE68A)),
              ],
            ),
          ],
        ),
        innerRadius: 40,
        ringWidth: 50,
        gap: 1,
        showLabels: true,
        showCenterLabel: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
