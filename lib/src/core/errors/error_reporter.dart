import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chart_error_boundary.dart';
import 'chart_logger.dart';

/// Severity level for error reporting.
enum ErrorSeverity {
  /// Low severity - minor issues that don't affect functionality.
  low,

  /// Medium severity - issues that may affect some functionality.
  medium,

  /// High severity - issues that significantly affect functionality.
  high,

  /// Critical severity - issues that completely break functionality.
  critical,
}

/// Context information for error reports.
@immutable
class ErrorContext {
  const ErrorContext({
    this.chartType,
    this.seriesCount,
    this.dataPointCount,
    this.viewportState,
    this.animationState,
    this.additionalData,
  });

  /// The type of chart where the error occurred.
  final String? chartType;

  /// Number of series in the chart.
  final int? seriesCount;

  /// Total number of data points.
  final int? dataPointCount;

  /// Current viewport state.
  final Map<String, dynamic>? viewportState;

  /// Current animation state.
  final Map<String, dynamic>? animationState;

  /// Additional context data.
  final Map<String, dynamic>? additionalData;

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        if (chartType != null) 'chartType': chartType,
        if (seriesCount != null) 'seriesCount': seriesCount,
        if (dataPointCount != null) 'dataPointCount': dataPointCount,
        if (viewportState != null) 'viewportState': viewportState,
        if (animationState != null) 'animationState': animationState,
        if (additionalData != null) ...additionalData!,
      };

  /// Creates a copy with updated values.
  ErrorContext copyWith({
    String? chartType,
    int? seriesCount,
    int? dataPointCount,
    Map<String, dynamic>? viewportState,
    Map<String, dynamic>? animationState,
    Map<String, dynamic>? additionalData,
  }) =>
      ErrorContext(
        chartType: chartType ?? this.chartType,
        seriesCount: seriesCount ?? this.seriesCount,
        dataPointCount: dataPointCount ?? this.dataPointCount,
        viewportState: viewportState ?? this.viewportState,
        animationState: animationState ?? this.animationState,
        additionalData: additionalData ?? this.additionalData,
      );
}

/// An error report containing all information about an error.
@immutable
class ErrorReport {
  const ErrorReport({
    required this.error,
    required this.timestamp,
    this.stackTrace,
    this.severity = ErrorSeverity.medium,
    this.context,
    this.tags,
    this.isFatal = false,
  });

  /// The error that occurred.
  final Object error;

  /// When the error occurred.
  final DateTime timestamp;

  /// Stack trace at the time of error.
  final StackTrace? stackTrace;

  /// Severity level of this error.
  final ErrorSeverity severity;

  /// Context information about the error.
  final ErrorContext? context;

  /// Tags for categorization.
  final List<String>? tags;

  /// Whether this error is fatal (app cannot continue).
  final bool isFatal;

  /// The error code if the error is a ChartException.
  String? get errorCode {
    if (error is ChartException) {
      return (error as ChartException).code;
    }
    return null;
  }

  /// The error message.
  String get message {
    if (error is ChartException) {
      return (error as ChartException).message;
    }
    return error.toString();
  }

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'error': error.toString(),
        'errorType': error.runtimeType.toString(),
        'timestamp': timestamp.toIso8601String(),
        'severity': severity.name,
        'isFatal': isFatal,
        if (errorCode != null) 'errorCode': errorCode,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (context != null) 'context': context!.toJson(),
        if (tags != null) 'tags': tags,
      };
}

/// Callback type for error report handlers.
typedef ErrorReportHandler = FutureOr<void> Function(ErrorReport report);

/// Abstract interface for error reporting services.
///
/// Implement this to integrate with crash reporting services like
/// Sentry, Crashlytics, or custom error tracking systems.
///
/// Example:
/// ```dart
/// class SentryErrorReporter extends ChartErrorReporter {
///   @override
///   Future<void> report(ErrorReport report) async {
///     await Sentry.captureException(
///       report.error,
///       stackTrace: report.stackTrace,
///       hint: Hint.withMap(report.context?.toJson() ?? {}),
///     );
///   }
/// }
///
/// // Set as global reporter
/// ChartErrorReporter.instance = SentryErrorReporter();
/// ```
abstract class ChartErrorReporter {
  /// The current global error reporter instance.
  ///
  /// Defaults to [DefaultErrorReporter] which logs errors using [ChartLogger].
  static ChartErrorReporter instance = DefaultErrorReporter();

  /// Reports an error.
  ///
  /// Subclasses should implement this to send errors to their service.
  FutureOr<void> report(ErrorReport report);

  /// Convenience method to report an error with context.
  FutureOr<void> reportError(
    Object error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorContext? context,
    List<String>? tags,
    bool isFatal = false,
  }) {
    return report(ErrorReport(
      error: error,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      tags: tags,
      isFatal: isFatal,
    ));
  }

  /// Reports a chart exception.
  FutureOr<void> reportChartException(
    ChartException exception, {
    StackTrace? stackTrace,
    ErrorContext? context,
    bool isFatal = false,
  }) {
    final severity = switch (exception) {
      InvalidChartDataException() => ErrorSeverity.medium,
      InvalidChartConfigException() => ErrorSeverity.medium,
      ChartRenderException() => ErrorSeverity.high,
      _ => ErrorSeverity.medium,
    };

    return reportError(
      exception,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      tags: [exception.code ?? 'UNKNOWN'],
      isFatal: isFatal,
    );
  }
}

/// Default error reporter that logs errors using [ChartLogger].
class DefaultErrorReporter extends ChartErrorReporter {
  @override
  void report(ErrorReport report) {
    final level = switch (report.severity) {
      ErrorSeverity.low => ChartLogLevel.warning,
      ErrorSeverity.medium => ChartLogLevel.error,
      ErrorSeverity.high => ChartLogLevel.error,
      ErrorSeverity.critical => ChartLogLevel.critical,
    };

    ChartLogger.instance.log(ChartLogEntry(
      level: level,
      message: report.message,
      timestamp: report.timestamp,
      error: report.error,
      stackTrace: report.stackTrace,
      context: report.context?.toJson(),
      tags: report.tags,
    ));
  }
}

/// An error reporter that collects reports in memory.
///
/// Useful for testing or for batching reports to send later.
class BufferedErrorReporter extends ChartErrorReporter {
  /// Maximum number of reports to keep.
  final int maxReports;

  final List<ErrorReport> _reports = [];

  /// Stream controller for report events.
  final StreamController<ErrorReport> _streamController =
      StreamController<ErrorReport>.broadcast();

  /// Creates a buffered reporter.
  BufferedErrorReporter({this.maxReports = 100});

  /// The current buffer of error reports.
  List<ErrorReport> get reports => List.unmodifiable(_reports);

  /// Stream of error reports as they are added.
  Stream<ErrorReport> get stream => _streamController.stream;

  @override
  void report(ErrorReport report) {
    _reports.add(report);
    _streamController.add(report);

    if (_reports.length > maxReports) {
      _reports.removeAt(0);
    }
  }

  /// Clears the buffer.
  void clear() => _reports.clear();

  /// Gets reports filtered by severity.
  List<ErrorReport> getBySeverity(ErrorSeverity severity) =>
      _reports.where((r) => r.severity == severity).toList();

  /// Gets reports filtered by error code.
  List<ErrorReport> getByErrorCode(String code) =>
      _reports.where((r) => r.errorCode == code).toList();

  /// Exports all reports as JSON.
  List<Map<String, dynamic>> exportAsJson() =>
      _reports.map((r) => r.toJson()).toList();

  /// Disposes the reporter and its resources.
  void dispose() {
    _streamController.close();
    _reports.clear();
  }
}

/// A composite reporter that forwards reports to multiple reporters.
class CompositeErrorReporter extends ChartErrorReporter {
  /// The reporters to forward to.
  final List<ChartErrorReporter> reporters;

  /// Creates a composite reporter.
  CompositeErrorReporter(this.reporters);

  @override
  Future<void> report(ErrorReport report) async {
    await Future.wait(
      reporters.map((r) async => await r.report(report)),
    );
  }
}

/// A reporter that filters reports based on criteria.
class FilteredErrorReporter extends ChartErrorReporter {
  /// The underlying reporter to forward to.
  final ChartErrorReporter innerReporter;

  /// Minimum severity to report.
  final ErrorSeverity minimumSeverity;

  /// Error codes to exclude from reporting.
  final Set<String> excludedErrorCodes;

  /// Creates a filtered reporter.
  FilteredErrorReporter({
    required this.innerReporter,
    this.minimumSeverity = ErrorSeverity.low,
    this.excludedErrorCodes = const {},
  });

  @override
  FutureOr<void> report(ErrorReport report) {
    // Check severity
    if (report.severity.index < minimumSeverity.index) {
      return null;
    }

    // Check excluded error codes
    if (report.errorCode != null &&
        excludedErrorCodes.contains(report.errorCode)) {
      return null;
    }

    return innerReporter.report(report);
  }
}

/// A reporter with rate limiting to prevent flooding.
class RateLimitedErrorReporter extends ChartErrorReporter {
  /// The underlying reporter to forward to.
  final ChartErrorReporter innerReporter;

  /// Maximum reports per window.
  final int maxReportsPerWindow;

  /// Time window for rate limiting.
  final Duration window;

  final List<DateTime> _reportTimes = [];

  /// Creates a rate-limited reporter.
  RateLimitedErrorReporter({
    required this.innerReporter,
    this.maxReportsPerWindow = 10,
    this.window = const Duration(minutes: 1),
  });

  @override
  FutureOr<void> report(ErrorReport report) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Remove old timestamps
    _reportTimes.removeWhere((t) => t.isBefore(windowStart));

    // Check if we're within rate limit
    if (_reportTimes.length >= maxReportsPerWindow) {
      // Log that we're rate limiting
      ChartLogger.instance.warning(
        'Error report rate limited',
        context: {
          'droppedError': report.error.toString(),
          'reportsInWindow': _reportTimes.length,
        },
        tags: ['rate_limit'],
      );
      return null;
    }

    _reportTimes.add(now);
    return innerReporter.report(report);
  }
}

/// Extension methods for easy error reporting.
extension ChartErrorReporting on Object {
  /// Reports this object as an error.
  FutureOr<void> reportAsChartError({
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorContext? context,
    List<String>? tags,
  }) {
    return ChartErrorReporter.instance.reportError(
      this,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      tags: tags,
    );
  }
}
