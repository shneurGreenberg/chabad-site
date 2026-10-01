import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/section_heading.dart';
import 'package:flutter_app/widgets/common.dart';
import 'package:flutter_app/widgets/site_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('typing a category name returns that menu section', () async {
    final repo = AppRepository();
    for (final lang in supportedLangs) {
      final name = uiText('nav.programs', lang);
      final hits = repo.searchSite(name, lang);
      expect(
        hits.where((h) => h.groupKey == 'nav.menu' && h.route == '/programs'),
        isNotEmpty,
        reason: '$lang ($name)',
      );
    }
    final gallery = repo.searchSite('גלריה', 'he');
    expect(
      gallery.where((h) => h.groupKey == 'nav.menu' && h.route == '/gallery'),
      isNotEmpty,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    repo.dispose();
  });

  test('programs section heading routes to the programs page', () {
    expect(sectionHeadingRoute('תוכניות הקהילה'), '/programs');
    expect(
      sectionHeadingRoute(uiText('home.programs.title', 'en')),
      '/programs',
    );
    expect(
      sectionHeadingRoute(uiText('home.programs.title', 'ru')),
      '/programs',
    );
    expect(sectionHeadingRoute(uiText('home.news.title', 'he')), '/news');
    expect(sectionHeadingRoute(uiText('home.events.title', 'en')), '/events');
    expect(sectionHeadingRoute(uiText('home.zmanim.title', 'ru')), '/zmanim');
    expect(sectionHeadingRoute(uiText('nav.gallery', 'he')), '/gallery');
    expect(sectionHeadingRoute(uiText('home.explore', 'en')), isNull);
  });

  testWidgets('programs heading opens the programs page', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: SectionHeader(title: 'תוכניות הקהילה'),
          ),
        ),
        GoRoute(
          path: '/programs',
          builder: (context, state) =>
              const Scaffold(body: Text('programs-destination')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(tester.getSize(find.byType(TextButton)).height, lessThan(44));
    await tester.tap(find.text('תוכניות הקהילה'));
    await tester.pumpAndSettle();
    expect(find.text('programs-destination'), findsOneWidget);
  });

  testWidgets('header search preview is wide enough to read', (tester) async {
    final repo = AppRepository();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleController>.value(
            value: LocaleController('he'),
          ),
          ChangeNotifierProvider<AppRepository>.value(value: repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: HeaderSearch(),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'גלריה');
    await tester.pump();
    expect(find.text('גלריה'), findsWidgets);
    expect(
      tester.widgetList<SizedBox>(find.byType(SizedBox)).any(
            (box) => box.width == headerSearchPreviewWidth,
          ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    repo.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
