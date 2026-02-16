<p align="center">
  <img src="https://raw.githubusercontent.com/sitharaj88/chartify/master/assets/chartify.png" width="600" alt="Chartify">
</p>

<h1 align="center">Chartify</h1>

<p align="center">
  A comprehensive, high-performance Flutter chart library with 32+ chart types.
</p>

<p align="center">
  <a href="https://pub.dev/packages/chartify"><img src="https://img.shields.io/pub/v/chartify.svg" alt="pub package"></a>
  <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://pub.dev/packages/chartify/score"><img src="https://img.shields.io/pub/points/chartify" alt="pub points"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10+-02569B.svg?logo=flutter" alt="Flutter"></a>
  <a href="https://sitharaj88.github.io/chartify/"><img src="https://img.shields.io/badge/Docs-Website-blueviolet" alt="Documentation"></a>
</p>

---

## Features

- **32+ chart types** across 5 categories: cartesian, circular, polar, hierarchical, and specialty
- **Modern theming** with built-in `modern()` and `modernDark()` themes, plus Material 3 seed-based theming
- **Smooth animations** with 8 animation types, custom curves, and staggered entry effects
- **Fully interactive** with tooltips, hover effects, pan, zoom, selection, and crosshair support
- **Accessible** with keyboard navigation, screen reader support, focus indicators, and WCAG contrast validation
- **Responsive** with density-aware layouts, automatic text scaling, and orientation-aware configs
- **Cross-platform** with Android, iOS, Web, macOS, Windows, and Linux support
- **High performance** with spatial indexing, canvas layer caching, data decimation, and dirty region tracking

## Chart Types at a Glance

| Category | Charts |
|----------|--------|
| **Cartesian** | Line, Bar, Area, Scatter, Bubble, Candlestick, Box Plot, Histogram, Waterfall, Step, Range, Lollipop, Dumbbell, Slope, Bump, Bullet, Gantt |
| **Circular** | Pie/Donut, Gauge, Radial Bar, Sunburst |
| **Polar** | Radar, Rose |
| **Hierarchical** | Funnel, Pyramid, Treemap |
| **Specialty** | Heatmap, Calendar Heatmap, Sankey, Sparkline |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  chartify: ^1.0.0
```

Then run:

```bash
flutter pub get
```

Import it:

```dart
import 'package:chartify/chartify.dart';
```

---

## Quick Start

### Line Chart

```dart
LineChart(
  data: LineChartData(
    series: [
      LineSeries(
        name: 'Revenue',
        data: [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 25),
          DataPoint(x: 2, y: 15),
          DataPoint(x: 3, y: 30),
          DataPoint(x: 4, y: 22),
          DataPoint(x: 5, y: 35),
        ],
        color: const Color(0xFF6366F1),
        curved: true,
        fillArea: true,
        areaOpacity: 0.2,
        showMarkers: true,
        strokeWidth: 2.5,
      ),
    ],
    xAxis: const AxisConfig(label: 'Month'),
    yAxis: const AxisConfig(label: 'Revenue (\$K)', min: 0),
    showLegend: true,
    crosshairEnabled: true,
  ),
  tooltip: const TooltipConfig(enabled: true),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
  ),
)
```

**LineSeries options:** `curved`, `curveType` (monotone, catmullRom, cardinal, natural, bezier), `fillArea`, `areaOpacity`, `areaGradient`, `showMarkers`, `markerShape` (circle, square, diamond, triangle, star, cross, x), `dashPattern`, `strokeWidth`, `tension`.

---

## Theming

Chartify uses Flutter's theme extension system. Apply a theme globally or per-widget:

### Global Theme

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [ChartThemeData.modern()],
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    extensions: [ChartThemeData.modernDark()],
  ),
)
```

### Seed-Based Theme

```dart
ChartThemeData.fromSeed(
  Colors.indigo,
  brightness: Brightness.light,
)
```

### Per-Widget Theme

```dart
ChartTheme(
  data: ChartThemeData.modern(),
  child: LineChart(data: myData),
)
```

### Available Theme Factories

| Factory | Description |
|---------|-------------|
| `ChartThemeData.modern()` | Contemporary design with indigo palette, dashed grids, rounded corners |
| `ChartThemeData.modernDark()` | OLED-optimized dark variant |
| `ChartThemeData.light()` | Classic light theme |
| `ChartThemeData.dark()` | Classic dark theme |
| `ChartThemeData.fromSeed(color)` | Material 3 dynamic theming from any seed color |

### Theme Properties

```dart
ChartThemeData(
  colorPalette: ColorPalette.modern(),
  gridDashPattern: [6, 4],       // Dashed grid lines (null = solid)
  barCornerRadius: 6.0,           // Corner radius for bars, histograms, etc.
  defaultStrokeWidth: 2.5,        // Default line width
  defaultMarkerSize: 8.0,         // Default marker size
  shadowBlurRadius: 8.0,          // Shadow blur amount
  shadowOpacity: 0.15,            // Shadow opacity
  areaFillOpacity: 0.15,          // Default area fill opacity
  // ... typography, colors, tooltip styling
)
```

### Color Palettes

```dart
ColorPalette.modern()           // Vibrant contemporary colors
ColorPalette.material()         // Material Design colors
ColorPalette.monochromatic(Colors.blue)  // Single-hue variations
ColorPalette.analogous(Colors.blue)      // Analogous scheme
ColorPalette.highContrast()     // WCAG AAA compliant
```

---

## Chart Examples

### Bar Chart

Supports vertical/horizontal bars, grouped/stacked/percentStacked modes, gradients, and rounded corners.

```dart
BarChart(
  data: BarChartData(
    series: [
      BarSeries.fromValues<double>(
        name: 'Revenue',
        values: const [45, 62, 55, 78, 52, 68],
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
    grouping: BarGrouping.grouped, // or .stacked, .percentStacked
    direction: BarDirection.vertical, // or .horizontal
  ),
  tooltip: const TooltipConfig(enabled: true),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
  ),
)
```

### Area Chart

```dart
AreaChart(
  data: AreaChartData(
    series: [
      AreaSeries(
        name: 'Downloads',
        data: const [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 35),
          DataPoint(x: 2, y: 25),
          DataPoint(x: 3, y: 50),
          DataPoint(x: 4, y: 40),
          DataPoint(x: 5, y: 60),
        ],
        color: const Color(0xFF6366F1),
        curved: true,
        fillOpacity: 0.3,
      ),
    ],
    stacking: StackingMode.none, // or .stacked, .percentStacked
  ),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 800),
  ),
)
```

### Pie / Donut Chart

Set `holeRadius > 0` for a donut chart. Supports gradient fills, exploded segments, shadow effects, and label connectors.

```dart
PieChart(
  data: PieChartData(
    sections: [
      PieSection(
        value: 35,
        label: 'Mobile',
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        shadowElevation: 6,
      ),
      const PieSection(value: 30, label: 'Desktop', color: Color(0xFF10B981)),
      const PieSection(value: 20, label: 'Tablet', color: Color(0xFFF59E0B)),
      const PieSection(value: 15, label: 'Other', color: Color(0xFF8B5CF6)),
    ],
    holeRadius: 0.5,         // 0 = pie, >0 = donut
    segmentGap: 3,
    cornerRadius: 4,
    enableShadows: true,
    showLabels: true,
    labelPosition: PieLabelPosition.outside,
    labelConnector: PieLabelConnector.elbow,
  ),
  // Optional center widget for donut charts
  centerWidget: const Text('Total\n100', textAlign: TextAlign.center),
  tooltip: const TooltipConfig(enabled: true),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
  ),
)
```

### Scatter Chart

```dart
ScatterChart(
  data: ScatterChartData(
    series: [
      ScatterSeries<double, double>(
        name: 'Group A',
        data: const [
          ScatterDataPoint(x: 10, y: 20, size: 12),
          ScatterDataPoint(x: 25, y: 35, size: 18),
          ScatterDataPoint(x: 40, y: 28, size: 10),
          ScatterDataPoint(x: 55, y: 45, size: 15),
        ],
        color: const Color(0xFF6366F1),
      ),
    ],
    xAxis: const AxisConfig(label: 'X Value', min: 0, max: 100),
    yAxis: const AxisConfig(label: 'Y Value', min: 0, max: 100),
  ),
  tooltip: const TooltipConfig(enabled: true),
)
```

### Bubble Chart

Like Scatter but with a third dimension via bubble size.

```dart
BubbleChart(
  data: BubbleChartData(
    series: [
      BubbleSeries<double, double>(
        name: 'Products',
        data: const [
          BubbleDataPoint(x: 10, y: 20, size: 100),
          BubbleDataPoint(x: 25, y: 45, size: 200),
          BubbleDataPoint(x: 55, y: 60, size: 300),
        ],
        color: const Color(0xFF6366F1),
        opacity: 0.7,
      ),
    ],
    sizeConfig: const BubbleSizeConfig(
      minSize: 10,
      maxSize: 50,
      scaling: BubbleSizeScaling.sqrt,
    ),
  ),
)
```

### Radar Chart

```dart
RadarChart(
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
    gridType: RadarGridType.polygon, // or .circular
  ),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
  ),
)
```

### Gauge Chart

```dart
GaugeChart(
  data: GaugeChartData(
    value: 72,
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
    needleLength: 0.8,
  ),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 800),
  ),
)
```

### Candlestick Chart

```dart
final now = DateTime.now();
CandlestickChart(
  data: CandlestickChartData(
    data: [
      CandlestickDataPoint(
        date: now.subtract(const Duration(days: 4)),
        open: 100, high: 110, low: 95, close: 105,
      ),
      CandlestickDataPoint(
        date: now.subtract(const Duration(days: 3)),
        open: 105, high: 115, low: 100, close: 98,
      ),
      CandlestickDataPoint(
        date: now.subtract(const Duration(days: 2)),
        open: 98, high: 108, low: 92, close: 106,
      ),
      CandlestickDataPoint(
        date: now.subtract(const Duration(days: 1)),
        open: 106, high: 120, low: 104, close: 118,
      ),
      CandlestickDataPoint(
        date: now,
        open: 118, high: 125, low: 115, close: 112,
      ),
    ],
    bullishColor: const Color(0xFF22C55E),
    bearishColor: const Color(0xFFEF4444),
    style: CandlestickStyle.filled,
  ),
  tooltip: const TooltipConfig(enabled: true),
)
```

### Waterfall Chart

```dart
WaterfallChart(
  data: const WaterfallChartData(
    items: [
      WaterfallItem(label: 'Start', value: 100, type: WaterfallItemType.total),
      WaterfallItem(label: 'Sales', value: 50, type: WaterfallItemType.increase),
      WaterfallItem(label: 'Services', value: 30, type: WaterfallItemType.increase),
      WaterfallItem(label: 'Costs', value: -40, type: WaterfallItemType.decrease),
      WaterfallItem(label: 'Tax', value: -20, type: WaterfallItemType.decrease),
      WaterfallItem(label: 'Final', value: 120, type: WaterfallItemType.total),
    ],
    increaseColor: Color(0xFF22C55E),
    decreaseColor: Color(0xFFEF4444),
    totalColor: Color(0xFF3B82F6),
    showConnectors: true,
    showValues: true,
  ),
)
```

### Box Plot Chart

```dart
BoxPlotChart(
  data: const BoxPlotChartData(
    items: [
      BoxPlotItem(
        label: 'Q1', min: 10, q1: 25, median: 35, q3: 50, max: 70,
        outliers: [5, 80], mean: 38,
      ),
      BoxPlotItem(
        label: 'Q2', min: 15, q1: 30, median: 45, q3: 60, max: 75,
        mean: 44,
      ),
      BoxPlotItem(
        label: 'Q3', min: 20, q1: 35, median: 50, q3: 65, max: 80,
        outliers: [15, 95], mean: 50,
      ),
    ],
    showOutliers: true,
    showMean: true,
    boxWidth: 0.6,
  ),
)
```

### Histogram Chart

```dart
HistogramChart(
  data: HistogramChartData(
    values: myDistributionValues, // List<double>
    binCount: 15,
    color: const Color(0xFF6366F1),
    showDistributionCurve: true,
    distributionCurveColor: const Color(0xFFEC4899),
  ),
)
```

### Sankey Chart

Visualize flow/energy/money transfers between nodes.

```dart
SankeyChart(
  data: const SankeyChartData(
    nodes: [
      SankeyNode(id: 'salary', label: 'Salary', color: Color(0xFF22C55E)),
      SankeyNode(id: 'freelance', label: 'Freelance', color: Color(0xFF3B82F6)),
      SankeyNode(id: 'housing', label: 'Housing', color: Color(0xFFEF4444)),
      SankeyNode(id: 'food', label: 'Food', color: Color(0xFFF59E0B)),
      SankeyNode(id: 'savings', label: 'Savings', color: Color(0xFF10B981)),
    ],
    links: [
      SankeyLink(sourceId: 'salary', targetId: 'housing', value: 1500),
      SankeyLink(sourceId: 'salary', targetId: 'food', value: 800),
      SankeyLink(sourceId: 'salary', targetId: 'savings', value: 1200),
      SankeyLink(sourceId: 'freelance', targetId: 'savings', value: 800),
    ],
    nodeWidth: 20,
    nodePadding: 15,
    linkOpacity: 0.5,
    showLabels: true,
    showValues: true,
  ),
  tooltip: const TooltipConfig(enabled: true),
)
```

### Treemap Chart

```dart
TreemapChart(
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
      ],
    ),
    algorithm: TreemapLayoutAlgorithm.squarified,
    showLabels: true,
  ),
)
```

### Gantt Chart

Full-featured project timeline with tasks, milestones, progress tracking, and dependencies.

```dart
final now = DateTime.now();
GanttChart(
  data: GanttChartData(
    tasks: [
      GanttTask(
        id: '1', label: 'Planning',
        start: now,
        end: now.add(const Duration(days: 7)),
        progress: 1.0,
        color: const Color(0xFF6366F1),
      ),
      GanttTask(
        id: '2', label: 'Development',
        start: now.add(const Duration(days: 5)),
        end: now.add(const Duration(days: 25)),
        progress: 0.4,
        color: const Color(0xFF8B5CF6),
      ),
      GanttTask(
        id: '3', label: 'Launch',
        start: now.add(const Duration(days: 25)),
        end: now.add(const Duration(days: 25)),
        isMilestone: true,
        color: const Color(0xFF22C55E),
      ),
    ],
    showProgress: true,
    showLabels: true,
    showDates: true,
    barHeight: 24,
  ),
)
```

### Heatmap Chart

```dart
HeatmapChart(
  data: HeatmapChartData(
    data: const [
      [1.0, 2.5, 3.2, 4.1, 2.8],
      [2.3, 4.5, 5.1, 3.8, 4.2],
      [3.1, 3.8, 6.2, 5.5, 3.9],
      [4.2, 5.1, 4.8, 7.2, 5.8],
    ],
    rowLabels: const ['Mon', 'Tue', 'Wed', 'Thu'],
    columnLabels: const ['9AM', '11AM', '1PM', '3PM', '5PM'],
    colorScale: HeatmapColorScale.viridis, // or .blues, .reds, .greens, .diverging
    showValues: true,
    cellBorderRadius: 4,
  ),
)
```

### Calendar Heatmap (GitHub-style)

```dart
CalendarHeatmapChart(
  data: CalendarHeatmapData(
    data: contributionData, // List<CalendarDataPoint>
    colorStops: const [
      Color(0xFFEBEDF0), // Empty
      Color(0xFF9BE9A8), // Low
      Color(0xFF40C463), // Medium
      Color(0xFF30A14E), // High
      Color(0xFF216E39), // Very High
    ],
    cellSize: 12,
    cellSpacing: 3,
    cellRadius: 2,
    showDayLabels: true,
    showMonthLabels: true,
  ),
)
```

### Sparkline Chart

Compact, word-sized charts for inline data visualization. Supports line, area, bar, and win/loss types.

```dart
SizedBox(
  height: 50,
  child: SparklineChart(
    data: const SparklineChartData(
      values: [10, 25, 15, 30, 22, 35, 28, 40],
      type: SparklineType.line, // or .area, .bar, .winLoss
      color: Color(0xFF6366F1),
      showLastMarker: true,
      showMinMarker: true,
      showMaxMarker: true,
      referenceLineType: SparklineReferenceType.average,
    ),
  ),
)
```

### More Charts

<details>
<summary><b>Radial Bar Chart</b></summary>

```dart
RadialBarChart(
  data: const RadialBarChartData(
    bars: [
      RadialBarItem(label: 'Sales', value: 85, maxValue: 100, color: Color(0xFF6366F1)),
      RadialBarItem(label: 'Marketing', value: 72, maxValue: 100, color: Color(0xFF10B981)),
      RadialBarItem(label: 'Support', value: 60, maxValue: 100, color: Color(0xFFF59E0B)),
    ],
    innerRadius: 0.3,
    trackGap: 8,
    strokeCap: StrokeCap.round,
    showLabels: true,
  ),
)
```

</details>

<details>
<summary><b>Sunburst Chart</b></summary>

```dart
SunburstChart(
  data: SunburstChartData(
    root: SunburstNode(
      label: 'Total',
      children: [
        SunburstNode(
          label: 'Americas', color: const Color(0xFF6366F1),
          children: [
            const SunburstNode(label: 'USA', value: 40),
            const SunburstNode(label: 'Canada', value: 15),
          ],
        ),
        SunburstNode(
          label: 'Europe', color: const Color(0xFF22C55E),
          children: [
            const SunburstNode(label: 'UK', value: 18),
            const SunburstNode(label: 'Germany', value: 16),
          ],
        ),
      ],
    ),
    innerRadius: 40,
    ringWidth: 50,
    showLabels: true,
  ),
)
```

</details>

<details>
<summary><b>Rose Chart</b></summary>

```dart
RoseChart(
  data: const RoseChartData(
    segments: [
      RoseSegment(label: 'N', value: 12, color: Color(0xFF6366F1)),
      RoseSegment(label: 'NE', value: 8, color: Color(0xFF8B5CF6)),
      RoseSegment(label: 'E', value: 15, color: Color(0xFFA855F7)),
      RoseSegment(label: 'SE', value: 22, color: Color(0xFFC084FC)),
      RoseSegment(label: 'S', value: 18, color: Color(0xFFD8B4FE)),
      RoseSegment(label: 'SW', value: 10, color: Color(0xFFE9D5FF)),
      RoseSegment(label: 'W', value: 25, color: Color(0xFFF3E8FF)),
      RoseSegment(label: 'NW', value: 14, color: Color(0xFFEDE9FE)),
    ],
    innerRadius: 0.2,
    gap: 2,
    showLabels: true,
    startAngle: -90,
  ),
)
```

</details>

<details>
<summary><b>Funnel Chart</b></summary>

```dart
FunnelChart(
  data: const FunnelChartData(
    sections: [
      FunnelSection(label: 'Visitors', value: 10000, color: Color(0xFF6366F1)),
      FunnelSection(label: 'Leads', value: 6500, color: Color(0xFF8B5CF6)),
      FunnelSection(label: 'Prospects', value: 4200, color: Color(0xFFA855F7)),
      FunnelSection(label: 'Sales', value: 1200, color: Color(0xFFD8B4FE)),
    ],
    mode: FunnelMode.proportional,
    neckWidth: 0.3,
    gap: 4,
    showConversionRate: true,
  ),
)
```

</details>

<details>
<summary><b>Pyramid Chart</b></summary>

```dart
PyramidChart(
  data: const PyramidChartData(
    sections: [
      PyramidSection(label: 'Basic', value: 50, color: Color(0xFF22C55E)),
      PyramidSection(label: 'Standard', value: 35, color: Color(0xFF3B82F6)),
      PyramidSection(label: 'Premium', value: 25, color: Color(0xFF8B5CF6)),
      PyramidSection(label: 'Enterprise', value: 15, color: Color(0xFFF59E0B)),
    ],
    mode: PyramidMode.proportional,
    gap: 3,
    showLabels: true,
  ),
)
```

</details>

<details>
<summary><b>Slope Chart</b></summary>

```dart
SlopeChart(
  data: const SlopeChartData(
    items: [
      SlopeItem(label: 'Product A', startValue: 45, endValue: 72, color: Color(0xFF6366F1)),
      SlopeItem(label: 'Product B', startValue: 68, endValue: 52, color: Color(0xFFEF4444)),
      SlopeItem(label: 'Product C', startValue: 55, endValue: 85, color: Color(0xFF22C55E)),
    ],
    startLabel: '2023',
    endLabel: '2024',
    showLabels: true,
    showValues: true,
  ),
)
```

</details>

<details>
<summary><b>Bump Chart</b></summary>

```dart
BumpChart(
  data: const BumpChartData(
    series: [
      BumpSeries(label: 'Team A', rankings: [1, 2, 1, 3, 2, 1], color: Color(0xFF6366F1)),
      BumpSeries(label: 'Team B', rankings: [2, 1, 3, 1, 1, 2], color: Color(0xFF22C55E)),
      BumpSeries(label: 'Team C', rankings: [3, 3, 2, 2, 3, 3], color: Color(0xFFF59E0B)),
    ],
    timeLabels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
    showLabels: true,
    showRankings: true,
  ),
)
```

</details>

<details>
<summary><b>Step Chart</b></summary>

```dart
StepChart(
  data: StepChartData(
    series: [
      StepSeries<int, double>(
        name: 'Temperature',
        data: const [
          DataPoint(x: 0, y: 20), DataPoint(x: 1, y: 22),
          DataPoint(x: 2, y: 25), DataPoint(x: 3, y: 23),
          DataPoint(x: 4, y: 28), DataPoint(x: 5, y: 26),
        ],
        color: const Color(0xFF6366F1),
        showMarkers: true,
        fillArea: true,
        fillOpacity: 0.2,
      ),
    ],
  ),
)
```

</details>

<details>
<summary><b>Lollipop / Dumbbell / Range / Bullet Charts</b></summary>

```dart
// Lollipop
LollipopChart(
  data: const LollipopChartData(
    items: [
      LollipopItem(label: 'A', value: 85, color: Color(0xFF6366F1)),
      LollipopItem(label: 'B', value: 65, color: Color(0xFF8B5CF6)),
    ],
    orientation: LollipopOrientation.horizontal,
    markerSize: 14,
  ),
)

// Dumbbell
DumbbellChart(
  data: const DumbbellChartData(
    items: [
      DumbbellItem(label: '2020', startValue: 45, endValue: 72),
      DumbbellItem(label: '2021', startValue: 52, endValue: 68),
    ],
    startColor: Color(0xFF6366F1),
    endColor: Color(0xFF22C55E),
  ),
)

// Bullet
BulletChart(
  data: const BulletChartData(
    items: [
      BulletItem(label: 'Revenue', value: 275, target: 250, ranges: [150, 225, 300], max: 300),
      BulletItem(label: 'Profit', value: 22, target: 25, ranges: [10, 18, 30], max: 30),
    ],
    showLabels: true,
    showValues: true,
  ),
)
```

</details>

---

## Animation

### Built-in Presets

```dart
ChartAnimation(
  duration: Duration(milliseconds: 800),
  curve: Curves.easeOutCubic,
)

// Presets
const ChartAnimation.fast()       // 300ms
const ChartAnimation.slow()       // 1200ms
const ChartAnimation.staggered()  // Sequential series animation
const ChartAnimation.none()       // Disabled
```

### Animation Types

```dart
ChartAnimation(
  type: AnimationType.draw,      // Draws path progressively
  // Other types: fade, scale, slideUp, slideDown, stagger, reveal, grow
)
```

### Custom Curves

```dart
ChartAnimation(
  curve: ChartCurves.spring,     // Spring physics
  // Also: .overshoot, .snappy, .smooth, .elastic, .bounce
  // Material: .emphasized, .emphasizedDecelerate, .standard
)
```

---

## Interactions

### Tooltip Configuration

```dart
TooltipConfig(
  enabled: true,
  showOnHover: true,                // Desktop
  showOnTap: true,                  // Mobile
  position: TooltipPosition.auto,   // auto, top, bottom, left, right
  showArrow: true,
  showIndicatorLine: true,
  showIndicatorDot: true,
  touchFriendly: true,              // Avoids user's finger on mobile
  animationDuration: Duration(milliseconds: 200),
  builder: (context, data) => MyCustomTooltip(data), // Custom widget
)
```

### Gesture Configuration

```dart
ChartGestureDetector(
  interactions: ChartInteractions(
    enablePan: true,
    enableZoom: true,
    enablePinchZoom: true,
    enableScrollWheelZoom: true,
    enableDoubleTapZoom: true,
    enableHover: true,
    enableSelection: true,
    enableMomentum: true,       // Inertia after pan
    multiSelect: false,
    hitTestRadius: 24.0,        // Touch target radius
    zoomAxis: ZoomAxis.both,
    panAxis: PanAxis.both,
  ),
  // ...
)
```

### ChartController

Programmatic control over chart state:

```dart
final controller = ChartController();

// Zoom
controller.zoom(2.0, Offset(100, 100));
controller.animateZoom(1.5, focalPoint, duration: Duration(milliseconds: 300));
controller.zoomToRange(xMin: 0, xMax: 50);
controller.resetViewport();

// Selection
controller.selectPoint(seriesIndex: 0, pointIndex: 3);
controller.togglePoint(seriesIndex: 0, pointIndex: 3);
controller.clearSelection();

// Series visibility
controller.toggleSeriesVisibility(0);
controller.isolateSeries(2);
controller.showAllSeries();

// Tooltip
controller.showTooltip(dataPointInfo);
controller.hideTooltip();
```

---

## Accessibility

Chartify provides built-in accessibility support:

```dart
ChartAccessibility(
  chartType: ChartType.line,
  title: 'Monthly Revenue',
  xAxisLabel: 'Month',
  yAxisLabel: 'Revenue',
).wrap(
  myChart,
  dataPoints: myDataPoints,
  seriesDescriptions: ['Revenue trend over 6 months'],
)

// Or use the convenient wrapper
AccessibleChartBuilder(
  chartType: ChartType.bar,
  title: 'Sales by Region',
  builder: (context) => BarChart(data: salesData),
  dataPoints: salesDataPoints,
)
```

**Keyboard shortcuts:** Arrow keys (navigate), Enter/Space (select), Escape (clear), 1-9 (focus series), D (description), T (trend), S (summary), +/- (zoom).

**Color accessibility:**

```dart
// WCAG-compliant palettes
ColorPalette.highContrast()

// Validate existing palette
theme.validateColorContrast(level: ContrastLevel.aa);

// Auto-adjust colors for contrast
final accessibleTheme = theme.withAccessibleColors(level: ContrastLevel.aaa);
```

---

## Responsive Design

Charts automatically adapt to screen size:

```dart
ResponsiveWrapper(
  config: const ResponsiveConfig(
    // Breakpoints
    compactWidth: 600,
    mediumWidth: 840,
    expandedWidth: 1200,
  ),
  child: LineChart(data: myData),
)
```

The `ChartResponsiveMixin` provides:
- `getResponsivePadding()` - Density-aware padding
- `getScaledFontSize()` - DPI-aware text scaling
- `getHitTestRadius()` - Touch-friendly hit targets

---

## Data Pipeline

Built-in data processing utilities:

```dart
// Data validation
DataValidator.validate(myData);

// Data decimation for large datasets
DataDecimator.decimate(
  points,
  targetCount: 500,
  algorithm: DecimationAlgorithm.lttb, // Largest-Triangle-Three-Buckets
);

// Data export
DataExportService.export(
  data: chartData,
  config: DataExportConfig.csv(),
);
```

---

## Plugin System

Extend charts with plugins:

```dart
// Built-in zoom plugin
ZoomPlugin(config: ZoomConfig.standard)

// Built-in export plugin
ExportPlugin()
```

---

## Requirements

- Flutter >= 3.10.0
- Dart SDK >= 3.0.0

## License

```
Copyright 2025 Sitharaj Seenivasan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

See [LICENSE](LICENSE) for the full license text.
