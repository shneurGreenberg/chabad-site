import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App boots and shows the home hero', (WidgetTester tester) async {
    await tester.pumpWidget(const ChabadApp());
    await tester.pump(const Duration(milliseconds: 300));

    // The site name (Hebrew default) should appear somewhere on the home page.
    expect(find.textContaining('חב"ד'), findsWidgets);
  });
}
