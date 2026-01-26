export interface ChartInfo {
  id: string
  title: string
  description: string
  category: 'cartesian' | 'circular' | 'hierarchical' | 'statistical' | 'specialty' | 'financial'
  features: string[]
  code: string
}

export const chartCategories = [
  { id: 'cartesian', label: 'Cartesian Charts', description: 'X-Y axis based charts for time series and comparisons' },
  { id: 'circular', label: 'Circular Charts', description: 'Pie, donut, and radial charts for proportions' },
  { id: 'hierarchical', label: 'Hierarchical Charts', description: 'Treemaps and sunbursts for nested data' },
  { id: 'statistical', label: 'Statistical Charts', description: 'Box plots and histograms for data analysis' },
  { id: 'specialty', label: 'Specialty Charts', description: 'Radar, funnel, Sankey, and gauge charts' },
  { id: 'financial', label: 'Financial Charts', description: 'Candlestick and OHLC for market data' },
]

export const charts: ChartInfo[] = [
  // Cartesian Charts
  {
    id: 'line',
    title: 'Line Chart',
    description: 'Display trends over time with smooth or straight lines. Supports multiple series, gradient fills, and data point markers.',
    category: 'cartesian',
    features: ['Multiple series', 'Smooth curves', 'Gradient fills', 'Interactive tooltips', 'Zoom & pan'],
    code: `import 'package:chartify/chartify.dart';

LineChart(
  series: [
    LineSeries(
      name: 'Revenue',
      data: [
        DataPoint(x: 1, y: 30),
        DataPoint(x: 2, y: 45),
        DataPoint(x: 3, y: 28),
        DataPoint(x: 4, y: 65),
        DataPoint(x: 5, y: 52),
      ],
      color: Colors.blue,
      strokeWidth: 2,
      showPoints: true,
      pointRadius: 4,
      curved: true, // Enable smooth curves
    ),
  ],
  config: ChartConfig(
    title: ChartTitle(text: 'Monthly Revenue'),
    legend: LegendConfig(position: LegendPosition.bottom),
    tooltip: TooltipConfig(enabled: true),
    xAxis: AxisConfig(
      title: AxisTitle(text: 'Month'),
      gridLines: GridLineConfig(show: true),
    ),
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Revenue (\\$K)'),
    ),
  ),
)`
  },
  {
    id: 'bar',
    title: 'Bar Chart',
    description: 'Compare values across categories with vertical bars. Supports grouped, stacked, and horizontal orientations.',
    category: 'cartesian',
    features: ['Grouped bars', 'Stacked bars', 'Horizontal mode', 'Rounded corners', 'Value labels'],
    code: `import 'package:chartify/chartify.dart';

BarChart(
  series: [
    BarSeries(
      name: 'Q1',
      data: [
        DataPoint(x: 0, y: 120),
        DataPoint(x: 1, y: 85),
        DataPoint(x: 2, y: 140),
        DataPoint(x: 3, y: 95),
      ],
      color: Colors.indigo,
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    BarSeries(
      name: 'Q2',
      data: [
        DataPoint(x: 0, y: 95),
        DataPoint(x: 1, y: 110),
        DataPoint(x: 2, y: 125),
        DataPoint(x: 3, y: 140),
      ],
      color: Colors.teal,
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
  ],
  config: ChartConfig(
    title: ChartTitle(text: 'Quarterly Sales by Region'),
    barMode: BarMode.grouped, // or BarMode.stacked
    xAxis: AxisConfig(
      categories: ['North', 'South', 'East', 'West'],
    ),
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Sales (\\$K)'),
    ),
  ),
)`
  },
  {
    id: 'area',
    title: 'Area Chart',
    description: 'Visualize cumulative totals with filled areas under lines. Perfect for showing trends and part-to-whole relationships.',
    category: 'cartesian',
    features: ['Gradient fills', 'Stacked areas', 'Transparency', 'Smooth curves', 'Multiple series'],
    code: `import 'package:chartify/chartify.dart';

AreaChart(
  series: [
    AreaSeries(
      name: 'Desktop',
      data: [
        DataPoint(x: 1, y: 60),
        DataPoint(x: 2, y: 55),
        DataPoint(x: 3, y: 52),
        DataPoint(x: 4, y: 48),
        DataPoint(x: 5, y: 45),
      ],
      color: Colors.blue,
      fillGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withValues(alpha: 0.4),
          Colors.blue.withValues(alpha: 0.0),
        ],
      ),
      curved: true,
    ),
    AreaSeries(
      name: 'Mobile',
      data: [
        DataPoint(x: 1, y: 40),
        DataPoint(x: 2, y: 45),
        DataPoint(x: 3, y: 48),
        DataPoint(x: 4, y: 52),
        DataPoint(x: 5, y: 55),
      ],
      color: Colors.green,
      fillGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.withValues(alpha: 0.4),
          Colors.green.withValues(alpha: 0.0),
        ],
      ),
      curved: true,
    ),
  ],
  config: ChartConfig(
    title: ChartTitle(text: 'Device Usage Trends'),
    areaMode: AreaMode.normal, // or AreaMode.stacked
    legend: LegendConfig(position: LegendPosition.top),
  ),
)`
  },
  {
    id: 'scatter',
    title: 'Scatter Chart',
    description: 'Plot individual data points to reveal correlations and patterns. Supports bubble sizing and color mapping.',
    category: 'cartesian',
    features: ['Correlation analysis', 'Bubble sizing', 'Color mapping', 'Trend lines', 'Clustering'],
    code: `import 'package:chartify/chartify.dart';

ScatterChart(
  series: [
    ScatterSeries(
      name: 'Product A',
      data: [
        ScatterPoint(x: 10, y: 20, size: 15),
        ScatterPoint(x: 15, y: 35, size: 20),
        ScatterPoint(x: 25, y: 45, size: 25),
        ScatterPoint(x: 35, y: 30, size: 18),
        ScatterPoint(x: 45, y: 55, size: 30),
      ],
      color: Colors.purple,
      opacity: 0.7,
    ),
    ScatterSeries(
      name: 'Product B',
      data: [
        ScatterPoint(x: 12, y: 25, size: 12),
        ScatterPoint(x: 22, y: 40, size: 22),
        ScatterPoint(x: 32, y: 35, size: 16),
        ScatterPoint(x: 42, y: 50, size: 28),
      ],
      color: Colors.orange,
      opacity: 0.7,
    ),
  ],
  config: ChartConfig(
    title: ChartTitle(text: 'Price vs Performance'),
    xAxis: AxisConfig(title: AxisTitle(text: 'Price (\\$)')),
    yAxis: AxisConfig(title: AxisTitle(text: 'Performance Score')),
    tooltip: TooltipConfig(
      formatter: (point) =>
        'Price: \\$\${point.x}\\nScore: \${point.y}\\nMarket Share: \${point.size}%',
    ),
  ),
)`
  },
  // Circular Charts
  {
    id: 'pie',
    title: 'Pie Chart',
    description: 'Show proportions of a whole with circular segments. Features animations, labels, and interactive selection.',
    category: 'circular',
    features: ['Animated slices', 'Percentage labels', 'Exploded slices', 'Custom colors', 'Legend integration'],
    code: `import 'package:chartify/chartify.dart';

PieChart(
  data: [
    PieSegment(
      label: 'Chrome',
      value: 65.5,
      color: Colors.blue,
    ),
    PieSegment(
      label: 'Safari',
      value: 18.8,
      color: Colors.orange,
    ),
    PieSegment(
      label: 'Firefox',
      value: 8.2,
      color: Colors.red,
    ),
    PieSegment(
      label: 'Edge',
      value: 4.5,
      color: Colors.green,
    ),
    PieSegment(
      label: 'Other',
      value: 3.0,
      color: Colors.grey,
    ),
  ],
  config: PieChartConfig(
    title: ChartTitle(text: 'Browser Market Share'),
    showLabels: true,
    labelPosition: LabelPosition.outside,
    labelFormatter: (segment) => '\${segment.label}\\n\${segment.percentage.toStringAsFixed(1)}%',
    startAngle: -90, // Start from top
    animationDuration: Duration(milliseconds: 800),
    onSegmentTap: (segment) => print('Tapped: \${segment.label}'),
  ),
)`
  },
  {
    id: 'donut',
    title: 'Donut Chart',
    description: 'A pie chart with a hollow center, perfect for displaying a key metric alongside proportions.',
    category: 'circular',
    features: ['Center content', 'Ring thickness', 'Multiple rings', 'Hover effects', 'Animated transitions'],
    code: `import 'package:chartify/chartify.dart';

DonutChart(
  data: [
    PieSegment(label: 'Completed', value: 72, color: Colors.green),
    PieSegment(label: 'In Progress', value: 18, color: Colors.blue),
    PieSegment(label: 'Pending', value: 10, color: Colors.grey),
  ],
  config: DonutChartConfig(
    title: ChartTitle(text: 'Project Status'),
    innerRadiusRatio: 0.6, // 60% hollow center
    centerContent: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '72%',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Completed',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
    strokeWidth: 2,
    strokeColor: Colors.white,
  ),
)`
  },
  {
    id: 'radial-bar',
    title: 'Radial Bar Chart',
    description: 'Display progress or comparison using circular bars. Great for dashboards and KPI displays.',
    category: 'circular',
    features: ['Progress tracking', 'Multiple rings', 'Gradient fills', 'Animated loading', 'Center labels'],
    code: `import 'package:chartify/chartify.dart';

RadialBarChart(
  data: [
    RadialBarSegment(
      label: 'Sales',
      value: 85,
      maxValue: 100,
      color: Colors.blue,
    ),
    RadialBarSegment(
      label: 'Revenue',
      value: 72,
      maxValue: 100,
      color: Colors.green,
    ),
    RadialBarSegment(
      label: 'Customers',
      value: 58,
      maxValue: 100,
      color: Colors.orange,
    ),
  ],
  config: RadialBarConfig(
    title: ChartTitle(text: 'Q4 Performance'),
    trackColor: Colors.grey.shade200,
    barWidth: 16,
    cornerRadius: 8,
    startAngle: -90,
    showLabels: true,
    labelPosition: RadialLabelPosition.end,
  ),
)`
  },
  // Hierarchical Charts
  {
    id: 'treemap',
    title: 'Treemap',
    description: 'Visualize hierarchical data using nested rectangles. Size represents quantity, color can show categories or values.',
    category: 'hierarchical',
    features: ['Nested rectangles', 'Drill-down', 'Color mapping', 'Tooltip on hover', 'Squarified layout'],
    code: `import 'package:chartify/chartify.dart';

TreemapChart(
  data: TreemapNode(
    label: 'Portfolio',
    children: [
      TreemapNode(
        label: 'Technology',
        value: 45000,
        color: Colors.blue,
        children: [
          TreemapNode(label: 'Software', value: 25000),
          TreemapNode(label: 'Hardware', value: 15000),
          TreemapNode(label: 'Services', value: 5000),
        ],
      ),
      TreemapNode(
        label: 'Healthcare',
        value: 30000,
        color: Colors.green,
        children: [
          TreemapNode(label: 'Pharma', value: 18000),
          TreemapNode(label: 'Biotech', value: 12000),
        ],
      ),
      TreemapNode(
        label: 'Finance',
        value: 25000,
        color: Colors.orange,
        children: [
          TreemapNode(label: 'Banking', value: 15000),
          TreemapNode(label: 'Insurance', value: 10000),
        ],
      ),
    ],
  ),
  config: TreemapConfig(
    title: ChartTitle(text: 'Investment Portfolio'),
    showLabels: true,
    padding: EdgeInsets.all(2),
    borderRadius: BorderRadius.circular(4),
    colorScheme: ColorScheme.category10,
    onNodeTap: (node) => print('Tapped: \${node.label}'),
  ),
)`
  },
  {
    id: 'sunburst',
    title: 'Sunburst Chart',
    description: 'Display hierarchical data in concentric rings. Inner rings represent higher levels, outer rings show details.',
    category: 'hierarchical',
    features: ['Multi-level rings', 'Interactive drill-down', 'Arc animations', 'Breadcrumb trail', 'Color inheritance'],
    code: `import 'package:chartify/chartify.dart';

SunburstChart(
  data: SunburstNode(
    label: 'Total',
    children: [
      SunburstNode(
        label: 'Americas',
        value: 40,
        color: Colors.blue,
        children: [
          SunburstNode(label: 'USA', value: 25),
          SunburstNode(label: 'Canada', value: 10),
          SunburstNode(label: 'Brazil', value: 5),
        ],
      ),
      SunburstNode(
        label: 'Europe',
        value: 35,
        color: Colors.green,
        children: [
          SunburstNode(label: 'UK', value: 15),
          SunburstNode(label: 'Germany', value: 12),
          SunburstNode(label: 'France', value: 8),
        ],
      ),
      SunburstNode(
        label: 'Asia',
        value: 25,
        color: Colors.orange,
        children: [
          SunburstNode(label: 'China', value: 12),
          SunburstNode(label: 'Japan', value: 8),
          SunburstNode(label: 'India', value: 5),
        ],
      ),
    ],
  ),
  config: SunburstConfig(
    title: ChartTitle(text: 'Global Revenue Distribution'),
    innerRadius: 40,
    padAngle: 0.02,
    showLabels: true,
    animationDuration: Duration(milliseconds: 600),
  ),
)`
  },
  // Statistical Charts
  {
    id: 'box-plot',
    title: 'Box Plot',
    description: 'Display statistical distribution showing median, quartiles, and outliers. Essential for data analysis.',
    category: 'statistical',
    features: ['Quartile display', 'Outlier detection', 'Whisker lines', 'Multiple groups', 'Horizontal mode'],
    code: `import 'package:chartify/chartify.dart';

BoxPlotChart(
  data: [
    BoxPlotData(
      label: 'Group A',
      min: 10,
      q1: 25,
      median: 50,
      q3: 75,
      max: 90,
      outliers: [5, 95],
      color: Colors.blue,
    ),
    BoxPlotData(
      label: 'Group B',
      min: 20,
      q1: 35,
      median: 55,
      q3: 70,
      max: 85,
      outliers: [],
      color: Colors.green,
    ),
    BoxPlotData(
      label: 'Group C',
      min: 15,
      q1: 30,
      median: 45,
      q3: 65,
      max: 80,
      outliers: [8, 88],
      color: Colors.orange,
    ),
  ],
  config: BoxPlotConfig(
    title: ChartTitle(text: 'Distribution Comparison'),
    boxWidth: 40,
    whiskerWidth: 20,
    outlierRadius: 4,
    showMean: true,
    meanMarker: BoxPlotMarker.diamond,
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Values'),
    ),
  ),
)`
  },
  {
    id: 'histogram',
    title: 'Histogram',
    description: 'Visualize frequency distribution of continuous data. Automatically bins values into ranges.',
    category: 'statistical',
    features: ['Auto binning', 'Custom bin width', 'Frequency/density', 'Cumulative line', 'Normal overlay'],
    code: `import 'package:chartify/chartify.dart';

HistogramChart(
  data: [
    23, 45, 56, 34, 67, 78, 45, 56, 67, 78,
    89, 45, 56, 34, 23, 45, 67, 78, 56, 45,
    34, 56, 67, 45, 56, 78, 89, 67, 56, 45,
  ],
  config: HistogramConfig(
    title: ChartTitle(text: 'Score Distribution'),
    binCount: 10, // or use binWidth: 10
    color: Colors.indigo,
    borderColor: Colors.indigo.shade700,
    showCumulative: true,
    cumulativeColor: Colors.red,
    xAxis: AxisConfig(
      title: AxisTitle(text: 'Score Range'),
    ),
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Frequency'),
    ),
  ),
)`
  },
  // Specialty Charts
  {
    id: 'radar',
    title: 'Radar Chart',
    description: 'Compare multiple variables across categories on a circular grid. Perfect for performance metrics.',
    category: 'specialty',
    features: ['Multi-axis comparison', 'Filled polygons', 'Multiple series', 'Custom scales', 'Animated drawing'],
    code: `import 'package:chartify/chartify.dart';

RadarChart(
  categories: ['Speed', 'Power', 'Range', 'Handling', 'Comfort', 'Price'],
  series: [
    RadarSeries(
      name: 'Model X',
      data: [85, 90, 70, 80, 75, 65],
      color: Colors.blue,
      fillOpacity: 0.3,
    ),
    RadarSeries(
      name: 'Model Y',
      data: [75, 80, 85, 70, 85, 80],
      color: Colors.red,
      fillOpacity: 0.3,
    ),
  ],
  config: RadarConfig(
    title: ChartTitle(text: 'Vehicle Comparison'),
    maxValue: 100,
    gridCount: 5,
    gridColor: Colors.grey.shade300,
    showLabels: true,
    labelOffset: 20,
    legend: LegendConfig(position: LegendPosition.bottom),
  ),
)`
  },
  {
    id: 'funnel',
    title: 'Funnel Chart',
    description: 'Visualize stages in a process showing progressive reduction. Ideal for sales pipelines.',
    category: 'specialty',
    features: ['Stage visualization', 'Conversion rates', 'Gradient fills', 'Labels with values', 'Horizontal mode'],
    code: `import 'package:chartify/chartify.dart';

FunnelChart(
  data: [
    FunnelSegment(
      label: 'Visitors',
      value: 10000,
      color: Colors.blue.shade400,
    ),
    FunnelSegment(
      label: 'Leads',
      value: 6500,
      color: Colors.blue.shade500,
    ),
    FunnelSegment(
      label: 'Qualified',
      value: 4200,
      color: Colors.blue.shade600,
    ),
    FunnelSegment(
      label: 'Proposals',
      value: 2100,
      color: Colors.blue.shade700,
    ),
    FunnelSegment(
      label: 'Closed',
      value: 850,
      color: Colors.blue.shade800,
    ),
  ],
  config: FunnelConfig(
    title: ChartTitle(text: 'Sales Funnel'),
    showLabels: true,
    showValues: true,
    showConversionRate: true,
    neckWidth: 0.3, // Width at bottom
    gap: 4,
    labelPosition: FunnelLabelPosition.right,
  ),
)`
  },
  {
    id: 'sankey',
    title: 'Sankey Diagram',
    description: 'Show flow and quantities between nodes. Width of links represents magnitude of flow.',
    category: 'specialty',
    features: ['Flow visualization', 'Node positioning', 'Link gradients', 'Hover highlighting', 'Tooltips'],
    code: `import 'package:chartify/chartify.dart';

SankeyChart(
  nodes: [
    SankeyNode(id: 'coal', label: 'Coal', color: Colors.brown),
    SankeyNode(id: 'gas', label: 'Natural Gas', color: Colors.blue),
    SankeyNode(id: 'oil', label: 'Oil', color: Colors.black87),
    SankeyNode(id: 'electricity', label: 'Electricity', color: Colors.yellow),
    SankeyNode(id: 'residential', label: 'Residential', color: Colors.green),
    SankeyNode(id: 'commercial', label: 'Commercial', color: Colors.purple),
    SankeyNode(id: 'industrial', label: 'Industrial', color: Colors.orange),
  ],
  links: [
    SankeyLink(source: 'coal', target: 'electricity', value: 25),
    SankeyLink(source: 'gas', target: 'electricity', value: 35),
    SankeyLink(source: 'gas', target: 'residential', value: 15),
    SankeyLink(source: 'oil', target: 'industrial', value: 30),
    SankeyLink(source: 'electricity', target: 'residential', value: 25),
    SankeyLink(source: 'electricity', target: 'commercial', value: 20),
    SankeyLink(source: 'electricity', target: 'industrial', value: 15),
  ],
  config: SankeyConfig(
    title: ChartTitle(text: 'Energy Flow'),
    nodeWidth: 20,
    nodePadding: 15,
    linkOpacity: 0.5,
    showLabels: true,
  ),
)`
  },
  {
    id: 'gauge',
    title: 'Gauge Chart',
    description: 'Display a single value within a range using a dial or arc. Perfect for KPIs and dashboards.',
    category: 'specialty',
    features: ['Arc display', 'Color zones', 'Animated needle', 'Value formatting', 'Min/max labels'],
    code: `import 'package:chartify/chartify.dart';

GaugeChart(
  value: 72,
  config: GaugeConfig(
    title: ChartTitle(text: 'Performance Score'),
    minValue: 0,
    maxValue: 100,
    startAngle: 135,
    sweepAngle: 270,
    segments: [
      GaugeSegment(
        from: 0,
        to: 40,
        color: Colors.red,
        label: 'Poor',
      ),
      GaugeSegment(
        from: 40,
        to: 70,
        color: Colors.orange,
        label: 'Fair',
      ),
      GaugeSegment(
        from: 70,
        to: 100,
        color: Colors.green,
        label: 'Good',
      ),
    ],
    showValue: true,
    valueStyle: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
    needleColor: Colors.grey.shade800,
    needleWidth: 4,
    animationDuration: Duration(milliseconds: 1000),
  ),
)`
  },
  {
    id: 'gantt',
    title: 'Gantt Chart',
    description: 'Project timeline visualization showing tasks, durations, and dependencies across time.',
    category: 'specialty',
    features: ['Task timelines', 'Dependencies', 'Progress bars', 'Milestones', 'Resource allocation'],
    code: `import 'package:chartify/chartify.dart';

GanttChart(
  tasks: [
    GanttTask(
      id: '1',
      label: 'Planning',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 15),
      progress: 100,
      color: Colors.blue,
    ),
    GanttTask(
      id: '2',
      label: 'Design',
      startDate: DateTime(2024, 1, 10),
      endDate: DateTime(2024, 2, 1),
      progress: 80,
      color: Colors.purple,
      dependencies: ['1'],
    ),
    GanttTask(
      id: '3',
      label: 'Development',
      startDate: DateTime(2024, 1, 25),
      endDate: DateTime(2024, 3, 15),
      progress: 45,
      color: Colors.green,
      dependencies: ['2'],
    ),
    GanttTask(
      id: '4',
      label: 'Testing',
      startDate: DateTime(2024, 3, 1),
      endDate: DateTime(2024, 3, 30),
      progress: 0,
      color: Colors.orange,
      dependencies: ['3'],
    ),
  ],
  config: GanttConfig(
    title: ChartTitle(text: 'Project Timeline'),
    showProgress: true,
    showDependencies: true,
    rowHeight: 40,
    headerHeight: 50,
    gridColor: Colors.grey.shade200,
    todayLineColor: Colors.red,
  ),
)`
  },
  // Financial Charts
  {
    id: 'candlestick',
    title: 'Candlestick Chart',
    description: 'Financial chart showing open, high, low, close prices. Essential for stock market analysis.',
    category: 'financial',
    features: ['OHLC data', 'Volume overlay', 'Custom colors', 'Technical indicators', 'Zoom & scroll'],
    code: `import 'package:chartify/chartify.dart';

CandlestickChart(
  data: [
    CandlestickData(
      date: DateTime(2024, 1, 1),
      open: 150.0,
      high: 155.0,
      low: 148.0,
      close: 153.0,
      volume: 1000000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 2),
      open: 153.0,
      high: 158.0,
      low: 152.0,
      close: 156.0,
      volume: 1200000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 3),
      open: 156.0,
      high: 157.0,
      low: 150.0,
      close: 151.0,
      volume: 900000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 4),
      open: 151.0,
      high: 154.0,
      low: 149.0,
      close: 152.0,
      volume: 800000,
    ),
    CandlestickData(
      date: DateTime(2024, 1, 5),
      open: 152.0,
      high: 160.0,
      low: 151.0,
      close: 159.0,
      volume: 1500000,
    ),
  ],
  config: CandlestickConfig(
    title: ChartTitle(text: 'AAPL Stock Price'),
    upColor: Colors.green,
    downColor: Colors.red,
    showVolume: true,
    volumeHeight: 0.2, // 20% of chart height
    showGrid: true,
    enableZoom: true,
    xAxis: AxisConfig(
      labelFormatter: (value) => DateFormat('MMM d').format(value),
    ),
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Price (\\$)'),
    ),
  ),
)`
  },
  {
    id: 'ohlc',
    title: 'OHLC Chart',
    description: 'Open-High-Low-Close chart using horizontal bars instead of candle bodies. Alternative financial visualization.',
    category: 'financial',
    features: ['OHLC bars', 'Volume subplot', 'Moving averages', 'Time scaling', 'Cross-hair cursor'],
    code: `import 'package:chartify/chartify.dart';

OHLCChart(
  data: [
    OHLCData(
      date: DateTime(2024, 1, 1),
      open: 150.0,
      high: 155.0,
      low: 148.0,
      close: 153.0,
    ),
    OHLCData(
      date: DateTime(2024, 1, 2),
      open: 153.0,
      high: 158.0,
      low: 152.0,
      close: 156.0,
    ),
    OHLCData(
      date: DateTime(2024, 1, 3),
      open: 156.0,
      high: 157.0,
      low: 150.0,
      close: 151.0,
    ),
    OHLCData(
      date: DateTime(2024, 1, 4),
      open: 151.0,
      high: 154.0,
      low: 149.0,
      close: 152.0,
    ),
    OHLCData(
      date: DateTime(2024, 1, 5),
      open: 152.0,
      high: 160.0,
      low: 151.0,
      close: 159.0,
    ),
  ],
  config: OHLCConfig(
    title: ChartTitle(text: 'Market Data'),
    upColor: Colors.green,
    downColor: Colors.red,
    tickWidth: 8,
    showGrid: true,
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Price'),
    ),
  ),
)`
  },
  {
    id: 'waterfall',
    title: 'Waterfall Chart',
    description: 'Show how an initial value is affected by positive and negative changes. Great for financial reporting.',
    category: 'financial',
    features: ['Running totals', 'Positive/negative colors', 'Subtotals', 'Connector lines', 'Labels'],
    code: `import 'package:chartify/chartify.dart';

WaterfallChart(
  data: [
    WaterfallSegment(
      label: 'Starting Balance',
      value: 1000,
      isTotal: true,
    ),
    WaterfallSegment(
      label: 'Revenue',
      value: 500,
    ),
    WaterfallSegment(
      label: 'Expenses',
      value: -200,
    ),
    WaterfallSegment(
      label: 'Taxes',
      value: -75,
    ),
    WaterfallSegment(
      label: 'Investments',
      value: 150,
    ),
    WaterfallSegment(
      label: 'Final Balance',
      value: 0, // Calculated automatically
      isTotal: true,
    ),
  ],
  config: WaterfallConfig(
    title: ChartTitle(text: 'Financial Summary'),
    positiveColor: Colors.green,
    negativeColor: Colors.red,
    totalColor: Colors.blue,
    showConnectors: true,
    connectorColor: Colors.grey.shade400,
    showLabels: true,
    labelFormatter: (value) => '\\$\${value.abs()}',
    barWidth: 0.6,
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Amount (\\$)'),
    ),
  ),
)`
  },
  {
    id: 'heatmap',
    title: 'Heatmap',
    description: 'Display matrix data using color intensity. Excellent for correlation matrices and time-based patterns.',
    category: 'statistical',
    features: ['Color gradients', 'Value labels', 'Row/column labels', 'Tooltip details', 'Custom color scales'],
    code: `import 'package:chartify/chartify.dart';

HeatmapChart(
  data: [
    ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    ['9AM', 10, 25, 30, 15, 20],
    ['12PM', 45, 50, 35, 40, 55],
    ['3PM', 30, 35, 40, 45, 25],
    ['6PM', 60, 55, 50, 45, 40],
    ['9PM', 20, 15, 25, 30, 10],
  ],
  config: HeatmapConfig(
    title: ChartTitle(text: 'Website Traffic by Day and Hour'),
    colorScale: ColorScale(
      colors: [Colors.blue.shade100, Colors.blue.shade900],
      domain: [0, 60],
    ),
    showValues: true,
    valueFormatter: (value) => value.toString(),
    cellBorderRadius: 4,
    cellPadding: 2,
    xAxisLabel: 'Day of Week',
    yAxisLabel: 'Time',
  ),
)`
  },
  {
    id: 'bubble',
    title: 'Bubble Chart',
    description: 'Extended scatter chart where point size represents a third dimension. Great for 3D data visualization.',
    category: 'cartesian',
    features: ['Size dimension', 'Color dimension', 'Animated bubbles', 'Quadrant lines', 'Legend by size'],
    code: `import 'package:chartify/chartify.dart';

BubbleChart(
  series: [
    BubbleSeries(
      name: 'Products',
      data: [
        BubblePoint(
          x: 10,
          y: 8,
          size: 30,
          label: 'Product A',
          color: Colors.blue,
        ),
        BubblePoint(
          x: 15,
          y: 12,
          size: 45,
          label: 'Product B',
          color: Colors.green,
        ),
        BubblePoint(
          x: 25,
          y: 6,
          size: 25,
          label: 'Product C',
          color: Colors.orange,
        ),
        BubblePoint(
          x: 30,
          y: 15,
          size: 60,
          label: 'Product D',
          color: Colors.purple,
        ),
        BubblePoint(
          x: 20,
          y: 10,
          size: 35,
          label: 'Product E',
          color: Colors.red,
        ),
      ],
    ),
  ],
  config: BubbleConfig(
    title: ChartTitle(text: 'Product Performance'),
    minBubbleSize: 10,
    maxBubbleSize: 50,
    opacity: 0.7,
    xAxis: AxisConfig(
      title: AxisTitle(text: 'Market Share (%)'),
    ),
    yAxis: AxisConfig(
      title: AxisTitle(text: 'Growth Rate (%)'),
    ),
    tooltip: TooltipConfig(
      formatter: (point) =>
        '\${point.label}\\nShare: \${point.x}%\\nGrowth: \${point.y}%\\nRevenue: \$\${point.size}M',
    ),
  ),
)`
  },
]

export function getChartsByCategory(category: string): ChartInfo[] {
  return charts.filter(chart => chart.category === category)
}

export function getChartById(id: string): ChartInfo | undefined {
  return charts.find(chart => chart.id === id)
}
