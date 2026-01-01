import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SafeZoneApp());

    // Verify that we have the home screen
    expect(find.text('Trang chủ'), findsWidgets);
  });
}
