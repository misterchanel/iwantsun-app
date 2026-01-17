// This is a basic Flutter widget test for IWantSun app.

import 'package:flutter_test/flutter_test.dart';
import 'package:iwantsun/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const IWantSunApp());

    // Wait for any async operations
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that the app renders without crashing
    expect(find.byType(IWantSunApp), findsOneWidget);
  });
}
