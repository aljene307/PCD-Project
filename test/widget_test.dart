import 'package:flutter_test/flutter_test.dart';

import 'package:ardhi/main.dart';

void main() {
  testWidgets('App boots without exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ArdhiApp());
    // One pump is enough to verify the widget tree builds.
    await tester.pump();
    expect(find.text('AgriSense'), findsOneWidget);
    // Drain any pending flutter_animate timers before tearing down.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
