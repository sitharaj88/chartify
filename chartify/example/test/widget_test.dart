import 'package:flutter_test/flutter_test.dart';

import 'package:chartify_example/main.dart';

void main() {
  testWidgets('Chart gallery loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChartifyExampleApp());

    // Verify that the gallery title is shown.
    expect(find.text('Chartify Gallery'), findsOneWidget);

    // Verify that chart examples are listed.
    expect(find.text('Simple Line Chart'), findsOneWidget);
  });
}
