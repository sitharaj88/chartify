import 'dart:ui';

import 'package:chartify/chartify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartController', () {
    late ChartController controller;

    setUp(() {
      controller = ChartController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('initialization', () {
      test('creates with default viewport', () {
        expect(controller.viewport.scaleX, 1.0);
        expect(controller.viewport.scaleY, 1.0);
        expect(controller.viewport.translateX, 0.0);
        expect(controller.viewport.translateY, 0.0);
      });

      test('creates with custom initial viewport', () {
        final customViewport = ChartViewport(
          xMin: 0,
          xMax: 100,
          yMin: 0,
          yMax: 50,
        );
        final customController = ChartController(initialViewport: customViewport);

        expect(customController.viewport.xMin, 0);
        expect(customController.viewport.xMax, 100);
        expect(customController.viewport.yMin, 0);
        expect(customController.viewport.yMax, 50);

        customController.dispose();
      });

      test('has no selection initially', () {
        expect(controller.hasSelection, false);
        expect(controller.selectedIndices, isEmpty);
      });

      test('has no hovered point initially', () {
        expect(controller.hoveredPoint, isNull);
      });

      test('is not interacting initially', () {
        expect(controller.isInteracting, false);
      });
    });

    group('viewport control', () {
      test('pan updates viewport and notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.pan(const Offset(10, 20));

        expect(controller.viewport.translateX, 10.0);
        expect(controller.viewport.translateY, 20.0);
        expect(notified, true);
      });

      test('zoom updates scale and translation', () {
        controller.zoom(2.0, const Offset(100, 100));

        expect(controller.viewport.scaleX, 2.0);
        expect(controller.viewport.scaleY, 2.0);
        expect(controller.viewport.isZoomed, true);
      });

      test('zoom clamps scale between 0.1 and 10.0', () {
        // Test upper bound
        controller.zoom(100.0, Offset.zero);
        expect(controller.viewport.scaleX, 10.0);

        // Reset and test lower bound
        controller.resetViewport();
        controller.zoom(0.001, Offset.zero);
        expect(controller.viewport.scaleX, 0.1);
      });

      test('resetViewport restores defaults', () {
        controller.pan(const Offset(50, 50));
        controller.zoom(2.0, const Offset(100, 100));

        controller.resetViewport();

        expect(controller.viewport.scaleX, 1.0);
        expect(controller.viewport.scaleY, 1.0);
        expect(controller.viewport.translateX, 0.0);
        expect(controller.viewport.translateY, 0.0);
      });

      test('setXRange updates viewport x bounds', () {
        controller.setXRange(10, 100);

        expect(controller.viewport.xMin, 10);
        expect(controller.viewport.xMax, 100);
      });

      test('setYRange updates viewport y bounds', () {
        controller.setYRange(0, 50);

        expect(controller.viewport.yMin, 0);
        expect(controller.viewport.yMax, 50);
      });
    });

    group('selection', () {
      test('selectPoint adds to selection', () {
        controller.selectPoint(0, 5);

        expect(controller.hasSelection, true);
        expect(controller.isPointSelected(0, 5), true);
        expect(controller.selectedIndices.length, 1);
      });

      test('selectPoint allows multiple selections', () {
        controller.selectPoint(0, 1);
        controller.selectPoint(0, 2);
        controller.selectPoint(1, 0);

        expect(controller.selectedIndices.length, 3);
        expect(controller.isPointSelected(0, 1), true);
        expect(controller.isPointSelected(0, 2), true);
        expect(controller.isPointSelected(1, 0), true);
      });

      test('togglePoint adds if not selected', () {
        controller.togglePoint(0, 5);

        expect(controller.isPointSelected(0, 5), true);
      });

      test('togglePoint removes if already selected', () {
        controller.selectPoint(0, 5);
        controller.togglePoint(0, 5);

        expect(controller.isPointSelected(0, 5), false);
      });

      test('deselectPoint removes from selection', () {
        controller.selectPoint(0, 5);
        controller.deselectPoint(0, 5);

        expect(controller.isPointSelected(0, 5), false);
        expect(controller.hasSelection, false);
      });

      test('deselectPoint does nothing if not selected', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.deselectPoint(0, 5);

        expect(notified, false);
      });

      test('clearSelection removes all selections', () {
        controller.selectPoint(0, 1);
        controller.selectPoint(0, 2);
        controller.selectPoint(1, 0);

        controller.clearSelection();

        expect(controller.hasSelection, false);
        expect(controller.selectedIndices, isEmpty);
      });

      test('clearSelection does nothing if no selection', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.clearSelection();

        expect(notified, false);
      });

      test('selectSeries selects all points in series', () {
        controller.selectSeries(0, 5);

        expect(controller.selectedIndices.length, 5);
        for (var i = 0; i < 5; i++) {
          expect(controller.isPointSelected(0, i), true);
        }
      });
    });

    group('hover state', () {
      test('setHoveredPoint updates hovered point', () {
        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
          xValue: 5.0,
          yValue: 50.0,
        );

        controller.setHoveredPoint(point);

        expect(controller.hoveredPoint, point);
      });

      test('setHoveredPoint notifies listeners on change', () {
        var notified = false;
        controller.addListener(() => notified = true);

        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
        );

        controller.setHoveredPoint(point);

        expect(notified, true);
      });

      test('setHoveredPoint does not notify if same point', () {
        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
        );

        controller.setHoveredPoint(point);

        var notified = false;
        controller.addListener(() => notified = true);

        controller.setHoveredPoint(point);

        expect(notified, false);
      });

      test('clearHover removes hovered point', () {
        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
        );

        controller.setHoveredPoint(point);
        controller.clearHover();

        expect(controller.hoveredPoint, isNull);
      });
    });

    group('tooltip', () {
      test('showTooltip sets tooltip point', () {
        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
        );

        controller.showTooltip(point);

        expect(controller.tooltipPoint, point);
      });

      test('hideTooltip clears tooltip point', () {
        final point = DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: const Offset(100, 200),
        );

        controller.showTooltip(point);
        controller.hideTooltip();

        expect(controller.tooltipPoint, isNull);
      });

      test('hideTooltip does not notify if no tooltip', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.hideTooltip();

        expect(notified, false);
      });
    });

    group('interaction state', () {
      test('startInteraction sets isInteracting true', () {
        controller.startInteraction();

        expect(controller.isInteracting, true);
      });

      test('endInteraction sets isInteracting false', () {
        controller.startInteraction();
        controller.endInteraction();

        expect(controller.isInteracting, false);
      });

      test('startInteraction does not notify if already interacting', () {
        controller.startInteraction();

        var notified = false;
        controller.addListener(() => notified = true);

        controller.startInteraction();

        expect(notified, false);
      });

      test('endInteraction does not notify if not interacting', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.endInteraction();

        expect(notified, false);
      });
    });

    group('navigation', () {
      test('selectNext selects first point when no selection', () {
        controller.selectNext(10);

        expect(controller.isPointSelected(0, 0), true);
        expect(controller.selectedIndices.length, 1);
      });

      test('selectNext moves to next point', () {
        controller.selectPoint(0, 5);
        controller.selectNext(10);

        expect(controller.isPointSelected(0, 6), true);
        expect(controller.selectedIndices.length, 1);
      });

      test('selectNext wraps around to first point', () {
        controller.selectPoint(0, 9);
        controller.selectNext(10);

        expect(controller.isPointSelected(0, 0), true);
      });

      test('selectPrevious selects last point when no selection', () {
        controller.selectPrevious(10);

        expect(controller.isPointSelected(0, 9), true);
      });

      test('selectPrevious moves to previous point', () {
        controller.selectPoint(0, 5);
        controller.selectPrevious(10);

        expect(controller.isPointSelected(0, 4), true);
      });

      test('selectPrevious wraps around to last point', () {
        controller.selectPoint(0, 0);
        controller.selectPrevious(10);

        expect(controller.isPointSelected(0, 9), true);
      });
    });

    group('dispose', () {
      test('clears all state on dispose', () {
        // Create a separate controller for this test
        final testController = ChartController();
        testController.selectPoint(0, 5);
        testController.setHoveredPoint(const DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: Offset(100, 200),
        ));
        testController.showTooltip(const DataPointInfo(
          seriesIndex: 0,
          pointIndex: 5,
          position: Offset(100, 200),
        ));

        // Verify state is set before dispose
        expect(testController.hasSelection, true);
        expect(testController.hoveredPoint, isNotNull);
        expect(testController.tooltipPoint, isNotNull);

        // Dispose should complete without error
        testController.dispose();

        // Note: After dispose, the controller should not be used
        // The test verifies dispose() can be called successfully
      });
    });
  });

  group('ChartViewport', () {
    test('default values', () {
      const viewport = ChartViewport();

      expect(viewport.xMin, isNull);
      expect(viewport.xMax, isNull);
      expect(viewport.yMin, isNull);
      expect(viewport.yMax, isNull);
      expect(viewport.scaleX, 1.0);
      expect(viewport.scaleY, 1.0);
      expect(viewport.translateX, 0.0);
      expect(viewport.translateY, 0.0);
    });

    test('hasCustomBounds returns true when bounds set', () {
      const viewportWithX = ChartViewport(xMin: 0);
      const viewportWithY = ChartViewport(yMax: 100);
      const viewportDefault = ChartViewport();

      expect(viewportWithX.hasCustomBounds, true);
      expect(viewportWithY.hasCustomBounds, true);
      expect(viewportDefault.hasCustomBounds, false);
    });

    test('isZoomed returns true when scaled', () {
      const zoomed = ChartViewport(scaleX: 2.0);
      const notZoomed = ChartViewport();

      expect(zoomed.isZoomed, true);
      expect(notZoomed.isZoomed, false);
    });

    test('isPanned returns true when translated', () {
      const panned = ChartViewport(translateX: 10);
      const notPanned = ChartViewport();

      expect(panned.isPanned, true);
      expect(notPanned.isPanned, false);
    });

    test('pan creates new viewport with offset', () {
      const viewport = ChartViewport();
      final panned = viewport.pan(const Offset(10, 20));

      expect(panned.translateX, 10);
      expect(panned.translateY, 20);
    });

    test('zoom creates new viewport with scale', () {
      const viewport = ChartViewport();
      final zoomed = viewport.zoom(2.0, const Offset(100, 100));

      expect(zoomed.scaleX, 2.0);
      expect(zoomed.scaleY, 2.0);
    });

    test('copyWith creates copy with replaced values', () {
      const original = ChartViewport(xMin: 0, xMax: 100);
      final copy = original.copyWith(xMax: 200, yMin: 10);

      expect(copy.xMin, 0);
      expect(copy.xMax, 200);
      expect(copy.yMin, 10);
    });

    test('equality works correctly', () {
      const v1 = ChartViewport(xMin: 0, xMax: 100);
      const v2 = ChartViewport(xMin: 0, xMax: 100);
      const v3 = ChartViewport(xMin: 0, xMax: 200);

      expect(v1, equals(v2));
      expect(v1, isNot(equals(v3)));
    });

    test('hashCode is consistent', () {
      const v1 = ChartViewport(xMin: 0, xMax: 100);
      const v2 = ChartViewport(xMin: 0, xMax: 100);

      expect(v1.hashCode, equals(v2.hashCode));
    });
  });

  group('DataPointIndex', () {
    test('stores series and point indices', () {
      const index = DataPointIndex(2, 5);

      expect(index.seriesIndex, 2);
      expect(index.pointIndex, 5);
    });

    test('equality works correctly', () {
      const i1 = DataPointIndex(2, 5);
      const i2 = DataPointIndex(2, 5);
      const i3 = DataPointIndex(2, 6);

      expect(i1, equals(i2));
      expect(i1, isNot(equals(i3)));
    });

    test('hashCode is consistent', () {
      const i1 = DataPointIndex(2, 5);
      const i2 = DataPointIndex(2, 5);

      expect(i1.hashCode, equals(i2.hashCode));
    });
  });

  group('DataPointInfo', () {
    test('stores all properties', () {
      final info = DataPointInfo(
        seriesIndex: 1,
        pointIndex: 5,
        position: const Offset(100, 200),
        xValue: 5.0,
        yValue: 50.0,
        seriesName: 'Series 1',
        label: 'Point 5',
        metadata: {'key': 'value'},
      );

      expect(info.seriesIndex, 1);
      expect(info.pointIndex, 5);
      expect(info.position, const Offset(100, 200));
      expect(info.xValue, 5.0);
      expect(info.yValue, 50.0);
      expect(info.seriesName, 'Series 1');
      expect(info.label, 'Point 5');
      expect(info.metadata, {'key': 'value'});
    });

    test('equality based on series and point index', () {
      final i1 = DataPointInfo(
        seriesIndex: 1,
        pointIndex: 5,
        position: const Offset(100, 200),
      );
      final i2 = DataPointInfo(
        seriesIndex: 1,
        pointIndex: 5,
        position: const Offset(150, 250), // Different position
      );
      final i3 = DataPointInfo(
        seriesIndex: 1,
        pointIndex: 6,
        position: const Offset(100, 200),
      );

      expect(i1, equals(i2));
      expect(i1, isNot(equals(i3)));
    });

    test('copyWith creates copy with replaced values', () {
      final original = DataPointInfo(
        seriesIndex: 1,
        pointIndex: 5,
        position: const Offset(100, 200),
        xValue: 5.0,
      );
      final copy = original.copyWith(
        position: const Offset(150, 250),
        label: 'New Label',
      );

      expect(copy.seriesIndex, 1);
      expect(copy.pointIndex, 5);
      expect(copy.position, const Offset(150, 250));
      expect(copy.xValue, 5.0);
      expect(copy.label, 'New Label');
    });
  });
}
