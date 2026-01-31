import 'package:chartify/chartify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinearScale', () {
    group('basic scaling', () {
      test('scales domain to range', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
        );

        expect(scale.scale(0), 0);
        expect(scale.scale(50), 200);
        expect(scale.scale(100), 400);
      });

      test('scales with negative domain', () {
        final scale = LinearScale(
          domain: (-50, 50),
          range: (0, 400),
        );

        expect(scale.scale(-50), 0);
        expect(scale.scale(0), 200);
        expect(scale.scale(50), 400);
      });

      test('scales with inverted range', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (400, 0),
        );

        expect(scale.scale(0), 400);
        expect(scale.scale(50), 200);
        expect(scale.scale(100), 0);
      });

      test('handles equal domain values', () {
        final scale = LinearScale(
          domain: (50, 50),
          range: (0, 400),
        );

        expect(scale.scale(50), 0);
      });

      test('extrapolates outside domain', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
        );

        expect(scale.scale(150), 600);
        expect(scale.scale(-50), -200);
      });
    });

    group('clamping', () {
      test('clamps output to range when enabled', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
          clamp: true,
        );

        expect(scale.scale(150), 400);
        expect(scale.scale(-50), 0);
      });

      test('does not clamp when disabled', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
          clamp: false,
        );

        expect(scale.scale(150), 600);
        expect(scale.scale(-50), -200);
      });
    });

    group('invert', () {
      test('inverts range to domain', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
        );

        expect(scale.invert(0), 0);
        expect(scale.invert(200), 50);
        expect(scale.invert(400), 100);
      });

      test('inverts with clamping', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
          clamp: true,
        );

        expect(scale.invert(500), 100);
        expect(scale.invert(-100), 0);
      });

      test('handles equal range values', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (200, 200),
        );

        expect(scale.invert(200), 0);
      });
    });

    group('ticks', () {
      test('generates reasonable tick values', () {
        final scale = LinearScale(
          domain: (0, 100),
          range: (0, 400),
        );

        final ticks = scale.ticks(count: 5);
        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(0));
        expect(ticks.last, lessThanOrEqualTo(100));
      });

      test('handles single value domain', () {
        final scale = LinearScale(
          domain: (50, 50),
          range: (0, 400),
        );

        final ticks = scale.ticks();
        expect(ticks, [50]);
      });

      test('tick values are nicely rounded', () {
        final scale = LinearScale(
          domain: (0, 97),
          range: (0, 400),
        );

        final ticks = scale.ticks(count: 5);
        // Ticks should be at nice intervals like 0, 20, 40, 60, 80
        for (final tick in ticks) {
          expect(tick % 10, 0);
        }
      });
    });

    group('nice domain', () {
      test('extends domain to nice values', () {
        final scale = LinearScale(
          domain: (3, 97),
          range: (0, 400),
          nice: true,
        );

        expect(scale.domain.$1, lessThanOrEqualTo(3));
        expect(scale.domain.$2, greaterThanOrEqualTo(97));
      });
    });

    group('copy methods', () {
      test('copyWithDomain creates new scale with domain', () {
        final original = LinearScale(
          domain: (0, 100),
          range: (0, 400),
          clamp: true,
        );
        final copy = original.copyWithDomain(0, 200);

        expect(copy.domain, (0.0, 200.0));
        expect(copy.range, original.range);
      });

      test('copyWithRange creates new scale with range', () {
        final original = LinearScale(
          domain: (0, 100),
          range: (0, 400),
        );
        final copy = original.copyWithRange(0, 800);

        expect(copy.domain, original.domain);
        expect(copy.range, (0.0, 800.0));
      });
    });

    group('properties', () {
      test('isInverted returns true for inverted range', () {
        final normal = LinearScale(domain: (0, 100), range: (0, 400));
        final inverted = LinearScale(domain: (0, 100), range: (400, 0));

        expect(normal.isInverted, false);
        expect(inverted.isInverted, true);
      });

      test('rangeExtent returns absolute range size', () {
        final normal = LinearScale(domain: (0, 100), range: (0, 400));
        final inverted = LinearScale(domain: (0, 100), range: (400, 0));

        expect(normal.rangeExtent, 400);
        expect(inverted.rangeExtent, 400);
      });
    });
  });

  group('LogScale', () {
    group('basic scaling', () {
      test('scales logarithmically', () {
        final scale = LogScale(
          domain: (1, 1000),
          range: (0, 300),
        );

        expect(scale.scale(1), 0);
        expect(scale.scale(10), closeTo(100, 0.01));
        expect(scale.scale(100), closeTo(200, 0.01));
        expect(scale.scale(1000), 300);
      });

      test('handles different bases', () {
        final scale = LogScale(
          domain: (1, 8),
          range: (0, 300),
          base: 2,
        );

        expect(scale.scale(1), 0);
        expect(scale.scale(2), closeTo(100, 0.01));
        expect(scale.scale(4), closeTo(200, 0.01));
        expect(scale.scale(8), 300);
      });

      test('handles values less than or equal to zero', () {
        final scale = LogScale(
          domain: (1, 100),
          range: (0, 200),
        );

        expect(scale.scale(0), 0);
        expect(scale.scale(-10), 0);
      });
    });

    group('invert', () {
      test('inverts logarithmically', () {
        final scale = LogScale(
          domain: (1, 1000),
          range: (0, 300),
        );

        expect(scale.invert(0), closeTo(1, 0.01));
        expect(scale.invert(100), closeTo(10, 0.1));
        expect(scale.invert(200), closeTo(100, 1));
        expect(scale.invert(300), closeTo(1000, 1));
      });
    });

    group('ticks', () {
      test('generates power-of-base ticks', () {
        final scale = LogScale(
          domain: (1, 1000),
          range: (0, 300),
        );

        final ticks = scale.ticks();
        expect(ticks, contains(1));
        expect(ticks, contains(10));
        expect(ticks, contains(100));
        expect(ticks, contains(1000));
      });
    });

    group('clamping', () {
      test('clamps when enabled', () {
        final scale = LogScale(
          domain: (1, 100),
          range: (0, 200),
          clamp: true,
        );

        expect(scale.scale(1000), 200);
        expect(scale.scale(0.1), 0);
      });
    });
  });

  group('BandScale', () {
    group('basic scaling', () {
      test('divides range into bands', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C', 'D'],
          range: (0, 400),
        );

        expect(scale.bandwidth, closeTo(100, 1));
      });

      test('scales categories to positions', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.scale('A'), closeTo(0, 1));
        expect(scale.scale('B'), closeTo(100, 1));
        expect(scale.scale('C'), closeTo(200, 1));
      });

      test('returns range start for unknown values', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.scale('X'), 0);
      });
    });

    group('padding', () {
      test('applies inner padding between bands', () {
        final noPadding = BandScale<String>(
          domain: ['A', 'B'],
          range: (0, 200),
        );
        final withPadding = BandScale<String>(
          domain: ['A', 'B'],
          range: (0, 200),
          paddingInner: 0.5,
        );

        expect(withPadding.bandwidth, lessThan(noPadding.bandwidth));
      });

      test('applies outer padding at edges', () {
        final noPadding = BandScale<String>(
          domain: ['A', 'B'],
          range: (0, 200),
        );
        final withPadding = BandScale<String>(
          domain: ['A', 'B'],
          range: (0, 200),
          paddingOuter: 0.5,
        );

        expect(withPadding.scale('A'), greaterThan(noPadding.scale('A')));
      });
    });

    group('scaleCenter', () {
      test('returns center of band', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.scaleCenter('A'), closeTo(50, 1));
        expect(scale.scaleCenter('B'), closeTo(150, 1));
        expect(scale.scaleCenter('C'), closeTo(250, 1));
      });
    });

    group('invert', () {
      test('returns category for position', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.invert(50), 'A');
        expect(scale.invert(150), 'B');
        expect(scale.invert(250), 'C');
      });

      test('clamps to valid indices', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.invert(-100), 'A');
        expect(scale.invert(500), 'C');
      });
    });

    group('ticks', () {
      test('returns all domain values', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.ticks(), ['A', 'B', 'C']);
      });
    });

    group('properties', () {
      test('domainValues returns list of values', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.domainValues, ['A', 'B', 'C']);
      });

      test('domain returns first and last', () {
        final scale = BandScale<String>(
          domain: ['A', 'B', 'C'],
          range: (0, 300),
        );

        expect(scale.domain, ('A', 'C'));
      });
    });

    group('copy methods', () {
      test('withDomainList creates new scale', () {
        final original = BandScale<String>(
          domain: ['A', 'B'],
          range: (0, 200),
        );
        final copy = original.withDomainList(['X', 'Y', 'Z']);

        expect(copy.domainValues, ['X', 'Y', 'Z']);
        expect(copy.range, original.range);
      });
    });
  });

  group('TimeScale', () {
    group('basic scaling', () {
      test('scales dates to range', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 11);
        final scale = TimeScale(
          domain: (start, end),
          range: (0, 1000),
        );

        expect(scale.scale(start), 0);
        expect(scale.scale(end), 1000);
        expect(scale.scale(DateTime(2024, 1, 6)), closeTo(500, 1));
      });

      test('handles same date domain', () {
        final date = DateTime(2024, 1, 1);
        final scale = TimeScale(
          domain: (date, date),
          range: (0, 100),
        );

        expect(scale.scale(date), 0);
      });
    });

    group('invert', () {
      test('inverts range to dates', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 11);
        final scale = TimeScale(
          domain: (start, end),
          range: (0, 1000),
        );

        final inverted = scale.invert(500);
        expect(inverted.year, 2024);
        expect(inverted.month, 1);
        expect(inverted.day, 6);
      });
    });

    group('ticks', () {
      test('generates appropriate time ticks', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final scale = TimeScale(
          domain: (start, end),
          range: (0, 300),
        );

        final ticks = scale.ticks(count: 5);
        expect(ticks, isNotEmpty);
        expect(ticks.first.isAfter(start) || ticks.first.isAtSameMomentAs(start), true);
        expect(ticks.last.isBefore(end) || ticks.last.isAtSameMomentAs(end), true);
      });

      test('adapts interval to time span', () {
        // Day-level span
        final dayScale = TimeScale(
          domain: (DateTime(2024, 1, 1), DateTime(2024, 1, 10)),
          range: (0, 100),
        );
        final dayTicks = dayScale.ticks(count: 5);
        expect(dayTicks.length, greaterThan(1));

        // Hour-level span
        final hourScale = TimeScale(
          domain: (DateTime(2024, 1, 1, 0), DateTime(2024, 1, 1, 12)),
          range: (0, 100),
        );
        final hourTicks = hourScale.ticks(count: 5);
        expect(hourTicks.length, greaterThan(1));
      });
    });

    group('tickFormatter', () {
      test('formats based on time span', () {
        // Year span - should show years
        final yearScale = TimeScale(
          domain: (DateTime(2020, 1, 1), DateTime(2024, 1, 1)),
          range: (0, 100),
        );
        final yearFormatter = yearScale.tickFormatter();
        expect(yearFormatter(DateTime(2022, 6, 15)), contains('2022'));

        // Day span - should show month/day
        final dayScale = TimeScale(
          domain: (DateTime(2024, 1, 1), DateTime(2024, 1, 15)),
          range: (0, 100),
        );
        final dayFormatter = dayScale.tickFormatter();
        expect(dayFormatter(DateTime(2024, 1, 5)), contains('5'));
      });
    });

    group('clamping', () {
      test('clamps when enabled', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 11);
        final scale = TimeScale(
          domain: (start, end),
          range: (0, 100),
          clamp: true,
        );

        expect(scale.scale(DateTime(2023, 12, 1)), 0);
        expect(scale.scale(DateTime(2024, 2, 1)), 100);
      });
    });

    group('copy methods', () {
      test('copyWithDomain creates new scale', () {
        final original = TimeScale(
          domain: (DateTime(2024, 1, 1), DateTime(2024, 1, 31)),
          range: (0, 100),
        );
        final copy = original.copyWithDomain(
          DateTime(2024, 2, 1),
          DateTime(2024, 2, 28),
        );

        expect(copy.domain.$1.month, 2);
        expect(copy.range, original.range);
      });

      test('copyWithRange creates new scale', () {
        final original = TimeScale(
          domain: (DateTime(2024, 1, 1), DateTime(2024, 1, 31)),
          range: (0, 100),
        );
        final copy = original.copyWithRange(0, 500);

        expect(copy.domain, original.domain);
        expect(copy.range, (0.0, 500.0));
      });
    });
  });
}
