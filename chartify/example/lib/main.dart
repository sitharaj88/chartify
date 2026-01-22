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
