import 'dart:ui';

/// Generic object pool for reusing expensive objects.
///
/// This reduces garbage collection pressure by recycling objects
/// instead of creating new ones each frame.
class ObjectPool<T> {
  ObjectPool({
    required this.create,
    this.reset,
    this.maxSize = 50,
  });

  /// Factory function to create new instances.
  final T Function() create;

  /// Optional function to reset an object before reuse.
  final void Function(T)? reset;

  /// Maximum pool size.
  final int maxSize;

  final List<T> _pool = [];
  int _activeCount = 0;

  /// Acquires an object from the pool or creates a new one.
  T acquire() {
    _activeCount++;
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return create();
  }

  /// Releases an object back to the pool.
  void release(T object) {
    _activeCount--;
    if (_pool.length < maxSize) {
      reset?.call(object);
      _pool.add(object);
    }
  }

  /// Releases all objects and clears the pool.
  void clear() {
    _pool.clear();
    _activeCount = 0;
  }

  /// Current number of pooled objects.
  int get pooledCount => _pool.length;

  /// Current number of active (acquired) objects.
  int get activeCount => _activeCount;

  /// Total objects managed by this pool.
  int get totalCount => _pool.length + _activeCount;
}

/// Specialized pool for Paint objects.
class PaintPool {
  PaintPool({int maxSize = 30}) : _pool = ObjectPool<Paint>(
    create: Paint.new,
    reset: (paint) {
      paint
        ..color = const Color(0xFF000000)
        ..strokeWidth = 0.0
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter
        ..shader = null
        ..maskFilter = null
        ..colorFilter = null
        ..imageFilter = null
        ..blendMode = BlendMode.srcOver
        ..isAntiAlias = true;
    },
    maxSize: maxSize,
  );

  final ObjectPool<Paint> _pool;

  /// Acquires a paint configured for fills.
  Paint acquireFill({
    required Color color,
    Shader? shader,
  }) {
    final paint = _pool.acquire();
    paint.style = PaintingStyle.fill;
    paint.color = color;
    paint.shader = shader;
    return paint;
  }

  /// Acquires a paint configured for strokes.
  Paint acquireStroke({
    required Color color,
    required double strokeWidth,
    StrokeCap cap = StrokeCap.round,
    StrokeJoin join = StrokeJoin.round,
    Shader? shader,
  }) {
    final paint = _pool.acquire();
    paint.style = PaintingStyle.stroke;
    paint.color = color;
    paint.strokeWidth = strokeWidth;
    paint.strokeCap = cap;
    paint.strokeJoin = join;
    paint.shader = shader;
    return paint;
  }

  /// Releases a paint back to the pool.
  void release(Paint paint) => _pool.release(paint);

  /// Clears the pool.
  void clear() => _pool.clear();
}

/// Specialized pool for Path objects.
class PathPool {
  PathPool({int maxSize = 50}) : _pool = ObjectPool<Path>(
    create: Path.new,
    reset: (path) => path.reset(),
    maxSize: maxSize,
  );

  final ObjectPool<Path> _pool;

  /// Acquires a fresh path.
  Path acquire() => _pool.acquire();

  /// Releases a path back to the pool.
  void release(Path path) => _pool.release(path);

  /// Clears the pool.
  void clear() => _pool.clear();
}

/// A scoped resource manager that automatically releases pooled objects.
///
/// Usage:
/// ```dart
/// final scope = PoolScope(paintPool: paintPool, pathPool: pathPool);
/// final paint = scope.acquirePaint(...);
/// final path = scope.acquirePath();
/// // Use paint and path...
/// scope.releaseAll(); // Releases everything
/// ```
class PoolScope {
  PoolScope({
    required this.paintPool,
    required this.pathPool,
  });

  final PaintPool paintPool;
  final PathPool pathPool;

  final List<Paint> _acquiredPaints = [];
  final List<Path> _acquiredPaths = [];

  /// Acquires a fill paint within this scope.
  Paint acquireFillPaint({
    required Color color,
    Shader? shader,
  }) {
    final paint = paintPool.acquireFill(color: color, shader: shader);
    _acquiredPaints.add(paint);
    return paint;
  }

  /// Acquires a stroke paint within this scope.
  Paint acquireStrokePaint({
    required Color color,
    required double strokeWidth,
    StrokeCap cap = StrokeCap.round,
    StrokeJoin join = StrokeJoin.round,
    Shader? shader,
  }) {
    final paint = paintPool.acquireStroke(
      color: color,
      strokeWidth: strokeWidth,
      cap: cap,
      join: join,
      shader: shader,
    );
    _acquiredPaints.add(paint);
    return paint;
  }

  /// Acquires a path within this scope.
  Path acquirePath() {
    final path = pathPool.acquire();
    _acquiredPaths.add(path);
    return path;
  }

  /// Releases all acquired resources.
  void releaseAll() {
    for (final paint in _acquiredPaints) {
      paintPool.release(paint);
    }
    for (final path in _acquiredPaths) {
      pathPool.release(path);
    }
    _acquiredPaints.clear();
    _acquiredPaths.clear();
  }
}

/// Global pools for chart rendering.
///
/// These are shared across all charts for maximum efficiency.
class ChartPools {
  ChartPools._();

  static final instance = ChartPools._();

  final paintPool = PaintPool(maxSize: 50);
  final pathPool = PathPool(maxSize: 100);

  /// Creates a new scope for automatic resource management.
  PoolScope createScope() => PoolScope(
    paintPool: paintPool,
    pathPool: pathPool,
  );

  /// Clears all pools (call when app is backgrounded).
  void clearAll() {
    paintPool.clear();
    pathPool.clear();
  }
}
