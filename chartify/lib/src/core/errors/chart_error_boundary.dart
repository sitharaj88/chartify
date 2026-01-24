import 'package:flutter/material.dart';

/// A widget that catches errors during chart rendering and displays a fallback UI.
///
/// This provides graceful degradation when charts encounter invalid data,
/// rendering errors, or other unexpected issues.
///
/// Example:
/// ```dart
/// ChartErrorBoundary(
///   child: LineChart(data: chartData),
///   fallback: (error) => Center(
///     child: Text('Chart error: $error'),
///   ),
/// )
/// ```
class ChartErrorBoundary extends StatefulWidget {
  const ChartErrorBoundary({
    required this.child,
    this.fallback,
    this.onError,
    super.key,
  });

  /// The chart widget to wrap.
  final Widget child;

  /// Optional custom fallback widget builder.
  /// If not provided, a default error message is shown.
  final Widget Function(Object error, StackTrace? stackTrace)? fallback;

  /// Optional callback when an error occurs.
  /// Useful for logging or analytics.
  final void Function(Object error, StackTrace? stackTrace)? onError;

  @override
  State<ChartErrorBoundary> createState() => _ChartErrorBoundaryState();
}

class _ChartErrorBoundaryState extends State<ChartErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void didUpdateWidget(ChartErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when child changes (e.g., new data)
    if (widget.child != oldWidget.child) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
    widget.onError?.call(error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback?.call(_error!, _stackTrace) ??
          _DefaultErrorWidget(error: _error!);
    }

    return _ErrorCatcher(
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// Internal widget that catches errors during build/layout/paint.
class _ErrorCatcher extends StatelessWidget {
  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  @override
  Widget build(BuildContext context) {
    // Use ErrorWidget.builder to catch rendering errors
    final originalBuilder = ErrorWidget.builder;

    return Builder(
      builder: (context) {
        ErrorWidget.builder = (details) {
          // Schedule error handling for after current frame
          WidgetsBinding.instance.addPostFrameCallback((_) =>
            onError(details.exception, details.stack),
          );
          // Return empty container during error handling
          return const SizedBox.shrink();
        };

        try {
          final result = child;
          // Restore original builder
          ErrorWidget.builder = originalBuilder;
          return result;
        } catch (e, st) {
          ErrorWidget.builder = originalBuilder;
          onError(e, st);
          return const SizedBox.shrink();
        }
      },
    );
  }
}

/// Default error widget shown when no custom fallback is provided.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: isDark ? Colors.amber[300] : Colors.amber[700],
          ),
          const SizedBox(height: 12),
          Text(
            'Chart Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatError(error),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatError(Object error) {
    final message = error.toString();
    // Truncate long error messages
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }
    return message;
  }
}

/// Custom exception for chart-related errors.
class ChartException implements Exception {
  const ChartException(this.message, {this.code});

  /// Error message describing what went wrong.
  final String message;

  /// Optional error code for categorization.
  final String? code;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Exception thrown when chart data is invalid.
class InvalidChartDataException extends ChartException {
  const InvalidChartDataException(super.message) : super(code: 'INVALID_DATA');
}

/// Exception thrown when chart configuration is invalid.
class InvalidChartConfigException extends ChartException {
  const InvalidChartConfigException(super.message)
      : super(code: 'INVALID_CONFIG');
}

/// Exception thrown when chart rendering fails.
class ChartRenderException extends ChartException {
  const ChartRenderException(super.message) : super(code: 'RENDER_ERROR');
}
