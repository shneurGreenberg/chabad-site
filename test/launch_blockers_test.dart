import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/public_content.dart';
import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/data/snapshot.dart';
import 'package:flutter_app/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('program cards with an empty title in every language are hidden', () {
    final blank = Program(
      id: 'id1001',
      title: {'he': '', 'en': '  ', 'ru': ''},
      description: {'he': 'תיאור', 'en': 'text', 'ru': 'текст'},
      schedule: {'he': '', 'en': '', 'ru': ''},
      audience: {'he': '', 'en': '', 'ru': ''},
    );
    final named = Program(
      id: 'school',
      title: {'he': 'בית ספר', 'en': 'School', 'ru': 'Школа'},
      description: {'he': '', 'en': '', 'ru': ''},
      schedule: {'he': '', 'en': '', 'ru': ''},
      audience: {'he': '', 'en': '', 'ru': ''},
    );
    final visible = [blank, named].where(programIsPublic).toList();
    expect(visible, hasLength(1));
    expect(visible.single.id, 'school');
  });

  test('addLead keeps the message on the lead', () async {
    final repo = AppRepository();
    repo.addLead(
      name: 'Lea',
      email: 'lea@example.com',
      phone: '+7 900',
      topic: {'he': 'שורשים', 'en': 'Roots', 'ru': 'Корни'},
      message: 'Хочу узнать о еврейских корнях',
    );
    final lead = repo.leads.first;
    expect(lead.message, 'Хочу узнать о еврейских корнях');
    final restored = leadFromJson(leadToJson(lead));
    expect(restored.message, lead.message);
    expect(restored.name, 'Lea');
    await Future<void>.delayed(const Duration(seconds: 4));
    repo.dispose();
  });

  test('packaged demo shiurim are hidden when Firestore has none', () {
    final demo = [
      Shiur(
        id: 'soon',
        title: {
          'he': 'הכנה לימים הנוראים',
          'en': 'Preparing for the High Holidays',
          'ru': 'Подготовка к Высоким праздникам',
        },
        rabbi: {'he': '', 'en': 'Rabbi Zaklos', 'ru': 'Заклос'},
        topic: {'he': '', 'en': '', 'ru': ''},
        durationMinutes: 45,
        date: DateTime(2026, 9, 1),
      ),
      Shiur(
        id: 'jacobson',
        title: {'he': 'מסע', 'en': 'Jacobson', 'ru': 'Джейкобсон'},
        rabbi: {'he': '', 'en': 'Rabbi YY Jacobson', 'ru': ''},
        topic: {'he': '', 'en': '', 'ru': ''},
        durationMinutes: 75,
        date: DateTime(2021, 6, 1),
        youtubeUrl: 'https://www.youtube.com/watch?v=OVKQe9fiNu8',
      ),
      Shiur(
        id: 'friedman',
        title: {'he': 'נח', 'en': 'Friedman', 'ru': 'Фридман'},
        rabbi: {'he': '', 'en': 'Rabbi Manis Friedman', 'ru': ''},
        topic: {'he': '', 'en': '', 'ru': ''},
        durationMinutes: 53,
        date: DateTime(2021, 12, 1),
        youtubeUrl: 'https://www.youtube.com/watch?v=nQlfH43G1mg',
      ),
    ];
    expect(visibleShiurim(demo), isEmpty);
    expect(shiurimAfterSnapshot(demo, null), isEmpty);
    expect(shiurimAfterSnapshot(demo, const []), isEmpty);

    final real = {
      'id': 'live',
      'title': {'he': 'שיעור', 'en': 'Live class', 'ru': 'Живой урок'},
      'rabbi': {'he': '', 'en': 'Zaklos', 'ru': 'Заклос'},
      'topic': {'he': '', 'en': '', 'ru': ''},
      'durationMinutes': 30,
      'date': '2026-09-28T00:00:00.000',
      'youtubeUrl': 'https://www.youtube.com/watch?v=abcdefghijk',
    };
    final kept = shiurimAfterSnapshot(demo, [
      {
        'id': 'jacobson',
        'title': {'en': 'Jacobson'},
        'rabbi': {'en': ''},
        'topic': {'en': ''},
        'youtubeUrl': 'https://youtu.be/OVKQe9fiNu8',
        'date': '2021-06-01T00:00:00.000',
      },
      real,
    ]);
    expect(kept, hasLength(1));
    expect(kept.single.id, 'live');
  });

  test('the toothbrush album is hidden from the public gallery', () {
    final toothbrush = GalleryPhoto(
      id: 'brushes',
      event: {'he': 'Зубные щетки', 'en': 'Зубные щетки', 'ru': 'Зубные щетки'},
      year: 2026,
      tags: const ['2026'],
      color: 0xFF1D4ED8,
    );
    final holiday = GalleryPhoto(
      id: 'rh',
      event: {'he': 'ראש השנה', 'en': 'Rosh Hashanah', 'ru': 'Рош ха-Шана'},
      year: 2026,
      tags: const [],
      color: 0xFF1D4ED8,
    );
    final visible = [toothbrush, holiday].where(galleryAlbumIsPublic).toList();
    expect(visible, hasLength(1));
    expect(visible.single.id, 'rh');
    expect(galleryAlbumIsPublic(toothbrush), isFalse);
  });

  test('past holiday news and a Hebrew-only item stay off the Russian home strip', () {
    final today = DateTime(2026, 9, 29);
    final holidays = NewsArticle(
      id: 'id1000',
      title: {
        'he': 'חגים',
        'en': 'High holidays',
        'ru': 'Рош ха-Шана и Йом Кипур',
      },
      body: {
        'he': '',
        'en': '',
        'ru': 'Приглашаем 11–13.9 и 20–21.9',
      },
      date: DateTime(2026, 9, 1),
      category: {'he': '', 'en': '', 'ru': 'Праздник'},
    );
    final hebrewOnly = NewsArticle(
      id: 'id1055',
      title: {
        'he': 'פתיחת בית הספר',
        'en': 'פתיחת בית הספר',
        'ru': 'פתיחת בית הספר',
      },
      body: {
        'he': 'פתיחת בית הספר',
        'en': 'פתיחת בית הספר',
        'ru': 'פתיחת בית הספר',
      },
      date: DateTime(2026, 9, 1),
      category: {'he': '', 'en': '', 'ru': 'Telegram'},
    );
    final current = NewsArticle(
      id: 'sukkot',
      title: {'he': 'סוכות', 'en': 'Sukkot', 'ru': 'Суккот в общине'},
      body: {'he': '', 'en': '', 'ru': 'Встреча 1.10'},
      date: DateTime(2026, 9, 28),
      category: {'he': '', 'en': '', 'ru': 'Новости'},
    );
    final strip = featuredHomeNews([holidays, hebrewOnly, current], 'ru', today);
    expect(strip.map((a) => a.id), ['sukkot']);
    expect(featuredOnHomeStrip(hebrewOnly, 'he', today), isTrue);
  });

  test('placeholder city and the dead website host are rewritten for visitors', () {
    expect(displayCityName('מיקום נוכחי', 'ru'), 'Новосибирск');
    expect(displayCityName('מיקום נוכחי', 'en'), 'Novosibirsk');
    expect(displayCityName('מיקום נוכחי', 'he'), 'נובוסיבירסק');
    expect(displayCityName('Новосибирск', 'he'), 'Новосибирск');
    expect(publicWebsiteUrl('http://jewishsib.com'), liveCommunitySite);
    expect(publicWebsiteUrl('https://www.jewishsib.com/old'), liveCommunitySite);
    expect(
      publicWebsiteUrl('https://t.me/jewishsib'),
      'https://t.me/jewishsib',
    );
  });

  test('nameless free products and seeded donors are not public', () {
    final blank = Product(
      id: 'id1011',
      name: {'he': '', 'en': '', 'ru': ''},
      description: {'he': '', 'en': '', 'ru': ''},
      price: 0,
      category: ProductCategory.judaica,
    );
    final priced = Product(
      id: 'candles',
      name: {'he': 'פמוטים', 'en': 'Candlesticks', 'ru': 'Подсвечники'},
      description: {'he': '', 'en': '', 'ru': ''},
      price: 89,
      category: ProductCategory.judaica,
    );
    expect([blank, priced].where(productIsPublic).map((p) => p.id), ['candles']);
    expect(
      donationIsSeededDemo(Donation(
        id: 'a',
        donor: 'M. Roth',
        amount: 1000,
        campaign: {'en': 'Lev'},
        date: DateTime(2026, 9, 1),
      )),
      isTrue,
    );
    expect(
      donationIsSeededDemo(Donation(
        id: 'b',
        donor: 'Real Guest',
        amount: 500,
        campaign: {'en': 'School'},
        date: DateTime(2026, 9, 1),
      )),
      isFalse,
    );
  });
}
