import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/pages/admin/admin.dart';

class _RecordingRepo extends AppRepository {
  int confirms = 0;
  int galleryAtConfirm = 0;

  @override
  Future<String?> persistAdminConfirm() async {
    confirms++;
    galleryAtConfirm = gallery.length;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gallery confirm persists the album without a second click',
      (tester) async {
    final repo = _RecordingRepo();
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
        child: const MaterialApp(home: Scaffold(body: ManageGalleryPanel())),
      ),
    );
    await tester.pump();

    final before = repo.gallery.length;
    await tester.tap(find.widgetWithText(FilledButton, 'הוספה'));
    await tester.pumpAndSettle();

    expect(find.text('שמור לשרת'), findsNothing);
    expect(find.text('Save to server'), findsNothing);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'שמירה'));
    await tester.pumpAndSettle();

    expect(repo.confirms, 1);
    expect(repo.galleryAtConfirm, before + 1);
    expect(repo.gallery.length, before + 1);

    await tester.pump(const Duration(seconds: 4));
    repo.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
