import 'package:chartify/chartify.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a test theme
ChartThemeData _testTheme() => ChartThemeData.light();

void main() {
  group('FilterableLegendConfig', () {
    test('has correct default values', () {
      const config = FilterableLegendConfig();

      expect(config.enableFiltering, true);
      expect(config.enableIsolation, true);
      expect(config.showHiddenAsGrayed, true);
      expect(config.hiddenOpacity, 0.3);
      expect(config.animateVisibilityChanges, true);
      expect(config.animationDuration, const Duration(milliseconds: 200));
    });

    test('copyWith creates copy with changes', () {
      const original = FilterableLegendConfig();
      final copy = original.copyWith(
        enableFiltering: false,
        hiddenOpacity: 0.5,
      );

      expect(copy.enableFiltering, false);
      expect(copy.hiddenOpacity, 0.5);
      expect(copy.enableIsolation, original.enableIsolation);
      expect(copy.showHiddenAsGrayed, original.showHiddenAsGrayed);
      expect(copy.animateVisibilityChanges, original.animateVisibilityChanges);
      expect(copy.animationDuration, original.animationDuration);
    });

    test('copyWith with all values', () {
      const original = FilterableLegendConfig();
      final copy = original.copyWith(
        enableFiltering: false,
        enableIsolation: false,
        showHiddenAsGrayed: false,
        hiddenOpacity: 0.1,
        animateVisibilityChanges: false,
        animationDuration: const Duration(milliseconds: 100),
      );

      expect(copy.enableFiltering, false);
      expect(copy.enableIsolation, false);
      expect(copy.showHiddenAsGrayed, false);
      expect(copy.hiddenOpacity, 0.1);
      expect(copy.animateVisibilityChanges, false);
      expect(copy.animationDuration, const Duration(milliseconds: 100));
    });
  });

  group('ChartController series visibility', () {
    late ChartController controller;

    setUp(() {
      controller = ChartController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('all series visible by default', () {
      expect(controller.hiddenSeriesIndices, isEmpty);
      expect(controller.hasHiddenSeries, false);
    });

    test('isSeriesVisible returns true for all indices by default', () {
      for (var i = 0; i < 10; i++) {
        expect(controller.isSeriesVisible(i), true);
      }
    });

    test('isSeriesHidden returns false for all indices by default', () {
      for (var i = 0; i < 10; i++) {
        expect(controller.isSeriesHidden(i), false);
      }
    });

    test('hideSeries adds index to hidden set', () {
      controller.hideSeries(0);

      expect(controller.isSeriesVisible(0), false);
      expect(controller.isSeriesHidden(0), true);
      expect(controller.hiddenSeriesIndices, contains(0));
      expect(controller.hasHiddenSeries, true);
    });

    test('hideSeries notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.hideSeries(0);

      expect(notified, true);
    });

    test('hideSeries does not notify if already hidden', () {
      controller.hideSeries(0);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.hideSeries(0);

      expect(notified, false);
    });

    test('showSeries removes index from hidden set', () {
      controller.hideSeries(0);
      controller.showSeries(0);

      expect(controller.isSeriesVisible(0), true);
      expect(controller.isSeriesHidden(0), false);
      expect(controller.hiddenSeriesIndices, isNot(contains(0)));
    });

    test('showSeries notifies listeners', () {
      controller.hideSeries(0);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.showSeries(0);

      expect(notified, true);
    });

    test('showSeries does not notify if already visible', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.showSeries(0);

      expect(notified, false);
    });

    test('toggleSeriesVisibility toggles from visible to hidden', () {
      controller.toggleSeriesVisibility(0);

      expect(controller.isSeriesVisible(0), false);
    });

    test('toggleSeriesVisibility toggles from hidden to visible', () {
      controller.hideSeries(0);
      controller.toggleSeriesVisibility(0);

      expect(controller.isSeriesVisible(0), true);
    });

    test('toggleSeriesVisibility notifies listeners', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggleSeriesVisibility(0);
      controller.toggleSeriesVisibility(0);

      expect(notifyCount, 2);
    });

    test('showAllSeries shows all hidden series', () {
      controller.hideSeries(0);
      controller.hideSeries(1);
      controller.hideSeries(2);

      controller.showAllSeries();

      expect(controller.hiddenSeriesIndices, isEmpty);
      expect(controller.hasHiddenSeries, false);
    });

    test('showAllSeries notifies listeners', () {
      controller.hideSeries(0);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.showAllSeries();

      expect(notified, true);
    });

    test('showAllSeries does not notify if no series hidden', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.showAllSeries();

      expect(notified, false);
    });

    test('isolateSeries hides all other series', () {
      controller.isolateSeries(1, 5);

      expect(controller.isSeriesVisible(0), false);
      expect(controller.isSeriesVisible(1), true);
      expect(controller.isSeriesVisible(2), false);
      expect(controller.isSeriesVisible(3), false);
      expect(controller.isSeriesVisible(4), false);
    });

    test('isolateSeries notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.isolateSeries(1, 5);

      expect(notified, true);
    });

    test('getVisibleSeriesIndices returns correct indices', () {
      controller.hideSeries(1);
      controller.hideSeries(3);

      final visible = controller.getVisibleSeriesIndices(5);

      expect(visible, [0, 2, 4]);
    });

    test('getVisibleSeriesIndices returns all indices when none hidden', () {
      final visible = controller.getVisibleSeriesIndices(5);

      expect(visible, [0, 1, 2, 3, 4]);
    });

    test('hiddenSeriesIndices is unmodifiable', () {
      final indices = controller.hiddenSeriesIndices;

      expect(
        () => indices.add(0),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('multiple hide/show operations work correctly', () {
      controller.hideSeries(0);
      controller.hideSeries(1);
      controller.showSeries(0);
      controller.hideSeries(2);
      controller.showSeries(1);

      expect(controller.isSeriesVisible(0), true);
      expect(controller.isSeriesVisible(1), true);
      expect(controller.isSeriesVisible(2), false);
    });
  });

  group('FilterableLegendExtension', () {
    late ChartController controller;

    setUp(() {
      controller = ChartController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('createLegendItems generates correct items', () {
      final names = ['Series A', 'Series B', 'Series C'];
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];

      final items = controller.createLegendItems(names, colors);

      expect(items.length, 3);
      expect(items[0].label, 'Series A');
      expect(items[0].color, const Color(0xFFFF0000));
      expect(items[0].isVisible, true);
      expect(items[1].label, 'Series B');
      expect(items[2].label, 'Series C');
    });

    test('createLegendItems reflects visibility state', () {
      controller.hideSeries(1);

      final names = ['A', 'B', 'C'];
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];

      final items = controller.createLegendItems(names, colors);

      expect(items[0].isVisible, true);
      expect(items[1].isVisible, false);
      expect(items[2].isVisible, true);
    });

    test('createLegendItems uses default color for missing colors', () {
      final names = ['A', 'B', 'C'];
      final colors = [const Color(0xFFFF0000)];

      final items = controller.createLegendItems(names, colors);

      expect(items[0].color, const Color(0xFFFF0000));
      expect(items[1].color, const Color(0xFF999999)); // Default
      expect(items[2].color, const Color(0xFF999999)); // Default
    });
  });

  group('FilterableLegend widget', () {
    late ChartController controller;

    setUp(() {
      controller = ChartController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders legend items', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
                LegendItem(
                  label: 'Series B',
                  color: Color(0xFF00FF00),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Series A'), findsOneWidget);
      expect(find.text('Series B'), findsOneWidget);
    });

    testWidgets('tapping legend item toggles visibility', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
            ),
          ),
        ),
      );

      expect(controller.isSeriesVisible(0), true);

      await tester.tap(find.text('Series A'));
      await tester.pumpAndSettle();

      expect(controller.isSeriesVisible(0), false);
    });

    testWidgets('onVisibilityChanged callback is called', (tester) async {
      int? changedIndex;
      bool? newVisibility;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              onVisibilityChanged: (index, isVisible) {
                changedIndex = index;
                newVisibility = isVisible;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Series A'));
      await tester.pumpAndSettle();

      expect(changedIndex, 0);
      expect(newVisibility, false);
    });

    testWidgets('filtering can be disabled', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              filterConfig: const FilterableLegendConfig(
                enableFiltering: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Series A'));
      await tester.pumpAndSettle();

      // Series should still be visible since filtering is disabled
      expect(controller.isSeriesVisible(0), true);
    });

    testWidgets('renders in vertical layout', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
                LegendItem(
                  label: 'Series B',
                  color: Color(0xFF00FF00),
                ),
              ],
              layout: LegendLayout.vertical,
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders in wrap layout', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
                LegendItem(
                  label: 'Series B',
                  color: Color(0xFF00FF00),
                ),
              ],
              layout: LegendLayout.wrap,
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('renders in horizontal layout with scroll', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              layout: LegendLayout.horizontal,
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('hidden items are grayed out when configured', (tester) async {
      controller.hideSeries(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              filterConfig: const FilterableLegendConfig(
                showHiddenAsGrayed: true,
              ),
            ),
          ),
        ),
      );

      // Item should still be visible (grayed out)
      expect(find.text('Series A'), findsOneWidget);
    });

    testWidgets('hidden items are hidden when showHiddenAsGrayed is false',
        (tester) async {
      controller.hideSeries(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              filterConfig: const FilterableLegendConfig(
                showHiddenAsGrayed: false,
              ),
            ),
          ),
        ),
      );

      // Item should be hidden (SizedBox.shrink)
      expect(find.text('Series A'), findsNothing);
    });

    testWidgets('updates when controller changes', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChartTheme(
            data: _testTheme(),
            child: FilterableLegend(
              controller: controller,
              items: const [
                LegendItem(
                  label: 'Series A',
                  color: Color(0xFFFF0000),
                ),
              ],
              filterConfig: const FilterableLegendConfig(
                showHiddenAsGrayed: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Series A'), findsOneWidget);

      controller.hideSeries(0);
      await tester.pumpAndSettle();

      expect(find.text('Series A'), findsNothing);
    });
  });
}
