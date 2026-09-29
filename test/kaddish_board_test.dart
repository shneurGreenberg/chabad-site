import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/data/kaddish.dart';
import 'package:flutter_app/l10n/strings.dart';
import 'package:flutter_app/pages/client/cemetery_page.dart';
import 'package:flutter_app/services/yahrzeit.dart';

const _peopleUrl = '/s/novosibirsk/api/people';

void main() {
  test('non-empty photo uses the kaddish /photos/ file', () {
    expect(kaddishPhotoFileUrl(''), '');
    expect(kaddishPhotoFileUrl('   '), '');
    expect(
      kaddishPhotoFileUrl('148.jpg'),
      'https://synagogue-kadish-shneur.amvera.io/photos/148.jpg',
    );
    final served = photoUrlFromKaddish('148.jpg', {
      'x': 44.74,
      'y': 29.23,
      'zoom': 2,
    });
    expect(
      served,
      'https://synagogue-kadish-shneur.amvera.io/photos/148.jpg?w=280&cx=44.74&cy=29.23&cz=2',
    );
    final requested = Uri.parse(sameOriginKaddishPhoto(served));
    expect(requested.path, endsWith('/kaddish-photos/148.jpg'));
    expect(requested.query, 'w=280&cx=44.74&cy=29.23&cz=2');
    final empty = graveFromKaddish({
      'id': 1,
      'name': 'Брусиловский Виктор сын Александра',
      'photo': '',
      'gregorianDateOfDeath': {'month': 8, 'date': 15, 'year': 2009},
    });
    expect(empty.photoUrl, isNull);
  });

  test('board load never requests the people URL', () async {
    final urls = <String>[];
    final graves = await fetchKaddishBoardGraves(
      get: (url, timeout) async {
        urls.add(url);
        expect(timeout.inSeconds, lessThan(22));
        expect(url.contains(_peopleUrl), isFalse);
        if (url == kaddishBoardApi) {
          return const KaddishResponse(
            200,
            '{"people":[{"id":4,"name":"Кац","gregorianDateOfDeath":{"month":1,"date":22,"year":2007},"photo":"148.jpg","title":"учитель"}]}',
          );
        }
        if (url == kaddishBoardFullApi) {
          return const KaddishResponse(
            200,
            '{"people":[{"id":4,"name":"Кац Арнольд сын Михаила","gregorianDateOfDeath":{"month":1,"date":22,"year":2007},"photo":"148.jpg","photoCrop":{"x":44.74,"y":29.23,"zoom":2},"title":"учитель","text":"биография"}]}',
          );
        }
        fail('unexpected URL $url');
      },
    );

    expect(urls, [kaddishBoardApi, kaddishBoardFullApi]);
    expect(urls.any((url) => url.contains(_peopleUrl)), isFalse);
    expect(graves, hasLength(1));
    final grave = graves.single;
    expect(grave.id, 'kaddish-4');
    expect(grave.name, 'Кац Арнольд сын Михаила');
    expect(grave.deathYear, 2007);
    expect(grave.deathMonth, 1);
    expect(grave.deathDay, 22);
    expect(
      grave.photoUrl,
      startsWith('https://synagogue-kadish-shneur.amvera.io/photos/148.jpg'),
    );
    expect(grave.notes['ru'], 'учитель');
    expect(grave.biographyHtml, 'биография');
    expect(grave.hebrewName, isEmpty);
    expect(grave.section, isEmpty);
    expect(grave.row, isEmpty);
    expect(grave.hebrewDeathLabel, 'ג׳ בשבט');
  });

  test('slim=0 is skipped when the short board already has text', () async {
    final urls = <String>[];
    final graves = await fetchKaddishBoardGraves(
      get: (url, timeout) async {
        urls.add(url);
        expect(url.contains(_peopleUrl), isFalse);
        return const KaddishResponse(
          200,
          '{"people":[{"id":4,"name":"Кац","gregorianDateOfDeath":{"month":1,"date":22,"year":2007},"text":"есть"}]}',
        );
      },
    );
    expect(urls, [kaddishBoardApi]);
    expect(graves.single.biographyHtml, 'есть');
    expect(graves.single.hebrewDeathLabel, 'ג׳ בשבט');
  });

  test('a direct board error does not start the proxy chain', () async {
    final urls = <String>[];
    final graves = await fetchKaddishBoardGraves(
      get: (url, timeout) async {
        urls.add(url);
        expect(url.contains(_peopleUrl), isFalse);
        return const KaddishResponse(404, 'missing');
      },
    );
    expect(urls, [kaddishBoardApi]);
    expect(graves, isEmpty);
  });

  test('a failed direct board uses one short proxy', () async {
    final calls = <(String, Duration)>[];
    final graves = await fetchKaddishBoardGraves(
      get: (url, timeout) async {
        calls.add((url, timeout));
        expect(url.contains(_peopleUrl), isFalse);
        final proxied = url.contains('corsproxy.io');
        if (!proxied && url == kaddishBoardApi) return null;
        if (proxied && !url.contains('slim')) {
          expect(timeout, kaddishProxyTimeout);
          return const KaddishResponse(
            200,
            '{"people":[{"id":7,"name":"Иван","gregorianDateOfDeath":{"month":5,"date":14,"year":1948},"photo":"7.jpg"}]}',
          );
        }
        if (!proxied && url == kaddishBoardFullApi) return null;
        return const KaddishResponse(500, '');
      },
    );

    final proxies = calls.where((call) => call.$1.contains('corsproxy.io'));
    expect(proxies, hasLength(1));
    expect(calls.first.$1, kaddishBoardApi);
    expect(calls.first.$2, kaddishDirectTimeout);
    expect(calls.any((call) => call.$1.contains(_peopleUrl)), isFalse);
    expect(graves.single.id, 'kaddish-7');
    expect(graves.single.hebrewDeathLabel, contains('אייר'));
    expect(graves.single.hebrewName, isEmpty);
    expect(graves.single.section, isEmpty);
    expect(graves.single.row, isEmpty);
  });

  test('a Gregorian date produces a Hebrew yahrzeit', () {
    final shevat = hebrewYahrzeitFromGregorian(year: 2007, month: 1, day: 22);
    expect(shevat, isNotNull);
    expect(shevat!.year, 5767);
    expect(shevat.day, 3);
    expect(shevat.monthName, 'שבט');
    expect(shevat.label, 'ג׳ בשבט');

    final adar1 = hebrewYahrzeitFromGregorian(year: 2000, month: 2, day: 29);
    expect(adar1!.label, 'כ״ג באדר א׳');

    final adar2 = hebrewYahrzeitFromGregorian(year: 2024, month: 3, day: 24);
    expect(adar2!.label, 'י״ד באדר ב׳');

    final tishrei = hebrewYahrzeitFromGregorian(year: 2023, month: 10, day: 7);
    expect(tishrei!.year, 5784);
    expect(tishrei.day, 22);
    expect(tishrei.monthName, 'תשרי');
    expect(tishrei.label, 'כ״ב בתשרי');
  });

  testWidgets(
    'cemetery roster shows loading, then empty only after it finishes',
    (tester) async {
      Future<void> pump({
        required bool loading,
        required bool sourceEmpty,
        required bool filteredEmpty,
      }) {
        return tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => LocaleController('en'),
            child: MaterialApp(
              home: Scaffold(
                body: CemeteryRosterSlot(
                  loading: loading,
                  sourceEmpty: sourceEmpty,
                  filteredEmpty: filteredEmpty,
                  child: const Text('roster'),
                ),
              ),
            ),
          ),
        );
      }

      await pump(loading: true, sourceEmpty: true, filteredEmpty: true);
      expect(find.byKey(CemeteryRosterSlot.loadingKey), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byKey(CemeteryRosterSlot.emptyKey), findsNothing);
      expect(find.text('Nothing to show yet'), findsNothing);

      await pump(loading: false, sourceEmpty: true, filteredEmpty: true);
      expect(find.byKey(CemeteryRosterSlot.loadingKey), findsNothing);
      expect(find.byKey(CemeteryRosterSlot.emptyKey), findsOneWidget);
      expect(find.text('Nothing to show yet'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      await pump(loading: false, sourceEmpty: false, filteredEmpty: false);
      expect(find.text('roster'), findsOneWidget);
      expect(find.byKey(CemeteryRosterSlot.emptyKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
