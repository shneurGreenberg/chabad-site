import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models.dart';
import '../services/location_zmanim.dart';
import '../services/telegram.dart';
import '../services/web_prefs.dart';

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
    Future<void>.microtask(() async {
      try {
        await refreshTimes();
      } catch (_) {}
    });
  }

  int _seq = 1000;
  String _newId() => 'id${_seq++}';

  /// Notify listeners after mutating a field directly (used by admin toggles).
  void refresh() => notifyListeners();

  // ---------------------------------------------------------------------------
  // Contact / about
  // ---------------------------------------------------------------------------
  final ContactInfo contact = ContactInfo(
    name: {
      'he': 'בית חב"ד ליובאוויטש',
      'en': 'Chabad Lubavitch Center',
      'ru': 'Центр Хабад Любавич',
    },
    address: {
      'he': 'רחוב הרצל 12, מרכז העיר',
      'en': '12 Herzl St., City Center',
      'ru': 'ул. Герцля 12, центр города',
    },
    phone: '+972-3-555-0182',
    email: 'info@chabad-city.org',
    hours: [
      MapEntry({'he': 'ראשון–חמישי', 'en': 'Sun–Thu', 'ru': 'Вс–Чт'},
          '09:00 – 20:00'),
      MapEntry({'he': 'שישי', 'en': 'Friday', 'ru': 'Пятница'}, '08:00 – 14:00'),
      MapEntry({'he': 'שבת', 'en': 'Shabbat', 'ru': 'Суббота'},
          '—'),
    ],
  );

  // ---------------------------------------------------------------------------
  // News
  // ---------------------------------------------------------------------------
  late final List<NewsArticle> news = [
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'סעודת שבת קהילתית לכל המשפחה',
        'en': 'Community Shabbat dinner for the whole family',
        'ru': 'Общинный субботний ужин для всей семьи',
      },
      body: {
        'he':
            'בשבת הקרובה נקיים סעודת שבת חגיגית בבית חב"ד. מוזמנים כל בני הקהילה, אורחים וסטודנטים. נא להירשם מראש.',
        'en':
            'This Shabbat we host a festive community dinner at the Chabad house. All members, guests and students are welcome. Please register in advance.',
        'ru':
            'В эту субботу мы проводим праздничный ужин в доме Хабада. Приглашаются все члены общины, гости и студенты. Просьба зарегистрироваться заранее.',
      },
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: {'he': 'אירועים', 'en': 'Events', 'ru': 'События'},
      imageColor: 0xFF1D4ED8,
      icon: Icons.dinner_dining,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'חלוקת מצות לקראת פסח',
        'en': 'Matzah distribution ahead of Passover',
        'ru': 'Раздача мацы к Песаху',
      },
      body: {
        'he':
            'מתנדבי בית חב"ד יצאו לחלק מצות שמורות לכל משפחות הקהילה. ניתן לבקש חבילה גם דרך האתר.',
        'en':
            'Chabad volunteers are distributing handmade matzah to community families. You can also request a package through the website.',
        'ru':
            'Волонтёры Хабада раздают мацу семьям общины. Пакет можно заказать и через сайт.',
      },
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: {'he': 'חגים', 'en': 'Holidays', 'ru': 'Праздники'},
      imageColor: 0xFF9333EA,
      icon: Icons.bakery_dining,
      source: NewsSource.telegram,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'שיעור חדש בתניא בכל יום שלישי',
        'en': 'New Tanya class every Tuesday',
        'ru': 'Новый урок Тании по вторникам',
      },
      body: {
        'he':
            'הרב פותח מחזור שיעורים חדש בספר התניא. השיעור מתאים למתחילים ולמתקדמים כאחד.',
        'en':
            'The Rabbi is opening a new cycle of Tanya classes, suitable for beginners and advanced students alike.',
        'ru':
            'Раввин открывает новый цикл уроков Тании — подойдёт и новичкам, и продвинутым.',
      },
      date: DateTime.now().subtract(const Duration(days: 7)),
      category: {'he': 'שיעורים', 'en': 'Classes', 'ru': 'Уроки'},
      imageColor: 0xFF0D9488,
      icon: Icons.menu_book,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'מבצע תפילין במרכז העיר',
        'en': 'Tefillin campaign in the city center',
        'ru': 'Акция тфилин в центре города',
      },
      body: {
        'he':
            'הנחנו תפילין עם עשרות יהודים שעברו ברחוב הראשי. הצטרפו אלינו למבצע הבא.',
        'en':
            'We helped dozens of Jews put on tefillin in the main street. Join us for the next campaign.',
        'ru':
            'Мы помогли десяткам евреев возложить тфилин на главной улице. Присоединяйтесь к следующей акции.',
      },
      date: DateTime.now().subtract(const Duration(days: 11)),
      category: {'he': 'מבצעים', 'en': 'Outreach', 'ru': 'Акции'},
      imageColor: 0xFFDB2777,
      icon: Icons.volunteer_activism,
      source: NewsSource.telegram,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Location + live zmanim / parasha
  // ---------------------------------------------------------------------------
  SiteLocation location = SiteLocation.jerusalem();

  void _restoreLocation() {
    final raw = readPref('chabad_site_location');
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      location = SiteLocation(
        cityName: m['city'] as String? ?? location.cityName,
        query: m['query'] as String? ?? location.query,
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
      title: {'he': 'גן ילדים חב"ד', 'en': 'Chabad Kindergarten', 'ru': 'Детский сад Хабад'},
      description: {
        'he': 'גן חם ואוהב עם חינוך יהודי ערכי לגילאי 2–5.',
        'en': 'A warm, loving kindergarten with values-based Jewish education, ages 2–5.',
        'ru': 'Тёплый детский сад с еврейским воспитанием, 2–5 лет.',
      },
      schedule: {'he': 'א׳–ה׳ 08:00–14:00', 'en': 'Sun–Thu 08:00–14:00', 'ru': 'Вс–Чт 08:00–14:00'},
      audience: {'he': 'גילאי 2–5', 'en': 'Ages 2–5', 'ru': '2–5 лет'},
      icon: Icons.child_care,
      color: 0xFFF59E0B,
    ),
    Program(
      id: _newId(),
      title: {'he': 'בית ספר לעברית', 'en': 'Hebrew School', 'ru': 'Школа иврита'},
      description: {
        'he': 'לימודי עברית, תפילה ומסורת לילדי הקהילה.',
        'en': 'Hebrew, prayer and tradition studies for community children.',
        'ru': 'Иврит, молитва и традиции для детей общины.',
      },
      schedule: {'he': 'יום ראשון 10:00', 'en': 'Sunday 10:00', 'ru': 'Воскресенье 10:00'},
      audience: {'he': 'גילאי 6–13', 'en': 'Ages 6–13', 'ru': '6–13 лет'},
      icon: Icons.school,
      color: 0xFF3B82F6,
    ),
    Program(
      id: _newId(),
      title: {'he': 'ארגון נשים', 'en': "Women's Circle", 'ru': 'Женский клуб'},
      description: {
        'he': 'מפגשי נשים, שיעורים והכנות לחגים.',
        'en': 'Women gatherings, classes and holiday preparations.',
        'ru': 'Встречи женщин, уроки и подготовка к праздникам.',
      },
      schedule: {'he': 'יום שלישי 20:00', 'en': 'Tuesday 20:00', 'ru': 'Вторник 20:00'},
      audience: {'he': 'נשים', 'en': 'Women', 'ru': 'Женщины'},
      icon: Icons.diversity_1,
      color: 0xFFEC4899,
    ),
    Program(
      id: _newId(),
      title: {'he': 'כולל אברכים', 'en': 'Kollel', 'ru': 'Колель'},
      description: {
        'he': 'לימוד תורה מעמיק לאברכים בשעות הבוקר.',
        'en': 'In-depth Torah study for young men in the mornings.',
        'ru': 'Углублённое изучение Торы по утрам.',
      },
      schedule: {'he': 'א׳–ו׳ 09:00', 'en': 'Sun–Fri 09:00', 'ru': 'Вс–Пт 09:00'},
      audience: {'he': 'גברים', 'en': 'Men', 'ru': 'Мужчины'},
      icon: Icons.auto_stories,
      color: 0xFF0D9488,
    ),
    Program(
      id: _newId(),
      title: {'he': 'סטודנטים וצעירים', 'en': 'Students & Young Pros', 'ru': 'Студенты и молодёжь'},
      description: {
        'he': 'ארוחות שבת, טיולים ומפגשים חברתיים.',
        'en': 'Shabbat meals, trips and social meetups.',
        'ru': 'Субботние трапезы, поездки и встречи.',
      },
      schedule: {'he': 'לפי לוח אירועים', 'en': 'Per events calendar', 'ru': 'По расписанию'},
      audience: {'he': 'גילאי 18–30', 'en': 'Ages 18–30', 'ru': '18–30 лет'},
      icon: Icons.groups_2,
      color: 0xFF8B5CF6,
    ),
    Program(
      id: _newId(),
      title: {'he': 'ביקורי חסד', 'en': 'Chesed Visits', 'ru': 'Визиты хеседа'},
      description: {
        'he': 'ביקורים אצל קשישים, חולים ובודדים בקהילה.',
        'en': 'Visits to the elderly, sick and lonely in the community.',
        'ru': 'Визиты к пожилым, больным и одиноким.',
      },
      schedule: {'he': 'לאורך השבוע', 'en': 'Throughout the week', 'ru': 'В течение недели'},
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.favorite,
      color: 0xFFEF4444,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Gallery + face tags
  // ---------------------------------------------------------------------------
  final List<String> faces = [
    'Rabbi Mendel',
    'Rebbetzin Chana',
    'David Katz',
    'Sarah Levin',
    'Yosef Cohen',
    'Miriam Gold',
  ];

  late final List<GalleryPhoto> gallery = [
    GalleryPhoto(id: _newId(), event: {'he': 'הדלקת נר חנוכה מרכזית', 'en': 'Grand Menorah lighting', 'ru': 'Зажигание меноры'}, year: 2025, tags: ['Rabbi Mendel', 'David Katz', 'Yosef Cohen'], color: 0xFF1D4ED8, icon: Icons.local_fire_department),
    GalleryPhoto(id: _newId(), event: {'he': 'סעודת פורים', 'en': 'Purim feast', 'ru': 'Пуримская трапеза'}, year: 2025, tags: ['Rebbetzin Chana', 'Sarah Levin', 'Miriam Gold'], color: 0xFFDB2777, icon: Icons.celebration),
    GalleryPhoto(id: _newId(), event: {'he': 'סדר פסח ציבורי', 'en': 'Public Passover Seder', 'ru': 'Общественный седер'}, year: 2024, tags: ['Rabbi Mendel', 'Rebbetzin Chana', 'David Katz'], color: 0xFF9333EA, icon: Icons.wine_bar),
    GalleryPhoto(id: _newId(), event: {'he': 'ל"ג בעומר', 'en': 'Lag BaOmer bonfire', 'ru': 'Костёр Лаг ба-Омер'}, year: 2024, tags: ['Yosef Cohen', 'David Katz'], color: 0xFFF59E0B, icon: Icons.forest),
    GalleryPhoto(id: _newId(), event: {'he': 'הכנסת ספר תורה', 'en': 'Torah dedication', 'ru': 'Внесение свитка Торы'}, year: 2023, tags: ['Rabbi Mendel', 'Yosef Cohen', 'Sarah Levin'], color: 0xFF0D9488, icon: Icons.auto_stories),
    GalleryPhoto(id: _newId(), event: {'he': 'מחנה קיץ לילדים', 'en': 'Kids summer camp', 'ru': 'Летний лагерь'}, year: 2023, tags: ['Miriam Gold', 'Sarah Levin'], color: 0xFF10B981, icon: Icons.beach_access),
    GalleryPhoto(id: _newId(), event: {'he': 'חתונה קהילתית', 'en': 'Community wedding', 'ru': 'Общинная свадьба'}, year: 2022, tags: ['Rabbi Mendel', 'Rebbetzin Chana'], color: 0xFF6366F1, icon: Icons.favorite),
    GalleryPhoto(id: _newId(), event: {'he': 'ראש השנה', 'en': 'Rosh Hashanah', 'ru': 'Рош ха-Шана'}, year: 2022, tags: ['David Katz', 'Miriam Gold', 'Yosef Cohen'], color: 0xFFF97316, icon: Icons.music_note),
    GalleryPhoto(id: _newId(), event: {'he': 'בר מצווה', 'en': 'Bar Mitzvah', 'ru': 'Бар-мицва'}, year: 2021, tags: ['Rabbi Mendel', 'David Katz'], color: 0xFF0EA5E9, icon: Icons.cake),
  ];

  // ---------------------------------------------------------------------------
  // Famous Jews
  // ---------------------------------------------------------------------------
  late final List<FamousPerson> famous = [
    FamousPerson(id: _newId(), name: {'he': 'ד"ר אברהם רוזן', 'en': 'Dr. Avraham Rosen', 'ru': 'Д-р Авраам Розен'}, profession: {'he': 'רופא ומנתח בכיר', 'en': 'Senior physician & surgeon', 'ru': 'Ведущий врач и хирург'}, bio: {'he': 'ניהל את המחלקה הכירורגית בבית החולים המרכזי במשך 30 שנה.', 'en': 'Led the surgical department of the central hospital for 30 years.', 'ru': 'Возглавлял хирургическое отделение центральной больницы 30 лет.'}, era: Era.present, color: 0xFF2563EB, initials: 'AR'),
    FamousPerson(id: _newId(), name: {'he': 'המהנדס יעקב שטרן', 'en': 'Eng. Yaakov Stern', 'ru': 'Инж. Яаков Штерн'}, profession: {'he': 'מהנדס גשרים', 'en': 'Bridge engineer', 'ru': 'Инженер мостов'}, bio: {'he': 'תכנן את הגשר הגדול בעיר, סמל הנדסי מוכר.', 'en': 'Designed the city\'s great bridge, a recognized engineering landmark.', 'ru': 'Спроектировал большой городской мост.'}, era: Era.present, color: 0xFF0D9488, initials: 'YS'),
    FamousPerson(id: _newId(), name: {'he': 'פרופ׳ לאה גולדברג', 'en': 'Prof. Lea Goldberg', 'ru': 'Проф. Лея Гольдберг'}, profession: {'he': 'חוקרת ומרצה', 'en': 'Researcher & lecturer', 'ru': 'Исследователь и лектор'}, bio: {'he': 'מובילה מחקר בתחום ההיסטוריה היהודית של האזור.', 'en': 'Leads research on the Jewish history of the region.', 'ru': 'Ведёт исследования еврейской истории региона.'}, era: Era.present, color: 0xFFDB2777, initials: 'LG'),
    FamousPerson(id: _newId(), name: {'he': 'הרב שלמה זלמן', 'en': 'Rabbi Shlomo Zalman', 'ru': 'Раввин Шломо Залман'}, profession: {'he': 'רבה של העיר (1890–1955)', 'en': 'City Rabbi (1890–1955)', 'ru': 'Раввин города (1890–1955)'}, bio: {'he': 'עמד בראש הקהילה בתקופות קשות ושמר על גחלת היהדות.', 'en': 'Led the community through difficult times and kept Judaism alive.', 'ru': 'Возглавлял общину в трудные времена.'}, era: Era.past, color: 0xFF7C3AED, initials: 'SZ'),
    FamousPerson(id: _newId(), name: {'he': 'מרים לוין', 'en': 'Miriam Levin', 'ru': 'Мириам Левин'}, profession: {'he': 'סופרת (1901–1978)', 'en': 'Author (1901–1978)', 'ru': 'Писательница (1901–1978)'}, bio: {'he': 'כתבה על חיי היהודים בעיר לפני המלחמה.', 'en': 'Wrote about Jewish life in the city before the war.', 'ru': 'Писала о еврейской жизни до войны.'}, era: Era.past, color: 0xFFB45309, initials: 'ML'),
    FamousPerson(id: _newId(), name: {'he': 'ד"ר יצחק פרל', 'en': 'Dr. Yitzchak Perl', 'ru': 'Д-р Ицхак Перл'}, profession: {'he': 'רופא הקהילה (1875–1943)', 'en': 'Community doctor (1875–1943)', 'ru': 'Врач общины (1875–1943)'}, bio: {'he': 'טיפל בכל בני הקהילה ללא תמורה במשך עשורים.', 'en': 'Cared for the entire community free of charge for decades.', 'ru': 'Десятилетиями лечил общину бесплатно.'}, era: Era.past, color: 0xFF475569, initials: 'YP'),
  ];

  // ---------------------------------------------------------------------------
  // Cemetery
  // ---------------------------------------------------------------------------
  late final List<Grave> graves = [
    Grave(id: _newId(), name: 'Shlomo Zalman Ha-Levi', hebrewName: 'שלמה זלמן הלוי', birthYear: 1890, deathYear: 1955, section: 'A', row: '3', notes: {'he': 'רבה של העיר', 'en': 'City Rabbi', 'ru': 'Раввин города'}),
    Grave(id: _newId(), name: 'Yitzchak Perl', hebrewName: 'יצחק פרל', birthYear: 1875, deathYear: 1943, section: 'A', row: '5', notes: {'he': 'רופא הקהילה', 'en': 'Community doctor', 'ru': 'Врач общины'}),
    Grave(id: _newId(), name: 'Chana Bracha', hebrewName: 'חנה ברכה', birthYear: 1902, deathYear: 1969, section: 'B', row: '1', notes: {'he': 'מייסדת ארגון הנשים', 'en': 'Founder of the women\'s circle', 'ru': 'Основательница женского клуба'}),
    Grave(id: _newId(), name: 'Menachem Weiss', hebrewName: 'מנחם ווייס', birthYear: 1888, deathYear: 1951, section: 'B', row: '4', notes: {'he': 'שוחט ובודק', 'en': 'Shochet', 'ru': 'Резник'}),
    Grave(id: _newId(), name: 'Rivka Stern', hebrewName: 'רבקה שטרן', birthYear: 1910, deathYear: 1994, section: 'C', row: '2', notes: {'he': 'מורה בבית הספר', 'en': 'School teacher', 'ru': 'Учитель'}),
    Grave(id: _newId(), name: 'Aharon Gold', hebrewName: 'אהרן גולד', birthYear: 1866, deathYear: 1932, section: 'A', row: '1', notes: {'he': 'גבאי בית הכנסת', 'en': 'Synagogue gabbai', 'ru': 'Габай синагоги'}),
  ];

  // ---------------------------------------------------------------------------
  // History + tour
  // ---------------------------------------------------------------------------
  final List<HistoryEvent> history = [
    HistoryEvent(year: '1740', title: {'he': 'ראשית הקהילה', 'en': 'First community', 'ru': 'Первая община'}, description: {'he': 'משפחות יהודיות ראשונות מתיישבות בעיר ומקימות מניין.', 'en': 'The first Jewish families settle and form a minyan.', 'ru': 'Первые еврейские семьи основывают миньян.'}),
    HistoryEvent(year: '1812', title: {'he': 'בית הכנסת הגדול', 'en': 'The Great Synagogue', 'ru': 'Большая синагога'}, description: {'he': 'נבנה בית הכנסת המרכזי ששרד עד היום.', 'en': 'The central synagogue, still standing today, is built.', 'ru': 'Построена центральная синагога.'}),
    HistoryEvent(year: '1901', title: {'he': 'תור הזהב', 'en': 'Golden age', 'ru': 'Золотой век'}, description: {'he': 'הקהילה מונה אלפי יהודים, בתי ספר וארגוני חסד.', 'en': 'The community numbers thousands, with schools and charities.', 'ru': 'Община насчитывает тысячи человек.'}),
    HistoryEvent(year: '1941', title: {'he': 'שנות המלחמה', 'en': 'The war years', 'ru': 'Военные годы'}, description: {'he': 'הקהילה נפגעה קשות בתקופת השואה.', 'en': 'The community suffered greatly during the Holocaust.', 'ru': 'Община сильно пострадала в годы Холокоста.'}),
    HistoryEvent(year: '1991', title: {'he': 'התחדשות', 'en': 'Renewal', 'ru': 'Возрождение'}, description: {'he': 'עם נפילת המסך פותח מחדש בית חב"ד בעיר.', 'en': 'After the Iron Curtain, Chabad reopens in the city.', 'ru': 'После падения «железного занавеса» Хабад вновь открывается.'}),
    HistoryEvent(year: 'today', title: {'he': 'קהילה חיה', 'en': 'A living community', 'ru': 'Живая община'}, description: {'he': 'מאות משפחות, גן, בית ספר ופעילות ענפה.', 'en': 'Hundreds of families, a kindergarten, school and vibrant activity.', 'ru': 'Сотни семей, сад, школа и активная жизнь.'}),
  ];

  late final List<TourStop> tour = [
    TourStop(id: _newId(), name: {'he': 'בית הכנסת הגדול', 'en': 'The Great Synagogue', 'ru': 'Большая синагога'}, description: {'he': 'לב הקהילה מזה מאתיים שנה.', 'en': 'The heart of the community for two centuries.', 'ru': 'Сердце общины уже два века.'}, color: 0xFF1D4ED8, icon: Icons.synagogue),
    TourStop(id: _newId(), name: {'he': 'הרובע היהודי', 'en': 'The Jewish quarter', 'ru': 'Еврейский квартал'}, description: {'he': 'סמטאות עתיקות ובתים היסטוריים.', 'en': 'Ancient alleys and historic homes.', 'ru': 'Древние улочки и исторические дома.'}, color: 0xFFB45309, icon: Icons.location_city),
    TourStop(id: _newId(), name: {'he': 'בית החיים הישן', 'en': 'The old cemetery', 'ru': 'Старое кладбище'}, description: {'he': 'מצבות בנות מאות שנים.', 'en': 'Gravestones centuries old.', 'ru': 'Надгробия многовековой давности.'}, color: 0xFF475569, icon: Icons.park),
    TourStop(id: _newId(), name: {'he': 'המקווה ההיסטורי', 'en': 'The historic mikveh', 'ru': 'Историческая миква'}, description: {'he': 'שוקם ופועל עד היום.', 'en': 'Restored and still in use today.', 'ru': 'Восстановлена и действует.'}, color: 0xFF0D9488, icon: Icons.water_drop),
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
    Shiur(id: _newId(), title: {'he': 'פרשת השבוע למעשה', 'en': 'The weekly parasha in practice', 'ru': 'Недельная глава на практике'}, rabbi: {'he': 'הרב מנדל', 'en': 'Rabbi Mendel', 'ru': 'Раввин Мендл'}, topic: {'he': 'פרשה', 'en': 'Parasha', 'ru': 'Глава'}, durationMinutes: 42, date: DateTime.now().subtract(const Duration(days: 2))),
    Shiur(id: _newId(), title: {'he': 'יסודות התניא — שער א׳', 'en': 'Foundations of Tanya — Gate 1', 'ru': 'Основы Тании — врата 1'}, rabbi: {'he': 'הרב מנדל', 'en': 'Rabbi Mendel', 'ru': 'Раввин Мендл'}, topic: {'he': 'חסידות', 'en': 'Chassidut', 'ru': 'Хасидизм'}, durationMinutes: 55, date: DateTime.now().subtract(const Duration(days: 9))),
    Shiur(id: _newId(), title: {'he': 'הלכות שבת למעשה', 'en': 'Practical laws of Shabbat', 'ru': 'Законы субботы на практике'}, rabbi: {'he': 'הרב מנדל', 'en': 'Rabbi Mendel', 'ru': 'Раввин Мендл'}, topic: {'he': 'הלכה', 'en': 'Halacha', 'ru': 'Алаха'}, durationMinutes: 38, date: DateTime.now().subtract(const Duration(days: 16))),
    Shiur(id: _newId(), title: {'he': 'סיפורי צדיקים', 'en': 'Stories of the Tzaddikim', 'ru': 'Истории праведников'}, rabbi: {'he': 'הרב מנדל', 'en': 'Rabbi Mendel', 'ru': 'Раввин Мендл'}, topic: {'he': 'מחשבה', 'en': 'Thought', 'ru': 'Мысль'}, durationMinutes: 30, date: DateTime.now().subtract(const Duration(days: 23))),
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
    {'he': 'החזקת בית חב"ד', 'en': 'General fund', 'ru': 'Общий фонд'},
    {'he': 'סעודות שבת', 'en': 'Shabbat meals', 'ru': 'Субботние трапезы'},
    {'he': 'חינוך ילדים', 'en': "Children's education", 'ru': 'Образование детей'},
    {'he': 'חבילות לנזקקים', 'en': 'Packages for the needy', 'ru': 'Помощь нуждающимся'},
  ];

  late final List<Donation> donations = [
    Donation(id: _newId(), donor: 'Anonymous', amount: 360, campaign: campaigns[0], date: DateTime.now().subtract(const Duration(days: 1))),
    Donation(id: _newId(), donor: 'M. Roth', amount: 1000, campaign: campaigns[2], date: DateTime.now().subtract(const Duration(days: 2))),
    Donation(id: _newId(), donor: 'A. Fishman', amount: 180, campaign: campaigns[1], date: DateTime.now().subtract(const Duration(days: 4))),
  ];

  // ---------------------------------------------------------------------------
  // Bots
  // ---------------------------------------------------------------------------
  final BotConfig telegramBot = BotConfig(name: 'Telegram News', handle: '@chabad_city_news', enabled: true, lastSync: DateTime.now().subtract(const Duration(hours: 2)), itemsSynced: 128);
  final BotConfig socialBot = BotConfig(name: 'Social Auto-Post', handle: 'FB · IG · X · VK', enabled: true, lastSync: DateTime.now().subtract(const Duration(hours: 5)), itemsSynced: 342);

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
    for (final slot in bannerSlots) slot.route: PageBanner(),
  };

  PageBanner bannerFor(String route) =>
      banners[route] ?? banners['/'] ?? PageBanner();

  void setBannerImage(String route, Uint8List bytes) {
    final current = banners.putIfAbsent(route, PageBanner.new);
    current.bytes = bytes;
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
}
