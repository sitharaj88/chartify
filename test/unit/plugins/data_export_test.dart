import 'package:chartify/chartify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataExportService', () {
    late DataExportService service;

    setUp(() {
      service = const DataExportService();
    });

    group('CSV export', () {
      test('exports simple data to CSV', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [
              const DataPoint(x: 1.0, y: 100.0),
              const DataPoint(x: 2.0, y: 150.0),
              const DataPoint(x: 3.0, y: 200.0),
            ],
          ),
        ];

        final csv = service.exportToCsv(series);

        expect(csv, contains('series,x,y'));
        expect(csv, contains('Sales,1.00,100.00'));
        expect(csv, contains('Sales,2.00,150.00'));
        expect(csv, contains('Sales,3.00,200.00'));
      });

      test('exports multiple series to CSV', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
          ExportableSeries<double, double>(
            name: 'Profit',
            data: [const DataPoint(x: 1.0, y: 50.0)],
          ),
        ];

        final csv = service.exportToCsv(series);

        expect(csv, contains('Sales,1.00,100.00'));
        expect(csv, contains('Profit,1.00,50.00'));
      });

      test('exports without headers when configured', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(
          series,
          config: const DataExportConfig(includeHeaders: false),
        );

        expect(csv, isNot(contains('series,x,y')));
        expect(csv, startsWith('Sales,1.00,100.00'));
      });

      test('escapes values with commas', () {
        final series = [
          ExportableSeries<String, double>(
            name: 'Category A, B',
            data: [const DataPoint(x: 'Item 1, 2', y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(series);

        expect(csv, contains('"Category A, B"'));
        expect(csv, contains('"Item 1, 2"'));
      });

      test('escapes values with quotes', () {
        final series = [
          ExportableSeries<String, double>(
            name: 'Say "Hello"',
            data: [const DataPoint(x: 'Test', y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(series);

        expect(csv, contains('"Say ""Hello"""'));
      });

      test('uses custom delimiter', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(
          series,
          config: const DataExportConfig(delimiter: ';'),
        );

        expect(csv, contains('series;x;y'));
        expect(csv, contains('Sales;1.00;100.00'));
      });

      test('exports with custom column names', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(
          series,
          config: const DataExportConfig(
            seriesNameColumn: 'category',
            xColumn: 'date',
            yColumn: 'value',
          ),
        );

        expect(csv, contains('category,date,value'));
      });

      test('includes metadata when configured', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [
              const DataPoint(
                x: 1.0,
                y: 100.0,
                metadata: {'region': 'North', 'product': 'A'},
              ),
            ],
          ),
        ];

        final csv = service.exportToCsv(
          series,
          config: const DataExportConfig(includeMetadata: true),
        );

        expect(csv, contains('product'));
        expect(csv, contains('region'));
        expect(csv, contains('North'));
        expect(csv, contains('A'));
      });

      test('handles DateTime values', () {
        final date = DateTime(2024, 6, 15, 10, 30);
        final series = [
          ExportableSeries<DateTime, double>(
            name: 'Events',
            data: [DataPoint(x: date, y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(series);

        expect(csv, contains('2024-06-15'));
      });

      test('uses custom date format', () {
        final date = DateTime(2024, 6, 15);
        final series = [
          ExportableSeries<DateTime, double>(
            name: 'Events',
            data: [DataPoint(x: date, y: 100.0)],
          ),
        ];

        final csv = service.exportToCsv(
          series,
          config: const DataExportConfig(dateFormat: 'dd/MM/yyyy'),
        );

        expect(csv, contains('15/06/2024'));
      });
    });

    group('TSV export', () {
      test('exports to TSV with tab delimiter', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final tsv = service.exportToTsv(series);

        expect(tsv, contains('series\tx\ty'));
        expect(tsv, contains('Sales\t1.00\t100.00'));
      });
    });

    group('JSON export', () {
      test('exports simple data to JSON', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [
              const DataPoint(x: 1.0, y: 100.0),
              const DataPoint(x: 2.0, y: 150.0),
            ],
          ),
        ];

        final json = service.exportToJson(series);

        expect(json, contains('"name":"Sales"'));
        expect(json, contains('"x":1'));
        expect(json, contains('"y":100'));
        expect(json, contains('"x":2'));
        expect(json, contains('"y":150'));
      });

      test('exports with pretty print', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final json = service.exportToJson(
          series,
          config: const DataExportConfig(prettyPrint: true),
        );

        expect(json, contains('\n'));
        expect(json, contains('  ')); // Indentation
      });

      test('exports DateTime as ISO string', () {
        final date = DateTime(2024, 6, 15, 10, 30, 45);
        final series = [
          ExportableSeries<DateTime, double>(
            name: 'Events',
            data: [DataPoint(x: date, y: 100.0)],
          ),
        ];

        final json = service.exportToJson(series);

        expect(json, contains('2024-06-15T10:30:45'));
      });

      test('includes metadata when configured', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [
              const DataPoint(
                x: 1.0,
                y: 100.0,
                metadata: {'region': 'North'},
              ),
            ],
            metadata: {'source': 'API'},
          ),
        ];

        final json = service.exportToJson(
          series,
          config: const DataExportConfig(includeMetadata: true),
        );

        expect(json, contains('"region":"North"'));
        expect(json, contains('"source":"API"'));
      });

      test('respects number precision', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.123456, y: 100.789012)],
          ),
        ];

        final json = service.exportToJson(
          series,
          config: const DataExportConfig(numberPrecision: 3),
        );

        expect(json, contains('1.123'));
        expect(json, contains('100.789'));
      });

      test('escapes special characters in strings', () {
        final series = [
          ExportableSeries<String, double>(
            name: 'Say "Hello"\nWorld',
            data: [const DataPoint(x: 'Test\tTab', y: 100.0)],
          ),
        ];

        final json = service.exportToJson(series);

        expect(json, contains(r'\"Hello\"'));
        expect(json, contains(r'\n'));
        expect(json, contains(r'\t'));
      });
    });

    group('export format selection', () {
      test('export method uses correct format', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final csv = service.export(
          series,
          config: const DataExportConfig(format: DataExportFormat.csv),
        );
        final json = service.export(
          series,
          config: const DataExportConfig(format: DataExportFormat.json),
        );

        expect(csv, contains('series,x,y'));
        expect(json, contains('"name":"Sales"'));
      });
    });

    group('extension methods', () {
      test('toCsv extension works', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final csv = series.toCsv();

        expect(csv, contains('Sales,1.00,100.00'));
      });

      test('toJson extension works', () {
        final series = [
          ExportableSeries<double, double>(
            name: 'Sales',
            data: [const DataPoint(x: 1.0, y: 100.0)],
          ),
        ];

        final json = series.toJson();

        expect(json, contains('"name":"Sales"'));
      });
    });
  });

  group('DataExportConfig', () {
    test('has correct default values', () {
      const config = DataExportConfig();

      expect(config.format, DataExportFormat.csv);
      expect(config.includeHeaders, true);
      expect(config.includeMetadata, false);
      expect(config.delimiter, ',');
      expect(config.quoteStrings, true);
    });

    test('csv preset has correct values', () {
      expect(DataExportConfig.csv.format, DataExportFormat.csv);
    });

    test('tsv preset has correct values', () {
      expect(DataExportConfig.tsv.format, DataExportFormat.tsv);
      expect(DataExportConfig.tsv.delimiter, '\t');
      expect(DataExportConfig.tsv.quoteStrings, false);
    });

    test('json preset has correct values', () {
      expect(DataExportConfig.json.format, DataExportFormat.json);
    });

    test('jsonPretty preset has correct values', () {
      expect(DataExportConfig.jsonPretty.format, DataExportFormat.json);
      expect(DataExportConfig.jsonPretty.prettyPrint, true);
    });

    test('copyWith creates copy with changes', () {
      const original = DataExportConfig();
      final copy = original.copyWith(
        format: DataExportFormat.json,
        includeMetadata: true,
      );

      expect(copy.format, DataExportFormat.json);
      expect(copy.includeMetadata, true);
      expect(copy.includeHeaders, original.includeHeaders);
    });
  });
}
