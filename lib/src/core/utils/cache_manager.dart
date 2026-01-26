import 'dart:collection';

/// A generic LRU (Least Recently Used) cache.
///
/// Provides O(1) get/put operations with automatic eviction
/// of least recently used items when capacity is exceeded.
class LRUCache<K, V> {
  LRUCache({
    this.maxSize = 100,
    this.onEvict,
  });

  /// Maximum number of entries.
  final int maxSize;

  /// Callback when an entry is evicted.
  final void Function(K key, V value)? onEvict;

  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  /// Gets a value from the cache, promoting it to most recently used.
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Re-insert to make it most recent
    }
    return value;
  }

  /// Gets a value or computes it if not present.
  V getOrPut(K key, V Function() compute) {
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing; // Re-insert to make it most recent
      return existing;
    }
    final value = compute();
    put(key, value);
    return value;
  }

  /// Puts a value in the cache.
  void put(K key, V value) {
    // Remove existing to update position
    _cache.remove(key);

    // Evict oldest if at capacity
    while (_cache.length >= maxSize) {
      final oldest = _cache.keys.first;
      final evicted = _cache.remove(oldest);
      if (evicted != null) {
        onEvict?.call(oldest, evicted);
      }
    }

    _cache[key] = value;
  }

  /// Removes a specific entry.
  V? remove(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      onEvict?.call(key, value);
    }
    return value;
  }

  /// Checks if the cache contains a key.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Clears all entries.
  void clear() {
    if (onEvict != null) {
      for (final entry in _cache.entries) {
        onEvict!(entry.key, entry.value);
      }
    }
    _cache.clear();
  }

  /// Current number of entries.
  int get length => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// All keys in order from oldest to newest.
  Iterable<K> get keys => _cache.keys;

  /// All values in order from oldest to newest.
  Iterable<V> get values => _cache.values;
}

/// A cache with time-based expiration.
class TimedCache<K, V> {
  TimedCache({
    required this.expiration, this.maxSize = 100,
    this.onEvict,
  });

  /// Maximum number of entries.
  final int maxSize;

  /// How long entries remain valid.
  final Duration expiration;

  /// Callback when an entry is evicted.
  final void Function(K key, V value)? onEvict;

  final Map<K, _TimedEntry<V>> _cache = {};

  /// Gets a value if it exists and hasn't expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > expiration) {
      _cache.remove(key);
      onEvict?.call(key, entry.value);
      return null;
    }

    return entry.value;
  }

  /// Gets a value or computes it if not present or expired.
  V getOrPut(K key, V Function() compute) {
    final entry = _cache[key];
    if (entry != null) {
      if (DateTime.now().difference(entry.timestamp) <= expiration) {
        return entry.value;
      }
      _cache.remove(key);
      onEvict?.call(key, entry.value);
    }
    final value = compute();
    put(key, value);
    return value;
  }

  /// Puts a value in the cache with current timestamp.
  void put(K key, V value) {
    // Evict oldest if at capacity
    while (_cache.length >= maxSize) {
      _evictOldest();
    }

    _cache[key] = _TimedEntry(value, DateTime.now());
  }

  void _evictOldest() {
    if (_cache.isEmpty) return;

    K? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.timestamp;
      }
    }

    if (oldestKey != null) {
      final evicted = _cache.remove(oldestKey);
      if (evicted != null && onEvict != null) {
        onEvict!(oldestKey, evicted.value);
      }
    }
  }

  /// Removes expired entries.
  void purgeExpired() {
    final now = DateTime.now();
    final expired = <K>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > expiration) {
        expired.add(entry.key);
      }
    }

    for (final key in expired) {
      final timedEntry = _cache.remove(key);
      if (timedEntry != null) {
        onEvict?.call(key, timedEntry.value);
      }
    }
  }

  /// Clears all entries.
  void clear() {
    if (onEvict != null) {
      for (final entry in _cache.entries) {
        onEvict!(entry.key, entry.value.value);
      }
    }
    _cache.clear();
  }

  /// Current number of entries.
  int get length => _cache.length;
}

class _TimedEntry<V> {
  _TimedEntry(this.value, this.timestamp);
  final V value;
  final DateTime timestamp;
}

/// A multi-level cache that checks faster caches first.
class MultiLevelCache<K, V> {
  MultiLevelCache(this.levels);

  /// Cache levels from fastest (L1) to slowest (Ln).
  final List<LRUCache<K, V>> levels;

  /// Gets a value, checking each level and promoting on hit.
  V? get(K key) {
    for (var i = 0; i < levels.length; i++) {
      final value = levels[i].get(key);
      if (value != null) {
        // Promote to faster caches
        for (var j = 0; j < i; j++) {
          levels[j].put(key, value);
        }
        return value;
      }
    }
    return null;
  }

  /// Puts a value in all cache levels.
  void put(K key, V value) {
    for (final level in levels) {
      level.put(key, value);
    }
  }

  /// Clears all cache levels.
  void clear() {
    for (final level in levels) {
      level.clear();
    }
  }
}

/// Cache key builder for common chart scenarios.
class CacheKeyBuilder {
  CacheKeyBuilder._();

  /// Creates a key for data point rendering.
  static String dataPoint(double x, double y, int seriesIndex) => 'dp_${x.toStringAsFixed(2)}_${y.toStringAsFixed(2)}_$seriesIndex';

  /// Creates a key for path rendering.
  static String path(int seriesIndex, double width, double height) => 'path_${seriesIndex}_${width.toInt()}_${height.toInt()}';

  /// Creates a key for text layout.
  static String text(String content, double fontSize, int maxWidth) => 'text_${content.hashCode}_${fontSize.toInt()}_$maxWidth';

  /// Creates a key for axis tick computation.
  static String axisTicks(double min, double max, int tickCount) => 'ticks_${min.toStringAsFixed(4)}_${max.toStringAsFixed(4)}_$tickCount';

  /// Creates a key for bounds computation.
  static String bounds(int dataHash, bool includeZero) => 'bounds_${dataHash}_$includeZero';
}

/// Central cache manager for chart rendering.
class ChartCacheManager {
  ChartCacheManager._();

  static final instance = ChartCacheManager._();

  /// Cache for computed paths.
  final paths = LRUCache<String, dynamic>();

  /// Cache for text layouts.
  final textLayouts = LRUCache<String, dynamic>(maxSize: 200);

  /// Cache for bounds calculations.
  final bounds = LRUCache<String, dynamic>(maxSize: 50);

  /// Cache for tick computations.
  final ticks = LRUCache<String, List<double>>(maxSize: 50);

  /// Clears all caches.
  void clearAll() {
    paths.clear();
    textLayouts.clear();
    bounds.clear();
    ticks.clear();
  }

  /// Gets cache statistics.
  Map<String, int> get stats => {
    'paths': paths.length,
    'textLayouts': textLayouts.length,
    'bounds': bounds.length,
    'ticks': ticks.length,
  };
}
