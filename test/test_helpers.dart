import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';

/// Test helpers and utilities for Chartify tests.

/// Creates a list of sample data points for testing.
List<DataPoint<double, double>> createSampleDataPoints({
  int count = 10,
  double startX = 0,
  double startY = 0,
}) {
  return List.generate(
    count,
    (i) => DataPoint<double, double>(
      x: startX + i.toDouble(),
      y: startY + (i * 10).toDouble(),
    ),
  );
}

/// Creates a list of data points with invalid values for testing validation.
List<DataPoint<double, double>> createInvalidDataPoints() {
  return [
    const DataPoint<double, double>(x: 1, y: 10),
    const DataPoint<double, double>(x: 2, y: double.nan),
    const DataPoint<double, double>(x: 3, y: 30),
    const DataPoint<double, double>(x: double.infinity, y: 40),
    const DataPoint<double, double>(x: 5, y: double.negativeInfinity),
  ];
}

/// Creates sample time series data points for testing.
List<DataPoint<DateTime, double>> createTimeSeriesDataPoints({
  int count = 10,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime(2024, 1, 1);
  return List.generate(
    count,
    (i) => DataPoint<DateTime, double>(
      x: start.add(Duration(days: i)),
      y: (i * 10 + 5).toDouble(),
    ),
  );
}

/// Creates sample categorical data points for testing.
List<DataPoint<String, double>> createCategoricalDataPoints() {
  return const [
    DataPoint<String, double>(x: 'Jan', y: 100),
    DataPoint<String, double>(x: 'Feb', y: 150),
    DataPoint<String, double>(x: 'Mar', y: 200),
    DataPoint<String, double>(x: 'Apr', y: 175),
    DataPoint<String, double>(x: 'May', y: 225),
  ];
}

/// Creates sample OHLC data points for testing.
List<OHLCDataPoint<DateTime>> createOHLCDataPoints({
  int count = 5,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime(2024, 1, 1);
  return List.generate(
    count,
    (i) => OHLCDataPoint<DateTime>(
      x: start.add(Duration(days: i)),
      open: 100 + i * 5.0,
      high: 110 + i * 5.0,
      low: 95 + i * 5.0,
      close: 105 + i * 5.0,
      volume: 1000000 + i * 100000.0,
    ),
  );
}

/// Creates sample box plot data points for testing.
List<BoxPlotDataPoint<String>> createBoxPlotDataPoints() {
  return const [
    BoxPlotDataPoint<String>(
      x: 'Group A',
      min: 10,
      q1: 25,
      median: 50,
      q3: 75,
      max: 90,
      mean: 48,
    ),
    BoxPlotDataPoint<String>(
      x: 'Group B',
      min: 15,
      q1: 30,
      median: 55,
      q3: 80,
      max: 95,
      outliers: [5, 100],
    ),
  ];
}

/// Creates a sized data point for bubble chart testing.
List<SizedDataPoint<double, double>> createSizedDataPoints({int count = 5}) {
  return List.generate(
    count,
    (i) => SizedDataPoint<double, double>(
      x: i.toDouble(),
      y: (i * 10).toDouble(),
      size: (i + 1) * 5.0,
    ),
  );
}

/// Creates sample hierarchical data for treemap/sunburst testing.
HierarchicalDataPoint<double> createHierarchicalData() {
  return HierarchicalDataPoint<double>(
    id: 'root',
    value: 100,
    label: 'Root',
    children: [
      HierarchicalDataPoint<double>(
        id: 'child1',
        value: 40,
        label: 'Child 1',
        parentId: 'root',
        children: [
          const HierarchicalDataPoint<double>(
            id: 'grandchild1',
            value: 20,
            label: 'Grandchild 1',
            parentId: 'child1',
          ),
          const HierarchicalDataPoint<double>(
            id: 'grandchild2',
            value: 20,
            label: 'Grandchild 2',
            parentId: 'child1',
          ),
        ],
      ),
      const HierarchicalDataPoint<double>(
        id: 'child2',
        value: 60,
        label: 'Child 2',
        parentId: 'root',
      ),
    ],
  );
}

/// Creates sample heatmap data points for testing.
List<HeatmapDataPoint<int, int, double>> createHeatmapDataPoints({
  int rows = 5,
  int cols = 5,
}) {
  final points = <HeatmapDataPoint<int, int, double>>[];
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      points.add(HeatmapDataPoint<int, int, double>(
        x: x,
        y: y,
        value: (x + y) * 10.0,
      ));
    }
  }
  return points;
}

/// Wraps a widget with MaterialApp for testing.
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

/// Wraps a widget with a fixed size container for golden testing.
Widget wrapForGoldenTest(
  Widget child, {
  Size size = const Size(800, 600),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

/// Test theme data for consistent golden tests.
ChartThemeData get testThemeLight => ChartThemeData.light();
ChartThemeData get testThemeDark => ChartThemeData.dark();
