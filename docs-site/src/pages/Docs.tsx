import React from 'react'
import { useLocation } from 'react-router-dom'
import { CodeBlock } from '../components/CodeBlock'
import { DocLayout } from '../components/DocLayout'
import { Callout } from '../components/Callout'

// Sidebar sections configuration
const sidebarSections = [
  {
    title: 'Getting Started',
    items: [
      { path: '/docs', label: 'Introduction' },
      { path: '/docs/installation', label: 'Installation' },
      { path: '/docs/quick-start', label: 'Quick Start' },
    ],
  },
  {
    title: 'Core Concepts',
    items: [
      { path: '/docs/architecture', label: 'Architecture' },
      { path: '/docs/data-models', label: 'Data Models' },
      { path: '/docs/configuration', label: 'Configuration' },
      { path: '/docs/theming', label: 'Theming' },
    ],
  },
  {
    title: 'Features',
    items: [
      { path: '/docs/animations', label: 'Animations' },
      { path: '/docs/interactions', label: 'Interactions' },
      { path: '/docs/tooltips', label: 'Tooltips' },
      { path: '/docs/legends', label: 'Legends' },
      { path: '/docs/accessibility', label: 'Accessibility' },
    ],
  },
  {
    title: 'Advanced',
    items: [
      { path: '/docs/performance', label: 'Performance' },
      { path: '/docs/custom-painters', label: 'Custom Painters' },
      { path: '/docs/plugins', label: 'Plugins' },
    ],
  },
]

// ============================================================================
// Code Snippets
// ============================================================================

const installCode = `# Add to your pubspec.yaml
dependencies:
  chartify: ^0.1.0

# Then run
flutter pub get`

const basicExampleCode = `import 'package:flutter/material.dart';
import 'package:chartify/chartify.dart';

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LineChart(
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
            curved: true,
            showPoints: true,
          ),
        ],
        config: ChartConfig(
          title: ChartTitle(text: 'Monthly Revenue'),
          tooltip: TooltipConfig(enabled: true),
        ),
      ),
    );
  }
}`

const themingCode = `final customTheme = ChartThemeData(
  brightness: Brightness.dark,
  backgroundColor: Color(0xFF1E1E1E),
  gridColor: Color(0xFF333333),
  axisColor: Color(0xFF666666),
  textColor: Color(0xFFE0E0E0),
  colorPalette: [
    Color(0xFF6366F1),
    Color(0xFF22D3EE),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ],
);

// Apply theme
ChartTheme(
  data: customTheme,
  child: LineChart(...),
)`

const animationCode = `LineChart(
  series: [...],
  animation: ChartAnimation(
    duration: Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
    mode: AnimationMode.sequential,
    delay: Duration(milliseconds: 100),
  ),
)`

const interactionsCode = `LineChart(
  series: [...],
  config: ChartConfig(
    interactions: InteractionConfig(
      enableZoom: true,
      zoomMode: ZoomMode.xy,
      minZoom: 0.5,
      maxZoom: 10.0,
      enablePan: true,
      enableDoubleTapZoom: true,
      enableSelection: true,
      crosshair: CrosshairConfig(
        enabled: true,
        snapToData: true,
      ),
    ),
    onDataPointTap: (point, series) {
      print('Tapped: \${point.x}, \${point.y}');
    },
  ),
)`

const tooltipCode = `ChartConfig(
  tooltip: TooltipConfig(
    enabled: true,
    mode: TooltipMode.crosshair,
    backgroundColor: Colors.black87,
    textStyle: TextStyle(color: Colors.white, fontSize: 12),
    borderRadius: BorderRadius.circular(8),
    formatter: (point) => 'Value: \${point.y.toStringAsFixed(2)}',
  ),
)`

const legendCode = `ChartConfig(
  legend: LegendConfig(
    show: true,
    position: LegendPosition.bottom,
    alignment: LegendAlignment.center,
    orientation: LegendOrientation.horizontal,
    iconShape: LegendIconShape.circle,
    onItemTap: (series, index) {
      setState(() => series.visible = !series.visible);
    },
  ),
)`

const accessibilityCode = `ChartConfig(
  accessibility: AccessibilityConfig(
    enabled: true,
    chartDescription: 'Line chart showing monthly revenue',
    announceDataPoints: true,
    highContrastMode: false,
  ),
)`

const performanceCode = `// Enable viewport culling for large datasets
LineChart(
  series: [
    LineSeries(
      data: largeDataset, // 10,000+ points
      enableCulling: true,
      cullPadding: 50,
    ),
  ],
  config: ChartConfig(
    performance: PerformanceConfig(
      enableCaching: true,
      useRepaintBoundary: true,
      throttleMs: 16,
    ),
  ),
)`

const customPainterCode = `class MyChartPainter extends ChartPainter {
  @override
  void paint(Canvas canvas, Size size, ChartData data) {
    // Custom rendering logic
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    for (final point in data.points) {
      final offset = calculateOffset(point, size);
      canvas.drawCircle(offset, 8, paint);
    }
  }
}`

const pluginsCode = `LineChart(
  series: [...],
  plugins: [
    ZoomPlugin(
      enabled: true,
      minZoom: 0.5,
      maxZoom: 5.0,
    ),
    CrosshairPlugin(
      enabled: true,
      showLabels: true,
    ),
    ReferenceLinePlugin(
      lines: [
        ReferenceLine(value: 50, label: 'Target'),
      ],
    ),
  ],
)`

const dataModelCode = `// Basic DataPoint
DataPoint(x: 1, y: 30)

// With label
DataPoint(x: 1, y: 30, label: 'January')

// With custom data
DataPoint(x: 1, y: 30, data: {'category': 'A'})

// Series with data points
LineSeries(
  name: 'Sales',
  data: [
    DataPoint(x: 1, y: 30),
    DataPoint(x: 2, y: 45),
  ],
  color: Colors.blue,
)`

const configCode = `ChartConfig(
  // Title
  title: ChartTitle(
    text: 'Monthly Revenue',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),

  // Axes
  xAxis: AxisConfig(
    label: 'Month',
    gridLines: true,
    tickCount: 6,
  ),
  yAxis: AxisConfig(
    label: 'Revenue (\$)',
    minValue: 0,
    maxValue: 100,
  ),

  // Grid
  grid: GridConfig(
    show: true,
    strokeColor: Colors.grey.withOpacity(0.2),
    strokeWidth: 1,
  ),

  // Padding
  padding: EdgeInsets.all(16),
)`

const architectureCode = `// Chart hierarchy
ChartWidget
├── ChartController      // State management
├── ChartPainter         // Rendering
├── GestureHandler       // Touch/mouse input
└── ChartConfig          // Configuration
    ├── AxisConfig
    ├── GridConfig
    ├── TooltipConfig
    ├── LegendConfig
    └── AnimationConfig`

// ============================================================================
// Page Metadata
// ============================================================================

const pageMeta: Record<string, { title: string; description: string; readingTime: string }> = {
  '/docs': {
    title: 'Introduction',
    description: 'Welcome to Chartify - a powerful, customizable charting library for Flutter applications.',
    readingTime: '3 min read',
  },
  '/docs/installation': {
    title: 'Installation',
    description: 'Learn how to add Chartify to your Flutter project.',
    readingTime: '2 min read',
  },
  '/docs/quick-start': {
    title: 'Quick Start',
    description: 'Get up and running with your first chart in minutes.',
    readingTime: '5 min read',
  },
  '/docs/architecture': {
    title: 'Architecture',
    description: 'Understand how Chartify is structured and organized.',
    readingTime: '4 min read',
  },
  '/docs/data-models': {
    title: 'Data Models',
    description: 'Learn about DataPoint, Series, and other core data structures.',
    readingTime: '5 min read',
  },
  '/docs/configuration': {
    title: 'Configuration',
    description: 'Configure axes, grids, titles, and other chart options.',
    readingTime: '6 min read',
  },
  '/docs/theming': {
    title: 'Theming',
    description: 'Customize colors, fonts, and styles across your charts.',
    readingTime: '4 min read',
  },
  '/docs/animations': {
    title: 'Animations',
    description: 'Add smooth, customizable animations to your charts.',
    readingTime: '4 min read',
  },
  '/docs/interactions': {
    title: 'Interactions',
    description: 'Enable zoom, pan, selection, and other user interactions.',
    readingTime: '5 min read',
  },
  '/docs/tooltips': {
    title: 'Tooltips',
    description: 'Display data details with customizable tooltips.',
    readingTime: '4 min read',
  },
  '/docs/legends': {
    title: 'Legends',
    description: 'Add and customize chart legends.',
    readingTime: '3 min read',
  },
  '/docs/accessibility': {
    title: 'Accessibility',
    description: 'Make your charts accessible to all users.',
    readingTime: '4 min read',
  },
  '/docs/performance': {
    title: 'Performance',
    description: 'Optimize charts for large datasets and smooth rendering.',
    readingTime: '5 min read',
  },
  '/docs/custom-painters': {
    title: 'Custom Painters',
    description: 'Create custom chart types with the painter API.',
    readingTime: '6 min read',
  },
  '/docs/plugins': {
    title: 'Plugins',
    description: 'Extend chart functionality with built-in and custom plugins.',
    readingTime: '5 min read',
  },
}

// ============================================================================
// Content Components
// ============================================================================

function IntroductionContent() {
  return (
    <>
      <p className="lead">
        Chartify is a comprehensive, high-performance charting library for Flutter that supports 25+ chart types,
        large datasets, and cross-platform compatibility.
      </p>

      <Callout type="tip" title="New to Chartify?">
        <p>Start with the <a href="/docs/installation">Installation</a> guide, then follow the <a href="/docs/quick-start">Quick Start</a> tutorial.</p>
      </Callout>

      <h2 id="features">Features</h2>
      <ul>
        <li><strong>25+ Chart Types:</strong> Line, bar, pie, scatter, treemap, sankey, gauge, and more</li>
        <li><strong>High Performance:</strong> Optimized for 10,000+ data points with viewport culling</li>
        <li><strong>Cross-Platform:</strong> Works on iOS, Android, Web, and Desktop</li>
        <li><strong>Fully Customizable:</strong> Themes, animations, interactions, and custom painters</li>
        <li><strong>Accessibility:</strong> Screen reader support and keyboard navigation</li>
        <li><strong>TypeScript-like API:</strong> Strongly typed with excellent IDE support</li>
      </ul>

      <h2 id="chart-types">Available Chart Types</h2>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4 not-prose my-6">
        {['Line', 'Bar', 'Pie', 'Scatter', 'Area', 'Candlestick', 'Radar', 'Gauge', 'Treemap', 'Sankey', 'Funnel', 'Heatmap'].map(type => (
          <div key={type} className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 text-center">
            <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{type} Chart</span>
          </div>
        ))}
      </div>

      <h2 id="quick-example">Quick Example</h2>
      <CodeBlock code={basicExampleCode} language="dart" filename="simple_chart.dart" />

      <h2 id="requirements">Requirements</h2>
      <ul>
        <li>Flutter 3.10.0 or higher</li>
        <li>Dart 3.0.0 or higher</li>
      </ul>
    </>
  )
}

function InstallationContent() {
  return (
    <>
      <h2 id="add-dependency">Add Dependency</h2>
      <p>Add Chartify to your Flutter project using the Flutter CLI or by editing your pubspec.yaml directly.</p>

      <CodeBlock code={installCode} language="yaml" filename="pubspec.yaml" />

      <Callout type="info" title="Version Compatibility">
        <p>Chartify requires Flutter 3.10.0 or higher and Dart 3.0.0 or higher.</p>
      </Callout>

      <h2 id="import">Import the Library</h2>
      <p>After installation, import Chartify in your Dart files:</p>

      <CodeBlock code={`import 'package:chartify/chartify.dart';`} language="dart" showLineNumbers={false} />

      <h2 id="platform-setup">Platform Setup</h2>

      <h3 id="web">Web</h3>
      <p>No additional setup required for web. Chartify uses CanvasKit for rendering.</p>

      <h3 id="mobile">iOS & Android</h3>
      <p>No additional setup required. Chartify works out of the box on mobile platforms.</p>

      <h3 id="desktop">Desktop</h3>
      <p>Ensure you have the desktop platform enabled in your Flutter project:</p>

      <CodeBlock code={`flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop`} language="bash" showLineNumbers={false} />

      <Callout type="success" title="You're Ready!">
        <p>Continue to the <a href="/docs/quick-start">Quick Start</a> guide to create your first chart.</p>
      </Callout>
    </>
  )
}

function QuickStartContent() {
  return (
    <>
      <h2 id="first-chart">Create Your First Chart</h2>
      <p>Let's create a simple line chart to visualize monthly revenue data.</p>

      <CodeBlock code={basicExampleCode} language="dart" filename="simple_chart.dart" />

      <Callout type="tip" title="Hot Reload">
        <p>Chartify supports hot reload. Changes to your chart configuration will be reflected immediately.</p>
      </Callout>

      <h2 id="understanding-structure">Understanding the Structure</h2>
      <p>Every Chartify chart consists of three main parts:</p>

      <ol>
        <li><strong>Series:</strong> The data to display (lines, bars, etc.)</li>
        <li><strong>Config:</strong> Chart configuration (titles, axes, tooltips)</li>
        <li><strong>Container:</strong> The widget that wraps the chart</li>
      </ol>

      <h2 id="adding-interactivity">Adding Interactivity</h2>
      <p>Enable zoom, pan, and tooltips with a few lines of code:</p>

      <CodeBlock code={interactionsCode} language="dart" filename="interactive_chart.dart" />

      <h2 id="next-steps">Next Steps</h2>
      <ul>
        <li>Learn about <a href="/docs/data-models">Data Models</a> to structure your data</li>
        <li>Explore <a href="/docs/configuration">Configuration</a> options</li>
        <li>Add <a href="/docs/theming">Custom Themes</a> to match your app</li>
        <li>Browse the <a href="/charts">Charts Gallery</a> for inspiration</li>
      </ul>
    </>
  )
}

function ArchitectureContent() {
  return (
    <>
      <h2 id="overview">Overview</h2>
      <p>Chartify is built with a modular, layered architecture that separates concerns and enables customization at every level.</p>

      <CodeBlock code={architectureCode} language="plaintext" showLineNumbers={false} />

      <h2 id="core-components">Core Components</h2>

      <h3 id="chart-widget">ChartWidget</h3>
      <p>The root widget that orchestrates all chart functionality. It manages the lifecycle and coordinates between components.</p>

      <h3 id="chart-controller">ChartController</h3>
      <p>Manages chart state including zoom level, selection, and animation state. You can access it to programmatically control the chart.</p>

      <h3 id="chart-painter">ChartPainter</h3>
      <p>Handles all rendering using Flutter's Canvas API. Each chart type has its own painter implementation.</p>

      <Callout type="info">
        <p>The painter is optimized for performance with techniques like viewport culling and layer caching.</p>
      </Callout>

      <h2 id="design-principles">Design Principles</h2>
      <ul>
        <li><strong>Composition over Inheritance:</strong> Mix and match features using plugins</li>
        <li><strong>Configuration Objects:</strong> All options are strongly typed</li>
        <li><strong>Immutable Data:</strong> Data changes trigger efficient re-renders</li>
        <li><strong>Platform Agnostic:</strong> Same API works across all platforms</li>
      </ul>
    </>
  )
}

function DataModelsContent() {
  return (
    <>
      <h2 id="data-point">DataPoint</h2>
      <p>The fundamental unit of data in Chartify. Represents a single value on the chart.</p>

      <CodeBlock code={dataModelCode} language="dart" filename="data_models.dart" />

      <h2 id="series-types">Series Types</h2>
      <p>Different chart types use different series classes:</p>

      <ul>
        <li><strong>LineSeries:</strong> For line and area charts</li>
        <li><strong>BarSeries:</strong> For bar and column charts</li>
        <li><strong>PieSeries:</strong> For pie and donut charts</li>
        <li><strong>ScatterSeries:</strong> For scatter plots</li>
        <li><strong>CandlestickSeries:</strong> For financial charts (OHLC)</li>
      </ul>

      <Callout type="tip" title="Type Safety">
        <p>Each series type has specific properties. The compiler will catch misconfigurations at build time.</p>
      </Callout>

      <h2 id="data-transformations">Data Transformations</h2>
      <p>Chartify can transform your data automatically:</p>
      <ul>
        <li>Sorting by x or y values</li>
        <li>Aggregation (sum, average, min, max)</li>
        <li>Filtering by range or condition</li>
        <li>Interpolation for missing values</li>
      </ul>
    </>
  )
}

function ConfigurationContent() {
  return (
    <>
      <h2 id="chart-config">ChartConfig</h2>
      <p>The main configuration object that controls all aspects of your chart.</p>

      <CodeBlock code={configCode} language="dart" filename="config.dart" />

      <h2 id="axis-configuration">Axis Configuration</h2>
      <p>Configure both X and Y axes independently:</p>
      <ul>
        <li><strong>label:</strong> Axis title text</li>
        <li><strong>minValue/maxValue:</strong> Value range (auto-calculated if not set)</li>
        <li><strong>tickCount:</strong> Number of tick marks</li>
        <li><strong>gridLines:</strong> Show grid lines</li>
        <li><strong>formatter:</strong> Custom label formatting</li>
      </ul>

      <h2 id="grid-configuration">Grid Configuration</h2>
      <p>Control the appearance of grid lines:</p>
      <ul>
        <li><strong>show:</strong> Toggle grid visibility</li>
        <li><strong>strokeColor:</strong> Grid line color</li>
        <li><strong>strokeWidth:</strong> Grid line thickness</li>
        <li><strong>dashPattern:</strong> Dashed line pattern</li>
      </ul>

      <Callout type="warning" title="Performance Note">
        <p>Disabling grid lines can improve performance for charts with many data points.</p>
      </Callout>
    </>
  )
}

function ThemingContent() {
  return (
    <>
      <h2 id="theme-data">ChartThemeData</h2>
      <p>Create custom themes to match your app's design system.</p>

      <CodeBlock code={themingCode} language="dart" filename="theme.dart" />

      <h2 id="color-palettes">Color Palettes</h2>
      <p>Define a color palette for automatic series coloring:</p>
      <ul>
        <li>Colors are assigned to series in order</li>
        <li>Palette cycles when there are more series than colors</li>
        <li>Individual series can override with explicit colors</li>
      </ul>

      <Callout type="tip" title="Accessibility">
        <p>Choose colors with sufficient contrast. Consider colorblind-friendly palettes for public-facing apps.</p>
      </Callout>

      <h2 id="dark-mode">Dark Mode Support</h2>
      <p>Create separate themes for light and dark modes:</p>

      <CodeBlock code={`ChartTheme(
  data: MediaQuery.of(context).platformBrightness == Brightness.dark
    ? darkTheme
    : lightTheme,
  child: LineChart(...),
)`} language="dart" showLineNumbers={false} />
    </>
  )
}

function AnimationsContent() {
  return (
    <>
      <h2 id="animation-config">Animation Configuration</h2>
      <p>Add smooth animations to chart rendering and updates.</p>

      <CodeBlock code={animationCode} language="dart" filename="animation.dart" />

      <h2 id="animation-modes">Animation Modes</h2>
      <ul>
        <li><strong>AnimationMode.simultaneous:</strong> All elements animate together</li>
        <li><strong>AnimationMode.sequential:</strong> Elements animate one after another</li>
        <li><strong>AnimationMode.fromCenter:</strong> Animation radiates from center</li>
        <li><strong>AnimationMode.fromLeft:</strong> Animation moves left to right</li>
      </ul>

      <Callout type="info" title="Performance">
        <p>Animations are hardware-accelerated and don't block the UI thread.</p>
      </Callout>

      <h2 id="custom-curves">Custom Curves</h2>
      <p>Use any Flutter Curve for animation easing:</p>
      <ul>
        <li><code>Curves.easeInOut</code> - Smooth acceleration/deceleration</li>
        <li><code>Curves.bounceOut</code> - Bouncy effect</li>
        <li><code>Curves.elasticOut</code> - Spring-like effect</li>
      </ul>
    </>
  )
}

function InteractionsContent() {
  return (
    <>
      <h2 id="interaction-config">Interaction Configuration</h2>
      <p>Enable rich user interactions with your charts.</p>

      <CodeBlock code={interactionsCode} language="dart" filename="interactions.dart" />

      <h2 id="zoom-pan">Zoom & Pan</h2>
      <ul>
        <li><strong>Pinch to zoom:</strong> Use two fingers on touch devices</li>
        <li><strong>Scroll wheel:</strong> Mouse wheel zooms on desktop/web</li>
        <li><strong>Double-tap:</strong> Quick zoom to point</li>
        <li><strong>Drag to pan:</strong> Move the visible area</li>
      </ul>

      <Callout type="tip" title="Keyboard Shortcuts">
        <p>When focused, charts support keyboard navigation: +/- to zoom, arrow keys to pan, R to reset.</p>
      </Callout>

      <h2 id="selection">Selection</h2>
      <p>Allow users to select data points:</p>
      <ul>
        <li><strong>SelectionMode.single:</strong> Select one point at a time</li>
        <li><strong>SelectionMode.multiple:</strong> Select multiple points</li>
        <li><strong>SelectionMode.range:</strong> Select a range of points</li>
      </ul>

      <h2 id="crosshair">Crosshair</h2>
      <p>Display crosshair lines that follow the pointer and snap to data points.</p>
    </>
  )
}

function TooltipsContent() {
  return (
    <>
      <h2 id="tooltip-config">Tooltip Configuration</h2>
      <p>Display detailed information when users hover or tap on data points.</p>

      <CodeBlock code={tooltipCode} language="dart" filename="tooltip.dart" />

      <h2 id="tooltip-modes">Tooltip Modes</h2>
      <ul>
        <li><strong>TooltipMode.single:</strong> Show tooltip for the nearest point</li>
        <li><strong>TooltipMode.crosshair:</strong> Show all values at the current X position</li>
        <li><strong>TooltipMode.grouped:</strong> Group multiple series in one tooltip</li>
      </ul>

      <h2 id="custom-formatting">Custom Formatting</h2>
      <p>Use a formatter function to customize tooltip content:</p>

      <Callout type="tip">
        <p>The formatter receives the full DataPoint, so you can access custom data attached to points.</p>
      </Callout>
    </>
  )
}

function LegendsContent() {
  return (
    <>
      <h2 id="legend-config">Legend Configuration</h2>
      <p>Add and customize chart legends.</p>

      <CodeBlock code={legendCode} language="dart" filename="legend.dart" />

      <h2 id="legend-positions">Legend Positions</h2>
      <ul>
        <li><strong>LegendPosition.top:</strong> Above the chart</li>
        <li><strong>LegendPosition.bottom:</strong> Below the chart</li>
        <li><strong>LegendPosition.left:</strong> Left side of chart</li>
        <li><strong>LegendPosition.right:</strong> Right side of chart</li>
      </ul>

      <h2 id="interactive-legend">Interactive Legend</h2>
      <p>Allow users to toggle series visibility by tapping legend items.</p>

      <Callout type="info">
        <p>When a series is hidden, its data is excluded from axis calculations for better scaling.</p>
      </Callout>
    </>
  )
}

function AccessibilityContent() {
  return (
    <>
      <h2 id="a11y-config">Accessibility Configuration</h2>
      <p>Make your charts accessible to users with disabilities.</p>

      <CodeBlock code={accessibilityCode} language="dart" filename="accessibility.dart" />

      <Callout type="warning" title="Important">
        <p>Accessibility is enabled by default. Only disable it if you have a specific reason to do so.</p>
      </Callout>

      <h2 id="screen-readers">Screen Reader Support</h2>
      <ul>
        <li>Chart description is announced when focused</li>
        <li>Data points can be navigated with arrow keys</li>
        <li>Point values are announced when selected</li>
      </ul>

      <h2 id="keyboard-navigation">Keyboard Navigation</h2>
      <ul>
        <li><strong>Tab:</strong> Focus the chart</li>
        <li><strong>Arrow keys:</strong> Navigate between points</li>
        <li><strong>Enter/Space:</strong> Select current point</li>
        <li><strong>Escape:</strong> Clear selection</li>
      </ul>

      <h2 id="high-contrast">High Contrast Mode</h2>
      <p>Enable high contrast colors for users with visual impairments.</p>
    </>
  )
}

function PerformanceContent() {
  return (
    <>
      <h2 id="large-datasets">Large Datasets</h2>
      <p>Chartify is optimized to handle tens of thousands of data points.</p>

      <CodeBlock code={performanceCode} language="dart" filename="performance.dart" />

      <h2 id="optimization-techniques">Optimization Techniques</h2>
      <ul>
        <li><strong>Viewport Culling:</strong> Only render visible points</li>
        <li><strong>Spatial Indexing:</strong> Fast hit detection with R-tree</li>
        <li><strong>Layer Caching:</strong> Cache static elements</li>
        <li><strong>Throttling:</strong> Limit re-render frequency</li>
      </ul>

      <Callout type="tip" title="Best Practices">
        <p>For datasets over 10,000 points, enable culling and consider downsampling for initial render.</p>
      </Callout>

      <h2 id="memory-management">Memory Management</h2>
      <p>Chartify automatically manages memory:</p>
      <ul>
        <li>Unused cache entries are cleared</li>
        <li>Large bitmaps are disposed when not visible</li>
        <li>Animation resources are released after completion</li>
      </ul>
    </>
  )
}

function CustomPaintersContent() {
  return (
    <>
      <h2 id="custom-painter">Creating Custom Painters</h2>
      <p>Extend Chartify with your own chart types using the painter API.</p>

      <CodeBlock code={customPainterCode} language="dart" filename="custom_painter.dart" />

      <Callout type="warning" title="Advanced Feature">
        <p>Custom painters require understanding of Flutter's Canvas API. Start with built-in charts before creating custom ones.</p>
      </Callout>

      <h2 id="painter-lifecycle">Painter Lifecycle</h2>
      <ol>
        <li><strong>shouldRepaint:</strong> Called to check if repaint is needed</li>
        <li><strong>paint:</strong> Render the chart to canvas</li>
        <li><strong>hitTest:</strong> Handle touch/mouse interactions</li>
      </ol>

      <h2 id="canvas-api">Canvas API</h2>
      <p>Common canvas operations:</p>
      <ul>
        <li><code>canvas.drawLine()</code> - Draw lines</li>
        <li><code>canvas.drawRect()</code> - Draw rectangles</li>
        <li><code>canvas.drawPath()</code> - Draw complex shapes</li>
        <li><code>canvas.drawCircle()</code> - Draw circles</li>
      </ul>
    </>
  )
}

function PluginsContent() {
  return (
    <>
      <h2 id="using-plugins">Using Plugins</h2>
      <p>Extend chart functionality with built-in and custom plugins.</p>

      <CodeBlock code={pluginsCode} language="dart" filename="plugins.dart" />

      <h2 id="built-in-plugins">Built-in Plugins</h2>
      <ul>
        <li><strong>ZoomPlugin:</strong> Pinch-to-zoom and scroll wheel zoom</li>
        <li><strong>CrosshairPlugin:</strong> Show crosshair lines and tooltip</li>
        <li><strong>DataLabelPlugin:</strong> Display values on data points</li>
        <li><strong>ReferenceLinePlugin:</strong> Add horizontal/vertical reference lines</li>
        <li><strong>AnnotationPlugin:</strong> Add text and shape annotations</li>
      </ul>

      <Callout type="tip" title="Plugin Order">
        <p>Plugins are processed in order. Put visual plugins (like annotations) after interaction plugins (like zoom).</p>
      </Callout>

      <h2 id="creating-plugins">Creating Custom Plugins</h2>
      <p>Implement the <code>ChartPlugin</code> interface to create your own plugins:</p>

      <CodeBlock code={`class MyPlugin extends ChartPlugin {
  @override
  void onInit(ChartController controller) {
    // Setup code
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // Custom rendering
  }

  @override
  void dispose() {
    // Cleanup
  }
}`} language="dart" showLineNumbers={false} />
    </>
  )
}

// ============================================================================
// Route to Content Mapping
// ============================================================================

const routeContent: Record<string, React.FC> = {
  '/docs': IntroductionContent,
  '/docs/installation': InstallationContent,
  '/docs/quick-start': QuickStartContent,
  '/docs/architecture': ArchitectureContent,
  '/docs/data-models': DataModelsContent,
  '/docs/configuration': ConfigurationContent,
  '/docs/theming': ThemingContent,
  '/docs/animations': AnimationsContent,
  '/docs/interactions': InteractionsContent,
  '/docs/tooltips': TooltipsContent,
  '/docs/legends': LegendsContent,
  '/docs/accessibility': AccessibilityContent,
  '/docs/performance': PerformanceContent,
  '/docs/custom-painters': CustomPaintersContent,
  '/docs/plugins': PluginsContent,
}

// ============================================================================
// Main Docs Component
// ============================================================================

export function Docs() {
  const location = useLocation()
  const ContentComponent = routeContent[location.pathname] || IntroductionContent
  const meta = pageMeta[location.pathname] || pageMeta['/docs']

  return (
    <DocLayout meta={meta} sidebarSections={sidebarSections}>
      <ContentComponent />
    </DocLayout>
  )
}
