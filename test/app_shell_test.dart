import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/common.dart';
import 'package:flutter_app/widgets/hover.dart';
import 'package:flutter_app/widgets/playful_icons.dart';
import 'package:flutter_app/widgets/site_scaffold.dart';
import 'package:flutter_app/widgets/whatsapp_icon.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> openHarness(
    WidgetTester tester, {
    required TextDirection direction,
    required bool leading,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: direction,
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            final fromEnd = menuDrawerFromEnd(context, leadingButton: leading);
            const menu = Drawer(child: Text('menu-body'));
            return Scaffold(
              drawer: fromEnd ? null : menu,
              endDrawer: fromEnd ? menu : null,
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      openMenuDrawer(context, leadingButton: leading),
                  child: const Text('open-menu'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('hebrew phone drawer opens from the hamburger side', (tester) async {
    await openHarness(tester, direction: TextDirection.rtl, leading: false);
    expect(tester.getTopLeft(find.byType(Drawer)).dx, lessThan(24));
  });

  testWidgets('english phone drawer opens from the right', (tester) async {
    await openHarness(tester, direction: TextDirection.ltr, leading: false);
    expect(tester.getTopLeft(find.byType(Drawer)).dx, greaterThan(200));
  });

  testWidgets('leading menu button opens from the left in english', (tester) async {
    await openHarness(tester, direction: TextDirection.ltr, leading: true);
    expect(tester.getTopLeft(find.byType(Drawer)).dx, lessThan(24));
  });

  testWidgets('leading menu button opens from the right in hebrew', (tester) async {
    await openHarness(tester, direction: TextDirection.rtl, leading: true);
    expect(tester.getTopLeft(find.byType(Drawer)).dx, greaterThan(200));
  });

  testWidgets('zmanim icon follows color and does not spin', (tester) async {
    const first = Color(0xFF112233);
    const next = Color(0xFFC9A227);

    Future<void> show(Color color) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlayfulIcon(Icons.schedule, color: color, size: 24),
            ),
          ),
        ),
      );
    }

    await show(first);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, first);
    expect(
      find.descendant(
        of: find.byType(PlayfulIcon),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );

    await show(next);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, next);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.schedule)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      find.descendant(
        of: find.byType(PlayfulIcon),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, next);
  });

  testWidgets('whatsapp mark has no plate behind the glyph', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: WhatsAppIcon.brandGreen,
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('wa-mark'),
              child: WhatsAppIcon(size: 48, color: Colors.white),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ClipOval), findsNothing);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('wa-mark')),
    );
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    );
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final data = bytes!.buffer.asUint8List();
    const side = 48;

    int at(int x, int y) => (y * side + x) * 4;

    // A square plate would paint the corner solid. The bubble only clips it.
    expect(data[at(0, 0) + 3], lessThan(250), reason: 'corner is a solid plate');
    expect(data[at(side - 1, side - 1) + 3], lessThan(250));

    var opaque = 0;
    var innerClear = 0;
    var innerInk = 0;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        final a = data[at(x, y) + 3];
        if (a > 200) opaque++;
        if (a > 250) {
          expect(data[at(x, y)], greaterThan(240));
          expect(data[at(x, y) + 1], greaterThan(240));
          expect(data[at(x, y) + 2], greaterThan(240));
        }
        if (x > 14 && x < 34 && y > 10 && y < 30) {
          if (a < 16) innerClear++;
          if (a > 200) innerInk++;
        }
      }
    }
    expect(opaque, greaterThan(80));
    expect(opaque, lessThan(side * side * 0.62), reason: 'glyph filled a plate');
    expect(innerClear, greaterThan(20), reason: 'bubble interior is a plate');
    expect(innerInk, greaterThan(10), reason: 'handset is missing');
  });

  testWidgets('rounded buttons keep their corners as the pointer leaves', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverLift(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Contact'),
                  ),
                ),
                const SizedBox(height: 16),
                HoverLift(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {},
                    child: const Text('White'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    void expectRounded() {
      for (final material in tester.widgetList<Material>(find.byType(Material))) {
        final shape = material.shape;
        if (shape is RoundedRectangleBorder) {
          final radius = shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
          expect(radius, greaterThan(8));
        }
      }
      for (final box in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
        final decoration = box.decoration;
        if (decoration is! BoxDecoration) continue;
        final shadows = decoration.boxShadow;
        if (shadows == null || shadows.isEmpty) continue;
        final radius = decoration.borderRadius?.resolve(TextDirection.ltr).topLeft.x ?? 0;
        expect(radius, greaterThan(8), reason: 'hover shadow went square');
      }
    }

    expectRounded();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('White')));
    await tester.pump();
    expectRounded();
    await gesture.moveTo(Offset.zero);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectRounded();
    }
  });

  testWidgets('phone footer skips the menu and desktop keeps a short one', (tester) async {
    final repo = AppRepository();
    var disposed = false;
    addTearDown(() {
      if (!disposed) repo.dispose();
    });

    Future<void> show({required Size size, required String lang}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final direction = lang == 'he' ? TextDirection.rtl : TextDirection.ltr;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleController(lang)),
            ChangeNotifierProvider.value(value: repo),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            builder: (context, child) => Directionality(
              textDirection: direction,
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SiteShell(
                    currentRoute: '/',
                    child: Text('page-body'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await show(size: const Size(390, 844), lang: 'he');
    expect(find.text('page-body'), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('תפריט')).dx, lessThan(180));
    await tester.tap(find.byTooltip('תפריט'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Drawer), findsOneWidget);
    expect(tester.getTopLeft(find.byType(Drawer)).dx, lessThan(24));
    expect(find.text('קישורים'), findsNothing);
    expect(find.text('עקבו אחרינו'), findsOneWidget);

    await show(size: const Size(1400, 900), lang: 'he');
    expect(find.text('קישורים'), findsOneWidget);
    expect(find.text('עקבו אחרינו'), findsOneWidget);
    expect(find.textContaining('כל הזכויות שמורות'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    disposed = true;
    await tester.pump(const Duration(seconds: 1));
  });
}
