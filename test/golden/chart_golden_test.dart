import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Chart Golden Tests', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    // ============== Line Chart ==============

    testGoldens('LineChart - basic', (tester) async {
      final widget = _chartWrapper(
        LineChart(
          data: LineChartData(
            series: [
              LineSeries(
                name: 'Revenue',
                data: [
                  const DataPoint(x: 0.0, y: 10.0),
                  const DataPoint(x: 1.0, y: 25.0),
                  const DataPoint(x: 2.0, y: 15.0),
                  const DataPoint(x: 3.0, y: 30.0),
                  const DataPoint(x: 4.0, y: 22.0),
                ],
                color: Colors.blue,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'line_chart_basic');
    });

    testGoldens('LineChart - curved with area fill', (tester) async {
      final widget = _chartWrapper(
        LineChart(
          data: LineChartData(
            series: [
              LineSeries(
                name: 'Sales',
                data: [
                  const DataPoint(x: 0.0, y: 20.0),
                  const DataPoint(x: 1.0, y: 35.0),
                  const DataPoint(x: 2.0, y: 25.0),
                  const DataPoint(x: 3.0, y: 45.0),
                  const DataPoint(x: 4.0, y: 38.0),
                ],
                color: Colors.teal,
                curved: true,
                fillArea: true,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'line_chart_curved_area');
    });

    testGoldens('LineChart - multiple series', (tester) async {
      final widget = _chartWrapper(
        LineChart(
          data: LineChartData(
            series: [
              LineSeries(
                name: 'Product A',
                data: [
                  const DataPoint(x: 0.0, y: 10.0),
                  const DataPoint(x: 1.0, y: 20.0),
                  const DataPoint(x: 2.0, y: 15.0),
                  const DataPoint(x: 3.0, y: 25.0),
                ],
                color: Colors.blue,
              ),
              LineSeries(
                name: 'Product B',
                data: [
                  const DataPoint(x: 0.0, y: 15.0),
                  const DataPoint(x: 1.0, y: 12.0),
                  const DataPoint(x: 2.0, y: 22.0),
                  const DataPoint(x: 3.0, y: 18.0),
                ],
                color: Colors.red,
              ),
              LineSeries(
                name: 'Product C',
                data: [
                  const DataPoint(x: 0.0, y: 8.0),
                  const DataPoint(x: 1.0, y: 18.0),
                  const DataPoint(x: 2.0, y: 12.0),
                  const DataPoint(x: 3.0, y: 28.0),
                ],
                color: Colors.green,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'line_chart_multiple_series');
    });

    // ============== Bar Chart ==============

    testGoldens('BarChart - basic', (tester) async {
      final widget = _chartWrapper(
        BarChart(
          data: BarChartData(
            series: [
              BarSeries(
                name: 'Sales',
                data: [
                  const DataPoint(x: 0.0, y: 100.0),
                  const DataPoint(x: 1.0, y: 150.0),
                  const DataPoint(x: 2.0, y: 120.0),
                  const DataPoint(x: 3.0, y: 180.0),
                ],
                color: Colors.blue,
              ),
            ],
            xAxis: BarXAxisConfig(categories: ['Q1', 'Q2', 'Q3', 'Q4']),
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'bar_chart_basic');
    });

    testGoldens('BarChart - grouped', (tester) async {
      final widget = _chartWrapper(
        BarChart(
          data: BarChartData(
            series: [
              BarSeries(
                name: '2023',
                data: [
                  const DataPoint(x: 0.0, y: 100.0),
                  const DataPoint(x: 1.0, y: 150.0),
                  const DataPoint(x: 2.0, y: 120.0),
                ],
                color: Colors.blue,
              ),
              BarSeries(
                name: '2024',
                data: [
                  const DataPoint(x: 0.0, y: 120.0),
                  const DataPoint(x: 1.0, y: 180.0),
                  const DataPoint(x: 2.0, y: 140.0),
                ],
                color: Colors.orange,
              ),
            ],
            xAxis: BarXAxisConfig(categories: ['Jan', 'Feb', 'Mar']),
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'bar_chart_grouped');
    });

    testGoldens('BarChart - stacked', (tester) async {
      final widget = _chartWrapper(
        BarChart(
          data: BarChartData(
            series: [
              BarSeries(
                name: 'Product A',
                data: [
                  const DataPoint(x: 0.0, y: 50.0),
                  const DataPoint(x: 1.0, y: 70.0),
                  const DataPoint(x: 2.0, y: 60.0),
                ],
                color: Colors.blue,
              ),
              BarSeries(
                name: 'Product B',
                data: [
                  const DataPoint(x: 0.0, y: 30.0),
                  const DataPoint(x: 1.0, y: 40.0),
                  const DataPoint(x: 2.0, y: 35.0),
                ],
                color: Colors.green,
              ),
              BarSeries(
                name: 'Product C',
                data: [
                  const DataPoint(x: 0.0, y: 20.0),
                  const DataPoint(x: 1.0, y: 25.0),
                  const DataPoint(x: 2.0, y: 22.0),
                ],
                color: Colors.orange,
              ),
            ],
            xAxis: BarXAxisConfig(categories: ['Q1', 'Q2', 'Q3']),
            grouping: BarGrouping.stacked,
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'bar_chart_stacked');
    });

    // ============== Area Chart ==============

    testGoldens('AreaChart - basic', (tester) async {
      final widget = _chartWrapper(
        AreaChart(
          data: AreaChartData(
            series: [
              AreaSeries(
                name: 'Revenue',
                data: [
                  const DataPoint(x: 0.0, y: 20.0),
                  const DataPoint(x: 1.0, y: 35.0),
                  const DataPoint(x: 2.0, y: 28.0),
                  const DataPoint(x: 3.0, y: 42.0),
                  const DataPoint(x: 4.0, y: 38.0),
                ],
                color: Colors.purple,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'area_chart_basic');
    });

    testGoldens('AreaChart - stacked', (tester) async {
      final widget = _chartWrapper(
        AreaChart(
          data: AreaChartData(
            series: [
              AreaSeries(
                name: 'Desktop',
                data: [
                  const DataPoint(x: 0.0, y: 40.0),
                  const DataPoint(x: 1.0, y: 45.0),
                  const DataPoint(x: 2.0, y: 42.0),
                  const DataPoint(x: 3.0, y: 48.0),
                ],
                color: Colors.blue,
              ),
              AreaSeries(
                name: 'Mobile',
                data: [
                  const DataPoint(x: 0.0, y: 30.0),
                  const DataPoint(x: 1.0, y: 35.0),
                  const DataPoint(x: 2.0, y: 38.0),
                  const DataPoint(x: 3.0, y: 32.0),
                ],
                color: Colors.green,
              ),
              AreaSeries(
                name: 'Tablet',
                data: [
                  const DataPoint(x: 0.0, y: 10.0),
                  const DataPoint(x: 1.0, y: 12.0),
                  const DataPoint(x: 2.0, y: 15.0),
                  const DataPoint(x: 3.0, y: 11.0),
                ],
                color: Colors.orange,
              ),
            ],
            stacked: true,
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'area_chart_stacked');
    });

    // ============== Pie Chart ==============

    testGoldens('PieChart - basic', (tester) async {
      final widget = _chartWrapper(
        PieChart(
          data: PieChartData(
            sections: [
              const PieSection(value: 40, label: 'Mobile', color: Colors.blue),
              const PieSection(value: 30, label: 'Desktop', color: Colors.green),
              const PieSection(value: 20, label: 'Tablet', color: Colors.orange),
              const PieSection(value: 10, label: 'Other', color: Colors.grey),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(600, 600));
      await screenMatchesGolden(tester, 'pie_chart_basic');
    });

    testGoldens('PieChart - donut', (tester) async {
      final widget = _chartWrapper(
        PieChart(
          data: PieChartData(
            sections: [
              const PieSection(value: 35, label: 'Chrome', color: Colors.blue),
              const PieSection(value: 25, label: 'Safari', color: Colors.orange),
              const PieSection(value: 20, label: 'Firefox', color: Colors.red),
              const PieSection(value: 15, label: 'Edge', color: Colors.teal),
              const PieSection(value: 5, label: 'Other', color: Colors.grey),
            ],
            holeRadius: 0.5,
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(600, 600));
      await screenMatchesGolden(tester, 'pie_chart_donut');
    });

    // ============== Scatter Chart ==============

    testGoldens('ScatterChart - basic', (tester) async {
      final widget = _chartWrapper(
        ScatterChart(
          data: ScatterChartData(
            series: [
              ScatterSeries(
                name: 'Data Points',
                data: [
                  const ScatterDataPoint(x: 1.0, y: 5.0),
                  const ScatterDataPoint(x: 2.0, y: 8.0),
                  const ScatterDataPoint(x: 3.0, y: 4.0),
                  const ScatterDataPoint(x: 4.0, y: 10.0),
                  const ScatterDataPoint(x: 5.0, y: 7.0),
                  const ScatterDataPoint(x: 6.0, y: 12.0),
                  const ScatterDataPoint(x: 7.0, y: 6.0),
                  const ScatterDataPoint(x: 8.0, y: 9.0),
                ],
                color: Colors.blue,
                pointSize: 8,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'scatter_chart_basic');
    });

    testGoldens('ScatterChart - multiple series', (tester) async {
      final widget = _chartWrapper(
        ScatterChart(
          data: ScatterChartData(
            series: [
              ScatterSeries(
                name: 'Group A',
                data: [
                  const ScatterDataPoint(x: 1.0, y: 5.0),
                  const ScatterDataPoint(x: 2.0, y: 8.0),
                  const ScatterDataPoint(x: 3.0, y: 4.0),
                  const ScatterDataPoint(x: 4.0, y: 10.0),
                ],
                color: Colors.blue,
                pointSize: 10,
              ),
              ScatterSeries(
                name: 'Group B',
                data: [
                  const ScatterDataPoint(x: 1.5, y: 7.0),
                  const ScatterDataPoint(x: 2.5, y: 3.0),
                  const ScatterDataPoint(x: 3.5, y: 9.0),
                  const ScatterDataPoint(x: 4.5, y: 6.0),
                ],
                color: Colors.red,
                pointSize: 10,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'scatter_chart_multiple_series');
    });

    // ============== Bubble Chart ==============

    testGoldens('BubbleChart - basic', (tester) async {
      final widget = _chartWrapper(
        BubbleChart(
          data: BubbleChartData(
            series: [
              BubbleSeries(
                name: 'Companies',
                data: [
                  const BubbleDataPoint(x: 10.0, y: 20.0, size: 30.0),
                  const BubbleDataPoint(x: 30.0, y: 40.0, size: 50.0),
                  const BubbleDataPoint(x: 50.0, y: 25.0, size: 20.0),
                  const BubbleDataPoint(x: 70.0, y: 55.0, size: 40.0),
                  const BubbleDataPoint(x: 90.0, y: 35.0, size: 25.0),
                ],
                color: Colors.indigo,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'bubble_chart_basic');
    });

    // ============== Radar Chart ==============

    testGoldens('RadarChart - basic', (tester) async {
      final widget = _chartWrapper(
        RadarChart(
          data: RadarChartData(
            axes: ['Speed', 'Power', 'Defense', 'Health', 'Agility'],
            series: [
              RadarSeries(
                name: 'Player 1',
                values: [80, 90, 70, 85, 75],
                color: Colors.blue,
              ),
            ],
          ),
          animation: const ChartAnimation.none(),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(600, 600));
      await screenMatchesGolden(tester, 'radar_chart_basic');
    });

    testGoldens('RadarChart - multiple series', (tester) async {
      final widget = _chartWrapper(
        RadarChart(
          data: RadarChartData(
            axes: ['Attack', 'Defense', 'Speed', 'Magic', 'Stamina'],
            series: [
              RadarSeries(
                name: 'Warrior',
                values: [90, 85, 60, 30, 80],
                color: Colors.red,
              ),
              RadarSeries(
                name: 'Mage',
                values: [40, 50, 70, 95, 60],
                color: Colors.purple,
              ),
            ],
          ),
          animation: const ChartAnimation.none(),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(600, 600));
      await screenMatchesGolden(tester, 'radar_chart_multiple_series');
    });

    // ============== Gauge Chart ==============

    testGoldens('GaugeChart - basic', (tester) async {
      final widget = _chartWrapper(
        GaugeChart(
          data: GaugeChartData(
            value: 75,
            minValue: 0,
            maxValue: 100,
            ranges: [
              const GaugeRange(start: 0, end: 30, color: Colors.red),
              const GaugeRange(start: 30, end: 70, color: Colors.yellow),
              const GaugeRange(start: 70, end: 100, color: Colors.green),
            ],
          ),
          animation: const ChartAnimation.none(),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(400, 300));
      await screenMatchesGolden(tester, 'gauge_chart_basic');
    });

    // ============== Candlestick Chart ==============

    testGoldens('CandlestickChart - basic', (tester) async {
      final widget = _chartWrapper(
        CandlestickChart(
          data: CandlestickChartData(
            data: [
              CandlestickDataPoint(
                date: DateTime(2024, 1, 1),
                open: 100,
                high: 110,
                low: 95,
                close: 105,
              ),
              CandlestickDataPoint(
                date: DateTime(2024, 1, 2),
                open: 105,
                high: 115,
                low: 100,
                close: 112,
              ),
              CandlestickDataPoint(
                date: DateTime(2024, 1, 3),
                open: 112,
                high: 118,
                low: 108,
                close: 106,
              ),
              CandlestickDataPoint(
                date: DateTime(2024, 1, 4),
                open: 106,
                high: 112,
                low: 102,
                close: 110,
              ),
              CandlestickDataPoint(
                date: DateTime(2024, 1, 5),
                open: 110,
                high: 120,
                low: 108,
                close: 118,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'candlestick_chart_basic');
    });

    // ============== Step Chart ==============

    testGoldens('StepChart - basic', (tester) async {
      final widget = _chartWrapper(
        StepChart(
          data: StepChartData(
            series: [
              StepSeries(
                name: 'Steps',
                data: [
                  const DataPoint(x: 0.0, y: 10.0),
                  const DataPoint(x: 1.0, y: 25.0),
                  const DataPoint(x: 2.0, y: 15.0),
                  const DataPoint(x: 3.0, y: 30.0),
                  const DataPoint(x: 4.0, y: 20.0),
                ],
                color: Colors.teal,
              ),
            ],
            animation: const ChartAnimation.none(),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(800, 400));
      await screenMatchesGolden(tester, 'step_chart_basic');
    });

    // ============== Sparkline Chart ==============

    testGoldens('SparklineChart - basic', (tester) async {
      final widget = _chartWrapper(
        SparklineChart(
          data: const SparklineChartData(
            values: [10, 25, 15, 30, 22, 18, 28, 35, 20, 32],
            color: Colors.blue,
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(200, 50));
      await screenMatchesGolden(tester, 'sparkline_chart_basic');
    });

    testGoldens('SparklineChart - with area', (tester) async {
      final widget = _chartWrapper(
        SparklineChart(
          data: const SparklineChartData(
            values: [10, 25, 15, 30, 22, 18, 28, 35, 20, 32],
            type: SparklineType.area,
            color: Colors.green,
            areaOpacity: 0.3,
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget, surfaceSize: const Size(200, 50));
      await screenMatchesGolden(tester, 'sparkline_chart_with_area');
    });
  });
}

/// Helper to wrap chart widgets with required theme
Widget _chartWrapper(Widget chart) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    home: Scaffold(
      body: ChartTheme(
        data: ChartThemeData.light(),
        child: chart,
      ),
    ),
  );
}
