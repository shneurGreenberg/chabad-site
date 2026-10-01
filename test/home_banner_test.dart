import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/data/snapshot.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/models.dart';
import 'package:flutter_app/pages/client/home_page.dart';
import 'package:flutter_app/widgets/common.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  test('hero slideshow keeps images and video', () {
    final banner = PageBanner(
      imageUrl: 'assets/images/beit-menachem-1.jpg',
      extra: [
        BannerSlide(videoUrl: 'https://www.youtube.com/watch?v=OVKQe9fiNu8'),
      ],
    );
    expect(banner.allSlides, hasLength(2));
    expect(banner.allSlides.last.hasVideo, isTrue);
    expect(heroSlideshowInterval, const Duration(seconds: 3));

    final restored = bannerFromJson(bannerToJson(banner));
    expect(restored.extra.single.videoUrl, contains('OVKQe9fiNu8'));
    expect(restored.allSlides, hasLength(2));
  });

  testWidgets('hero slides rotate every 3 seconds', (tester) async {
    final banner = PageBanner(
      bytes: png,
      extra: [
        BannerSlide(bytes: png),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: BannerFill(banner: banner, positioned: false),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('banner-slide-0')), findsOneWidget);

    await tester.pump(heroSlideshowInterval);
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byKey(const ValueKey('banner-slide-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('banner-slide-0')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('news banner slides in from the side and rotates', (tester) async {
    final articles = [
      NewsArticle(
        id: 'one',
        title: {'he': 'א', 'en': 'One', 'ru': 'Новость один'},
        body: {'he': '', 'en': '', 'ru': ''},
        date: DateTime(2026, 1, 2),
        category: {'he': '', 'en': '', 'ru': ''},
      ),
      NewsArticle(
        id: 'two',
        title: {'he': 'ב', 'en': 'Two', 'ru': 'Новость два'},
        body: {'he': '', 'en': '', 'ru': ''},
        date: DateTime(2026, 1, 1),
        category: {'he': '', 'en': '', 'ru': ''},
      ),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('ru'),
        child: MaterialApp(
          home: Scaffold(
            body: HomeNewsTicker(
              articles: articles,
              interval: const Duration(seconds: 1),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Новость один'), findsOneWidget);
    expect(find.text('Новость два'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final slides = tester.widgetList<SlideTransition>(find.byType(SlideTransition));
    expect(
      slides.any((slide) => slide.position.value.dx > 0.5 && slide.position.value.dy == 0),
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Новость два'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-news-ticker')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('registration banner opens the register page', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: HomeRegisterBanner()),
        ),
        GoRoute(
          path: '/contact',
          builder: (_, _) => const Scaffold(body: Text('registration-page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('ru'),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(
      find.text(
        'Если у вас еврейское происхождение или еврейские корни — зарегистрируйтесь и узнайте, какие программы и услуги мы можем предложить.',
      ),
      findsOneWidget,
    );
    expect(find.text('Зарегистрироваться'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-register-banner')));
    await tester.pumpAndSettle();
    expect(find.text('registration-page'), findsOneWidget);
  });

  testWidgets('home page hides the large times block and shows cemetery and kaddish tiles',
      (tester) async {
    final repo = AppRepository();

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: HomePage()),
          ),
        ),
        GoRoute(
          path: '/cemetery',
          builder: (_, _) => const Scaffold(body: Text('cemetery-page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController('ru')),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Суббота'), findsNothing);
    expect(find.text('Зажигание свечей'), findsNothing);
    expect(find.text('04:52'), findsNothing);
    expect(find.text('Времена'), findsOneWidget);

    expect(find.byKey(const ValueKey('home-cemetery-tile')), findsOneWidget);
    expect(find.text('Кладбище'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-tourist-tile')), findsOneWidget);
    expect(find.text('Информация для туристов'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-kaddish-tile')), findsOneWidget);
    expect(find.text('Проект «Кадиш»'), findsOneWidget);
    expect(
      find.text(
        'В синагоге есть экран, на котором поминают и вспоминают усопших евреев общины и города.',
      ),
      findsOneWidget,
    );
    expect(
      LocaleController('he').t('home.kaddish.body'),
      'בבית הכנסת יש מסך שבו מזכירים וזוכרים את הנפטרים היהודים של הקהילה ושל העיר.',
    );
    expect(
      LocaleController('en').t('home.kaddish.body'),
      'The synagogue has a screen where they mention and remember the Jewish deceased of the community and of the city.',
    );

    final kaddish = find.byKey(const ValueKey('home-kaddish-tile'));
    await tester.ensureVisible(kaddish);
    await tester.pump();
    await tester.tap(kaddish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('cemetery-page'),
      findsOneWidget,
      reason: 'uri=${router.routeInformationProvider.value.uri}',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    repo.dispose();
    await tester.pump();
  });
}
