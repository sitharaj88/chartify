import '../../../core/data/data_point.dart';

/// Format for data export.
enum DataExportFormat {
  /// Comma-separated values format.
  csv,

  /// JavaScript Object Notation format.
  json,

  /// Tab-separated values format.
  tsv,
}

/// Configuration for data export.
class DataExportConfig {
  const DataExportConfig({
    this.format = DataExportFormat.csv,
    this.includeHeaders = true,
    this.includeMetadata = false,
    this.dateFormat = 'yyyy-MM-dd',
    this.numberPrecision = 2,
    this.nullValue = '',
    this.delimiter = ',',
    this.lineEnding = '\n',
    this.quoteStrings = true,
    this.seriesNameColumn = 'series',
    this.xColumn = 'x',
    this.yColumn = 'y',
    this.prettyPrint = false,
    this.indentSize = 2,
  });

  /// Export format.
  final DataExportFormat format;

  /// Whether to include column headers (for CSV/TSV).
  final bool includeHeaders;

  /// Whether to include metadata in the export.
  final bool includeMetadata;

  /// Date format string for DateTime values.
  final String dateFormat;

  /// Number of decimal places for numeric values.
  final int numberPrecision;

  /// Value to use for null entries.
  final String nullValue;

  /// Field delimiter (for CSV/TSV).
  final String delimiter;

  /// Line ending character(s).
  final String lineEnding;

  /// Whether to quote string values in CSV.
  final bool quoteStrings;

  /// Column name for series identifier.
  final String seriesNameColumn;

  /// Column name for x values.
  final String xColumn;

  /// Column name for y values.
  final String yColumn;

  /// Whether to pretty-print JSON output.
  final bool prettyPrint;

  /// Indent size for pretty-printed JSON.
  final int indentSize;

  /// Creates a copy with updated values.
  DataExportConfig copyWith({
    DataExportFormat? format,
    bool? includeHeaders,
    bool? includeMetadata,
    String? dateFormat,
    int? numberPrecision,
    String? nullValue,
    String? delimiter,
    String? lineEnding,
    bool? quoteStrings,
    String? seriesNameColumn,
    String? xColumn,
    String? yColumn,
    bool? prettyPrint,
    int? indentSize,
  }) =>
      DataExportConfig(
        format: format ?? this.format,
        includeHeaders: includeHeaders ?? this.includeHeaders,
        includeMetadata: includeMetadata ?? this.includeMetadata,
        dateFormat: dateFormat ?? this.dateFormat,
        numberPrecision: numberPrecision ?? this.numberPrecision,
        nullValue: nullValue ?? this.nullValue,
        delimiter: delimiter ?? this.delimiter,
        lineEnding: lineEnding ?? this.lineEnding,
        quoteStrings: quoteStrings ?? this.quoteStrings,
        seriesNameColumn: seriesNameColumn ?? this.seriesNameColumn,
        xColumn: xColumn ?? this.xColumn,
        yColumn: yColumn ?? this.yColumn,
        prettyPrint: prettyPrint ?? this.prettyPrint,
        indentSize: indentSize ?? this.indentSize,
      );

  /// Creates a config for CSV export.
  static const csv = DataExportConfig(format: DataExportFormat.csv);

  /// Creates a config for TSV export.
  static const tsv = DataExportConfig(
    format: DataExportFormat.tsv,
    delimiter: '\t',
    quoteStrings: false,
  );

  /// Creates a config for JSON export.
  static const json = DataExportConfig(format: DataExportFormat.json);

  /// Creates a config for pretty-printed JSON export.
  static const jsonPretty = DataExportConfig(
    format: DataExportFormat.json,
    prettyPrint: true,
  );
}

/// A data series for export containing name and data points.
class ExportableSeries<X, Y> {
  const ExportableSeries({
    required this.name,
    required this.data,
    this.metadata,
  });

  /// Name of the series.
  final String name;

  /// Data points in the series.
  final List<DataPoint<X, Y>> data;

  /// Optional metadata for the series.
  final Map<String, dynamic>? metadata;
}

/// Service for exporting chart data to various formats.
///
/// Example:
/// ```dart
/// final service = DataExportService();
///
/// // Export to CSV
/// final csv = service.exportToCsv([
///   ExportableSeries(
///     name: 'Sales',
///     data: [
///       DataPoint(x: 1, y: 100),
///       DataPoint(x: 2, y: 150),
///     ],
///   ),
/// ]);
///
/// // Export to JSON
/// final json = service.exportToJson(series);
/// ```
class DataExportService {
  /// Default configuration for exports.
  final DataExportConfig defaultConfig;

  /// Creates a data export service with optional default config.
  const DataExportService({this.defaultConfig = const DataExportConfig()});

  /// Exports data using the specified format.
  String export<X, Y>(
    List<ExportableSeries<X, Y>> series, {
    DataExportConfig? config,
  }) {
    final cfg = config ?? defaultConfig;
    return switch (cfg.format) {
      DataExportFormat.csv => exportToCsv(series, config: cfg),
      DataExportFormat.tsv => exportToTsv(series, config: cfg),
      DataExportFormat.json => exportToJson(series, config: cfg),
    };
  }

  /// Exports data to CSV format.
  String exportToCsv<X, Y>(
    List<ExportableSeries<X, Y>> series, {
    DataExportConfig? config,
  }) {
    final cfg = config ?? defaultConfig;
    return _exportDelimited(series, cfg);
  }

  /// Exports data to TSV format.
  String exportToTsv<X, Y>(
    List<ExportableSeries<X, Y>> series, {
    DataExportConfig? config,
  }) {
    final cfg = (config ?? defaultConfig).copyWith(
      delimiter: '\t',
      quoteStrings: false,
    );
    return _exportDelimited(series, cfg);
  }

  /// Exports data to JSON format.
  String exportToJson<X, Y>(
    List<ExportableSeries<X, Y>> series, {
    DataExportConfig? config,
  }) {
    final cfg = config ?? defaultConfig;
    final data = _buildJsonData(series, cfg);

    if (cfg.prettyPrint) {
      return _prettyPrintJson(data, cfg.indentSize);
    }
    return _toJsonString(data);
  }

  String _exportDelimited<X, Y>(
    List<ExportableSeries<X, Y>> series,
    DataExportConfig config,
  ) {
    final buffer = StringBuffer();
    final columns = _getColumns(series, config);

    // Write header
    if (config.includeHeaders) {
      buffer.write(columns.map((c) => _escapeField(c, config)).join(config.delimiter));
      buffer.write(config.lineEnding);
    }

    // Write data rows
    for (final s in series) {
      for (final point in s.data) {
        final row = _buildRow(s.name, point, columns, config);
        buffer.write(row.map((v) => _escapeField(v, config)).join(config.delimiter));
        buffer.write(config.lineEnding);
      }
    }

    return buffer.toString();
  }

  List<String> _getColumns<X, Y>(
    List<ExportableSeries<X, Y>> series,
    DataExportConfig config,
  ) {
    final columns = <String>[
      config.seriesNameColumn,
      config.xColumn,
      config.yColumn,
    ];

    if (config.includeMetadata) {
      // Collect all unique metadata keys
      final metadataKeys = <String>{};
      for (final s in series) {
        for (final point in s.data) {
          if (point.metadata != null) {
            metadataKeys.addAll(point.metadata!.keys);
          }
        }
      }
      columns.addAll(metadataKeys.toList()..sort());
    }

    return columns;
  }

  List<String> _buildRow<X, Y>(
    String seriesName,
    DataPoint<X, Y> point,
    List<String> columns,
    DataExportConfig config,
  ) {
    final row = <String>[];

    for (final column in columns) {
      if (column == config.seriesNameColumn) {
        row.add(seriesName);
      } else if (column == config.xColumn) {
        row.add(_formatValue(point.x, config));
      } else if (column == config.yColumn) {
        row.add(_formatValue(point.y, config));
      } else if (config.includeMetadata && point.metadata != null) {
        final value = point.metadata![column];
        row.add(value != null ? _formatValue(value, config) : config.nullValue);
      } else {
        row.add(config.nullValue);
      }
    }

    return row;
  }

  String _formatValue(dynamic value, DataExportConfig config) {
    if (value == null) return config.nullValue;

    if (value is DateTime) {
      return _formatDateTime(value, config.dateFormat);
    }

    if (value is double) {
      return value.toStringAsFixed(config.numberPrecision);
    }

    if (value is num) {
      return value.toString();
    }

    return value.toString();
  }

  String _formatDateTime(DateTime dt, String format) {
    // Simple date formatting - in production, use intl package
    return format
        .replaceAll('yyyy', dt.year.toString().padLeft(4, '0'))
        .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
        .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
        .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', dt.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', dt.second.toString().padLeft(2, '0'));
  }

  String _escapeField(String value, DataExportConfig config) {
    if (!config.quoteStrings) return value;

    // Escape quotes by doubling them
    final escaped = value.replaceAll('"', '""');

    // Quote if contains delimiter, newline, or quotes
    if (value.contains(config.delimiter) ||
        value.contains('\n') ||
        value.contains('\r') ||
        value.contains('"')) {
      return '"$escaped"';
    }

    return escaped;
  }

  List<Map<String, dynamic>> _buildJsonData<X, Y>(
    List<ExportableSeries<X, Y>> series,
    DataExportConfig config,
  ) {
    return series.map((s) {
      final seriesData = <String, dynamic>{
        'name': s.name,
        'data': s.data.map((point) {
          final pointData = <String, dynamic>{
            config.xColumn: _jsonValue(point.x, config),
            config.yColumn: _jsonValue(point.y, config),
          };

          if (config.includeMetadata && point.metadata != null) {
            pointData['metadata'] = point.metadata;
          }

          return pointData;
        }).toList(),
      };

      if (config.includeMetadata && s.metadata != null) {
        seriesData['metadata'] = s.metadata;
      }

      return seriesData;
    }).toList();
  }

  dynamic _jsonValue(dynamic value, DataExportConfig config) {
    if (value == null) return null;

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is double) {
      // Round to precision but keep as number
      final factor = _pow10(config.numberPrecision);
      return (value * factor).round() / factor;
    }

    return value;
  }

  double _pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  String _toJsonString(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return '"${_escapeJsonString(value)}"';

    if (value is List) {
      final items = value.map(_toJsonString).join(',');
      return '[$items]';
    }

    if (value is Map) {
      final entries = value.entries
          .map((e) => '"${_escapeJsonString(e.key.toString())}":${_toJsonString(e.value)}')
          .join(',');
      return '{$entries}';
    }

    return '"${_escapeJsonString(value.toString())}"';
  }

  String _prettyPrintJson(dynamic value, int indentSize, [int depth = 0]) {
    final indent = ' ' * (depth * indentSize);
    final childIndent = ' ' * ((depth + 1) * indentSize);

    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return '"${_escapeJsonString(value)}"';

    if (value is List) {
      if (value.isEmpty) return '[]';
      final items = value
          .map((v) => '$childIndent${_prettyPrintJson(v, indentSize, depth + 1)}')
          .join(',\n');
      return '[\n$items\n$indent]';
    }

    if (value is Map) {
      if (value.isEmpty) return '{}';
      final entries = value.entries
          .map((e) =>
              '$childIndent"${_escapeJsonString(e.key.toString())}": ${_prettyPrintJson(e.value, indentSize, depth + 1)}')
          .join(',\n');
      return '{\n$entries\n$indent}';
    }

    return '"${_escapeJsonString(value.toString())}"';
  }

  String _escapeJsonString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}

/// Extension methods for easy data export on series lists.
extension DataExportExtension<X, Y> on List<ExportableSeries<X, Y>> {
  /// Exports to CSV format.
  String toCsv({DataExportConfig? config}) =>
      const DataExportService().exportToCsv(this, config: config);

  /// Exports to TSV format.
  String toTsv({DataExportConfig? config}) =>
      const DataExportService().exportToTsv(this, config: config);

  /// Exports to JSON format.
  String toJson({DataExportConfig? config}) =>
      const DataExportService().exportToJson(this, config: config);

  /// Exports using the specified format.
  String export({DataExportConfig? config}) =>
      const DataExportService().export(this, config: config);
}
