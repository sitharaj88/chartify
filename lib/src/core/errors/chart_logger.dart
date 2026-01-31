import 'dart:async';

import 'package:flutter/foundation.dart';

/// Log level for chart logging.
enum ChartLogLevel {
  /// Debug messages for development.
  debug,

  /// Informational messages.
  info,

  /// Warning messages for potential issues.
  warning,

  /// Error messages for recoverable errors.
  error,

  /// Critical messages for severe errors.
  critical,
}

/// A log entry containing all relevant information about a log event.
@immutable
class ChartLogEntry {
  const ChartLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.context,
    this.tags,
  });

  /// The severity level of this log entry.
  final ChartLogLevel level;

  /// The log message.
  final String message;

  /// When this log entry was created.
  final DateTime timestamp;

  /// Optional error associated with this log entry.
  final Object? error;

  /// Optional stack trace associated with this log entry.
  final StackTrace? stackTrace;

  /// Optional context data for additional information.
  final Map<String, dynamic>? context;

  /// Optional tags for categorization.
  final List<String>? tags;

  /// Creates a copy with updated values.
  ChartLogEntry copyWith({
    ChartLogLevel? level,
    String? message,
    DateTime? timestamp,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) =>
      ChartLogEntry(
        level: level ?? this.level,
        message: message ?? this.message,
        timestamp: timestamp ?? this.timestamp,
        error: error ?? this.error,
        stackTrace: stackTrace ?? this.stackTrace,
        context: context ?? this.context,
        tags: tags ?? this.tags,
      );

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('[${level.name.toUpperCase()}] ')
      ..write('$timestamp: ')
      ..write(message);

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    if (tags != null && tags!.isNotEmpty) {
      buffer.write(' | Tags: ${tags!.join(', ')}');
    }

    return buffer.toString();
  }

  /// Converts this log entry to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (context != null) 'context': context,
        if (tags != null) 'tags': tags,
      };
}

/// Abstract logger interface for chart logging.
///
/// Implement this interface to integrate with your preferred logging solution.
///
/// Example:
/// ```dart
/// class MyChartLogger extends ChartLogger {
///   @override
///   void log(ChartLogEntry entry) {
///     print('[${entry.level.name}] ${entry.message}');
///   }
/// }
///
/// // Set as global logger
/// ChartLogger.instance = MyChartLogger();
/// ```
abstract class ChartLogger {
  /// The current global logger instance.
  ///
  /// Defaults to [DefaultChartLogger] which prints to console in debug mode.
  static ChartLogger instance = DefaultChartLogger();

  /// The minimum log level to process.
  ///
  /// Logs below this level will be ignored.
  ChartLogLevel get minimumLevel => ChartLogLevel.debug;

  /// Logs an entry.
  ///
  /// Subclasses should implement this to handle log entries.
  void log(ChartLogEntry entry);

  /// Logs a debug message.
  void debug(
    String message, {
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    _logIfEnabled(ChartLogLevel.debug, message, context: context, tags: tags);
  }

  /// Logs an info message.
  void info(
    String message, {
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    _logIfEnabled(ChartLogLevel.info, message, context: context, tags: tags);
  }

  /// Logs a warning message.
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    _logIfEnabled(
      ChartLogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      tags: tags,
    );
  }

  /// Logs an error message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    _logIfEnabled(
      ChartLogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      tags: tags,
    );
  }

  /// Logs a critical message.
  void critical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    _logIfEnabled(
      ChartLogLevel.critical,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      tags: tags,
    );
  }

  void _logIfEnabled(
    ChartLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    if (level.index >= minimumLevel.index) {
      log(ChartLogEntry(
        level: level,
        message: message,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
        context: context,
        tags: tags,
      ));
    }
  }
}

/// Default logger that prints to console in debug mode.
class DefaultChartLogger extends ChartLogger {
  /// Whether to print logs to console.
  final bool printToConsole;

  /// Minimum level to log.
  @override
  final ChartLogLevel minimumLevel;

  /// Creates a default logger.
  DefaultChartLogger({
    this.printToConsole = true,
    this.minimumLevel = ChartLogLevel.debug,
  });

  @override
  void log(ChartLogEntry entry) {
    if (printToConsole && kDebugMode) {
      debugPrint(entry.toString());
      if (entry.stackTrace != null &&
          entry.level.index >= ChartLogLevel.error.index) {
        debugPrint(entry.stackTrace.toString());
      }
    }
  }
}

/// A logger that collects log entries in memory.
///
/// Useful for testing or for collecting logs to send to a remote service.
class BufferedChartLogger extends ChartLogger {
  /// Maximum number of entries to keep in the buffer.
  final int maxEntries;

  @override
  final ChartLogLevel minimumLevel;

  final List<ChartLogEntry> _buffer = [];

  /// Stream of log entries.
  final StreamController<ChartLogEntry> _streamController =
      StreamController<ChartLogEntry>.broadcast();

  /// Creates a buffered logger.
  BufferedChartLogger({
    this.maxEntries = 1000,
    this.minimumLevel = ChartLogLevel.debug,
  });

  /// The current buffer of log entries.
  List<ChartLogEntry> get entries => List.unmodifiable(_buffer);

  /// Stream of log entries as they are added.
  Stream<ChartLogEntry> get stream => _streamController.stream;

  @override
  void log(ChartLogEntry entry) {
    _buffer.add(entry);
    _streamController.add(entry);

    // Trim buffer if it exceeds max size
    if (_buffer.length > maxEntries) {
      _buffer.removeAt(0);
    }
  }

  /// Clears the buffer.
  void clear() => _buffer.clear();

  /// Gets entries filtered by level.
  List<ChartLogEntry> getByLevel(ChartLogLevel level) =>
      _buffer.where((e) => e.level == level).toList();

  /// Gets entries filtered by tag.
  List<ChartLogEntry> getByTag(String tag) =>
      _buffer.where((e) => e.tags?.contains(tag) ?? false).toList();

  /// Exports all entries as JSON.
  List<Map<String, dynamic>> exportAsJson() =>
      _buffer.map((e) => e.toJson()).toList();

  /// Disposes the logger and its resources.
  void dispose() {
    _streamController.close();
    _buffer.clear();
  }
}

/// A composite logger that forwards logs to multiple loggers.
class CompositeChartLogger extends ChartLogger {
  /// The loggers to forward logs to.
  final List<ChartLogger> loggers;

  /// Creates a composite logger.
  CompositeChartLogger(this.loggers);

  @override
  ChartLogLevel get minimumLevel => loggers
      .map((l) => l.minimumLevel)
      .reduce((a, b) => a.index < b.index ? a : b);

  @override
  void log(ChartLogEntry entry) {
    for (final logger in loggers) {
      if (entry.level.index >= logger.minimumLevel.index) {
        logger.log(entry);
      }
    }
  }
}

/// A logger that filters logs based on tags.
class FilteredChartLogger extends ChartLogger {
  /// The underlying logger to forward to.
  final ChartLogger innerLogger;

  /// Tags to include. If empty, all tags are included.
  final Set<String> includeTags;

  /// Tags to exclude.
  final Set<String> excludeTags;

  /// Creates a filtered logger.
  FilteredChartLogger({
    required this.innerLogger,
    this.includeTags = const {},
    this.excludeTags = const {},
  });

  @override
  ChartLogLevel get minimumLevel => innerLogger.minimumLevel;

  @override
  void log(ChartLogEntry entry) {
    final entryTags = entry.tags ?? [];

    // Check exclude tags first
    if (excludeTags.isNotEmpty &&
        entryTags.any((t) => excludeTags.contains(t))) {
      return;
    }

    // Check include tags
    if (includeTags.isNotEmpty &&
        !entryTags.any((t) => includeTags.contains(t))) {
      return;
    }

    innerLogger.log(entry);
  }
}
