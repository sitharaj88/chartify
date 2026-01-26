import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../core/base/chart_controller.dart';
import '../theme/chart_theme_data.dart';

/// Base interface for chart plugins.
///
/// Plugins extend chart functionality without modifying core chart code.
/// They can hook into the rendering pipeline, gesture handling, and
/// lifecycle events.
///
/// Example:
/// ```dart
/// class MyPlugin extends ChartPlugin {
///   @override
///   String get id => 'my_plugin';
///
///   @override
///   void onAfterPaint(PluginPaintContext context) {
///     // Draw custom overlay
///   }
/// }
/// ```
abstract class ChartPlugin {
  /// Unique identifier for this plugin.
  String get id;

  /// Display name for UI purposes.
  String get displayName => id;

  /// Plugin version.
  String get version => '1.0.0';

  /// Whether this plugin is enabled.
  bool enabled = true;

  /// Priority for ordering plugins (higher = runs first).
  int get priority => 0;

  /// Dependencies on other plugins (by id).
  List<String> get dependencies => [];

  /// Called when the plugin is attached to a chart.
  void onAttach(PluginContext context) {}

  /// Called when the plugin is detached from a chart.
  void onDetach() {}

  /// Called before the chart paints.
  void onBeforePaint(PluginPaintContext context) {}

  /// Called after the chart paints.
  void onAfterPaint(PluginPaintContext context) {}

  /// Called when the chart data changes.
  void onDataChange(PluginDataContext context) {}

  /// Called when animation state changes.
  void onAnimationUpdate(double progress) {}

  /// Called when the chart is resized.
  void onResize(Size oldSize, Size newSize) {}

  /// Handles pointer events. Return true if handled.
  bool onPointerEvent(PointerEvent event) => false;

  /// Handles tap events. Return true if handled.
  bool onTap(TapDownDetails details) => false;

  /// Handles long press events. Return true if handled.
  bool onLongPress(LongPressStartDetails details) => false;

  /// Handles scale/pinch events. Return true if handled.
  bool onScaleUpdate(ScaleUpdateDetails details) => false;

  /// Handles scale end events. Return true if handled.
  bool onScaleEnd(ScaleEndDetails details) => false;

  /// Disposes plugin resources.
  void dispose() {}
}

/// Context provided when a plugin is attached.
class PluginContext {
  const PluginContext({
    required this.chartController,
    required this.theme,
    this.chartType,
  });

  /// The chart controller.
  final ChartController chartController;

  /// The current theme.
  final ChartThemeData theme;

  /// The type of chart this plugin is attached to.
  final String? chartType;
}

/// Context provided during paint operations.
class PluginPaintContext {
  const PluginPaintContext({
    required this.canvas,
    required this.size,
    required this.chartArea,
    required this.theme,
    this.animationProgress = 1.0,
  });

  /// The canvas to draw on.
  final Canvas canvas;

  /// The total size of the chart.
  final Size size;

  /// The area designated for data rendering.
  final Rect chartArea;

  /// The current theme.
  final ChartThemeData theme;

  /// Current animation progress (0.0 to 1.0).
  final double animationProgress;
}

/// Context provided when data changes.
class PluginDataContext {
  const PluginDataContext({
    required this.oldData,
    required this.newData,
  });

  /// Previous data (if any).
  final dynamic oldData;

  /// New data.
  final dynamic newData;
}

/// Registry for managing chart plugins.
///
/// Plugins are registered globally and can be attached to individual charts.
class PluginRegistry {
  PluginRegistry._();

  static final PluginRegistry _instance = PluginRegistry._();

  /// Gets the singleton instance.
  static PluginRegistry get instance => _instance;

  final Map<String, ChartPlugin> _plugins = {};
  final List<ChartPlugin> _sortedPlugins = [];
  bool _sorted = true;

  /// Registers a plugin.
  void register(ChartPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw PluginException('Plugin with id "${plugin.id}" already registered');
    }

    // Check dependencies
    for (final dep in plugin.dependencies) {
      if (!_plugins.containsKey(dep)) {
        throw PluginException(
          'Plugin "${plugin.id}" depends on "$dep" which is not registered',
        );
      }
    }

    _plugins[plugin.id] = plugin;
    _sortedPlugins.add(plugin);
    _sorted = false;
  }

  /// Unregisters a plugin.
  void unregister(String pluginId) {
    final plugin = _plugins.remove(pluginId);
    if (plugin != null) {
      _sortedPlugins.remove(plugin);
      plugin.dispose();
    }
  }

  /// Gets a plugin by id.
  ChartPlugin? get(String id) => _plugins[id];

  /// Gets a plugin by type.
  T? getByType<T extends ChartPlugin>() {
    for (final plugin in _plugins.values) {
      if (plugin is T) return plugin;
    }
    return null;
  }

  /// Gets all registered plugins, sorted by priority.
  List<ChartPlugin> get all {
    if (!_sorted) {
      _sortedPlugins.sort((a, b) => b.priority.compareTo(a.priority));
      _sorted = true;
    }
    return List.unmodifiable(_sortedPlugins);
  }

  /// Gets all enabled plugins, sorted by priority.
  List<ChartPlugin> get enabled => all.where((p) => p.enabled).toList();

  /// Whether a plugin is registered.
  bool isRegistered(String id) => _plugins.containsKey(id);

  /// Clears all plugins.
  void clear() {
    for (final plugin in _plugins.values) {
      plugin.dispose();
    }
    _plugins.clear();
    _sortedPlugins.clear();
  }
}

/// Exception thrown for plugin-related errors.
class PluginException implements Exception {
  PluginException(this.message);

  final String message;

  @override
  String toString() => 'PluginException: $message';
}

/// Manager for plugins attached to a specific chart.
class ChartPluginManager {
  ChartPluginManager({
    required this.context,
    List<String>? pluginIds,
  }) {
    if (pluginIds != null) {
      for (final id in pluginIds) {
        attach(id);
      }
    }
  }

  /// The plugin context.
  final PluginContext context;

  final List<ChartPlugin> _attachedPlugins = [];

  /// Attaches a plugin by id.
  void attach(String pluginId) {
    final plugin = PluginRegistry.instance.get(pluginId);
    if (plugin == null) {
      throw PluginException('Plugin "$pluginId" not found in registry');
    }

    if (_attachedPlugins.contains(plugin)) return;

    _attachedPlugins.add(plugin);
    _attachedPlugins.sort((a, b) => b.priority.compareTo(a.priority));
    plugin.onAttach(context);
  }

  /// Detaches a plugin by id.
  void detach(String pluginId) {
    final plugin = PluginRegistry.instance.get(pluginId);
    if (plugin != null && _attachedPlugins.remove(plugin)) {
      plugin.onDetach();
    }
  }

  /// Gets an attached plugin by type.
  T? getPlugin<T extends ChartPlugin>() {
    for (final plugin in _attachedPlugins) {
      if (plugin is T) return plugin;
    }
    return null;
  }

  /// Calls onBeforePaint on all attached plugins.
  void beforePaint(PluginPaintContext paintContext) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled) {
        plugin.onBeforePaint(paintContext);
      }
    }
  }

  /// Calls onAfterPaint on all attached plugins.
  void afterPaint(PluginPaintContext paintContext) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled) {
        plugin.onAfterPaint(paintContext);
      }
    }
  }

  /// Notifies plugins of data change.
  void notifyDataChange(PluginDataContext dataContext) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled) {
        plugin.onDataChange(dataContext);
      }
    }
  }

  /// Notifies plugins of animation update.
  void notifyAnimationUpdate(double progress) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled) {
        plugin.onAnimationUpdate(progress);
      }
    }
  }

  /// Notifies plugins of resize.
  void notifyResize(Size oldSize, Size newSize) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled) {
        plugin.onResize(oldSize, newSize);
      }
    }
  }

  /// Dispatches pointer event to plugins.
  bool handlePointerEvent(PointerEvent event) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled && plugin.onPointerEvent(event)) {
        return true;
      }
    }
    return false;
  }

  /// Dispatches tap event to plugins.
  bool handleTap(TapDownDetails details) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled && plugin.onTap(details)) {
        return true;
      }
    }
    return false;
  }

  /// Dispatches long press event to plugins.
  bool handleLongPress(LongPressStartDetails details) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled && plugin.onLongPress(details)) {
        return true;
      }
    }
    return false;
  }

  /// Dispatches scale update event to plugins.
  bool handleScaleUpdate(ScaleUpdateDetails details) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled && plugin.onScaleUpdate(details)) {
        return true;
      }
    }
    return false;
  }

  /// Dispatches scale end event to plugins.
  bool handleScaleEnd(ScaleEndDetails details) {
    for (final plugin in _attachedPlugins) {
      if (plugin.enabled && plugin.onScaleEnd(details)) {
        return true;
      }
    }
    return false;
  }

  /// Disposes all attached plugins.
  void dispose() {
    for (final plugin in _attachedPlugins) {
      plugin.onDetach();
    }
    _attachedPlugins.clear();
  }

  /// Number of attached plugins.
  int get length => _attachedPlugins.length;

  /// Whether there are any attached plugins.
  bool get isEmpty => _attachedPlugins.isEmpty;

  /// Whether there are attached plugins.
  bool get isNotEmpty => _attachedPlugins.isNotEmpty;
}

/// Mixin for widgets that support plugins.
mixin PluginAwareMixin<T extends StatefulWidget> on State<T> {
  ChartPluginManager? _pluginManager;

  /// The plugin manager.
  ChartPluginManager? get pluginManager => _pluginManager;

  /// Initializes the plugin manager.
  void initPlugins(PluginContext context, {List<String>? pluginIds}) {
    _pluginManager = ChartPluginManager(
      context: context,
      pluginIds: pluginIds,
    );
  }

  /// Disposes the plugin manager.
  void disposePlugins() {
    _pluginManager?.dispose();
    _pluginManager = null;
  }
}
