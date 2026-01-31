import 'package:chartify/chartify.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

void main() {
  group('DataValidator', () {
    group('isValidNumber', () {
      test('returns true for valid numbers', () {
        expect(DataValidator.isValidNumber(0), true);
        expect(DataValidator.isValidNumber(1), true);
        expect(DataValidator.isValidNumber(-1), true);
        expect(DataValidator.isValidNumber(3.14), true);
        expect(DataValidator.isValidNumber(1000000), true);
        expect(DataValidator.isValidNumber(-999.999), true);
      });

      test('returns false for null', () {
        expect(DataValidator.isValidNumber(null), false);
      });

      test('returns false for NaN', () {
        expect(DataValidator.isValidNumber(double.nan), false);
      });

      test('returns false for positive infinity', () {
        expect(DataValidator.isValidNumber(double.infinity), false);
      });

      test('returns false for negative infinity', () {
        expect(DataValidator.isValidNumber(double.negativeInfinity), false);
      });

      test('returns true for very large finite numbers', () {
        expect(DataValidator.isValidNumber(double.maxFinite), true);
        expect(DataValidator.isValidNumber(-double.maxFinite), true);
      });

      test('returns true for very small positive numbers', () {
        expect(DataValidator.isValidNumber(double.minPositive), true);
      });
    });

    group('isValidDataPoint', () {
      test('returns true for valid numeric data points', () {
        const point = DataPoint<double, double>(x: 1.0, y: 10.0);
        expect(DataValidator.isValidDataPoint(point), true);
      });

      test('returns false when x is NaN', () {
        const point = DataPoint<double, double>(x: double.nan, y: 10.0);
        expect(DataValidator.isValidDataPoint(point), false);
      });

      test('returns false when y is NaN', () {
        const point = DataPoint<double, double>(x: 1.0, y: double.nan);
        expect(DataValidator.isValidDataPoint(point), false);
      });

      test('returns false when x is infinity', () {
        const point = DataPoint<double, double>(x: double.infinity, y: 10.0);
        expect(DataValidator.isValidDataPoint(point), false);
      });

      test('returns false when y is negative infinity', () {
        const point = DataPoint<double, double>(x: 1.0, y: double.negativeInfinity);
        expect(DataValidator.isValidDataPoint(point), false);
      });

      test('returns true for non-numeric x values', () {
        const stringPoint = DataPoint<String, double>(x: 'category', y: 10.0);
        expect(DataValidator.isValidDataPoint(stringPoint), true);

        final datePoint = DataPoint<DateTime, double>(
          x: DateTime(2024, 1, 1),
          y: 10.0,
        );
        expect(DataValidator.isValidDataPoint(datePoint), true);
      });

      test('returns true for integer y values', () {
        const point = DataPoint<double, int>(x: 1.0, y: 10);
        expect(DataValidator.isValidDataPoint(point), true);
      });
    });

    group('filterValidPoints', () {
      test('returns empty list for empty input', () {
        final result = DataValidator.filterValidPoints<double, double>([]);
        expect(result, isEmpty);
      });

      test('returns all points when all are valid', () {
        final points = createSampleDataPoints(count: 5);
        final result = DataValidator.filterValidPoints(points);
        expect(result.length, 5);
      });

      test('filters out invalid points', () {
        final points = createInvalidDataPoints();
        final result = DataValidator.filterValidPoints(points);

        // Only points at index 0 and 2 are valid
        expect(result.length, 2);
        expect(result[0].x, 1);
        expect(result[1].x, 3);
      });

      test('preserves order of valid points', () {
        final points = [
          const DataPoint<double, double>(x: 1, y: 10),
          const DataPoint<double, double>(x: 2, y: double.nan),
          const DataPoint<double, double>(x: 3, y: 30),
          const DataPoint<double, double>(x: 4, y: 40),
        ];
        final result = DataValidator.filterValidPoints(points);

        expect(result[0].x, 1);
        expect(result[1].x, 3);
        expect(result[2].x, 4);
      });
    });

    group('validatePoints', () {
      test('does not throw for valid points', () {
        final points = createSampleDataPoints(count: 5);
        expect(() => DataValidator.validatePoints(points), returnsNormally);
      });

      test('throws InvalidChartDataException for invalid points', () {
        final points = createInvalidDataPoints();
        expect(
          () => DataValidator.validatePoints(points),
          throwsA(isA<InvalidChartDataException>()),
        );
      });

      test('exception message includes invalid indices', () {
        final points = createInvalidDataPoints();
        try {
          DataValidator.validatePoints(points);
          fail('Expected exception');
        } on InvalidChartDataException catch (e) {
          expect(e.message, contains('1'));
          expect(e.message, contains('3'));
          expect(e.message, contains('4'));
        }
      });

      test('exception message includes series name when provided', () {
        final points = createInvalidDataPoints();
        try {
          DataValidator.validatePoints(points, seriesName: 'Test Series');
          fail('Expected exception');
        } on InvalidChartDataException catch (e) {
          expect(e.message, contains('Test Series'));
        }
      });
    });

    group('clampToSafeValue', () {
      test('returns value when finite', () {
        expect(DataValidator.clampToSafeValue(50.0), 50.0);
        expect(DataValidator.clampToSafeValue(-50.0), -50.0);
        expect(DataValidator.clampToSafeValue(0.0), 0.0);
      });

      test('returns default for NaN', () {
        expect(DataValidator.clampToSafeValue(double.nan), 0.0);
        expect(
          DataValidator.clampToSafeValue(double.nan, defaultValue: 10.0),
          10.0,
        );
      });

      test('clamps positive infinity to max', () {
        expect(DataValidator.clampToSafeValue(double.infinity), 1e10);
        expect(
          DataValidator.clampToSafeValue(double.infinity, max: 100.0),
          100.0,
        );
      });

      test('clamps negative infinity to min', () {
        expect(DataValidator.clampToSafeValue(double.negativeInfinity), -1e10);
        expect(
          DataValidator.clampToSafeValue(double.negativeInfinity, min: -100.0),
          -100.0,
        );
      });

      test('clamps finite values to range', () {
        expect(
          DataValidator.clampToSafeValue(150.0, min: 0.0, max: 100.0),
          100.0,
        );
        expect(
          DataValidator.clampToSafeValue(-50.0, min: 0.0, max: 100.0),
          0.0,
        );
      });
    });

    group('validateBounds', () {
      test('returns bounds when valid', () {
        final (min, max) = DataValidator.validateBounds(0, 100);
        expect(min, 0);
        expect(max, 100);
      });

      test('throws for NaN min', () {
        expect(
          () => DataValidator.validateBounds(double.nan, 100),
          throwsA(isA<InvalidChartConfigException>()),
        );
      });

      test('throws for NaN max', () {
        expect(
          () => DataValidator.validateBounds(0, double.nan),
          throwsA(isA<InvalidChartConfigException>()),
        );
      });

      test('throws for infinity', () {
        expect(
          () => DataValidator.validateBounds(0, double.infinity),
          throwsA(isA<InvalidChartConfigException>()),
        );
      });

      test('throws when min > max', () {
        expect(
          () => DataValidator.validateBounds(100, 50),
          throwsA(isA<InvalidChartConfigException>()),
        );
      });

      test('auto-adjusts when min == max', () {
        final (min, max) = DataValidator.validateBounds(50, 50);
        expect(min, 49);
        expect(max, 51);
      });

      test('exception includes axis name when provided', () {
        try {
          DataValidator.validateBounds(double.nan, 100, axisName: 'X Axis');
          fail('Expected exception');
        } on InvalidChartConfigException catch (e) {
          expect(e.message, contains('X Axis'));
        }
      });
    });

    group('hasValidData', () {
      test('returns false for empty list', () {
        expect(DataValidator.hasValidData<double, double>([]), false);
      });

      test('returns true when at least one valid point exists', () {
        final points = createInvalidDataPoints();
        expect(DataValidator.hasValidData(points), true);
      });

      test('returns false when all points are invalid', () {
        final points = [
          const DataPoint<double, double>(x: double.nan, y: 10),
          const DataPoint<double, double>(x: 2, y: double.infinity),
        ];
        expect(DataValidator.hasValidData(points), false);
      });

      test('returns true when all points are valid', () {
        final points = createSampleDataPoints(count: 5);
        expect(DataValidator.hasValidData(points), true);
      });
    });

    group('calculateSafeBounds', () {
      test('returns null for empty input', () {
        expect(DataValidator.calculateSafeBounds([]), isNull);
      });

      test('returns bounds for valid values', () {
        final result = DataValidator.calculateSafeBounds([10, 20, 30, 40, 50]);
        expect(result, (10.0, 50.0));
      });

      test('filters out invalid values', () {
        final result = DataValidator.calculateSafeBounds([
          10,
          double.nan,
          30,
          double.infinity,
          50,
        ]);
        expect(result, (10.0, 50.0));
      });

      test('handles single valid value', () {
        final result = DataValidator.calculateSafeBounds([
          double.nan,
          42,
          double.infinity,
        ]);
        expect(result, (42.0, 42.0));
      });

      test('returns null when all values are invalid', () {
        final result = DataValidator.calculateSafeBounds([
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]);
        expect(result, isNull);
      });

      test('works with negative values', () {
        final result = DataValidator.calculateSafeBounds([-50, -20, 0, 30]);
        expect(result, (-50.0, 30.0));
      });
    });
  });

  group('DataPointValidation extension', () {
    test('isValid returns true for valid point', () {
      const point = DataPoint<double, double>(x: 1.0, y: 10.0);
      expect(point.isValid, true);
    });

    test('isValid returns false for invalid point', () {
      const point = DataPoint<double, double>(x: 1.0, y: double.nan);
      expect(point.isValid, false);
    });
  });

  group('DataPointListValidation extension', () {
    test('validOnly filters invalid points', () {
      final points = createInvalidDataPoints();
      final valid = points.validOnly;
      expect(valid.length, 2);
    });

    test('hasValidData returns true when valid points exist', () {
      final points = createInvalidDataPoints();
      expect(points.hasValidData, true);
    });

    test('validate throws for invalid points', () {
      final points = createInvalidDataPoints();
      expect(() => points.validate(), throwsA(isA<InvalidChartDataException>()));
    });

    test('validate accepts series name', () {
      final points = createInvalidDataPoints();
      try {
        points.validate(seriesName: 'My Series');
        fail('Expected exception');
      } on InvalidChartDataException catch (e) {
        expect(e.message, contains('My Series'));
      }
    });
  });
}
