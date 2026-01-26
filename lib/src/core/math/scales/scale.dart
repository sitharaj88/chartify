import 'dart:math' as math;

/// Abstract scale interface for mapping values between domains.
///
/// Scales transform values from a data domain to an output range,
/// typically used for converting data values to pixel coordinates.
///
/// Example:
/// ```dart
/// final scale = LinearScale(domain: (0, 100), range: (0, 400));
/// final pixel = scale.scale(50); // Returns 200.0
/// final value = scale.invert(200); // Returns 50.0
/// ```
abstract class Scale<T> {
  /// The input domain (data space) as (min, max).
  (T, T) get domain;

  /// The output range (screen space) as (start, end).
  (double, double) get range;

  /// Maps a domain value to a range value.
  double scale(T value);

  /// Inverse mapping from range value to domain value.
  T invert(double value);

  /// Returns nicely-rounded tick values for this scale.
  ///
  /// [count] is a hint for the number of ticks desired.
  /// The actual number may vary to produce nice values.
  List<T> ticks({int? count});

  /// Returns a tick formatter function for this scale.
  String Function(T) tickFormatter({int? precision});

  /// Creates a copy of this scale with a new domain.
  Scale<T> copyWithDomain(T min, T max);

  /// Creates a copy of this scale with a new range.
  Scale<T> copyWithRange(double start, double end);

  /// Whether this scale is inverted (range end < range start).
  bool get isInverted => range.$2 < range.$1;

  /// The length of the range.
  double get rangeExtent => (range.$2 - range.$1).abs();
}

/// A continuous numeric scale using linear interpolation.
///
/// Linear scales map a continuous, quantitative domain to a continuous range.
class LinearScale extends Scale<double> {
  LinearScale({
    required (double, double) domain,
    required (double, double) range,
    this.clamp = false,
    this.nice = false,
    this.niceTickCount,
  })  : _domain = domain,
        _range = range {
    if (nice) {
      _domain = _niceDomain(_domain, niceTickCount ?? 10);
    }
  }

  (double, double) _domain;
  final (double, double) _range;

  /// Whether to clamp output values to the range.
  final bool clamp;

  /// Whether to extend the domain to nice round values.
  final bool nice;

  /// Hint for number of ticks when computing nice domain.
  final int? niceTickCount;

  @override
  (double, double) get domain => _domain;

  @override
  (double, double) get range => _range;

  @override
  double scale(double value) {
    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    if (dMax == dMin) return rMin;

    final t = (value - dMin) / (dMax - dMin);
    final result = rMin + t * (rMax - rMin);

    if (clamp) {
      final min = math.min(rMin, rMax);
      final max = math.max(rMin, rMax);
      return result.clamp(min, max);
    }

    return result;
  }

  @override
  double invert(double value) {
    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    if (rMax == rMin) return dMin;

    final t = (value - rMin) / (rMax - rMin);
    final result = dMin + t * (dMax - dMin);

    if (clamp) {
      final min = math.min(dMin, dMax);
      final max = math.max(dMin, dMax);
      return result.clamp(min, max);
    }

    return result;
  }

  @override
  List<double> ticks({int? count}) {
    count ??= 10;
    final (min, max) = _domain;

    if (min == max) return [min];

    final step = _tickStep(min, max, count);
    if (step == 0 || !step.isFinite) return [min];

    final start = (min / step).ceil() * step;
    final stop = (max / step).floor() * step;

    final ticks = <double>[];
    var tick = start;
    while (tick <= stop + step * 0.5) {
      ticks.add(_roundToPrecision(tick, step));
      tick += step;
    }

    return ticks;
  }

  @override
  String Function(double) tickFormatter({int? precision}) {
    precision ??= _calculatePrecision(_tickStep(_domain.$1, _domain.$2, 10));
    return (value) => value.toStringAsFixed(precision!);
  }

  @override
  Scale<double> copyWithDomain(double min, double max) => LinearScale(
      domain: (min, max),
      range: _range,
      clamp: clamp,
      nice: nice,
      niceTickCount: niceTickCount,
    );

  @override
  Scale<double> copyWithRange(double start, double end) => LinearScale(
      domain: _domain,
      range: (start, end),
      clamp: clamp,
      nice: nice,
      niceTickCount: niceTickCount,
    );

  /// Computes a nice step value for tick generation.
  static double _tickStep(double min, double max, int count) {
    final span = max - min;
    var step = math.pow(10, (math.log(span / count) / math.ln10).floor());
    final err = span / count / step;

    if (err <= 0.15) {
      step *= 10;
    } else if (err <= 0.35) {
      step *= 5;
    } else if (err <= 0.75) {
      step *= 2;
    }

    return step.toDouble();
  }

  /// Extends domain to nice round values.
  static (double, double) _niceDomain((double, double) domain, int count) {
    final (min, max) = domain;
    if (min == max) return domain;

    final step = _tickStep(min, max, count);
    return (
      (min / step).floor() * step,
      (max / step).ceil() * step,
    );
  }

  /// Rounds a value to avoid floating point precision issues.
  static double _roundToPrecision(double value, double step) {
    final precision = _calculatePrecision(step);
    final multiplier = math.pow(10, precision);
    return (value * multiplier).round() / multiplier;
  }

  /// Calculates decimal precision needed for a step value.
  static int _calculatePrecision(double step) {
    if (step >= 1) return 0;
    return -(math.log(step) / math.ln10).floor();
  }
}

/// A logarithmic scale for data that spans multiple orders of magnitude.
///
/// Logarithmic scales are useful for visualizing data with exponential growth.
class LogScale extends Scale<double> {
  LogScale({
    required (double, double) domain,
    required (double, double) range,
    this.base = 10,
    this.clamp = false,
  })  : assert(domain.$1 > 0 && domain.$2 > 0, 'Log scale domain must be positive'),
        _domain = domain,
        _range = range;

  final (double, double) _domain;
  final (double, double) _range;

  /// The logarithm base (default: 10).
  final double base;

  /// Whether to clamp output values to the range.
  final bool clamp;

  @override
  (double, double) get domain => _domain;

  @override
  (double, double) get range => _range;

  double _log(double x) => math.log(x) / math.log(base);

  @override
  double scale(double value) {
    if (value <= 0) return _range.$1;

    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    final logMin = _log(dMin);
    final logMax = _log(dMax);

    if (logMax == logMin) return rMin;

    final t = (_log(value) - logMin) / (logMax - logMin);
    final result = rMin + t * (rMax - rMin);

    if (clamp) {
      final min = math.min(rMin, rMax);
      final max = math.max(rMin, rMax);
      return result.clamp(min, max);
    }

    return result;
  }

  @override
  double invert(double value) {
    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    final logMin = _log(dMin);
    final logMax = _log(dMax);

    if (rMax == rMin) return dMin;

    final t = (value - rMin) / (rMax - rMin);
    final result = math.pow(base, logMin + t * (logMax - logMin)).toDouble();

    if (clamp) {
      final min = math.min(dMin, dMax);
      final max = math.max(dMin, dMax);
      return result.clamp(min, max);
    }

    return result;
  }

  @override
  List<double> ticks({int? count}) {
    count ??= 10;
    final (min, max) = _domain;

    final logMin = _log(min).floor();
    final logMax = _log(max).ceil();

    final ticks = <double>[];
    for (var i = logMin; i <= logMax; i++) {
      final tick = math.pow(base, i).toDouble();
      if (tick >= min && tick <= max) {
        ticks.add(tick);
      }
    }

    return ticks;
  }

  @override
  String Function(double) tickFormatter({int? precision}) => (value) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      if (value >= 1) return value.toStringAsFixed(0);
      return value.toStringAsPrecision(2);
    };

  @override
  Scale<double> copyWithDomain(double min, double max) => LogScale(
      domain: (min, max),
      range: _range,
      base: base,
      clamp: clamp,
    );

  @override
  Scale<double> copyWithRange(double start, double end) => LogScale(
      domain: _domain,
      range: (start, end),
      base: base,
      clamp: clamp,
    );
}

/// A band scale for categorical/ordinal data.
///
/// Band scales divide the range into uniform bands, one for each domain value.
class BandScale<T> extends Scale<T> {
  BandScale({
    required List<T> domain,
    required (double, double) range,
    this.paddingInner = 0.0,
    this.paddingOuter = 0.0,
    this.align = 0.5,
  })  : _domain = domain,
        _range = range,
        _domainIndex = {for (var i = 0; i < domain.length; i++) domain[i]: i};

  final List<T> _domain;
  final (double, double) _range;
  final Map<T, int> _domainIndex;

  /// Padding between bands (0.0 to 1.0).
  final double paddingInner;

  /// Padding at the edges (0.0 to 1.0).
  final double paddingOuter;

  /// Alignment of bands within the range (0.0 to 1.0).
  final double align;

  @override
  (T, T) get domain => (_domain.first, _domain.last);

  /// The full list of domain values.
  List<T> get domainValues => List.unmodifiable(_domain);

  @override
  (double, double) get range => _range;

  /// The width of each band.
  double get bandwidth {
    final n = _domain.length;
    if (n == 0) return 0;

    final (rMin, rMax) = _range;
    final rangeSize = (rMax - rMin).abs();

    final step = rangeSize / (n - paddingInner + paddingOuter * 2);
    return step * (1 - paddingInner);
  }

  /// The step size between band starts.
  double get step {
    final n = _domain.length;
    if (n == 0) return 0;

    final (rMin, rMax) = _range;
    final rangeSize = (rMax - rMin).abs();

    return rangeSize / (n - paddingInner + paddingOuter * 2);
  }

  @override
  double scale(T value) {
    final index = _domainIndex[value];
    if (index == null) return _range.$1;

    final (rMin, rMax) = _range;
    final start = math.min(rMin, rMax);

    return start + paddingOuter * step + index * step;
  }

  /// Returns the center position of the band for a value.
  double scaleCenter(T value) => scale(value) + bandwidth / 2;

  @override
  T invert(double value) {
    final (rMin, rMax) = _range;
    final start = math.min(rMin, rMax);
    final offset = value - start - paddingOuter * step;

    final index = (offset / step).floor().clamp(0, _domain.length - 1);
    return _domain[index];
  }

  @override
  List<T> ticks({int? count}) => _domain;

  @override
  String Function(T) tickFormatter({int? precision}) => (value) => value.toString();

  @override
  // For band scales, this replaces the entire domain
  Scale<T> copyWithDomain(T min, T max) => BandScale<T>(
      domain: [min, max],
      range: _range,
      paddingInner: paddingInner,
      paddingOuter: paddingOuter,
      align: align,
    );

  @override
  Scale<T> copyWithRange(double start, double end) => BandScale<T>(
      domain: _domain,
      range: (start, end),
      paddingInner: paddingInner,
      paddingOuter: paddingOuter,
      align: align,
    );

  /// Creates a new band scale with the given domain list.
  BandScale<T> withDomainList(List<T> newDomain) => BandScale<T>(
      domain: newDomain,
      range: _range,
      paddingInner: paddingInner,
      paddingOuter: paddingOuter,
      align: align,
    );
}

/// A time scale for DateTime values.
///
/// Time scales are specialized linear scales for temporal data.
class TimeScale extends Scale<DateTime> {
  TimeScale({
    required (DateTime, DateTime) domain,
    required (double, double) range,
    this.clamp = false,
  })  : _domain = domain,
        _range = range;

  final (DateTime, DateTime) _domain;
  final (double, double) _range;

  /// Whether to clamp output values to the range.
  final bool clamp;

  @override
  (DateTime, DateTime) get domain => _domain;

  @override
  (double, double) get range => _range;

  @override
  double scale(DateTime value) {
    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    final domainSpan = dMax.millisecondsSinceEpoch - dMin.millisecondsSinceEpoch;
    if (domainSpan == 0) return rMin;

    final t = (value.millisecondsSinceEpoch - dMin.millisecondsSinceEpoch) / domainSpan;
    final result = rMin + t * (rMax - rMin);

    if (clamp) {
      final min = math.min(rMin, rMax);
      final max = math.max(rMin, rMax);
      return result.clamp(min, max);
    }

    return result;
  }

  @override
  DateTime invert(double value) {
    final (dMin, dMax) = _domain;
    final (rMin, rMax) = _range;

    if (rMax == rMin) return dMin;

    final t = (value - rMin) / (rMax - rMin);
    final ms = dMin.millisecondsSinceEpoch +
        t * (dMax.millisecondsSinceEpoch - dMin.millisecondsSinceEpoch);

    return DateTime.fromMillisecondsSinceEpoch(ms.round());
  }

  @override
  List<DateTime> ticks({int? count}) {
    count ??= 10;
    final (min, max) = _domain;

    final span = max.difference(min);
    final interval = _chooseInterval(span, count);

    final ticks = <DateTime>[];
    var current = _roundToInterval(min, interval);

    while (current.isBefore(max) || current.isAtSameMomentAs(max)) {
      if (current.isAfter(min) || current.isAtSameMomentAs(min)) {
        ticks.add(current);
      }
      current = _addInterval(current, interval);
    }

    return ticks;
  }

  @override
  String Function(DateTime) tickFormatter({int? precision}) {
    final (min, max) = _domain;
    final span = max.difference(min);

    if (span.inDays > 365) {
      return (dt) => '${dt.year}';
    } else if (span.inDays > 30) {
      return (dt) => '${_monthNames[dt.month - 1]} ${dt.year}';
    } else if (span.inDays > 1) {
      return (dt) => '${_monthNames[dt.month - 1]} ${dt.day}';
    } else if (span.inHours > 1) {
      return (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
  }

  @override
  Scale<DateTime> copyWithDomain(DateTime min, DateTime max) => TimeScale(domain: (min, max), range: _range, clamp: clamp);

  @override
  Scale<DateTime> copyWithRange(double start, double end) => TimeScale(domain: _domain, range: (start, end), clamp: clamp);

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static _TimeInterval _chooseInterval(Duration span, int count) {
    final targetMs = span.inMilliseconds / count;

    for (final interval in _intervals) {
      if (interval.milliseconds >= targetMs) {
        return interval;
      }
    }
    return _intervals.last;
  }

  static DateTime _roundToInterval(DateTime dt, _TimeInterval interval) {
    switch (interval.type) {
      case _IntervalType.second:
        return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      case _IntervalType.minute:
        return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      case _IntervalType.hour:
        return DateTime(dt.year, dt.month, dt.day, dt.hour);
      case _IntervalType.day:
        return DateTime(dt.year, dt.month, dt.day);
      case _IntervalType.month:
        return DateTime(dt.year, dt.month);
      case _IntervalType.year:
        return DateTime(dt.year);
    }
  }

  static DateTime _addInterval(DateTime dt, _TimeInterval interval) {
    switch (interval.type) {
      case _IntervalType.second:
        return dt.add(Duration(seconds: interval.count));
      case _IntervalType.minute:
        return dt.add(Duration(minutes: interval.count));
      case _IntervalType.hour:
        return dt.add(Duration(hours: interval.count));
      case _IntervalType.day:
        return dt.add(Duration(days: interval.count));
      case _IntervalType.month:
        return DateTime(dt.year, dt.month + interval.count, dt.day);
      case _IntervalType.year:
        return DateTime(dt.year + interval.count, dt.month, dt.day);
    }
  }

  static final _intervals = [
    const _TimeInterval(_IntervalType.second, 1),
    const _TimeInterval(_IntervalType.second, 5),
    const _TimeInterval(_IntervalType.second, 15),
    const _TimeInterval(_IntervalType.second, 30),
    const _TimeInterval(_IntervalType.minute, 1),
    const _TimeInterval(_IntervalType.minute, 5),
    const _TimeInterval(_IntervalType.minute, 15),
    const _TimeInterval(_IntervalType.minute, 30),
    const _TimeInterval(_IntervalType.hour, 1),
    const _TimeInterval(_IntervalType.hour, 3),
    const _TimeInterval(_IntervalType.hour, 6),
    const _TimeInterval(_IntervalType.hour, 12),
    const _TimeInterval(_IntervalType.day, 1),
    const _TimeInterval(_IntervalType.day, 7),
    const _TimeInterval(_IntervalType.month, 1),
    const _TimeInterval(_IntervalType.month, 3),
    const _TimeInterval(_IntervalType.year, 1),
  ];
}

enum _IntervalType { second, minute, hour, day, month, year }

class _TimeInterval {
  const _TimeInterval(this.type, this.count);

  final _IntervalType type;
  final int count;

  int get milliseconds {
    switch (type) {
      case _IntervalType.second:
        return count * 1000;
      case _IntervalType.minute:
        return count * 60 * 1000;
      case _IntervalType.hour:
        return count * 60 * 60 * 1000;
      case _IntervalType.day:
        return count * 24 * 60 * 60 * 1000;
      case _IntervalType.month:
        return count * 30 * 24 * 60 * 60 * 1000;
      case _IntervalType.year:
        return count * 365 * 24 * 60 * 60 * 1000;
    }
  }
}
