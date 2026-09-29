import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/models.dart';
import 'package:flutter_app/pages/client/gallery_page.dart';
import 'package:flutter_app/services/emblem_cache.dart';
import 'package:flutter_app/services/web_prefs.dart';
import 'package:flutter_app/widgets/admin_fields.dart';
import 'package:flutter_app/widgets/boot_splash.dart';
import 'package:flutter_app/widgets/brand.dart';
import 'package:flutter_app/widgets/whatsapp_icon.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  tearDown(clearEmblemSplashCache);

  test('Russian is the default until a language is chosen', () {
    removePref('lang');
    expect(LocaleController().lang, 'ru');
    expect(LocaleController().t('common.loading'), 'Загрузка...');

    final chosen = LocaleController();
    chosen.setLang('he');
    expect(LocaleController().lang, 'he');
    expect(LocaleController().direction, TextDirection.rtl);

    chosen.setLang('en');
    expect(LocaleController().lang, 'en');

    removePref('lang');
    expect(LocaleController().lang, 'ru');
    expect(LocaleController().direction, TextDirection.ltr);
  });

  test('emblem splash cache round-trips the configured logo', () {
    writeEmblemSplashCache(png);
    expect(readEmblemSplashCache(), png);
    expect(readPref(emblemSplashCacheKey), startsWith('data:image/jpeg;base64,'));
    clearEmblemSplashCache();
    expect(readEmblemSplashCache(), isNull);
  });

  testWidgets('boot splash shows the cached community logo', (tester) async {
    writeEmblemSplashCache(png);
    final repo = AppRepository();
    expect(repo.emblemBytes, isNotNull);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController('ru')),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: const MaterialApp(home: CommunityBootSplash()),
      ),
    );

    expect(find.byType(ChabadEmblem), findsOneWidget);
    expect(find.text('Загрузка...'), findsOneWidget);
    final image = tester.widget<Image>(find.descendant(
      of: find.byType(ChabadEmblem),
      matching: find.byType(Image),
    ));
    expect(image.image, isA<MemoryImage>());
    await tester.pump(const Duration(seconds: 4));
    repo.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('WhatsApp icon uses the brand asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WhatsAppIcon(size: 32))),
    );
    expect(find.bySemanticsLabel('WhatsApp'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    expect(provider, isA<AssetImage>());
    expect((provider as AssetImage).assetName, 'assets/images/whatsapp.png');
  });

  testWidgets('gallery lightbox arrows, thumbnails, and keyboard', (tester) async {
    final shots = [
      GalleryShot(id: 'a', imageBytes: png),
      GalleryShot(id: 'b', imageBytes: png),
      GalleryShot(id: 'c', imageBytes: png),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('ru'),
        child: MaterialApp(
          home: GalleryLightbox(shots: shots, initialIndex: 0),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-prev')), findsNothing);
    expect(find.byKey(const ValueKey('gallery-thumb-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-next')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gallery-thumb-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('escape closes the gallery lightbox', (tester) async {
    final shots = [
      GalleryShot(id: 'a', imageBytes: png),
      GalleryShot(id: 'b', imageBytes: png),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('ru'),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => GalleryLightbox(shots: shots, initialIndex: 0),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(GalleryLightbox), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(GalleryLightbox), findsNothing);
  });

  testWidgets('upload overlay shows progress without covering the whole app', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('ru'),
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('still-here'),
                ),
                GalleryUploadOverlay(done: 1, total: 4),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('gallery-upload-progress')), findsOneWidget);
    expect(find.text('1 из 4'), findsOneWidget);
    expect(find.text('Загрузка фото…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('still-here'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('gallery upload yields between images instead of blocking the batch', () async {
    final repo = AppRepository();
    final album = GalleryPhoto(
      id: 'album-test',
      event: const {'he': '', 'en': 'Album', 'ru': 'Альбом'},
      year: 2026,
      tags: const [],
      color: 0xFF1D4ED8,
    );
    final gates = <Completer<Uint8List>>[
      Completer<Uint8List>(),
      Completer<Uint8List>(),
    ];
    var calls = 0;
    final seen = <int>[];
    final future = repo.addGalleryShots(
      album,
      [Uint8List.fromList([1]), Uint8List.fromList([2])],
      yieldFrame: () async {},
      compress: (bytes) {
        final gate = gates[calls];
        calls++;
        return gate.future;
      },
      onProgress: (done, total) {
        seen.add(done);
        expect(total, 2);
      },
    );

    await pumpEventQueue();
    expect(calls, 1);
    expect(album.photos, isEmpty);
    expect(seen, contains(0));

    gates[0].complete(Uint8List.fromList([9, 9]));
    await pumpEventQueue();
    expect(album.photos, hasLength(1));
    expect(calls, 2);

    gates[1].complete(Uint8List.fromList([8, 8]));
    await pumpEventQueue();
    await future;
    expect(album.photos, hasLength(2));
    expect(seen.last, 2);
    repo.dispose();
  });
}
