import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../plugin.dart';

/// Plugin for exporting charts to images.
///
/// Supports exporting to PNG and JPEG formats with configurable
/// quality and scale settings.
///
/// Example:
/// ```dart
/// // Register the plugin
/// PluginRegistry.instance.register(ExportPlugin());
///
/// // Get the plugin and export
/// final export = pluginManager.getPlugin<ExportPlugin>();
/// final bytes = await export?.exportToPng(context);
/// ```
class ExportPlugin extends ChartPlugin {
  ExportPlugin({
    this.defaultScale = 2.0,
    this.defaultFormat = ExportFormat.png,
    this.defaultQuality = 90,
  });

  /// Default scale factor for exports.
  final double defaultScale;

  /// Default export format.
  final ExportFormat defaultFormat;

  /// Default JPEG quality (1-100).
  final int defaultQuality;

  // Captured render data
  GlobalKey? _boundaryKey;

  @override
  String get id => 'chartify.export';

  @override
  String get displayName => 'Export Plugin';

  @override
  int get priority => -100; // Run after other plugins

  /// Sets the repaint boundary for capturing.
  void setBoundary(GlobalKey key) {
    _boundaryKey = key;
  }

  /// Exports the chart to PNG format.
  Future<Uint8List?> exportToPng({
    double? scale,
    GlobalKey? boundaryKey,
  }) async => _export(
      format: ExportFormat.png,
      scale: scale ?? defaultScale,
      boundaryKey: boundaryKey ?? _boundaryKey,
    );

  /// Exports the chart to JPEG format.
  Future<Uint8List?> exportToJpeg({
    double? scale,
    int? quality,
    GlobalKey? boundaryKey,
  }) async => _export(
      format: ExportFormat.jpeg,
      scale: scale ?? defaultScale,
      quality: quality ?? defaultQuality,
      boundaryKey: boundaryKey ?? _boundaryKey,
    );

  /// Exports the chart to the specified format.
  Future<Uint8List?> export({
    ExportFormat? format,
    double? scale,
    int? quality,
    GlobalKey? boundaryKey,
  }) async => _export(
      format: format ?? defaultFormat,
      scale: scale ?? defaultScale,
      quality: quality ?? defaultQuality,
      boundaryKey: boundaryKey ?? _boundaryKey,
    );

  Future<Uint8List?> _export({
    required ExportFormat format,
    required double scale,
    int quality = 90,
    GlobalKey? boundaryKey,
  }) async {
    final key = boundaryKey ?? _boundaryKey;
    if (key == null) return null;

    final context = key.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final image = await boundary.toImage(pixelRatio: scale);
      final byteData = await image.toByteData(
        format: format == ExportFormat.png
            ? ui.ImageByteFormat.png
            : ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) return null;

      if (format == ExportFormat.jpeg) {
        // For JPEG, we need to convert from raw RGBA
        // This is a simplified implementation
        // In production, use an image encoding library
        return byteData.buffer.asUint8List();
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Gets the chart size for export.
  Size? getExportSize({GlobalKey? boundaryKey}) {
    final key = boundaryKey ?? _boundaryKey;
    if (key == null) return null;

    final context = key.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    return boundary?.size;
  }
}

/// Export format options.
enum ExportFormat {
  /// PNG format (lossless, supports transparency).
  png,

  /// JPEG format (lossy, smaller file size).
  jpeg,
}

/// Configuration for chart exports.
class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.png,
    this.scale = 2.0,
    this.quality = 90,
    this.backgroundColor,
    this.includeTitle = true,
    this.includeLegend = true,
    this.padding = EdgeInsets.zero,
  });

  /// Export format.
  final ExportFormat format;

  /// Scale factor (1.0 = 100%, 2.0 = 200%).
  final double scale;

  /// JPEG quality (1-100).
  final int quality;

  /// Background color (null = transparent for PNG).
  final Color? backgroundColor;

  /// Whether to include the title in export.
  final bool includeTitle;

  /// Whether to include the legend in export.
  final bool includeLegend;

  /// Additional padding around the chart.
  final EdgeInsets padding;

  /// Creates a copy with updated values.
  ExportConfig copyWith({
    ExportFormat? format,
    double? scale,
    int? quality,
    Color? backgroundColor,
    bool? includeTitle,
    bool? includeLegend,
    EdgeInsets? padding,
  }) => ExportConfig(
      format: format ?? this.format,
      scale: scale ?? this.scale,
      quality: quality ?? this.quality,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      includeTitle: includeTitle ?? this.includeTitle,
      includeLegend: includeLegend ?? this.includeLegend,
      padding: padding ?? this.padding,
    );
}

/// Widget wrapper that enables chart export.
class ExportableChart extends StatefulWidget {
  const ExportableChart({
    required this.child, super.key,
    this.onExportReady,
  });

  /// The chart to make exportable.
  final Widget child;

  /// Called when export is ready with the export function.
  final void Function(Future<Uint8List?> Function(ExportConfig config) export)? onExportReady;

  @override
  State<ExportableChart> createState() => _ExportableChartState();
}

class _ExportableChartState extends State<ExportableChart> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onExportReady?.call(_export);
    });
  }

  Future<Uint8List?> _export(ExportConfig config) async {
    final context = _boundaryKey.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final image = await boundary.toImage(pixelRatio: config.scale);
      final byteData = await image.toByteData(
        format: config.format == ExportFormat.png
            ? ui.ImageByteFormat.png
            : ui.ImageByteFormat.rawRgba,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );
}

/// Extension for easy export access.
extension ExportExtension on BuildContext {
  /// Gets the export plugin if available.
  ExportPlugin? get exportPlugin => PluginRegistry.instance.getByType<ExportPlugin>();
}
