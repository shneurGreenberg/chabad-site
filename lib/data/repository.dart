import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../services/cloud_sync.dart';
import '../services/image_compress.dart';
import '../services/location_zmanim.dart';
import '../services/persist.dart';
import '../services/telegram.dart';
import '../services/web_prefs.dart';
import 'snapshot.dart';

/// In-memory data store with mock content for the whole site.
///
/// In production most of this content (especially [leads]) would be served by
/// an external CRM / backend. Here everything lives in memory so the admin and
/// client sides can be demonstrated end-to-end. Admin edits update the same
/// store the client reads, so changes appear live.
class AppRepository extends ChangeNotifier {
  AppRepository() {
    TelegramService.instance.loadSaved();
    _restoreLocation();
    Future<void>.microtask(_boot);
  }

  static const _contentSeed = 6;
  static const _snapKey = 'chabad_site_snapshot';
  static const _imgPrefix = 'chabad_img:';
  static const _quotaHe =
      'השמירה המקומית נכשלה — נסו תמונה קטנה יותר. התוכן נשמר גם ב-Firestore כשהשרת זמין.';
  static const _cloudDeniedHe =
      'השמירה לשרת נחסמה. בקונסול Firebase: Firestore → Rules — הדביקו את הכללים מהמנהל ולחצו Publish. Storage לא צריך.';
  static const _cloudFailHe =
      'השמירה לשרת נכשלה. התוכן נשמר מקומית בדפדפן. בדקו Firestore → Data אחרי שמירה מהמנהל.';
  static const _cloudUnavailableHe =
      'אין חיבור ל-Firestore. ודאו שהדאטאבייס (default) נוצר בפרויקט chabad-site-c60ae.';

  String? cloudError;
  DateTime? cloudOkAt;

  int _seq = 1000;
  String _newId() => 'id${_seq++}';
  bool _hydrated = false;
  Timer? _saveDebounce;
  void Function(String message)? onPersistWarning;

  /// Notify listeners after mutating a field directly (used by admin toggles).
  void refresh() => notifyListeners();

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_hydrated) _schedulePersist();
  }

  void _notifyUi() => super.notifyListeners();

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    await CloudSync.instance.init();
    await _hydrate();
    await _loadKaddishGraves();
    _hydrated = true;
    _notifyUi();
    try {
      await refreshTimes();
    } catch (_) {}
    unawaited(_pullCloud());
  }

  // ---------------------------------------------------------------------------
  // Contact / about
  // ---------------------------------------------------------------------------
  final ContactInfo contact = ContactInfo(
    name: {
      'he': 'בית חב״ד בית מנחם',
      'en': 'Chabad Beit Menachem',
      'ru': 'Хабад Бейт Менахем',
    },
    address: {
      'he': 'רחוב שצ׳טינקינה 68, נובוסיבירסק, רוסיה 630099',
      'en': '68 Shchetinkina St., Novosibirsk, Russia 630099',
      'ru': 'ул. Щетинкина, 68, Новосибирск, 630099',
    },
    phone: '+7 (383) 222-20-23',
    email: 'chabad.nsk@gmail.com',
    hours: [
      MapEntry(
        {'he': 'שני וחמישי', 'en': 'Monday & Thursday', 'ru': 'Понедельник и четверг'},
        'תפילה בבית הכנסת 09:30',
      ),
      MapEntry(
        {'he': 'שבת', 'en': 'Shabbat', 'ru': 'Суббота'},
        'תפילה 10:00 · סעודת שבת 13:00',
      ),
      MapEntry(
        {'he': 'המבנה', 'en': 'Building', 'ru': 'Здание'},
        'פתוח כל יום 09:00–17:00',
      ),
      MapEntry(
        {'he': 'סיורים', 'en': 'Tours', 'ru': 'Экскурсии'},
        'בתיאום מראש',
      ),
      MapEntry(
        {'he': 'יום ראשון', 'en': 'Sunday', 'ru': 'Воскресенье'},
        'פעילות ילדים בבית הכנסת',
      ),
      MapEntry(
        {'he': 'מקווה גברים', 'en': "Men's mikveh", 'ru': 'Мужская миква'},
        'בבוקר',
      ),
      MapEntry(
        {'he': 'מקווה נשים', 'en': "Women's mikveh", 'ru': 'Женская миква'},
        'בתיאום מראש',
      ),
    ],
    staff: [
      StaffContact(
        name: {
          'he': 'סנדר קרוגלוב',
          'en': 'Sender Kruglov',
          'ru': 'Сендер Круглов',
        },
        role: {
          'he': 'נשיא הקהילה',
          'en': 'President of the community',
          'ru': 'Президент общины',
        },
        phone: '+7 913 770-79-78',
      ),
      StaffContact(
        name: {
          'he': 'זויה',
          'en': 'Zoya',
          'ru': 'Зоя',
        },
        role: {
          'he': 'מזכירה',
          'en': 'Secretary',
          'ru': 'Секретарь',
        },
        phone: '+7 903 900-43-20',
      ),
    ],
  );

  String googleMapsApiKey = '';

  void setGoogleMapsApiKey(String key) {
    googleMapsApiKey = key.trim();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // News
  // ---------------------------------------------------------------------------
  late final List<NewsArticle> news = [
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'בית מנחם — בית הכנסת היחיד בנובוסיבירסק',
        'en': 'Beit Menachem — the only synagogue in Novosibirsk',
        'ru': 'Бейт Менахем — единственная синагога Новосибирска',
      },
      body: {
        'he':
            'ב־28 באוגוסט 2013 נחנך המרכז הקהילתי בית מנחם ברחוב שצ׳טינקינה 68. בטקס השתתפו הרב הראשי לרוסיה ברל לזר, ראש העיר דאז ולדימיר גורודצקי, ויותר מאלף אורחים. הבניין (~3,400 מ״ר) כולל בית כנסת, מקווה, ספרייה, אולם אירועים וחנות כשרה.',
        'en':
            'On 28 August 2013 the Beit Menachem community center opened at 68 Shchetinkina Street. Russia\'s Chief Rabbi Berel Lazar, then-mayor Vladimir Gorodetsky and more than a thousand guests attended. The ~3,400 m² building holds a synagogue, mikveh, library, hall and kosher shop.',
        'ru':
            '28 августа 2013 года открыт общинный центр «Бейт Менахем» на ул. Щетинкина, 68. На церемонии были главный раввин России Берл Лазар, мэр Владимир Городецкий и более тысячи гостей. В здании (~3400 м²) — синагога, миква, библиотека, зал и кошерный магазин.',
      },
      date: DateTime(2013, 8, 28),
      category: {'he': 'קהילה', 'en': 'Community', 'ru': 'Община'},
      imageColor: 0xFF1D4ED8,
      icon: Icons.synagogue,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'ליד אור אבנר — חינוך יהודי בנובוסיבירסק',
        'en': 'Or Avner — Jewish education in Novosibirsk',
        'ru': 'Лицей «Ор Авнер» — еврейское образование',
      },
      body: {
        'he':
            'מאז ספטמבר 2000 פועל ליד אור אבנר עם גן לגילאי 3–6, ביוזמת הרב זקלס. הילדים משתתפים בכל חגי הקהילה, ובוגרים ממשיכים ללימודים ברוסיה ובישראל. כתובת: רחוב שקספיר 9ב.',
        'en':
            'Since September 2000 Or Avner school and a preschool for ages 3–6 have operated at Rabbi Zaklos\'s initiative. Children take part in every communal holiday; graduates continue studies in Russia and Israel. Address: 9b Shakspira St.',
        'ru':
            'С сентября 2000 года работает лицей «Ор Авнер» с дошкольной группой 3–6 лет. Дети участвуют во всех праздниках общины; выпускники учатся в вузах России и Израиля. Адрес: ул. Шекспира, 9Б.',
      },
      date: DateTime(2000, 9, 1),
      category: {'he': 'חינוך', 'en': 'Education', 'ru': 'Образование'},
      imageColor: 0xFF0D9488,
      icon: Icons.school,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'מרכז «לב» לילדים עם צרכים מיוחדים',
        'en': 'Lev center for children with special needs',
        'ru': 'Центр «Лев» для детей с особыми потребностями',
      },
      body: {
        'he':
            'הקהילה מפעילה את מרכז האינטגרציה «לב» ברחוב שקספיר 9א — כולל בריכה ותוכניות חינוך משלים (Smart J) לילדים ולנוער עם מוגבלות.',
        'en':
            'The community runs the Lev integration center at 9a Shakspira Street, including a pool and extra education (Smart J) for children and youth with disabilities.',
        'ru':
            'При общине работает интеграционный центр «Лев» (ул. Шекспира, 9А) — бассейн и доп. образование Smart J для детей и молодёжи с ОВЗ.',
      },
      date: DateTime(2019, 1, 1),
      category: {'he': 'חסד', 'en': 'Chesed', 'ru': 'Хесед'},
      imageColor: 0xFFDB2777,
      icon: Icons.favorite,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'שליחות חב״ד בנובוסיבירסק מאז 1999',
        'en': 'Chabad shlichut in Novosibirsk since 1999',
        'ru': 'Миссия Хабада в Новосибирске с 1999 года',
      },
      body: {
        'he':
            'בסוף 1999 הגיע לעיר הרב שניאור זלמן זקלס, שליח הרבי ובוגר ישיבות בניו יורק, מילאנו וברזיל. יחד עם הרבנית מרים הם חידשו את החיים היהודיים בסיביר: תפילות, חגים, חסד וחינוך.',
        'en':
            'In late 1999 Rabbi Shneur Zalman Zaklos, a Chabad emissary trained in New York, Milan and Brazil, arrived in the city. Together with Rebbetzin Miriam they revived Jewish life in Siberia: prayer, holidays, chesed and education.',
        'ru':
            'В конце 1999 года в город прибыл раввин Шнеур Залман Заклос, посланник Ребе, учившийся в Нью-Йорке, Милане и Бразилии. Вместе с раббанит Мириам они возродили еврейскую жизнь Сибири.',
      },
      date: DateTime(1999, 12, 1),
      category: {'he': 'קהילה', 'en': 'Community', 'ru': 'Община'},
      imageColor: 0xFF9333EA,
      icon: Icons.volunteer_activism,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Location + live zmanim / parasha
  // ---------------------------------------------------------------------------
  SiteLocation location = SiteLocation.novosibirsk();

  void _restoreLocation() {
    final raw = readPref('chabad_site_location');
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final city = m['city'] as String? ?? '';
      final query = m['query'] as String? ?? '';
      if (city.contains('ירושלים') ||
          query.toLowerCase().contains('jerusalem')) {
        return;
      }
      location = SiteLocation(
        cityName: city.isEmpty ? location.cityName : city,
        query: query.isEmpty ? location.query : query,
        latitude: (m['lat'] as num?)?.toDouble() ?? location.latitude,
        longitude: (m['lon'] as num?)?.toDouble() ?? location.longitude,
        timezone: m['tz'] as String? ?? location.timezone,
      );
    } catch (_) {}
  }

  void _persistLocation() {
    writePref(
      'chabad_site_location',
      jsonEncode({
        'city': location.cityName,
        'query': location.query,
        'lat': location.latitude,
        'lon': location.longitude,
        'tz': location.timezone,
      }),
    );
  }

  Future<void> setLocation(SiteLocation next) async {
    location = next;
    _persistLocation();
    await refreshTimes();
  }

  Future<void> refreshTimes() async {
    final data = await LocationZmanimApi.fetchTimes(location);
    zmanim
      ..clear()
      ..addAll(data.zmanim);
    shabbat
      ..clear()
      ..addAll(data.shabbat);
    notifyListeners();
  }

  int importTelegramPosts(List<TelegramPost> posts) {
    var added = 0;
    for (final p in posts) {
      if (news.any((n) => n.telegramMessageId == p.messageId)) continue;
      final text = p.text.trim();
      final first = text.isEmpty
          ? 'פוסט מהטלגרם'
          : text.split('\n').first.trim();
      news.insert(
        0,
        NewsArticle(
          id: _newId(),
          title: {'he': first, 'en': first, 'ru': first},
          body: {'he': text, 'en': text, 'ru': text},
          date: p.date,
          category: {'he': 'טלגרם', 'en': 'Telegram', 'ru': 'Telegram'},
          imageColor: 0xFF0EA5E9,
          icon: Icons.send,
          source: NewsSource.telegram,
          imageBytes: p.imageBytes,
          telegramMessageId: p.messageId,
        ),
      );
      added++;
    }
    if (added > 0) {
      telegramBot.lastSync = DateTime.now();
      telegramBot.itemsSynced += added;
      notifyListeners();
    }
    return added;
  }

  // ---------------------------------------------------------------------------
  // Zmanim
  // ---------------------------------------------------------------------------
  final List<Zman> zmanim = [
    Zman(name: {'he': 'עלות השחר', 'en': 'Dawn', 'ru': 'Рассвет'}, time: '04:52'),
    Zman(
        name: {'he': 'הנץ החמה', 'en': 'Sunrise', 'ru': 'Восход'},
        time: '05:58'),
    Zman(
        name: {'he': 'סוף זמן ק"ש', 'en': 'Latest Shema', 'ru': 'Крайний Шма'},
        time: '09:14'),
    Zman(
        name: {'he': 'חצות היום', 'en': 'Midday', 'ru': 'Полдень'},
        time: '12:41'),
    Zman(
        name: {'he': 'מנחה גדולה', 'en': 'Mincha Gedola', 'ru': 'Минха гдола'},
        time: '13:15'),
    Zman(
        name: {'he': 'שקיעה', 'en': 'Sunset', 'ru': 'Закат'}, time: '19:24'),
    Zman(
        name: {'he': 'צאת הכוכבים', 'en': 'Nightfall', 'ru': 'Появление звёзд'},
        time: '19:52'),
  ];

  final Map<String, String> shabbat = {
    'candle': '19:06',
    'havdala': '20:18',
    'parasha_he': 'פרשת קדושים',
    'parasha_en': 'Parashat Kedoshim',
    'parasha_ru': 'Глава Кдошим',
  };

  // ---------------------------------------------------------------------------
  // Programs
  // ---------------------------------------------------------------------------
  late final List<Program> programs = [
    Program(
      id: _newId(),
      title: {'he': 'בית הכנסת בית מנחם', 'en': 'Beit Menachem synagogue', 'ru': 'Синагога Бейт Менахем'},
      description: {
        'he': 'בית הכנסת היחיד בנובוסיבירסק. תפילה בשני וחמישי ב־09:30, בשבת ב־10:00, והמבנה פתוח כל יום 09:00–17:00. סיורים בתיאום מראש.',
        'en': 'The only synagogue in Novosibirsk. Prayer Monday and Thursday at 09:30, Shabbat at 10:00. Building open daily 09:00–17:00. Tours by appointment.',
        'ru': 'Единственная синагога Новосибирска. Молитва в понедельник и четверг в 09:30, в субботу в 10:00. Здание открыто каждый день 09:00–17:00. Экскурсии по записи.',
      },
      schedule: {
        'he': 'שני וחמישי 09:30 · שבת 10:00 · המבנה כל יום 09:00–17:00',
        'en': 'Mon & Thu 09:30 · Shabbat 10:00 · building daily 09:00–17:00',
        'ru': 'Пн и Чт 09:30 · Шаббат 10:00 · здание ежедневно 09:00–17:00',
      },
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.synagogue,
      color: 0xFF1D4ED8,
      imageUrl: 'assets/images/beit-menachem-1.jpg',
    ),
    Program(
      id: _newId(),
      title: {'he': 'פעילות ילדים ביום ראשון', 'en': 'Sunday children\'s activity', 'ru': 'Детская программа в воскресенье'},
      description: {
        'he': 'פעילות לילדים בבית הכנסת ביום ראשון.',
        'en': 'Children\'s activity at the synagogue on Sunday.',
        'ru': 'Детская программа в синагоге по воскресеньям.',
      },
      schedule: {'he': 'יום ראשון בבית הכנסת', 'en': 'Sunday at the synagogue', 'ru': 'Воскресенье в синагоге'},
      audience: {'he': 'ילדים', 'en': 'Children', 'ru': 'Дети'},
      icon: Icons.child_care,
      color: 0xFFF59E0B,
    ),
    Program(
      id: _newId(),
      title: {'he': 'סעודת שבת', 'en': 'Shabbat meal', 'ru': 'Субботняя трапеза'},
      description: {
        'he': 'סעודת שבת קהילתית בבית מנחם אחרי התפילה.',
        'en': 'Community Shabbat meal at Beit Menachem after prayer.',
        'ru': 'Общинная субботняя трапеза в Бейт Менахем после молитвы.',
      },
      schedule: {'he': 'שבת 13:00', 'en': 'Shabbat 13:00', 'ru': 'Шаббат 13:00'},
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.restaurant,
      color: 0xFFC2410C,
    ),
    Program(
      id: _newId(),
      title: {'he': 'ליד אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'},
      description: {
        'he': 'בית ספר יהודי עם גן לגילאי 3–6. פועל מאז 2000 ברחוב שקספיר 9ב.',
        'en': 'Jewish school with preschool for ages 3–6. Operating since 2000 at 9b Shakspira St.',
        'ru': 'Еврейский лицей с дошкольной группой 3–6 лет. С 2000 года, ул. Шекспира, 9Б.',
      },
      schedule: {'he': 'ימי לימוד', 'en': 'School days', 'ru': 'Учебные дни'},
      audience: {'he': 'ילדים', 'en': 'Children', 'ru': 'Дети'},
      icon: Icons.school,
      color: 0xFF3B82F6,
    ),
    Program(
      id: _newId(),
      title: {'he': 'מרכז לב', 'en': 'Lev center', 'ru': 'Центр Лев'},
      description: {
        'he': 'מרכז אינטגרציה לילדים ולנוער עם צרכים מיוחדים, כולל בריכה וחינוך משלים Smart J. רחוב שקספיר 9א.',
        'en': 'Integration center for children and youth with special needs, including a pool and Smart J. 9a Shakspira St.',
        'ru': 'Интеграционный центр для детей и молодёжи с ОВЗ, бассейн и Smart J. Ул. Шекспира, 9А.',
      },
      schedule: {'he': 'לפי תוכניות', 'en': 'By program', 'ru': 'По программам'},
      audience: {'he': 'ילדים ומשפחות', 'en': 'Children & families', 'ru': 'Дети и семьи'},
      icon: Icons.favorite,
      color: 0xFFEC4899,
    ),
    Program(
      id: _newId(),
      title: {'he': 'נוער — Yahad Stars ו־EnerJew', 'en': 'Youth — Yahad Stars & EnerJew', 'ru': 'Молодёжь — Yahad Stars и EnerJew'},
      description: {
        'he': 'מועדוני נוער בבית מנחם: מפגשים, שבתות ופרויקטים לצעירים.',
        'en': 'Youth clubs at Beit Menachem: meetups, Shabbat and projects for young people.',
        'ru': 'Молодёжные клубы в Бейт Менахем: встречи, субботы и проекты.',
      },
      schedule: {'he': 'לפי לוח אירועים', 'en': 'Per events calendar', 'ru': 'По расписанию'},
      audience: {'he': 'נוער וסטודנטים', 'en': 'Youth & students', 'ru': 'Молодёжь и студенты'},
      icon: Icons.groups_2,
      color: 0xFF8B5CF6,
    ),
    Program(
      id: _newId(),
      title: {'he': 'מקווה', 'en': 'Mikveh', 'ru': 'Миква'},
      description: {
        'he': 'מקווה לגברים ולנשים בתוך המרכז הקהילתי, רחוב שצ׳טינקינה 68. לגברים בבוקר; לנשים בתיאום מראש.',
        'en': 'Men\'s and women\'s mikveh inside the community center, 68 Shchetinkina St. Men in the morning; women by appointment.',
        'ru': 'Мужская и женская миквы в общинном центре, ул. Щетинкина, 68. Для мужчин утром; для женщин по записи.',
      },
      schedule: {
        'he': 'גברים: בבוקר · נשים: בתיאום מראש',
        'en': 'Men: morning · Women: by appointment',
        'ru': 'Мужчины: утром · Женщины: по записи',
      },
      audience: {'he': 'נשים וגברים', 'en': 'Women and men', 'ru': 'Женщины и мужчины'},
      icon: Icons.water_drop,
      color: 0xFF0D9488,
    ),
    Program(
      id: _newId(),
      title: {'he': 'חסד וסיוע הומניטרי', 'en': 'Chesed & humanitarian aid', 'ru': 'Хесед и гуманитарная помощь'},
      description: {
        'he': 'חלוקת מזון, בגדים ומצות לפסח לקשישים ולמשפחות נזקקות בקהילה.',
        'en': 'Food, clothing and Passover matzah for elderly and families in need.',
        'ru': 'Продукты, одежда и маца к Песаху для пожилых и нуждающихся семей.',
      },
      schedule: {'he': 'לאורך השנה', 'en': 'Year-round', 'ru': 'В течение года'},
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.volunteer_activism,
      color: 0xFFEF4444,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Gallery + face tags
  // ---------------------------------------------------------------------------
  final List<String> faces = [
    'Rabbi Zaklos',
    'Rebbetzin Miriam',
    'Sender Kruglov',
  ];

  late final List<GalleryPhoto> gallery = [
    GalleryPhoto(id: _newId(), event: {'he': 'בית מנחם', 'en': 'Beit Menachem', 'ru': 'Бейт Менахем'}, year: 2013, tags: ['Rabbi Zaklos', 'Rebbetzin Miriam'], color: 0xFF1D4ED8, icon: Icons.synagogue, imageUrl: 'assets/images/beit-menachem-1.jpg'),
    GalleryPhoto(id: _newId(), event: {'he': 'בית הכנסת בית מנחם', 'en': 'Beit Menachem synagogue', 'ru': 'Синагога Бейт Менахем'}, year: 2013, tags: ['Rabbi Zaklos'], color: 0xFF0D9488, icon: Icons.synagogue, imageUrl: 'assets/images/beit-menachem-2.jpg'),
    GalleryPhoto(id: _newId(), event: {'he': 'חנוכה בנובוסיבירסק', 'en': 'Chanukah in Novosibirsk', 'ru': 'Ханука в Новосибирске'}, year: 2024, tags: ['Rabbi Zaklos', 'Sender Kruglov'], color: 0xFFF59E0B, icon: Icons.local_fire_department),
    GalleryPhoto(id: _newId(), event: {'he': 'ראש השנה בבית מנחם', 'en': 'Rosh Hashanah at Beit Menachem', 'ru': 'Рош ха-Шана в Бейт Менахем'}, year: 2024, tags: ['Rabbi Zaklos', 'Rebbetzin Miriam'], color: 0xFFF97316, icon: Icons.music_note),
    GalleryPhoto(id: _newId(), event: {'he': 'ילדי אור אבנר בחג', 'en': 'Or Avner children at a holiday', 'ru': 'Дети Ор Авнер на празднике'}, year: 2023, tags: ['Rebbetzin Miriam'], color: 0xFF10B981, icon: Icons.child_care),
    GalleryPhoto(id: _newId(), event: {'he': 'סדר פסח קהילתי', 'en': 'Community Passover Seder', 'ru': 'Общинный седер Песаха'}, year: 2024, tags: ['Rabbi Zaklos', 'Rebbetzin Miriam', 'Sender Kruglov'], color: 0xFF9333EA, icon: Icons.wine_bar),
  ];

  // ---------------------------------------------------------------------------
  // Famous Jews
  // ---------------------------------------------------------------------------
  late final List<FamousPerson> famous = [
    FamousPerson(id: _newId(), name: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, profession: {'he': 'רב העיר ושליח חב״ד', 'en': 'Chief Rabbi & Chabad emissary', 'ru': 'Главный раввин и посланник Хабада'}, bio: {'he': 'נולד בקריית מלאכי. למד בישיבות בניו יורק, מילאנו וברזיל, והגיע לשליחות בנובוסיבירסק ב־1999. רב העיר והמחוז, יוזם ליד אור אבנר ובית מנחם.', 'en': 'Born in Kiryat Malachi. Studied in New York, Milan and Brazil, and arrived on shlichut in 1999. Chief Rabbi of the city and region; founded Or Avner and Beit Menachem.', 'ru': 'Родился в Кирьят-Малахи. Учился в Нью-Йорке, Милане и Бразилии, прибыл в 1999. Главный раввин города и области, инициатор «Ор Авнер» и «Бейт Менахем».'}, era: Era.present, color: 0xFF1D4ED8, initials: 'SZ'),
    FamousPerson(id: _newId(), name: {'he': 'הרבנית מרים זקלס', 'en': 'Rebbetzin Miriam Zaklos', 'ru': 'Раббанит Мириам Заклос'}, profession: {'he': 'שליחת חב״ד', 'en': 'Chabad emissary', 'ru': 'Посланница Хабада'}, bio: {'he': 'שותפה לשליחות בנובוסיבירסק מאז 1999. מובילה חינוך, חגים וחיי הקהילה לצד הרב.', 'en': 'Partner in the Novosibirsk shlichut since 1999. Leads education, holidays and community life alongside the Rabbi.', 'ru': 'Вместе с раввином на миссии с 1999 года. Образование, праздники и жизнь общины.'}, era: Era.present, color: 0xFFDB2777, initials: 'MZ'),
    FamousPerson(id: _newId(), name: {'he': 'אלכסנדר (סנדר) קרוגלוב', 'en': 'Alexander (Sender) Kruglov', 'ru': 'Александр (Сендер) Круглов'}, profession: {'he': 'נשיא הקהילה', 'en': 'President of the community', 'ru': 'Президент общины'}, bio: {'he': 'נולד ב־1990 באוסט־קמנוגורסק. מאז 2015 בנובוסיבירסק: מנהיג נוער, משגיח במסעדה הכשרה, ומיוני 2019 נשיא קהילת בית מנחם.', 'en': 'Born 1990 in Ust-Kamenogorsk. In Novosibirsk since 2015: youth leader, kosher restaurant mashgiach, and since June 2019 president of the Beit Menachem community.', 'ru': 'Родился в 1990 в Усть-Каменогорске. С 2015 в Новосибирске: лидер молодёжи, машгиах, с июня 2019 президент общины «Бейт Менахем».'}, era: Era.present, color: 0xFF0D9488, initials: 'SK'),
  ];

  // ---------------------------------------------------------------------------
  // Cemetery (loaded from JSON asset — not stored in snapshot)
  // ---------------------------------------------------------------------------
  late final List<Grave> graves = [];

  static const _kaddishAsset = 'assets/data/kaddish_novosibirsk.json';
  static const _kaddishPhotoBase =
      'https://synagogue-kadish-shneur.amvera.io/photos/';

  Future<void> _loadKaddishGraves() async {
    try {
      final raw = await rootBundle.loadString(_kaddishAsset);
      final list = jsonDecode(raw);
      if (list is! List) return;
      graves
        ..clear()
        ..addAll([
          for (final item in list)
            if (item is Map) _graveFromKaddish(Map<String, dynamic>.from(item)),
        ]);
    } catch (_) {}
  }

  Grave _graveFromKaddish(Map<String, dynamic> m) {
    final photo = '${m['photo'] ?? ''}'.trim();
    final givenUrl = '${m['photoUrl'] ?? ''}'.trim();
    String? photoUrl;
    if (givenUrl.isNotEmpty) {
      photoUrl = givenUrl;
    } else if (photo.isNotEmpty) {
      photoUrl = '$_kaddishPhotoBase$photo';
    }
    final hebrew = m['hebrew'];
    var hebrewName = '';
    if (hebrew is String) {
      hebrewName = hebrew.trim();
    } else if (hebrew is Map) {
      hebrewName = '${hebrew['name'] ?? hebrew['he'] ?? ''}'.trim();
    }
    final title = '${m['title'] ?? ''}'.trim();
    return Grave(
      id: 'kaddish-${m['id']}',
      name: '${m['name'] ?? ''}'.trim(),
      hebrewName: hebrewName,
      birthYear: (m['birthYear'] as num?)?.toInt(),
      deathYear: (m['deathYear'] as num?)?.toInt() ?? 0,
      deathMonth: (m['deathMonth'] as num?)?.toInt(),
      deathDay: (m['deathDay'] as num?)?.toInt(),
      section: '${m['section'] ?? ''}'.trim(),
      row: '${m['row'] ?? ''}'.trim(),
      notes: title.isEmpty
          ? const {}
          : {'he': title, 'en': title, 'ru': title},
      photoUrl: photoUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // History + tour
  // ---------------------------------------------------------------------------
  final List<HistoryEvent> history = [
    HistoryEvent(year: '1893', title: {'he': 'ראשית הקהילה', 'en': 'Community founded', 'ru': 'Основание общины'}, description: {'he': 'הקהילה היהודית בנובו־ניקולאייבסק (לימים נובוסיבירסק) נוסדת. בין החברים: סוחרים, בעלי מלאכה וגולים.', 'en': 'The Jewish community of Novo-Nikolayevsk (later Novosibirsk) is formed — merchants, craftsmen and exiles.', 'ru': 'Еврейская община Новониколаевска (затем Новосибирск) образована: купцы, мастеровые и ссыльные.'}),
    HistoryEvent(year: '1926', title: {'he': 'נובוסיבירסק', 'en': 'The city is renamed', 'ru': 'Город переименован'}, description: {'he': 'שם העיר משתנה לנובוסיבירסק. החיים היהודיים ממשיכים תחת לחץ סובייטי גובר.', 'en': 'The city is renamed Novosibirsk. Jewish life continues under growing Soviet pressure.', 'ru': 'Город получает имя Новосибирск. Еврейская жизнь — под нарастающим советским давлением.'}),
    HistoryEvent(year: '1990s', title: {'he': 'התחדשות', 'en': 'Revival', 'ru': 'Возрождение'}, description: {'he': 'עם הפשרה הפוליטית הקהילה מתחדשת ומצטרפת לפדרציית הקהילות היהודיות ברוסיה (FEOR). פועלים גם הסוכנות היהודית וחסד «אתיקווה».', 'en': 'With political thaw the community revives and joins FEOR. The Jewish Agency and Hesed Atikva also operate in the city.', 'ru': 'С оттепелью община возрождается и входит в ФЕОР. Работают Сохнут и хесед «Атиква».'}),
    HistoryEvent(year: '1999', title: {'he': 'שליחות חב״ד', 'en': 'Chabad arrives', 'ru': 'Приезд Хабада'}, description: {'he': 'הרב שניאור זלמן זקלס מגיע לעיר כרב מוסמך ראשון בהיסטוריה של נובוסיבירסק, שליח הרבי מליובאוויטש. העירייה מקצה קרקע במרכז העיר לבית כנסת.', 'en': 'Rabbi Shneur Zalman Zaklos arrives as the first ordained rabbi in the city\'s history, a Chabad emissary. The municipality grants land downtown for a synagogue.', 'ru': 'Раввин Шнеур Залман Заклос — первый дипломированный раввин в истории города, посланник Ребе. Мэрия выделяет участок в центре под синагогу.'}),
    HistoryEvent(year: '2000', title: {'he': 'אור אבנר', 'en': 'Or Avner', 'ru': 'Ор Авнер'}, description: {'he': 'נפתח הליד היהודי אור אבנר עם גן לגיל הרך.', 'en': 'Or Avner Jewish school and preschool open.', 'ru': 'Открывается еврейский лицей «Ор Авнер» с дошкольной группой.'}),
    HistoryEvent(year: '2013', title: {'he': 'חנוכת בית מנחם', 'en': 'Beit Menachem opens', 'ru': 'Открытие Бейт Менахем'}, description: {'he': 'ב־28 באוגוסט נחנך המרכז (~3,400 מ״ר) ברחוב שצ׳טינקינה 68, על שם הרבי. בטקס: הרב ברל לזר, ראש העיר גורודצקי, ויותר מאלף אורחים. הבנייה נמשכה כ־13 שנה מתרומות.', 'en': 'On 28 August the ~3,400 m² center at 68 Shchetinkina St. opens, named for the Rebbe. Chief Rabbi Berel Lazar, Mayor Gorodetsky and 1,000+ guests attend. Construction took about 13 years, funded by donations.', 'ru': '28 августа открыт центр (~3400 м²) на ул. Щетинкина, 68, в честь Ребе. Берл Лазар, мэр Городецкий и более тысячи гостей. Строительство около 13 лет на пожертвования.'}),
    HistoryEvent(year: 'today', title: {'he': 'קהילה חיה בסיביר', 'en': 'A living community in Siberia', 'ru': 'Живая община Сибири'}, description: {'he': 'תפילות יומיות, מקווה, חנות כשרה, נוער, אור אבנר ומרכז לב. באזור כ־12,000 יהודים. בית מנחם הוא הבית הרוחני של יהדות נובוסיבירסק.', 'en': 'Daily prayers, mikveh, kosher shop, youth, Or Avner and Lev. About 12,000 Jews in the region. Beit Menachem is the spiritual home of Novosibirsk Jewry.', 'ru': 'Ежедневные молитвы, миква, кошерный магазин, молодёжь, «Ор Авнер» и «Лев». Около 12 000 евреев в регионе. Бейт Менахем — духовный дом евреев Новосибирска.'}),
  ];

  late final List<TourStop> tour = [
    TourStop(id: _newId(), name: {'he': 'בית מנחם', 'en': 'Beit Menachem', 'ru': 'Бейт Менахем'}, description: {'he': 'בית הכנסת והמרכז הקהילתי, רחוב שצ׳טינקינה 68. כיפה ומגן דוד — לב יהדות נובוסיבירסק.', 'en': 'Synagogue and community center, 68 Shchetinkina St. Dome and Star of David — the heart of Novosibirsk Jewry.', 'ru': 'Синагога и общинный центр, ул. Щетинкина, 68. Купол и звезда Давида — сердце еврейского Новосибирска.'}, color: 0xFF1D4ED8, icon: Icons.synagogue),
    TourStop(id: _newId(), name: {'he': 'מקווה וחנות כשרה', 'en': 'Mikveh & kosher shop', 'ru': 'Миква и кошерный магазин'}, description: {'he': 'בתוך אותו בניין: מקווה לגברים ולנשים, חנות כשרה ואולם אירועים.', 'en': 'In the same building: men\'s and women\'s mikveh, kosher shop and banquet hall.', 'ru': 'В том же здании: миквы, кошерный магазин и праздничный зал.'}, color: 0xFF0D9488, icon: Icons.water_drop),
    TourStop(id: _newId(), name: {'he': 'ליד אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'}, description: {'he': 'בית הספר היהודי וגן הילדים, רחוב שקספיר 9ב.', 'en': 'The Jewish school and preschool, 9b Shakspira St.', 'ru': 'Еврейский лицей и детская группа, ул. Шекспира, 9Б.'}, color: 0xFF3B82F6, icon: Icons.school),
    TourStop(id: _newId(), name: {'he': 'מרכז לב', 'en': 'Lev center', 'ru': 'Центр Лев'}, description: {'he': 'מרכז לילדים עם צרכים מיוחדים ובריכה, רחוב שקספיר 9א.', 'en': 'Center for children with special needs and a pool, 9a Shakspira St.', 'ru': 'Центр для детей с ОВЗ и бассейн, ул. Шекспира, 9А.'}, color: 0xFFEC4899, icon: Icons.favorite),
  ];

  // ---------------------------------------------------------------------------
  // Store
  // ---------------------------------------------------------------------------
  late final List<Product> products = [
    Product(id: _newId(), name: {'he': 'זוג פמוטים מכסף', 'en': 'Silver candlesticks (pair)', 'ru': 'Серебряные подсвечники'}, description: {'he': 'פמוטי שבת מהודרים.', 'en': 'Elegant Shabbat candlesticks.', 'ru': 'Элегантные субботние подсвечники.'}, price: 89, category: ProductCategory.judaica, color: 0xFF6366F1, icon: Icons.light),
    Product(id: _newId(), name: {'he': 'מזוזה מהודרת', 'en': 'Mezuzah scroll & case', 'ru': 'Мезуза со свитком'}, description: {'he': 'קלף כשר עם בית מעוצב.', 'en': 'Kosher scroll with a designer case.', 'ru': 'Кошерный свиток с корпусом.'}, price: 45, category: ProductCategory.judaica, color: 0xFF8B5CF6, icon: Icons.door_front_door),
    Product(id: _newId(), name: {'he': 'סידור תהילת השם', 'en': 'Tehillat Hashem Siddur', 'ru': 'Сидур Теилат Ашем'}, description: {'he': 'נוסח האר"י, כריכה קשה.', 'en': 'Nusach Ari, hardcover.', 'ru': 'Нусах Ари, твёрдый переплёт.'}, price: 22, category: ProductCategory.books, color: 0xFF0D9488, icon: Icons.menu_book),
    Product(id: _newId(), name: {'he': 'ספר התניא', 'en': 'Tanya', 'ru': 'Тания'}, description: {'he': 'מהדורה מוערת בשלוש שפות.', 'en': 'Annotated edition in three languages.', 'ru': 'Аннотированное издание на трёх языках.'}, price: 28, category: ProductCategory.books, color: 0xFF0EA5E9, icon: Icons.auto_stories),
    Product(id: _newId(), name: {'he': 'יין ענבים כשר', 'en': 'Kosher grape wine', 'ru': 'Кошерное вино'}, description: {'he': 'לקידוש ולהבדלה.', 'en': 'For Kiddush and Havdalah.', 'ru': 'Для кидуша и авдалы.'}, price: 18, category: ProductCategory.food, color: 0xFF9333EA, icon: Icons.wine_bar),
    Product(id: _newId(), name: {'he': 'מצות שמורות', 'en': 'Shmurah Matzah', 'ru': 'Маца шмура'}, description: {'he': 'אפייה בעבודת יד לפסח.', 'en': 'Handmade for Passover.', 'ru': 'Ручной выпечки к Песаху.'}, price: 35, category: ProductCategory.food, color: 0xFFF59E0B, icon: Icons.bakery_dining),
    Product(id: _newId(), name: {'he': 'טלית צמר', 'en': 'Wool Tallit', 'ru': 'Талит шерстяной'}, description: {'he': 'טלית גדול איכותית.', 'en': 'Quality full-size tallit.', 'ru': 'Качественный большой талит.'}, price: 120, category: ProductCategory.judaica, color: 0xFF334155, icon: Icons.checkroom),
    Product(id: _newId(), name: {'he': 'עוגיות דבש כשרות', 'en': 'Kosher honey cookies', 'ru': 'Кошерное медовое печенье'}, description: {'he': 'מארז מתנה לראש השנה.', 'en': 'Gift box for Rosh Hashanah.', 'ru': 'Подарочный набор к Рош ха-Шана.'}, price: 15, category: ProductCategory.food, color: 0xFFEA580C, icon: Icons.cookie),
  ];

  // ---------------------------------------------------------------------------
  // Torah library
  // ---------------------------------------------------------------------------
  late final List<Shiur> shiurim = [
    Shiur(id: _newId(), title: {'he': 'פרשת השבוע למעשה', 'en': 'The weekly parasha in practice', 'ru': 'Недельная глава на практике'}, rabbi: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, topic: {'he': 'פרשה', 'en': 'Parasha', 'ru': 'Глава'}, durationMinutes: 42, date: DateTime.now().subtract(const Duration(days: 2))),
    Shiur(id: _newId(), title: {'he': 'יסודות התניא', 'en': 'Foundations of Tanya', 'ru': 'Основы Тании'}, rabbi: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, topic: {'he': 'חסידות', 'en': 'Chassidut', 'ru': 'Хасидизм'}, durationMinutes: 55, date: DateTime.now().subtract(const Duration(days: 9))),
    Shiur(id: _newId(), title: {'he': 'הלכות שבת למעשה', 'en': 'Practical laws of Shabbat', 'ru': 'Законы субботы на практике'}, rabbi: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, topic: {'he': 'הלכה', 'en': 'Halacha', 'ru': 'Алаха'}, durationMinutes: 38, date: DateTime.now().subtract(const Duration(days: 16))),
    Shiur(id: _newId(), title: {'he': 'כולל תורה', 'en': 'Kollel Torah', 'ru': 'Колель Тора'}, rabbi: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, topic: {'he': 'גמרא', 'en': 'Gemara', 'ru': 'Гемара'}, durationMinutes: 60, date: DateTime.now().subtract(const Duration(days: 23))),
  ];

  // ---------------------------------------------------------------------------
  // CRM leads (from external system - mock)
  // ---------------------------------------------------------------------------
  late final List<Lead> leads = [
    Lead(id: _newId(), name: 'Daniel Berman', email: 'daniel.b@example.com', phone: '+972-52-111-2233', topic: {'he': 'ארוחות שבת', 'en': 'Shabbat meals', 'ru': 'Субботние трапезы'}, date: DateTime.now().subtract(const Duration(days: 1)), status: LeadStatus.fresh, source: 'website'),
    Lead(id: _newId(), name: 'Anna Fishman', email: 'anna.f@example.com', phone: '+7-926-555-0110', topic: {'he': 'שיעורי תורה', 'en': 'Torah classes', 'ru': 'Уроки Торы'}, date: DateTime.now().subtract(const Duration(days: 2)), status: LeadStatus.contacted, source: 'telegram'),
    Lead(id: _newId(), name: 'Michael Roth', email: 'michael.r@example.com', phone: '+1-347-555-0192', topic: {'he': 'יוצאי העיר', 'en': 'City alumni', 'ru': 'Земляки'}, date: DateTime.now().subtract(const Duration(days: 3)), status: LeadStatus.member, source: 'website'),
    Lead(id: _newId(), name: 'Rachel Weiss', email: 'rachel.w@example.com', phone: '+972-54-777-8899', topic: {'he': 'ארגון נשים', 'en': "Women's Circle", 'ru': 'Женский клуб'}, date: DateTime.now().subtract(const Duration(days: 5)), status: LeadStatus.contacted, source: 'website'),
  ];

  // ---------------------------------------------------------------------------
  // Donations
  // ---------------------------------------------------------------------------
  final List<Loc> campaigns = [
    {'he': 'החזקת בית מנחם', 'en': 'Beit Menachem upkeep', 'ru': 'Содержание Бейт Менахем'},
    {'he': 'ליד אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'},
    {'he': 'מרכז לב', 'en': 'Lev special-needs center', 'ru': 'Центр Лев'},
    {'he': 'חסד ומצות לפסח', 'en': 'Chesed & Passover matzah', 'ru': 'Хесед и маца к Песаху'},
  ];

  late final List<Donation> donations = [
    Donation(id: _newId(), donor: 'Anonymous', amount: 360, campaign: campaigns[0], date: DateTime.now().subtract(const Duration(days: 1))),
    Donation(id: _newId(), donor: 'M. Roth', amount: 1000, campaign: campaigns[2], date: DateTime.now().subtract(const Duration(days: 2))),
    Donation(id: _newId(), donor: 'A. Fishman', amount: 180, campaign: campaigns[1], date: DateTime.now().subtract(const Duration(days: 4))),
  ];

  final List<NewsletterSubscriber> subscribers = [];

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  SubscribeResult subscribeNewsletter(String raw) {
    final email = raw.trim().toLowerCase();
    if (email.isEmpty || !_emailRe.hasMatch(email)) {
      return SubscribeResult.invalid;
    }
    if (subscribers.any((s) => s.email == email)) {
      return SubscribeResult.duplicate;
    }
    subscribers.insert(
      0,
      NewsletterSubscriber(email: email, date: DateTime.now()),
    );
    notifyListeners();
    return SubscribeResult.ok;
  }

  void removeSubscriber(String email) {
    subscribers.removeWhere((s) => s.email == email);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Bots
  // ---------------------------------------------------------------------------
  final BotConfig telegramBot = BotConfig(name: 'Telegram News', handle: '@jewishsib', enabled: true, lastSync: DateTime.now().subtract(const Duration(hours: 2)), itemsSynced: 0);
  final BotConfig socialBot = BotConfig(name: 'Social Auto-Post', handle: 'VK jewishsib', enabled: true, lastSync: DateTime.now().subtract(const Duration(hours: 5)), itemsSynced: 0);

  // ---------------------------------------------------------------------------
  // Shopping cart
  // ---------------------------------------------------------------------------
  final Map<String, int> _cart = {};
  Map<String, int> get cart => _cart;
  int get cartCount => _cart.values.fold(0, (a, b) => a + b);
  double get cartTotal {
    double t = 0;
    _cart.forEach((id, qty) {
      final p = products.where((e) => e.id == id);
      if (p.isNotEmpty) t += p.first.price * qty;
    });
    return t;
  }

  void addToCart(String id) {
    _cart[id] = (_cart[id] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(String id) {
    if (!_cart.containsKey(id)) return;
    final n = _cart[id]! - 1;
    if (n <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = n;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutations (used by admin + client forms)
  // ---------------------------------------------------------------------------
  void addNews(NewsArticle a) {
    news.insert(0, a);
    notifyListeners();
  }

  void updateNews() => notifyListeners();

  void deleteNews(String id) {
    news.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  NewsArticle newBlankNews() => NewsArticle(
        id: _newId(),
        title: {'he': '', 'en': '', 'ru': ''},
        body: {'he': '', 'en': '', 'ru': ''},
        date: DateTime.now(),
        category: {'he': 'כללי', 'en': 'General', 'ru': 'Общее'},
      );

  void addProgram(Program p) {
    programs.add(p);
    notifyListeners();
  }

  void deleteProgram(String id) {
    programs.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Program newBlankProgram() => Program(
        id: _newId(),
        title: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
        schedule: {'he': '', 'en': '', 'ru': ''},
        audience: {'he': '', 'en': '', 'ru': ''},
      );

  void addProduct(Product p) {
    products.add(p);
    notifyListeners();
  }

  void deleteProduct(String id) {
    products.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Product newBlankProduct() => Product(
        id: _newId(),
        name: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
        price: 0,
        category: ProductCategory.judaica,
      );

  void addLead({
    required String name,
    required String email,
    required String phone,
    required Loc topic,
    String source = 'website',
  }) {
    leads.insert(
      0,
      Lead(
        id: _newId(),
        name: name,
        email: email,
        phone: phone,
        topic: topic,
        date: DateTime.now(),
        source: source,
      ),
    );
    notifyListeners();
  }

  void setLeadStatus(Lead lead, LeadStatus status) {
    lead.status = status;
    notifyListeners();
  }

  void addDonation({required String donor, required double amount, required Loc campaign}) {
    donations.insert(
      0,
      Donation(id: _newId(), donor: donor.isEmpty ? 'Anonymous' : donor, amount: amount, campaign: campaign, date: DateTime.now()),
    );
    notifyListeners();
  }

  GalleryPhoto newBlankGallery() => GalleryPhoto(
        id: _newId(),
        event: {'he': '', 'en': '', 'ru': ''},
        year: DateTime.now().year,
        tags: const [],
        color: 0xFF1D4ED8,
      );

  void addGalleryPhoto(GalleryPhoto p) {
    gallery.insert(0, p);
    notifyListeners();
  }

  void deleteGalleryPhoto(String id) {
    gallery.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Simulates the social bot pushing the latest news to social networks.
  void runSocialPush() {
    socialBot.lastSync = DateTime.now();
    socialBot.itemsSynced += 3;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Page banners (replace the default blue hero)
  // ---------------------------------------------------------------------------
  final Map<String, PageBanner> banners = {
    for (final slot in bannerSlots)
      slot.route: PageBanner(
        imageUrl: slot.route == '/' || slot.route == '/about'
            ? 'assets/images/beit-menachem-1.jpg'
            : 'assets/images/beit-menachem-2.jpg',
      ),
  };

  PageBanner bannerFor(String route) =>
      banners[route] ?? banners['/'] ?? PageBanner();

  void setBannerImage(String route, Uint8List bytes) {
    final current = banners.putIfAbsent(route, PageBanner.new);
    current.bytes = compressSiteImage(bytes);
    current.imageUrl = null;
    notifyListeners();
  }

  void setBannerAlign(String route, {double? x, double? y}) {
    final current = banners.putIfAbsent(route, PageBanner.new);
    if (x != null) current.alignX = x;
    if (y != null) current.alignY = y;
    notifyListeners();
  }

  void clearBanner(String route) {
    banners[route] = PageBanner();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Site search
  // ---------------------------------------------------------------------------
  bool _locHas(Loc map, String q) =>
      map.values.any((v) => v.toLowerCase().contains(q));

  List<SearchHit> searchSite(String query, String lang) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final hits = <SearchHit>[];

    for (final a in news) {
      if (!a.published) continue;
      if (_locHas(a.title, q) || _locHas(a.body, q) || _locHas(a.category, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.news',
          title: trLoc(a.title, lang),
          subtitle: trLoc(a.body, lang),
          route: '/news?h=${a.id}',
          icon: Icons.article_outlined,
        ));
      }
    }
    for (final p in programs) {
      if (_locHas(p.title, q) ||
          _locHas(p.description, q) ||
          _locHas(p.audience, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.programs',
          title: trLoc(p.title, lang),
          subtitle: trLoc(p.description, lang),
          route: '/programs?h=${p.id}',
          icon: Icons.groups_outlined,
        ));
      }
    }
    for (final p in products) {
      if (_locHas(p.name, q) || _locHas(p.description, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.products',
          title: trLoc(p.name, lang),
          subtitle: trLoc(p.description, lang),
          route: '/store?h=${p.id}',
          icon: Icons.storefront_outlined,
        ));
      }
    }
    for (final p in famous) {
      if (_locHas(p.name, q) ||
          _locHas(p.profession, q) ||
          _locHas(p.bio, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.famous',
          title: trLoc(p.name, lang),
          subtitle: trLoc(p.profession, lang),
          route: '/famous?h=${p.id}',
          icon: Icons.star_outline,
        ));
      }
    }
    for (final g in graves) {
      if (g.name.toLowerCase().contains(q) ||
          g.hebrewName.toLowerCase().contains(q) ||
          _locHas(g.notes, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.cemetery',
          title: g.hebrewName.isEmpty ? g.name : g.hebrewName,
          subtitle: g.name,
          route: '/cemetery?h=${g.id}',
          icon: Icons.grid_view_outlined,
        ));
      }
    }
    for (final s in shiurim) {
      if (_locHas(s.title, q) || _locHas(s.rabbi, q) || _locHas(s.topic, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.library',
          title: trLoc(s.title, lang),
          subtitle: trLoc(s.rabbi, lang),
          route: '/library?h=${s.id}',
          icon: Icons.menu_book_outlined,
        ));
      }
    }
    if (hits.length > 24) return hits.sublist(0, 24);
    return hits;
  }

  // ---------------------------------------------------------------------------
  // Persistence (IndexedDB / localStorage)
  // ---------------------------------------------------------------------------
  void _noteId(String id) {
    final n = int.tryParse(id.replaceFirst(RegExp(r'^id'), ''));
    if (n != null && n >= _seq) _seq = n + 1;
  }

  void _schedulePersist() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistNow());
    });
  }

  Map<String, dynamic> _encodeSnapshot() => {
        'v': 3,
        'seed': _contentSeed,
        'seq': _seq,
        'updatedAt': DateTime.now().toIso8601String(),
        'mapsKey': googleMapsApiKey,
        'location': locationToJson(location),
        'contact': contactToJson(contact),
        'news': [for (final a in news) newsToJson(a)],
        'programs': [for (final p in programs) programToJson(p)],
        'products': [for (final p in products) productToJson(p)],
        'gallery': [for (final p in gallery) galleryToJson(p)],
        'banners': {
          for (final e in banners.entries) e.key: bannerToJson(e.value),
        },
        'cart': _cart,
        'leads': [for (final l in leads) leadToJson(l)],
        'donations': [for (final d in donations) donationToJson(d)],
        'subscribers': [for (final s in subscribers) subscriberToJson(s)],
        'telegramBot': botToJson(telegramBot),
        'socialBot': botToJson(socialBot),
        'lang': readPref('lang') ?? 'he',
        'imageKeys': _collectImages().keys.toList(),
      };

  void _applySnapshot(Map<String, dynamic> m) {
    googleMapsApiKey = '${m['mapsKey'] ?? googleMapsApiKey}';
    location = locationFromJson(m['location'], location);
    _persistLocation();
    contactFromJson(contact, m['contact']);

    if (m['news'] is List) {
      news
        ..clear()
        ..addAll((m['news'] as List).map(newsFromJson));
    }
    if (m['programs'] is List) {
      programs
        ..clear()
        ..addAll((m['programs'] as List).map(programFromJson));
    }
    if (m['products'] is List) {
      products
        ..clear()
        ..addAll((m['products'] as List).map(productFromJson));
    }
    if (m['gallery'] is List) {
      gallery
        ..clear()
        ..addAll((m['gallery'] as List).map(galleryFromJson));
    }
    if (m['banners'] is Map) {
      final raw = Map<String, dynamic>.from(m['banners'] as Map);
      for (final e in raw.entries) {
        banners[e.key] = bannerFromJson(e.value);
      }
    }
    if (m['cart'] is Map) {
      _cart
        ..clear()
        ..addAll({
          for (final e in (m['cart'] as Map).entries)
            '${e.key}': (e.value as num?)?.toInt() ?? 0,
        });
      _cart.removeWhere((_, qty) => qty <= 0);
    }
    if (m['leads'] is List) {
      leads
        ..clear()
        ..addAll((m['leads'] as List).map(leadFromJson));
    }
    if (m['donations'] is List) {
      donations
        ..clear()
        ..addAll((m['donations'] as List).map(donationFromJson));
    }
    if (m['subscribers'] is List) {
      subscribers
        ..clear()
        ..addAll((m['subscribers'] as List).map(subscriberFromJson));
    }
    botFromJson(telegramBot, m['telegramBot']);
    botFromJson(socialBot, m['socialBot']);

    final seq = (m['seq'] as num?)?.toInt();
    if (seq != null && seq > _seq) _seq = seq;
    for (final a in news) {
      _noteId(a.id);
    }
    for (final p in programs) {
      _noteId(p.id);
    }
    for (final p in products) {
      _noteId(p.id);
    }
    for (final p in gallery) {
      _noteId(p.id);
    }
    for (final l in leads) {
      _noteId(l.id);
    }
    for (final d in donations) {
      _noteId(d.id);
    }
  }

  Future<void> _hydrate() async {
    final raw = await persistGet(_snapKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final seed = (m['seed'] as num?)?.toInt() ?? 0;
      if (seed < _contentSeed) return;
      _applySnapshot(m);
      await _hydrateLocalImages(m);
    } catch (_) {}
  }

  Future<void> _hydrateLocalImages(Map<String, dynamic> m) async {
    final keys = <String>[
      if (m['imageKeys'] is List)
        for (final k in m['imageKeys'] as List) '$k',
    ];
    if (keys.isEmpty) {
      keys.addAll(_collectImages().keys);
      keys.addAll([
        for (final e in banners.entries) 'banner:${e.key}',
        for (final a in news) 'news:${a.id}',
        for (final p in programs) 'program:${p.id}',
        for (final p in products) 'product:${p.id}',
        for (final p in gallery) 'gallery:${p.id}',
      ]);
    }
    for (final key in keys.toSet()) {
      final raw = await persistGet('$_imgPrefix$key');
      final bytes = b64ToBytes(raw);
      if (bytes != null) _applyLocalImage(key, bytes);
    }
  }

  Map<String, Uint8List> _collectImages() {
    final out = <String, Uint8List>{};
    for (final e in banners.entries) {
      final b = e.value.bytes;
      if (b != null && b.isNotEmpty) out['banner:${e.key}'] = b;
    }
    for (final a in news) {
      final b = a.imageBytes;
      if (b != null && b.isNotEmpty) out['news:${a.id}'] = b;
    }
    for (final p in programs) {
      final b = p.imageBytes;
      if (b != null && b.isNotEmpty) out['program:${p.id}'] = b;
    }
    for (final p in products) {
      final b = p.imageBytes;
      if (b != null && b.isNotEmpty) out['product:${p.id}'] = b;
    }
    for (final p in gallery) {
      final b = p.imageBytes;
      if (b != null && b.isNotEmpty) out['gallery:${p.id}'] = b;
    }
    return out;
  }

  void _applyLocalImage(String key, Uint8List bytes) {
    final i = key.indexOf(':');
    if (i <= 0) return;
    final kind = key.substring(0, i);
    final id = key.substring(i + 1);
    switch (kind) {
      case 'banner':
        banners.putIfAbsent(id, PageBanner.new).bytes = bytes;
      case 'news':
        for (final a in news) {
          if (a.id == id) a.imageBytes = bytes;
        }
      case 'program':
        for (final p in programs) {
          if (p.id == id) p.imageBytes = bytes;
        }
      case 'product':
        for (final p in products) {
          if (p.id == id) p.imageBytes = bytes;
        }
      case 'gallery':
        for (final p in gallery) {
          if (p.id == id) p.imageBytes = bytes;
        }
    }
  }

  Future<void> _pullCloud() async {
    final cloud = await CloudSync.instance.pull();
    if (cloud == null) return;
    final seed = (cloud.snapshot['seed'] as num?)?.toInt() ?? 0;
    if (seed < _contentSeed) return;
    final localImages = _collectImages();
    _applySnapshot(cloud.snapshot);
    for (final e in cloud.images.entries) {
      _applyLocalImage(e.key, e.value);
    }
    for (final e in localImages.entries) {
      if (!cloud.images.containsKey(e.key)) {
        _applyLocalImage(e.key, e.value);
      }
    }
    try {
      await persistPut(_snapKey, jsonEncode(_encodeSnapshot()));
      for (final e in cloud.images.entries) {
        await persistPut('$_imgPrefix${e.key}', bytesToB64(e.value)!);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistNow() async {
    final images = _collectImages();
    final snap = _encodeSnapshot();
    try {
      await persistPut(_snapKey, jsonEncode(snap));
      for (final e in images.entries) {
        await persistPut('$_imgPrefix${e.key}', bytesToB64(e.value)!);
      }
    } catch (e) {
      if (isQuotaExceeded(e)) {
        onPersistWarning?.call(_quotaHe);
      }
    }
    final err = await CloudSync.instance.push(snapshot: snap, images: images);
    cloudError = err;
    cloudOkAt = err == null ? CloudSync.instance.lastOkAt : null;
    _notifyUi();
    if (err == null || err == 'not-signed-in') return;
    if (err == 'permission-denied') {
      onPersistWarning?.call(_cloudDeniedHe);
    } else if (err == 'unavailable') {
      onPersistWarning?.call(_cloudUnavailableHe);
    } else {
      onPersistWarning?.call(_cloudFailHe);
    }
  }

  Future<String?> publishToCloud() async {
    CloudSync.instance.adminSession = true;
    await _persistNow();
    return cloudError;
  }
}
