import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Get chart ID from URL hash (e.g., #line, #bar, #pie)
String? getChartIdFromUrl() {
  final hash = web.window.location.hash;
  if (hash.isEmpty || hash == '#') return null;
  // Remove the # prefix
  return hash.substring(1).toLowerCase();
}
