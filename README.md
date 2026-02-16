# Chartify

A comprehensive, high-performance Flutter chart library with 32+ chart types, modern theming, animations, and cross-platform support.

[![pub package](https://img.shields.io/pub/v/chartify.svg)](https://pub.dev/packages/chartify)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Features

- **32+ chart types** — Line, Bar, Area, Pie, Scatter, Bubble, Radar, Gauge, Candlestick, Sankey, Treemap, and many more
- **Modern theming** — Built-in `modern()` and `modernDark()` themes with customizable properties
- **Smooth animations** — Configurable entry animations with custom curves
- **Interactive** — Tooltips, hover effects, selection, and zoom support
- **Accessible** — Semantic labels, focus indicators, and contrast validation
- **Cross-platform** — Android, iOS, Web, macOS, Windows, Linux

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  chartify: ^1.0.0
```

## Quick Start

```dart
import 'package:chartify/chartify.dart';

// Line chart
LineChart(
  data: LineChartData(
    series: [
      LineSeries(
        name: 'Sales',
        data: [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 25),
          DataPoint(x: 2, y: 15),
          DataPoint(x: 3, y: 30),
        ],
        curved: true,
        fillArea: true,
      ),
    ],
  ),
)
```

## Theming

Apply a modern theme globally:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [ChartThemeData.modern()],
  ),
  darkTheme: ThemeData(
    extensions: [ChartThemeData.modernDark()],
  ),
)
```

Or customize from a seed color:

```dart
ChartThemeData.fromSeed(Colors.indigo)
```

Theme properties include `gridDashPattern`, `barCornerRadius`, `shadowBlurRadius`, `shadowOpacity`, `areaFillOpacity`, and more.

## Chart Types

### Cartesian
Line, Bar, Area, Scatter, Bubble, Candlestick, Box Plot, Histogram, Waterfall, Step, Range, Lollipop, Dumbbell, Slope, Bump, Bullet, Gantt

### Circular
Pie/Donut, Gauge, Radial Bar, Sunburst

### Polar
Radar, Rose

### Hierarchical
Funnel, Pyramid, Treemap

### Specialty
Heatmap, Calendar Heatmap, Sankey, Sparkline

## Examples

### Bar Chart

```dart
BarChart(
  data: BarChartData(
    series: [
      BarSeries(
        name: 'Revenue',
        data: [
          BarData(x: 'Q1', y: 120),
          BarData(x: 'Q2', y: 180),
          BarData(x: 'Q3', y: 150),
          BarData(x: 'Q4', y: 210),
        ],
        cornerRadius: 6,
      ),
    ],
  ),
)
```

### Pie Chart

```dart
PieChart(
  data: PieChartData(
    sections: [
      PieSection(value: 35, label: 'Mobile'),
      PieSection(value: 25, label: 'Desktop'),
      PieSection(value: 20, label: 'Tablet'),
      PieSection(value: 20, label: 'Other'),
    ],
    holeRadius: 0.5, // Makes it a donut chart
  ),
)
```

### Radar Chart

```dart
RadarChart(
  data: RadarChartData(
    categories: ['Speed', 'Power', 'Range', 'Defense', 'Agility'],
    series: [
      RadarSeries(
        name: 'Player A',
        values: [80, 90, 70, 60, 85],
      ),
    ],
  ),
)
```

## Animation

```dart
LineChart(
  data: lineData,
  animation: ChartAnimation(
    duration: Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
  ),
)
```

## License

```
Copyright 2025 Sitharaj Seenivasan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```
