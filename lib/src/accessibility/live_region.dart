import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../rendering/painters/series_painter.dart';
import 'chart_semantics.dart';

/// Politeness levels for screen reader announcements.
///
/// Controls how urgently the screen reader should announce updates.
enum LiveRegionPoliteness {
  /// No announcements (updates are ignored).
  off,

  /// Polite announcements (waits for screen reader to finish current speech).
  polite,

  /// Assertive announcements (interrupts current speech immediately).
  assertive,
}

/// Controller for managing screen reader announcements in charts.
///
/// Provides methods to announce chart changes, navigation events,
/// and data updates to assistive technologies.
///
/// Example:
/// ```dart
/// final liveRegion = LiveRegionController();
///
/// // Announce navigation
/// liveRegion.announceNavigation(dataPoint);
///
/// // Announce data change
/// liveRegion.announceDataChange('5 new data points added');
/// ```
class LiveRegionController {
  LiveRegionController({
    this.defaultPoliteness = LiveRegionPoliteness.polite,
  });

  /// Default politeness level for announcements.
  final LiveRegionPoliteness defaultPoliteness;

  /// Whether announcements are enabled.
  bool _enabled = true;

  /// Queue of pending announcements.
  final List<_Announcement> _queue = [];

  /// Whether currently processing the queue.
  bool _isProcessing = false;

  /// Minimum delay between announcements (ms).
  static const int _minDelay = 100;

  /// Gets whether announcements are enabled.
  bool get enabled => _enabled;

  /// Enables or disables announcements.
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _queue.clear();
    }
  }

  /// Announces a data change to screen readers.
  ///
  /// Use for significant data updates like:
  /// - New data points added
  /// - Data refresh completed
  /// - Series added/removed
  void announceDataChange(
    String message, {
    LiveRegionPoliteness? politeness,
  }) {
    _announce(
      message,
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.dataChange,
    );
  }

  /// Announces navigation to a data point.
  ///
  /// Called when keyboard navigation moves to a new point.
  void announceNavigation(
    DataPointInfo point, {
    String? customMessage,
    LiveRegionPoliteness? politeness,
  }) {
    final message = customMessage ?? _buildNavigationMessage(point);
    _announce(
      message,
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.navigation,
    );
  }

  /// Announces a chart summary.
  ///
  /// Called when chart first receives focus or user requests summary.
  void announceChartSummary(
    ChartSemantics semantics, {
    LiveRegionPoliteness? politeness,
  }) {
    _announce(
      semantics.chartDescription,
      politeness: politeness ?? LiveRegionPoliteness.polite,
      type: _AnnouncementType.summary,
    );
  }

  /// Announces trend information for data points.
  ///
  /// Called when user requests trend analysis (e.g., pressing 'T' key).
  void announceTrend(
    List<DataPointInfo> points, {
    LiveRegionPoliteness? politeness,
  }) {
    if (points.isEmpty) {
      _announce(
        'No data available for trend analysis.',
        politeness: politeness ?? defaultPoliteness,
        type: _AnnouncementType.trend,
      );
      return;
    }

    final trendMessage = _buildTrendMessage(points);
    _announce(
      trendMessage,
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.trend,
    );
  }

  /// Announces selection change.
  ///
  /// Called when user selects/deselects data points.
  void announceSelection(
    DataPointInfo? point, {
    bool isSelected = true,
    LiveRegionPoliteness? politeness,
  }) {
    final message = point == null
        ? 'Selection cleared.'
        : isSelected
            ? 'Selected: ${_buildPointDescription(point)}'
            : 'Deselected: ${_buildPointDescription(point)}';

    _announce(
      message,
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.selection,
    );
  }

  /// Announces zoom level change.
  void announceZoomChange(
    double zoomLevel, {
    LiveRegionPoliteness? politeness,
  }) {
    final percentage = (zoomLevel * 100).round();
    _announce(
      'Zoom level: $percentage%',
      politeness: politeness ?? LiveRegionPoliteness.polite,
      type: _AnnouncementType.zoom,
    );
  }

  /// Announces filter change.
  void announceFilterChange(
    String filterDescription, {
    LiveRegionPoliteness? politeness,
  }) {
    _announce(
      'Filter applied: $filterDescription',
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.filter,
    );
  }

  /// Announces an error or warning.
  void announceError(
    String errorMessage, {
    LiveRegionPoliteness? politeness,
  }) {
    _announce(
      'Error: $errorMessage',
      politeness: politeness ?? LiveRegionPoliteness.assertive,
      type: _AnnouncementType.error,
    );
  }

  /// Announces a custom message.
  void announce(
    String message, {
    LiveRegionPoliteness? politeness,
  }) {
    _announce(
      message,
      politeness: politeness ?? defaultPoliteness,
      type: _AnnouncementType.custom,
    );
  }

  /// Internal method to queue and process announcements.
  void _announce(
    String message, {
    required LiveRegionPoliteness politeness,
    required _AnnouncementType type,
  }) {
    if (!_enabled || politeness == LiveRegionPoliteness.off) {
      return;
    }

    // Remove duplicate announcements of the same type
    _queue.removeWhere((a) => a.type == type);

    _queue.add(_Announcement(
      message: message,
      politeness: politeness,
      type: type,
      timestamp: DateTime.now(),
    ));

    _processQueue();
  }

  /// Processes the announcement queue.
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final announcement = _queue.removeAt(0);
      await _sendAnnouncement(announcement);

      // Small delay between announcements
      if (_queue.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: _minDelay));
      }
    }

    _isProcessing = false;
  }

  /// Sends announcement to the accessibility service.
  Future<void> _sendAnnouncement(_Announcement announcement) async {
    // Note: Using the deprecated announce API for broader compatibility
    // The replacement API is not yet fully available
    // ignore: deprecated_member_use
    await SemanticsService.announce(
      announcement.message,
      TextDirection.ltr,
      assertiveness: announcement.politeness == LiveRegionPoliteness.assertive
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );
  }

  /// Builds a navigation message for a data point.
  String _buildNavigationMessage(DataPointInfo point) {
    final buffer = StringBuffer();

    // Position information
    buffer.write('Point ${point.dataIndex + 1}');

    // Label if available
    if (point.label != null && point.label!.isNotEmpty) {
      buffer.write(': ${point.label}');
    }

    // Value
    buffer.write(', value: ${_formatValue(point.dataY)}');

    return buffer.toString();
  }

  /// Builds a trend message for a series of points.
  String _buildTrendMessage(List<DataPointInfo> points) {
    if (points.length < 2) {
      return 'Insufficient data for trend analysis.';
    }

    final firstValue = points.first.dataY;
    final lastValue = points.last.dataY;
    final change = lastValue - firstValue;
    final percentChange =
        firstValue != 0 ? (change / firstValue * 100).abs() : 0.0;

    final buffer = StringBuffer();

    if (change > 0) {
      buffer.write('Upward trend. ');
      buffer.write('Increased by ${percentChange.toStringAsFixed(1)}% ');
    } else if (change < 0) {
      buffer.write('Downward trend. ');
      buffer.write('Decreased by ${percentChange.toStringAsFixed(1)}% ');
    } else {
      buffer.write('No change. ');
    }

    buffer.write('from ${_formatValue(firstValue)} to ${_formatValue(lastValue)}. ');
    buffer.write('${points.length} data points analyzed.');

    return buffer.toString();
  }

  /// Builds a description of a single data point.
  String _buildPointDescription(DataPointInfo point) {
    if (point.label != null && point.label!.isNotEmpty) {
      return '${point.label}: ${_formatValue(point.dataY)}';
    }
    return 'Value: ${_formatValue(point.dataY)}';
  }

  /// Formats a numeric value for speech.
  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} million';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} thousand';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Clears all pending announcements.
  void clearQueue() {
    _queue.clear();
  }

  /// Disposes resources.
  void dispose() {
    _queue.clear();
    _enabled = false;
  }
}

/// Types of announcements for deduplication.
enum _AnnouncementType {
  dataChange,
  navigation,
  summary,
  trend,
  selection,
  zoom,
  filter,
  error,
  custom,
}

/// Internal announcement data class.
class _Announcement {
  const _Announcement({
    required this.message,
    required this.politeness,
    required this.type,
    required this.timestamp,
  });

  final String message;
  final LiveRegionPoliteness politeness;
  final _AnnouncementType type;
  final DateTime timestamp;
}

/// Widget that wraps content with live region support.
///
/// Announces changes to the child content to screen readers.
class LiveRegionWidget extends StatefulWidget {
  const LiveRegionWidget({
    required this.child,
    super.key,
    this.controller,
    this.label,
    this.politeness = LiveRegionPoliteness.polite,
  });

  /// The child widget.
  final Widget child;

  /// Optional controller for programmatic announcements.
  final LiveRegionController? controller;

  /// Semantic label for the live region.
  final String? label;

  /// Default politeness for automatic announcements.
  final LiveRegionPoliteness politeness;

  @override
  State<LiveRegionWidget> createState() => _LiveRegionWidgetState();
}

class _LiveRegionWidgetState extends State<LiveRegionWidget> {
  late LiveRegionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        LiveRegionController(defaultPoliteness: widget.politeness);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: widget.politeness != LiveRegionPoliteness.off,
        label: widget.label,
        child: widget.child,
      );
}

/// Provider for LiveRegionController to descendant widgets.
class LiveRegionProvider extends InheritedWidget {
  const LiveRegionProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The live region controller.
  final LiveRegionController controller;

  /// Gets the controller from context.
  static LiveRegionController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<LiveRegionProvider>();
    assert(provider != null, 'No LiveRegionProvider found in context');
    return provider!.controller;
  }

  /// Gets the controller from context, or null if not found.
  static LiveRegionController? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<LiveRegionProvider>();
    return provider?.controller;
  }

  @override
  bool updateShouldNotify(LiveRegionProvider oldWidget) =>
      controller != oldWidget.controller;
}

/// Extension for easy access to live region controller.
extension LiveRegionContextExtension on BuildContext {
  /// Gets the live region controller from context.
  LiveRegionController? get liveRegionController =>
      LiveRegionProvider.maybeOf(this);

  /// Announces a message using the live region controller.
  void announceToScreenReader(
    String message, {
    LiveRegionPoliteness politeness = LiveRegionPoliteness.polite,
  }) {
    final controller = liveRegionController;
    if (controller != null) {
      controller.announce(message, politeness: politeness);
    } else {
      // Fallback: direct announcement without controller
      // ignore: deprecated_member_use
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }
}
