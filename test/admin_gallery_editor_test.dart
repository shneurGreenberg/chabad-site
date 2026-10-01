import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/models.dart';
import 'package:flutter_app/pages/admin/admin.dart';
import 'package:flutter_app/widgets/admin_fields.dart';

class _SlowRepo extends AppRepository {
  final gate = Completer<void>();
  int confirms = 0;

  @override
  Future<String?> persistAdminConfirm() {
    confirms++;
    return gate.future.then((_) => null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('he');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ru');
  });

  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<void> pumpPanel(WidgetTester tester, Widget panel, AppRepository repo) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController('he')),
          ChangeNotifierProvider<AppRepository>.value(value: repo),
        ],
        child: MaterialApp(home: Scaffold(body: panel)),
      ),
    );
    await tester.pump();
  }

  Future<void> expectSaveClosesEditor(WidgetTester tester, Widget panel) async {
    final repo = _SlowRepo();
    addTearDown(() {
      if (!repo.gate.isCompleted) repo.gate.complete();
    });
    await pumpPanel(tester, panel, repo);
    await tester.tap(find.widgetWithText(FilledButton, 'הוספה'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'שמירה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(repo.confirms, 1);
    expect(repo.gate.isCompleted, isFalse);
    repo.gate.complete();
    await tester.pump(const Duration(seconds: 4));
    repo.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('saving news closes the edit window before the cloud write finishes',
      (tester) async {
    await expectSaveClosesEditor(tester, const ManageNewsPanel());
  });

  testWidgets('saving a program closes the edit window before the cloud write finishes',
      (tester) async {
    await expectSaveClosesEditor(tester, const ManageProgramsPanel());
  });

  testWidgets('saving a gallery album closes the edit window before the cloud write finishes',
      (tester) async {
    await expectSaveClosesEditor(tester, const ManageGalleryPanel());
  });

  testWidgets('every uploaded photo is listed and can be deleted or starred',
      (tester) async {
    final photos = [
      for (var i = 0; i < 8; i++) GalleryShot(id: 's$i', imageBytes: png),
    ];
    String? removed;
    String? cover;
    int? draggedTo;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController('he'),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AlbumPhotosPicker(
                photos: photos,
                onAdd: () async {},
                onRemove: (id) => removed = id,
                onMakeCover: (id) => cover = id,
                onReorder: (oldIndex, newIndex) => draggedTo = newIndex,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(ValueKey('album-shot-s$i')), findsOneWidget);
      expect(find.byKey(ValueKey('album-delete-s$i')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('album-delete-s3')));
    expect(removed, 's3');
    await tester.tap(find.byKey(const ValueKey('album-cover-s5')));
    expect(cover, 's5');
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(8));
    expect(draggedTo, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('preparing photos shows before the upload progress animation',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        key: const ValueKey('he'),
        create: (_) => LocaleController('he'),
        child: const MaterialApp(
          home: GalleryUploadOverlay(done: 0, total: 12, preparing: true),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('gallery-upload-preparing')), findsOneWidget);
    expect(find.text('מכין תמונות'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-upload-progress')), findsNothing);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        key: const ValueKey('ru'),
        create: (_) => LocaleController('ru'),
        child: const MaterialApp(
          home: GalleryUploadOverlay(done: 0, total: 12, preparing: true),
        ),
      ),
    );
    expect(find.text('Готовим фото'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        key: const ValueKey('en'),
        create: (_) => LocaleController('en'),
        child: const MaterialApp(
          home: GalleryUploadOverlay(done: 1, total: 12),
        ),
      ),
    );
    expect(find.text('Preparing photos'), findsNothing);
    expect(find.text('Uploading photos…'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-upload-progress')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('a starred photo or a drag to first becomes the album cover', () async {
    final repo = AppRepository();
    addTearDown(repo.dispose);
    final first = Uint8List.fromList([1]);
    final second = Uint8List.fromList([2, 2]);
    final album = GalleryPhoto(
      id: 'album',
      event: const {'he': 'אירוע', 'en': 'Event', 'ru': 'Событие'},
      year: 2026,
      tags: const [],
      color: 0xFF1D4ED8,
      photos: [
        GalleryShot(id: 'a', imageBytes: first),
        GalleryShot(id: 'b', imageBytes: second),
        GalleryShot(id: 'c', imageBytes: Uint8List.fromList([3])),
      ],
    );
    repo.setGalleryCover(album, 'b');
    expect(album.photos.first.id, 'b');
    expect(album.imageBytes, second);
    expect(album.coverBytes, second);

    repo.moveGalleryShot(album, 2, 0);
    expect(album.photos.first.id, 'c');
    expect(album.imageBytes, album.photos.first.imageBytes);

    repo.deleteGalleryShot(album, 'c');
    expect(album.photos.map((s) => s.id), ['b', 'a']);
    expect(album.imageBytes, second);
  });
}
