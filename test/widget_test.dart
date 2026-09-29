import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/services/web_prefs.dart';
import 'package:flutter_app/widgets/boot_splash.dart';
import 'package:flutter_app/widgets/brand.dart';

void main() {
  testWidgets('App boots in Russian with the community logo', (tester) async {
    removePref('lang');
    await tester.pumpWidget(const ChabadApp());
    await tester.pump();

    expect(find.byType(ChabadEmblem), findsWidgets);
    final loading = find.text('Загрузка...');
    final city = find.textContaining('Новосибирск');
    expect(
      loading.evaluate().isNotEmpty || city.evaluate().isNotEmpty,
      isTrue,
    );
    if (loading.evaluate().isNotEmpty) {
      expect(find.byType(CommunityBootSplash), findsOneWidget);
    }
    // Let boot timeouts finish, then unmount so repository timers are cancelled.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
