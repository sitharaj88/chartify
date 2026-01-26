import { useState } from 'react'
import { motion } from 'framer-motion'
import { CodeBlock } from '../components/CodeBlock'

interface Example {
  id: string
  title: string
  description: string
  code: string
}

const examples: Example[] = [
  {
    id: 'dashboard',
    title: 'Analytics Dashboard',
    description: 'A complete dashboard with multiple chart types showing revenue, user metrics, and traffic sources.',
    code: `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Line Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue Trend',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        series: [
                          LineSeries(
                            name: 'This Year',
                            data: [
                              DataPoint(x: 1, y: 45),
                              DataPoint(x: 2, y: 52),
                              DataPoint(x: 3, y: 48),
                              DataPoint(x: 4, y: 61),
                              DataPoint(x: 5, y: 55),
                              DataPoint(x: 6, y: 72),
                            ],
                            color: Colors.blue,
                            curved: true,
                            fillGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.withValues(alpha: 0.3),
                                Colors.blue.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          LineSeries(
                            name: 'Last Year',
                            data: [
                              DataPoint(x: 1, y: 38),
                              DataPoint(x: 2, y: 42),
                              DataPoint(x: 3, y: 45),
                              DataPoint(x: 4, y: 50),
                              DataPoint(x: 5, y: 48),
                              DataPoint(x: 6, y: 58),
                            ],
                            color: Colors.grey,
                            curved: true,
                            strokeDashArray: [5, 5],
                          ),
                        ],
                        config: ChartConfig(
                          tooltip: TooltipConfig(
                            mode: TooltipMode.crosshair,
                          ),
                          legend: LegendConfig(
                            position: LegendPosition.top,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildGaugeCard(
                    context,
                    'Sales Target',
                    78,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGaugeCard(
                    context,
                    'Customer Satisfaction',
                    92,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Traffic Sources Donut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Traffic Sources',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: DonutChart(
                        data: [
                          PieSegment(
                              label: 'Organic', value: 45, color: Colors.green),
                          PieSegment(
                              label: 'Direct', value: 25, color: Colors.blue),
                          PieSegment(
                              label: 'Referral', value: 18, color: Colors.orange),
                          PieSegment(
                              label: 'Social', value: 12, color: Colors.purple),
                        ],
                        config: DonutChartConfig(
                          innerRadiusRatio: 0.6,
                          showLabels: true,
                          centerContent: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Total',
                                  style: TextStyle(color: Colors.grey)),
                              Text('125K',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeCard(
    BuildContext context,
    String title,
    double value,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: GaugeChart(
                value: value,
                config: GaugeConfig(
                  minValue: 0,
                  maxValue: 100,
                  segments: [
                    GaugeSegment(from: 0, to: 50, color: Colors.red),
                    GaugeSegment(from: 50, to: 75, color: Colors.orange),
                    GaugeSegment(from: 75, to: 100, color: color),
                  ],
                  showValue: true,
                  valueStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}`
  },
  {
    id: 'stock-tracker',
    title: 'Stock Price Tracker',
    description: 'Real-time stock price visualization with candlestick chart, volume bars, and technical indicators.',
    code: `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class StockTracker extends StatefulWidget {
  const StockTracker({super.key});

  @override
  State<StockTracker> createState() => _StockTrackerState();
}

class _StockTrackerState extends State<StockTracker> {
  String selectedPeriod = '1M';
  final periods = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  // Sample stock data
  final stockData = [
    CandlestickData(
      date: DateTime(2024, 1, 2),
      open: 185.0, high: 188.0, low: 183.0, close: 187.5,
      volume: 45000000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 3),
      open: 187.5, high: 190.0, low: 186.0, close: 189.2,
      volume: 52000000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 4),
      open: 189.2, high: 191.5, low: 188.0, close: 188.5,
      volume: 38000000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 5),
      open: 188.5, high: 192.0, low: 187.5, close: 191.8,
      volume: 61000000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 8),
      open: 191.8, high: 195.0, low: 190.0, close: 194.2,
      volume: 72000000,
    ),
    // Add more data points...
  ];

  @override
  Widget build(BuildContext context) {
    final latestPrice = stockData.last.close;
    final previousPrice = stockData[stockData.length - 2].close;
    final change = latestPrice - previousPrice;
    final changePercent = (change / previousPrice) * 100;
    final isPositive = change >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AAPL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$\${latestPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    Text(
                      '\${change >= 0 ? '+' : ''}\${change.toStringAsFixed(2)} '
                      '(\${changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Period Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: periods.map((period) {
                final isSelected = period == selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => selectedPeriod = period),
                  ),
                );
              }).toList(),
            ),
          ),

          // Candlestick Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CandlestickChart(
                data: stockData,
                config: CandlestickConfig(
                  upColor: Colors.green,
                  downColor: Colors.red,
                  showVolume: true,
                  volumeHeight: 0.2,
                  enableZoom: true,
                  enablePan: true,
                  showGrid: true,
                  gridColor: Colors.grey.shade200,
                  tooltip: TooltipConfig(
                    enabled: true,
                    formatter: (data) => '''
Open: \\\$\${data.open.toStringAsFixed(2)}
High: \\\$\${data.high.toStringAsFixed(2)}
Low: \\\$\${data.low.toStringAsFixed(2)}
Close: \\\$\${data.close.toStringAsFixed(2)}
Volume: \${(data.volume / 1000000).toStringAsFixed(1)}M''',
                  ),
                  crosshair: CrosshairConfig(
                    enabled: true,
                    lineColor: Colors.grey,
                    labelBackgroundColor: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Buy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sell'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}`
  },
  {
    id: 'project-management',
    title: 'Project Timeline',
    description: 'Gantt chart showing project tasks, dependencies, milestones, and progress tracking.',
    code: `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class ProjectTimeline extends StatelessWidget {
  const ProjectTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      GanttTask(
        id: 'planning',
        label: 'Project Planning',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 15),
        progress: 100,
        color: Colors.blue,
      ),
      GanttTask(
        id: 'requirements',
        label: 'Requirements Gathering',
        startDate: DateTime(2024, 1, 8),
        endDate: DateTime(2024, 1, 22),
        progress: 100,
        color: Colors.blue,
        dependencies: ['planning'],
      ),
      GanttTask(
        id: 'design',
        label: 'UI/UX Design',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 2, 5),
        progress: 85,
        color: Colors.purple,
        dependencies: ['requirements'],
      ),
      GanttTask(
        id: 'backend',
        label: 'Backend Development',
        startDate: DateTime(2024, 1, 25),
        endDate: DateTime(2024, 3, 1),
        progress: 60,
        color: Colors.green,
        dependencies: ['requirements'],
      ),
      GanttTask(
        id: 'frontend',
        label: 'Frontend Development',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 3, 15),
        progress: 45,
        color: Colors.orange,
        dependencies: ['design'],
      ),
      GanttTask(
        id: 'integration',
        label: 'API Integration',
        startDate: DateTime(2024, 2, 20),
        endDate: DateTime(2024, 3, 10),
        progress: 20,
        color: Colors.teal,
        dependencies: ['backend', 'frontend'],
      ),
      GanttTask(
        id: 'testing',
        label: 'Testing & QA',
        startDate: DateTime(2024, 3, 5),
        endDate: DateTime(2024, 3, 25),
        progress: 0,
        color: Colors.red,
        dependencies: ['integration'],
      ),
      GanttTask(
        id: 'deployment',
        label: 'Deployment',
        startDate: DateTime(2024, 3, 20),
        endDate: DateTime(2024, 3, 30),
        progress: 0,
        color: Colors.indigo,
        dependencies: ['testing'],
        isMilestone: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Tasks', '8'),
                _buildSummaryItem('Completed', '2'),
                _buildSummaryItem('In Progress', '4'),
                _buildSummaryItem('Overall', '52%'),
              ],
            ),
          ),

          // Gantt Chart
          Expanded(
            child: GanttChart(
              tasks: tasks,
              config: GanttConfig(
                showProgress: true,
                showDependencies: true,
                showMilestones: true,
                rowHeight: 48,
                headerHeight: 60,
                gridColor: Colors.grey.shade200,
                todayLineColor: Colors.red,
                todayLineWidth: 2,
                dependencyLineColor: Colors.grey,
                dependencyLineStyle: DependencyLineStyle.curved,
                onTaskTap: (task) {
                  // Show task details
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _TaskDetailSheet(task: task),
                  );
                },
                onTaskDoubleTap: (task) {
                  // Edit task
                },
                tooltip: TooltipConfig(
                  enabled: true,
                  formatter: (task) => '''
\${task.label}
Start: \${_formatDate(task.startDate)}
End: \${_formatDate(task.endDate)}
Progress: \${task.progress}%''',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new task
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '\${date.month}/\${date.day}/\${date.year}';
}

class _TaskDetailSheet extends StatelessWidget {
  final GanttTask task;

  const _TaskDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: task.progress / 100,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 8),
          Text('\${task.progress}% Complete'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Edit Task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}`
  },
  {
    id: 'energy-flow',
    title: 'Energy Flow Diagram',
    description: 'Sankey diagram showing energy production, distribution, and consumption flows.',
    code: `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class EnergyFlowDiagram extends StatelessWidget {
  const EnergyFlowDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Flow Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Production & Consumption',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Annual energy flow in Terawatt-hours (TWh)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SankeyChart(
                nodes: [
                  // Sources (left)
                  SankeyNode(
                    id: 'coal',
                    label: 'Coal',
                    color: Colors.brown,
                  ),
                  SankeyNode(
                    id: 'natural_gas',
                    label: 'Natural Gas',
                    color: Colors.blue,
                  ),
                  SankeyNode(
                    id: 'nuclear',
                    label: 'Nuclear',
                    color: Colors.purple,
                  ),
                  SankeyNode(
                    id: 'renewables',
                    label: 'Renewables',
                    color: Colors.green,
                  ),
                  SankeyNode(
                    id: 'oil',
                    label: 'Oil',
                    color: Colors.black87,
                  ),

                  // Intermediate (middle)
                  SankeyNode(
                    id: 'electricity',
                    label: 'Electricity Generation',
                    color: Colors.amber,
                  ),
                  SankeyNode(
                    id: 'heat',
                    label: 'Heat Production',
                    color: Colors.red,
                  ),

                  // End uses (right)
                  SankeyNode(
                    id: 'residential',
                    label: 'Residential',
                    color: Colors.teal,
                  ),
                  SankeyNode(
                    id: 'commercial',
                    label: 'Commercial',
                    color: Colors.indigo,
                  ),
                  SankeyNode(
                    id: 'industrial',
                    label: 'Industrial',
                    color: Colors.orange,
                  ),
                  SankeyNode(
                    id: 'transport',
                    label: 'Transportation',
                    color: Colors.cyan,
                  ),
                  SankeyNode(
                    id: 'losses',
                    label: 'Losses',
                    color: Colors.grey,
                  ),
                ],
                links: [
                  // Source to electricity
                  SankeyLink(
                      source: 'coal', target: 'electricity', value: 950),
                  SankeyLink(
                      source: 'natural_gas',
                      target: 'electricity',
                      value: 620),
                  SankeyLink(
                      source: 'nuclear', target: 'electricity', value: 380),
                  SankeyLink(
                      source: 'renewables',
                      target: 'electricity',
                      value: 480),

                  // Source to heat
                  SankeyLink(
                      source: 'natural_gas', target: 'heat', value: 280),
                  SankeyLink(source: 'coal', target: 'heat', value: 120),

                  // Direct use
                  SankeyLink(
                      source: 'oil', target: 'transport', value: 850),
                  SankeyLink(
                      source: 'natural_gas',
                      target: 'industrial',
                      value: 340),

                  // Electricity to end uses
                  SankeyLink(
                      source: 'electricity',
                      target: 'residential',
                      value: 520),
                  SankeyLink(
                      source: 'electricity',
                      target: 'commercial',
                      value: 480),
                  SankeyLink(
                      source: 'electricity',
                      target: 'industrial',
                      value: 680),
                  SankeyLink(
                      source: 'electricity',
                      target: 'transport',
                      value: 120),
                  SankeyLink(
                      source: 'electricity', target: 'losses', value: 630),

                  // Heat to end uses
                  SankeyLink(
                      source: 'heat', target: 'residential', value: 180),
                  SankeyLink(
                      source: 'heat', target: 'commercial', value: 120),
                  SankeyLink(
                      source: 'heat', target: 'industrial', value: 80),
                  SankeyLink(source: 'heat', target: 'losses', value: 20),
                ],
                config: SankeyConfig(
                  title: ChartTitle(text: ''),
                  nodeWidth: 24,
                  nodePadding: 20,
                  linkOpacity: 0.5,
                  linkGradient: true,
                  showLabels: true,
                  labelPadding: 8,
                  tooltip: TooltipConfig(
                    enabled: true,
                    formatter: (link) =>
                        '\${link.source} → \${link.target}\\n\${link.value} TWh',
                  ),
                  onNodeTap: (node) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped: \${node.label}')),
                    );
                  },
                ),
              ),
            ),

            // Legend
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem('Sources', Colors.blue),
                _legendItem('Conversion', Colors.amber),
                _legendItem('End Use', Colors.teal),
                _legendItem('Losses', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}`
  },
  {
    id: 'performance-radar',
    title: 'Performance Comparison',
    description: 'Radar chart comparing multiple products or entities across various performance metrics.',
    code: `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class PerformanceComparison extends StatefulWidget {
  const PerformanceComparison({super.key});

  @override
  State<PerformanceComparison> createState() => _PerformanceComparisonState();
}

class _PerformanceComparisonState extends State<PerformanceComparison> {
  final categories = [
    'Performance',
    'Battery Life',
    'Display',
    'Camera',
    'Build Quality',
    'Value',
  ];

  final products = [
    {
      'name': 'Phone A',
      'color': Colors.blue,
      'data': [92, 78, 88, 95, 85, 72],
    },
    {
      'name': 'Phone B',
      'color': Colors.red,
      'data': [88, 92, 85, 82, 90, 88],
    },
    {
      'name': 'Phone C',
      'color': Colors.green,
      'data': [78, 85, 92, 88, 82, 95],
    },
  ];

  Set<int> selectedProducts = {0, 1, 2};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Comparison'),
      ),
      body: Column(
        children: [
          // Product Selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: List.generate(products.length, (index) {
                final product = products[index];
                final isSelected = selectedProducts.contains(index);
                return FilterChip(
                  label: Text(product['name'] as String),
                  selected: isSelected,
                  selectedColor:
                      (product['color'] as Color).withValues(alpha: 0.2),
                  checkmarkColor: product['color'] as Color,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedProducts.add(index);
                      } else if (selectedProducts.length > 1) {
                        selectedProducts.remove(index);
                      }
                    });
                  },
                );
              }),
            ),
          ),

          // Radar Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RadarChart(
                categories: categories,
                series: selectedProducts.map((index) {
                  final product = products[index];
                  return RadarSeries(
                    name: product['name'] as String,
                    data: (product['data'] as List<int>)
                        .map((e) => e.toDouble())
                        .toList(),
                    color: product['color'] as Color,
                    fillOpacity: 0.2,
                    strokeWidth: 2,
                  );
                }).toList(),
                config: RadarConfig(
                  maxValue: 100,
                  gridCount: 5,
                  gridColor: Colors.grey.shade300,
                  gridStyle: RadarGridStyle.polygon,
                  axisColor: Colors.grey.shade400,
                  showLabels: true,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  labelOffset: 24,
                  animationDuration: const Duration(milliseconds: 500),
                  legend: LegendConfig(
                    position: LegendPosition.bottom,
                    orientation: LegendOrientation.horizontal,
                  ),
                  tooltip: TooltipConfig(
                    enabled: true,
                  ),
                ),
              ),
            ),
          ),

          // Detailed Scores
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Scores',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...categories.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: selectedProducts.map((productIndex) {
                              final product = products[productIndex];
                              final score =
                                  (product['data'] as List<int>)[entry.key];
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    children: [
                                      LinearProgressIndicator(
                                        value: score / 100,
                                        backgroundColor:
                                            Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          product['color'] as Color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$score',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: product['color'] as Color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}`
  },
]

export function Examples() {
  const [selectedExample, setSelectedExample] = useState(examples[0])

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <h1 className="text-4xl font-bold text-slate-900 dark:text-white mb-4">
            Real-World Examples
          </h1>
          <p className="text-lg text-slate-600 dark:text-slate-400 max-w-3xl">
            Complete, production-ready examples showing how to use Chartify in real applications.
            Each example includes full source code that you can copy and adapt.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid lg:grid-cols-4 gap-8">
          {/* Example List */}
          <div className="space-y-2">
            {examples.map(example => (
              <button
                key={example.id}
                onClick={() => setSelectedExample(example)}
                className={`w-full text-left p-4 rounded-lg transition-colors ${
                  selectedExample.id === example.id
                    ? 'bg-primary-50 dark:bg-primary-900/20 border-2 border-primary-500'
                    : 'bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:border-primary-300 dark:hover:border-primary-700'
                }`}
              >
                <h3 className={`font-medium mb-1 ${
                  selectedExample.id === example.id
                    ? 'text-primary-700 dark:text-primary-300'
                    : 'text-slate-900 dark:text-white'
                }`}>
                  {example.title}
                </h3>
                <p className="text-sm text-slate-500 dark:text-slate-400 line-clamp-2">
                  {example.description}
                </p>
              </button>
            ))}
          </div>

          {/* Code Display */}
          <div className="lg:col-span-3">
            <motion.div
              key={selectedExample.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
            >
              <div className="mb-6">
                <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">
                  {selectedExample.title}
                </h2>
                <p className="text-slate-600 dark:text-slate-400">
                  {selectedExample.description}
                </p>
              </div>

              <CodeBlock
                code={selectedExample.code}
                language="dart"
                filename={`${selectedExample.id}.dart`}
              />
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}
