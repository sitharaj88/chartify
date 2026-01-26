import 'dart:math' as math;
import 'dart:ui';

/// Abstract interface for spatial indexing.
///
/// Enables O(log n) hit testing instead of O(n) linear search.
abstract class SpatialIndex<T> {
  /// Inserts an item with its bounding rectangle.
  void insert(T item, Rect bounds);

  /// Queries all items that contain the given point.
  List<T> queryPoint(Offset point);

  /// Queries all items that intersect the given rectangle.
  List<T> queryRect(Rect rect);

  /// Finds the nearest item to a point within maxDistance.
  T? findNearest(Offset point, {double maxDistance = double.infinity});

  /// Removes all items.
  void clear();

  /// Number of items in the index.
  int get length;
}

/// A Quadtree implementation for efficient 2D spatial queries.
///
/// Provides O(log n) average-case performance for point queries
/// on chart data points and hit regions.
class QuadTree<T> implements SpatialIndex<T> {
  QuadTree({
    required this.bounds,
    this.maxItems = 10,
    this.maxDepth = 8,
  }) : _depth = 0;

  QuadTree._child({
    required this.bounds,
    required this.maxItems,
    required this.maxDepth,
    required int depth,
  }) : _depth = depth;

  /// The bounding rectangle of this node.
  final Rect bounds;

  /// Maximum items before subdivision.
  final int maxItems;

  /// Maximum tree depth.
  final int maxDepth;

  final int _depth;
  final List<_QuadTreeEntry<T>> _items = [];
  List<QuadTree<T>>? _children;

  @override
  void insert(T item, Rect itemBounds) {
    // If we have children, insert into appropriate child
    if (_children != null) {
      final index = _getChildIndex(itemBounds);
      if (index != -1) {
        _children![index].insert(item, itemBounds);
        return;
      }
      // Item spans multiple children, store here
      _items.add(_QuadTreeEntry(item, itemBounds));
      return;
    }

    _items.add(_QuadTreeEntry(item, itemBounds));

    // Subdivide if over capacity and not at max depth
    if (_items.length > maxItems && _depth < maxDepth) {
      _subdivide();
    }
  }

  void _subdivide() {
    final midX = bounds.left + bounds.width / 2;
    final midY = bounds.top + bounds.height / 2;

    _children = [
      // Top-left
      QuadTree._child(
        bounds: Rect.fromLTRB(bounds.left, bounds.top, midX, midY),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: _depth + 1,
      ),
      // Top-right
      QuadTree._child(
        bounds: Rect.fromLTRB(midX, bounds.top, bounds.right, midY),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: _depth + 1,
      ),
      // Bottom-left
      QuadTree._child(
        bounds: Rect.fromLTRB(bounds.left, midY, midX, bounds.bottom),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: _depth + 1,
      ),
      // Bottom-right
      QuadTree._child(
        bounds: Rect.fromLTRB(midX, midY, bounds.right, bounds.bottom),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: _depth + 1,
      ),
    ];

    // Re-insert items into children
    final oldItems = List<_QuadTreeEntry<T>>.from(_items);
    _items.clear();

    for (final entry in oldItems) {
      final index = _getChildIndex(entry.bounds);
      if (index != -1) {
        _children![index].insert(entry.item, entry.bounds);
      } else {
        _items.add(entry);
      }
    }
  }

  int _getChildIndex(Rect itemBounds) {
    final midX = bounds.left + bounds.width / 2;
    final midY = bounds.top + bounds.height / 2;

    final inTop = itemBounds.bottom <= midY;
    final inBottom = itemBounds.top >= midY;
    final inLeft = itemBounds.right <= midX;
    final inRight = itemBounds.left >= midX;

    if (inTop) {
      if (inLeft) return 0;
      if (inRight) return 1;
    } else if (inBottom) {
      if (inLeft) return 2;
      if (inRight) return 3;
    }

    return -1; // Spans multiple quadrants
  }

  @override
  List<T> queryPoint(Offset point) {
    final results = <T>[];
    _queryPoint(point, results);
    return results;
  }

  void _queryPoint(Offset point, List<T> results) {
    if (!bounds.contains(point)) return;

    for (final entry in _items) {
      if (entry.bounds.contains(point)) {
        results.add(entry.item);
      }
    }

    if (_children != null) {
      for (final child in _children!) {
        child._queryPoint(point, results);
      }
    }
  }

  @override
  List<T> queryRect(Rect rect) {
    final results = <T>[];
    _queryRect(rect, results);
    return results;
  }

  void _queryRect(Rect rect, List<T> results) {
    if (!bounds.overlaps(rect)) return;

    for (final entry in _items) {
      if (entry.bounds.overlaps(rect)) {
        results.add(entry.item);
      }
    }

    if (_children != null) {
      for (final child in _children!) {
        child._queryRect(rect, results);
      }
    }
  }

  @override
  T? findNearest(Offset point, {double maxDistance = double.infinity}) {
    T? nearest;
    var nearestDistance = maxDistance;

    _findNearest(point, (item, distance) {
      if (distance < nearestDistance) {
        nearest = item;
        nearestDistance = distance;
      }
    });

    return nearest;
  }

  void _findNearest(Offset point, void Function(T item, double distance) callback) {
    for (final entry in _items) {
      final distance = _distanceToRect(point, entry.bounds);
      callback(entry.item, distance);
    }

    if (_children != null) {
      // Sort children by distance for early termination
      final sortedChildren = List<QuadTree<T>>.from(_children!);
      sortedChildren.sort((a, b) {
        final distA = _distanceToRect(point, a.bounds);
        final distB = _distanceToRect(point, b.bounds);
        return distA.compareTo(distB);
      });

      for (final child in sortedChildren) {
        child._findNearest(point, callback);
      }
    }
  }

  double _distanceToRect(Offset point, Rect rect) {
    final dx = math.max(rect.left - point.dx, math.max(0, point.dx - rect.right));
    final dy = math.max(rect.top - point.dy, math.max(0, point.dy - rect.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  void clear() {
    _items.clear();
    _children = null;
  }

  @override
  int get length {
    var count = _items.length;
    if (_children != null) {
      for (final child in _children!) {
        count += child.length;
      }
    }
    return count;
  }
}

class _QuadTreeEntry<T> {
  _QuadTreeEntry(this.item, this.bounds);
  final T item;
  final Rect bounds;
}

/// A simple grid-based spatial index for uniform distributions.
///
/// More efficient than QuadTree when data is uniformly distributed.
class GridIndex<T> implements SpatialIndex<T> {
  GridIndex({
    required this.bounds,
    this.cellSize = 50.0,
  }) {
    _cols = (bounds.width / cellSize).ceil().clamp(1, 100);
    _rows = (bounds.height / cellSize).ceil().clamp(1, 100);
    _cells = List.generate(_cols * _rows, (_) => <_QuadTreeEntry<T>>[]);
  }

  /// The bounding rectangle.
  final Rect bounds;

  /// Size of each grid cell.
  final double cellSize;

  late final int _cols;
  late final int _rows;
  late final List<List<_QuadTreeEntry<T>>> _cells;
  int _length = 0;

  @override
  void insert(T item, Rect itemBounds) {
    final minCol = _getCol(itemBounds.left);
    final maxCol = _getCol(itemBounds.right);
    final minRow = _getRow(itemBounds.top);
    final maxRow = _getRow(itemBounds.bottom);

    final entry = _QuadTreeEntry(item, itemBounds);

    for (var row = minRow; row <= maxRow; row++) {
      for (var col = minCol; col <= maxCol; col++) {
        _cells[row * _cols + col].add(entry);
      }
    }

    _length++;
  }

  int _getCol(double x) => ((x - bounds.left) / cellSize).floor().clamp(0, _cols - 1);
  int _getRow(double y) => ((y - bounds.top) / cellSize).floor().clamp(0, _rows - 1);

  @override
  List<T> queryPoint(Offset point) {
    if (!bounds.contains(point)) return [];

    final col = _getCol(point.dx);
    final row = _getRow(point.dy);
    final cell = _cells[row * _cols + col];

    final results = <T>[];
    final seen = <T>{};

    for (final entry in cell) {
      if (entry.bounds.contains(point) && seen.add(entry.item)) {
        results.add(entry.item);
      }
    }

    return results;
  }

  @override
  List<T> queryRect(Rect rect) {
    final minCol = _getCol(rect.left);
    final maxCol = _getCol(rect.right);
    final minRow = _getRow(rect.top);
    final maxRow = _getRow(rect.bottom);

    final results = <T>[];
    final seen = <T>{};

    for (var row = minRow; row <= maxRow; row++) {
      for (var col = minCol; col <= maxCol; col++) {
        final cell = _cells[row * _cols + col];
        for (final entry in cell) {
          if (entry.bounds.overlaps(rect) && seen.add(entry.item)) {
            results.add(entry.item);
          }
        }
      }
    }

    return results;
  }

  @override
  T? findNearest(Offset point, {double maxDistance = double.infinity}) {
    T? nearest;
    var nearestDistance = maxDistance;

    // Search in expanding rings
    final centerCol = _getCol(point.dx);
    final centerRow = _getRow(point.dy);
    final maxRing = math.max(_cols, _rows);

    for (var ring = 0; ring <= maxRing; ring++) {
      final minSearchCol = (centerCol - ring).clamp(0, _cols - 1);
      final maxSearchCol = (centerCol + ring).clamp(0, _cols - 1);
      final minSearchRow = (centerRow - ring).clamp(0, _rows - 1);
      final maxSearchRow = (centerRow + ring).clamp(0, _rows - 1);

      for (var row = minSearchRow; row <= maxSearchRow; row++) {
        for (var col = minSearchCol; col <= maxSearchCol; col++) {
          // Only check cells on the ring boundary
          if (ring > 0 &&
              col > minSearchCol && col < maxSearchCol &&
              row > minSearchRow && row < maxSearchRow) {
            continue;
          }

          final cell = _cells[row * _cols + col];
          for (final entry in cell) {
            final distance = _distanceToRect(point, entry.bounds);
            if (distance < nearestDistance) {
              nearest = entry.item;
              nearestDistance = distance;
            }
          }
        }
      }

      // If we found something, check if it's closer than next ring
      if (nearest != null && nearestDistance < ring * cellSize) {
        break;
      }
    }

    return nearest;
  }

  double _distanceToRect(Offset point, Rect rect) {
    final dx = math.max(rect.left - point.dx, math.max(0, point.dx - rect.right));
    final dy = math.max(rect.top - point.dy, math.max(0, point.dy - rect.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  void clear() {
    for (final cell in _cells) {
      cell.clear();
    }
    _length = 0;
  }

  @override
  int get length => _length;
}

/// Information about a hit test result.
class HitTestInfo<T> {
  HitTestInfo({
    required this.item,
    required this.bounds,
    required this.distance,
    this.dataIndex,
    this.seriesIndex,
  });

  /// The item that was hit.
  final T item;

  /// The bounds of the item.
  final Rect bounds;

  /// Distance from the query point to the item.
  final double distance;

  /// Optional index into the data array.
  final int? dataIndex;

  /// Optional series index.
  final int? seriesIndex;
}

/// A spatial index specifically designed for chart hit testing.
class ChartSpatialIndex {
  ChartSpatialIndex({required Rect bounds})
      : _index = QuadTree<HitTestInfo<dynamic>>(bounds: bounds);

  final QuadTree<HitTestInfo<dynamic>> _index;

  /// Registers a hit region for a data point.
  void registerDataPoint<T>({
    required T item,
    required Rect bounds,
    required int dataIndex,
    int? seriesIndex,
  }) {
    _index.insert(
      HitTestInfo<T>(
        item: item,
        bounds: bounds,
        distance: 0,
        dataIndex: dataIndex,
        seriesIndex: seriesIndex,
      ),
      bounds,
    );
  }

  /// Finds the hit info at a point.
  HitTestInfo<dynamic>? hitTest(Offset point) {
    final results = _index.queryPoint(point);
    if (results.isEmpty) return null;

    // Return the one with smallest bounds (most specific)
    return results.reduce((a, b) =>
      a.bounds.width * a.bounds.height < b.bounds.width * b.bounds.height ? a : b,
    );
  }

  /// Finds all hits within a distance.
  List<HitTestInfo<dynamic>> hitTestRadius(Offset point, double radius) {
    final searchRect = Rect.fromCircle(center: point, radius: radius);
    return _index.queryRect(searchRect);
  }

  /// Finds the nearest data point.
  HitTestInfo<dynamic>? findNearest(Offset point, {double maxDistance = 50.0}) => _index.findNearest(point, maxDistance: maxDistance);

  /// Clears the index.
  void clear() => _index.clear();

  /// Number of registered items.
  int get length => _index.length;
}
