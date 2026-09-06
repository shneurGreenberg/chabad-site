import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../theme.dart';
import '../util/youtube.dart';
import '../services/cloud_sync.dart';
import '../services/image_compress.dart';
import '../services/location_zmanim.dart';
import '../services/persist.dart';
import '../services/notify.dart';
import '../services/telegram.dart';
import '../services/web_prefs.dart';
import '../services/yahrzeit.dart';
import '../services/cors_proxy.dart';
import 'holidays.dart';
import 'kaddish.dart';
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

  static const _contentSeed = 8;
  static const _imgSynagogue = 'assets/images/beit-menachem-1.jpg';
  static const _imgHall = 'assets/images/beit-menachem-2.jpg';
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
  bool _cloudSeen = false;
  bool _cloudPulled = false;
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

  /// Returns true if initial data load is complete (hydrate + cloud pull done).
  bool get isDataReady => _hydrated && _cloudPulled;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      // Set a global timeout of 15 seconds for the entire boot process
      await Future.any([
        _bootCore(),
        Future.delayed(const Duration(seconds: 15)).then((_) {
          throw TimeoutException('Boot timeout after 15 seconds');
        }),
      ]);
    } catch (e) {
      // On any error or timeout, ensure we still mark as ready with seed data
      debugPrint('Boot error: $e');
      if (!_cloudPulled) {
        _cloudPulled = true;
      }
      if (!_hydrated) {
        _hydrated = true;
      }
      _notifyUi();
    }
  }

  Future<void> _bootCore() async {
    try {
      await TelegramService.instance.loadSavedAsync();
    } catch (e) {
      debugPrint('Telegram service load failed: $e');
    }
    
    try {
      await CloudSync.instance.init();
    } catch (e) {
      debugPrint('CloudSync init failed: $e');
    }
    
    try {
      await _hydrate();
    } catch (e) {
      debugPrint('Hydrate failed: $e');
    }
    
    _hydrated = true;
    
    try {
      // Cloud pull with 8 second timeout
      await Future.any([
        _pullCloud(),
        Future.delayed(const Duration(seconds: 8)).then((_) {
          if (!_cloudPulled) {
            _cloudPulled = true;
          }
        }),
      ]);
    } catch (e) {
      debugPrint('Cloud pull failed: $e');
      _cloudPulled = true;
    }
    
    try {
      await _loadKaddishGraves();
    } catch (e) {
      debugPrint('Kaddish graves load failed: $e');
    }
    
    // Retry refreshing times up to 3 times if it fails
    var attempts = 0;
    while (attempts < 3) {
      try {
        await refreshTimes();
        break;
      } catch (e) {
        attempts++;
        if (attempts >= 3) {
          debugPrint('Failed to refresh times after 3 attempts: $e');
          break;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    
    if (!_cloudPulled) {
      _cloudPulled = true;
    }
    _notifyUi();
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
        {
          'he': 'תפילה בבית הכנסת 09:30',
          'en': 'Synagogue prayer 09:30',
          'ru': 'Молитва в синагоге 09:30',
        },
      ),
      MapEntry(
        {'he': 'שבת', 'en': 'Shabbat', 'ru': 'Суббота'},
        {
          'he': 'תפילה 10:00 · סעודת שבת 13:00',
          'en': 'Prayer 10:00 · Shabbat meal 13:00',
          'ru': 'Молитва 10:00 · субботняя трапеза 13:00',
        },
      ),
      MapEntry(
        {'he': 'המבנה', 'en': 'Building', 'ru': 'Здание'},
        {
          'he': 'פתוח כל יום 09:00–17:00',
          'en': 'Open daily 09:00–17:00',
          'ru': 'Открыто каждый день 09:00–17:00',
        },
      ),
      MapEntry(
        {'he': 'סיורים', 'en': 'Tours', 'ru': 'Экскурсии'},
        {
          'he': 'בתיאום מראש',
          'en': 'By appointment',
          'ru': 'По предварительной записи',
        },
      ),
      MapEntry(
        {'he': 'יום ראשון', 'en': 'Sunday', 'ru': 'Воскресенье'},
        {
          'he': 'פעילות ילדים בבית הכנסת',
          'en': 'Children\'s program at the synagogue',
          'ru': 'Детская программа в синагоге',
        },
      ),
      MapEntry(
        {'he': 'מקווה גברים', 'en': "Men's mikveh", 'ru': 'Мужская миква'},
        {
          'he': 'בבוקר',
          'en': 'In the morning',
          'ru': 'Утром',
        },
      ),
      MapEntry(
        {'he': 'מקווה נשים', 'en': "Women's mikveh", 'ru': 'Женская миква'},
        {
          'he': 'בתיאום מראש',
          'en': 'By appointment',
          'ru': 'По предварительной записи',
        },
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

  final SiteLinks links = SiteLinks();
  final List<Loc> campaignNotes = [
    {
      'he': 'החזקת הבניין, תפילות וקהילה יומיומית',
      'en': 'Building upkeep, daily prayer and community life',
      'ru': 'Содержание здания, молитвы и повседневная жизнь общины',
    },
    {
      'he': 'חינוך יהודי לילדים בנובוסיבירסק',
      'en': 'Jewish education for children in Novosibirsk',
      'ru': 'Еврейское образование детей в Новосибирске',
    },
    {
      'he': 'תמיכה בילדים עם צרכים מיוחדים',
      'en': 'Support for children with special needs',
      'ru': 'Поддержка детей с особыми потребностями',
    },
    {
      'he': 'מצות וסיוע לחג הפסח',
      'en': 'Matzah and Passover assistance',
      'ru': 'Маца и помощь к Песаху',
    },
    {
      'he': 'מושב, שופר וסעודות הימים הנוראים',
      'en': 'High Holiday seats, shofar and meals',
      'ru': 'Места, шофар и трапезы Высоких праздников',
    },
  ];
  late final List<CommunityEvent> events = [
    CommunityEvent(
      id: _newId(),
      title: {
        'he': 'סעודת שבת קהילתית',
        'en': 'Community Shabbat meal',
        'ru': 'Общинная субботняя трапеза',
      },
      description: {
        'he': 'סעודה חמה אחרי התפילה. הרשמה מראש — מספר המקומות מוגבל.',
        'en': 'A warm meal after services. Please RSVP — seats are limited.',
        'ru': 'Тёплая трапеза после молитвы. Регистрация заранее — мест мало.',
      },
      place: {
        'he': 'אולם בית מנחם',
        'en': 'Beit Menachem hall',
        'ru': 'Зал Бейт Менахем',
      },
      startsAt: DateTime.now().add(const Duration(days: 5, hours: 3)),
      capacity: 80,
    ),
    CommunityEvent(
      id: _newId(),
      title: {
        'he': 'ערב ראש השנה',
        'en': 'Erev Rosh Hashanah',
        'ru': 'Канун Рош ха-Шана',
      },
      description: {
        'he': 'תפילת ערבית, שופר וברכה לקהילה. מוזמנים משפחות וילדים.',
        'en': 'Maariv, shofar and a blessing for the community. Families welcome.',
        'ru': 'Маарив, шофар и благословение общины. Семьи приглашаются.',
      },
      place: {
        'he': 'בית הכנסת בית מנחם',
        'en': 'Beit Menachem synagogue',
        'ru': 'Синагога Бейт Менахем',
      },
      startsAt: DateTime(DateTime.now().year, 9, 11, 18, 30),
      capacity: 200,
    ),
  ];
  final List<StoreOrder> orders = [];

  String googleMapsApiKey = '';
  final SiteCopy siteCopy = SiteCopy.defaults();
  String paletteId = SitePalettes.classic.id;
  bool _gravesEdited = false;

  SitePalette get palette => SitePalettes.byId(paletteId);

  void setPaletteId(String id) {
    paletteId = SitePalettes.byId(id).id;
    notifyListeners();
  }

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
        'he': 'הימים הנוראים תשפ״ז בבית מנחם',
        'en': 'High Holidays 5787 at Beit Menachem',
        'ru': 'Высокие праздники 5787 в Бейт Менахем',
      },
      body: {
        'he':
            'מזמינים את כל הקהילה לתפילות הימים הנוראים בבית הכנסת בית מנחם, שצ׳טינקינה 68. ראש השנה: 11–13 בספטמבר 2026. יום כיפור: 20–21 בספטמבר. סוכות מתחיל ב־25 בספטמבר. לרישום ולמקומות בסעודות: +7 (383) 222-20-23 או chabad.nsk@gmail.com.',
        'en':
            'All are invited to High Holiday prayers at Beit Menachem, 68 Shchetinkina St. Rosh Hashanah: 11–13 September 2026. Yom Kippur: 20–21 September. Sukkot begins 25 September. For seats and meals: +7 (383) 222-20-23 or chabad.nsk@gmail.com.',
        'ru':
            'Приглашаем общину на молитвы Высоких праздников в синагоге Бейт Менахем, ул. Щетинкина, 68. Рош ха-Шана: 11–13 сентября 2026. Йом Кипур: 20–21 сентября. Суккот с 25 сентября. Запись: +7 (383) 222-20-23 или chabad.nsk@gmail.com.',
      },
      date: DateTime(2026, 8, 20),
      category: {'he': 'חגים', 'en': 'Holidays', 'ru': 'Праздники'},
      imageColor: 0xFFC2410C,
      icon: Icons.auto_awesome,
      imageUrl: _imgSynagogue,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'בית מנחם — בית הכנסת בנובוסיבירסק',
        'en': 'Beit Menachem — the synagogue in Novosibirsk',
        'ru': 'Бейт Менахем — синагога Новосибирска',
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
      imageUrl: _imgSynagogue,
    ),
    NewsArticle(
      id: _newId(),
      title: {
        'he': 'בית ספר אור אבנר — חינוך יהודי בנובוסיבירסק',
        'en': 'Or Avner — Jewish education in Novosibirsk',
        'ru': 'Лицей «Ор Авнер» — еврейское образование',
      },
      body: {
        'he':
            'מאז ספטמבר 2000 פועל בית ספר אור אבנר עם גן לגילאי 3–6, ביוזמת הרב זקלס. הילדים משתתפים בכל חגי הקהילה, ובוגרים ממשיכים ללימודים ברוסיה ובישראל. כתובת: רחוב שקספיר 9ב.',
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
      imageUrl: _imgHall,
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
    try {
      final data = await LocationZmanimApi.fetchTimes(location);
      zmanim
        ..clear()
        ..addAll(data.zmanim);
      shabbat
        ..clear()
        ..addAll(data.shabbat);
      debugPrint('Zmanim refreshed: candle=${shabbat['candle']}, havdala=${shabbat['havdala']}, parasha_he=${shabbat['parasha_he']}');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh zmanim: $e');
      // Keep existing seed data on error
      rethrow;
    }
  }

  /// Called when the UI locale changes to refresh location name and zmanim.
  Future<void> onLocaleChanged(String lang) async {
    if (location.latitude == 0 && location.longitude == 0) return;
    
    try {
      final place = await LocationZmanimApi.fromCoordinates(
        location.latitude,
        location.longitude,
        lang: lang,
      );
      location.cityName = place.name;
      await refreshTimes();
    } catch (_) {}
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

  static const publicSiteBase = 'https://shneurgreenberg.github.io/chabad-site';

  List<NewsArticle> get newsPendingTelegram =>
      news.where((a) => a.published && !a.onTelegram).toList();

  Future<void> publishNewsToTelegram(NewsArticle a, String lang) async {
    if (a.onTelegram) return;
    final tg = TelegramService.instance;
    final title = trLoc(a.title, lang);
    final body = trLoc(a.body, lang);
    final link = '$publicSiteBase/news/${a.id}';
    final text = '<b>${TelegramService.escapeHtml(title)}</b>\n\n'
        '${TelegramService.escapeHtml(body)}\n\n'
        '🔗 $link';
    final url = a.imageUrl;
    final photo = (url != null &&
            (url.startsWith('http://') || url.startsWith('https://')))
        ? url
        : null;
    final id = await tg.publishToChannel(text: text, photoUrl: photo);
    a.telegramPublishedId = id;
    a.telegramPublishedAt = DateTime.now();
    telegramBot.lastSync = DateTime.now();
    telegramBot.itemsSynced += 1;
    notifyListeners();
  }

  Future<int> publishPendingNewsToTelegram(String lang) async {
    var n = 0;
    for (final a in List<NewsArticle>.from(newsPendingTelegram)) {
      await publishNewsToTelegram(a, lang);
      n++;
    }
    return n;
  }

  // ---------------------------------------------------------------------------
  // Zmanim
  // ---------------------------------------------------------------------------
  final List<Zman> zmanim = [
    Zman(name: {'he': 'עלות השחר', 'en': 'Dawn', 'ru': 'Рассвет'}, time: '04:52', kind: ZmanKind.dawn),
    Zman(name: {'he': 'הנץ החמה', 'en': 'Sunrise', 'ru': 'Восход'}, time: '05:58', kind: ZmanKind.sunrise),
    Zman(name: {'he': 'סוף זמן ק"ש', 'en': 'Latest Shema', 'ru': 'Крайний Шма'}, time: '09:14', kind: ZmanKind.shema),
    Zman(name: {'he': 'סוף זמן תפילה', 'en': 'Latest Shacharit', 'ru': 'Крайняя Шахарит'}, time: '09:50', kind: ZmanKind.shacharit),
    Zman(name: {'he': 'חצות היום', 'en': 'Midday', 'ru': 'Полдень'}, time: '12:41', kind: ZmanKind.midday),
    Zman(name: {'he': 'מנחה גדולה', 'en': 'Mincha Gedola', 'ru': 'Минха гдола'}, time: '13:15', kind: ZmanKind.mincha),
    Zman(name: {'he': 'שקיעה', 'en': 'Sunset', 'ru': 'Закат'}, time: '19:24', kind: ZmanKind.sunset),
    Zman(name: {'he': 'צאת הכוכבים', 'en': 'Nightfall', 'ru': 'Появление звёзд'}, time: '19:52', kind: ZmanKind.stars),
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
        'he': 'בית הכנסת בנובוסיבירסק. תפילה בשני וחמישי ב־09:30, בשבת ב־10:00, והמבנה פתוח כל יום 09:00–17:00. סיורים בתיאום מראש.',
        'en': 'The synagogue in Novosibirsk. Prayer Monday and Thursday at 09:30, Shabbat at 10:00. Building open daily 09:00–17:00. Tours by appointment.',
        'ru': 'Синагога Новосибирска. Молитва в понедельник и четверг в 09:30, в субботу в 10:00. Здание открыто каждый день 09:00–17:00. Экскурсии по записи.',
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
        'he':
            'פעילות לילדים בבית הכנסת ביום ראשון: שירים, סיפורי תורה, מלאכה וכיבוד. מתאים לגילאי הגן ובית הספר. ההורים מוזמנים להישאר.',
        'en':
            'Sunday children\'s program at the synagogue: songs, Torah stories, crafts and a snack. For preschool and school ages. Parents are welcome to stay.',
        'ru':
            'Детская программа в синагоге по воскресеньям: песни, рассказы Торы, поделки и угощение. Для дошкольников и школьников. Родители могут остаться.',
      },
      schedule: {'he': 'יום ראשון בבית הכנסת', 'en': 'Sunday at the synagogue', 'ru': 'Воскресенье в синагоге'},
      audience: {'he': 'ילדים', 'en': 'Children', 'ru': 'Дети'},
      icon: Icons.child_care,
      color: 0xFFF59E0B,
      imageUrl: _imgHall,
    ),
    Program(
      id: _newId(),
      title: {'he': 'סעודת שבת', 'en': 'Shabbat meal', 'ru': 'Субботняя трапеза'},
      description: {
        'he':
            'סעודת שבת קהילתית בבית מנחם אחרי התפילה — קידוש, ארוחה חמה ושיחה. הרשמה מראש עוזרת למטבח לתכנן.',
        'en':
            'Community Shabbat meal at Beit Menachem after prayer — Kiddush, a hot meal and conversation. Please register so the kitchen can plan.',
        'ru':
            'Общинная субботняя трапеза в Бейт Менахем после молитвы — кидуш, горячий обед и беседа. Запишитесь заранее.',
      },
      schedule: {'he': 'שבת 13:00', 'en': 'Shabbat 13:00', 'ru': 'Шаббат 13:00'},
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.restaurant,
      color: 0xFFC2410C,
      imageUrl: _imgHall,
    ),
    Program(
      id: _newId(),
      title: {'he': 'בית ספר אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'},
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
      imageUrl: _imgHall,
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
      imageUrl: _imgSynagogue,
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
      imageUrl: _imgHall,
    ),
    Program(
      id: _newId(),
      title: {'he': 'חוג נשים', 'en': "Women's Circle", 'ru': 'Женский клуб'},
      description: {
        'he':
            'מפגשי נשים בבית מנחם: לימוד, חברותא והכנות לחגים. לפרטים: הרבנית מרים זקלס דרך המזכירות.',
        'en':
            'Women\'s gatherings at Beit Menachem: study, friendship and holiday prep. Details: Rebbetzin Miriam Zaklos via the office.',
        'ru':
            'Встречи женщин в Бейт Менахем: учёба, общение и подготовка к праздникам. Подробности: раббанит Мириам Заклос через секретариат.',
      },
      schedule: {'he': 'לפי הזמנה', 'en': 'By invitation', 'ru': 'По приглашению'},
      audience: {'he': 'נשים', 'en': 'Women', 'ru': 'Женщины'},
      icon: Icons.diversity_3,
      color: 0xFFDB2777,
    ),
    Program(
      id: _newId(),
      title: {'he': 'שיעורי תורה', 'en': 'Torah classes', 'ru': 'Уроки Торы'},
      description: {
        'he':
            'שיעורי פרשה, תניא והלכה עם הרב שניאור זלמן זקלס. חלק מהשיעורים יועלו ליוטיוב — אפשר להוסיף קישור בדף המנהל.',
        'en':
            'Parasha, Tanya and Halacha with Rabbi Shneur Zalman Zaklos. Some classes will be posted on YouTube — add the link in the admin library.',
        'ru':
            'Уроки главы, Тании и алахи с раввином Шнеуром Залманом Заклосом. Часть занятий будет на YouTube — ссылку можно добавить в админке.',
      },
      schedule: {'he': 'לפי לוח השיעורים', 'en': 'Per class calendar', 'ru': 'По расписанию уроков'},
      audience: {'he': 'כל הקהילה', 'en': 'Everyone', 'ru': 'Все'},
      icon: Icons.menu_book,
      color: 0xFF1D4ED8,
      imageUrl: _imgSynagogue,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Gallery
  // ---------------------------------------------------------------------------
  late final List<GalleryPhoto> gallery = [
    GalleryPhoto(
      id: _newId(),
      event: {'he': 'בית מנחם', 'en': 'Beit Menachem', 'ru': 'Бейт Менахем'},
      year: 2013,
      tags: ['Rabbi Zaklos', 'Rebbetzin Miriam'],
      color: 0xFF1D4ED8,
      icon: Icons.synagogue,
      photos: [
        GalleryShot(id: _newId(), imageUrl: 'assets/images/beit-menachem-1.jpg'),
        GalleryShot(id: _newId(), imageUrl: 'assets/images/beit-menachem-2.jpg'),
      ],
    ),
    GalleryPhoto(id: _newId(), event: {'he': 'חנוכה בנובוסיבירסק', 'en': 'Chanukah in Novosibirsk', 'ru': 'Ханука в Новосибирске'}, year: 2024, tags: ['Rabbi Zaklos', 'Sender Kruglov'], color: 0xFFF59E0B, icon: Icons.local_fire_department),
    GalleryPhoto(id: _newId(), event: {'he': 'ראש השנה בבית מנחם', 'en': 'Rosh Hashanah at Beit Menachem', 'ru': 'Рош ха-Шана в Бейт Менахем'}, year: 2024, tags: ['Rabbi Zaklos', 'Rebbetzin Miriam'], color: 0xFFF97316, icon: Icons.music_note),
    GalleryPhoto(id: _newId(), event: {'he': 'ילדי אור אבנר בחג', 'en': 'Or Avner children at a holiday', 'ru': 'Дети Ор Авнер на празднике'}, year: 2023, tags: ['Rebbetzin Miriam'], color: 0xFF10B981, icon: Icons.child_care),
    GalleryPhoto(id: _newId(), event: {'he': 'סדר פסח קהילתי', 'en': 'Community Passover Seder', 'ru': 'Общинный седер Песаха'}, year: 2024, tags: ['Rabbi Zaklos', 'Rebbetzin Miriam', 'Sender Kruglov'], color: 0xFF9333EA, icon: Icons.wine_bar),
  ];

  // ---------------------------------------------------------------------------
  // Famous Jews
  // ---------------------------------------------------------------------------
  late final List<FamousPerson> famous = [
    FamousPerson(id: _newId(), name: {'he': 'הרב שניאור זלמן זקלס', 'en': 'Rabbi Shneur Zalman Zaklos', 'ru': 'Раввин Шнеур Залман Заклос'}, profession: {'he': 'רב העיר ושליח חב״ד', 'en': 'Chief Rabbi & Chabad emissary', 'ru': 'Главный раввин и посланник Хабада'}, bio: {'he': 'נולד בקריית מלאכי. למד בישיבות בניו יורק, מילאנו וברזיל, והגיע לשליחות בנובוסיבירסק ב־1999. רב העיר והמחוז, יוזם בית ספר אור אבנר ובית מנחם.', 'en': 'Born in Kiryat Malachi. Studied in New York, Milan and Brazil, and arrived on shlichut in 1999. Chief Rabbi of the city and region; founded Or Avner and Beit Menachem.', 'ru': 'Родился в Кирьят-Малахи. Учился в Нью-Йорке, Милане и Бразилии, прибыл в 1999. Главный раввин города и области, инициатор «Ор Авнер» и «Бейт Менахем».'}, era: Era.present, color: 0xFF1D4ED8, initials: 'SZ'),
    FamousPerson(id: _newId(), name: {'he': 'הרבנית מרים זקלס', 'en': 'Rebbetzin Miriam Zaklos', 'ru': 'Раббанит Мириам Заклос'}, profession: {'he': 'שליחת חב״ד', 'en': 'Chabad emissary', 'ru': 'Посланница Хабада'}, bio: {'he': 'שותפה לשליחות בנובוסיבירסק מאז 1999. מובילה חינוך, חגים וחיי הקהילה לצד הרב.', 'en': 'Partner in the Novosibirsk shlichut since 1999. Leads education, holidays and community life alongside the Rabbi.', 'ru': 'Вместе с раввином на миссии с 1999 года. Образование, праздники и жизнь общины.'}, era: Era.present, color: 0xFFDB2777, initials: 'MZ'),
    FamousPerson(id: _newId(), name: {'he': 'אלכסנדר (סנדר) קרוגלוב', 'en': 'Alexander (Sender) Kruglov', 'ru': 'Александр (Сендер) Круглов'}, profession: {'he': 'נשיא הקהילה', 'en': 'President of the community', 'ru': 'Президент общины'}, bio: {'he': 'נולד ב־1990 באוסט־קמנוגורסק. מאז 2015 בנובוסיבירסק: מנהיג נוער, משגיח במסעדה הכשרה, ומיוני 2019 נשיא קהילת בית מנחם.', 'en': 'Born 1990 in Ust-Kamenogorsk. In Novosibirsk since 2015: youth leader, kosher restaurant mashgiach, and since June 2019 president of the Beit Menachem community.', 'ru': 'Родился в 1990 в Усть-Каменогорске. С 2015 в Новосибирске: лидер молодёжи, машгиах, с июня 2019 президент общины «Бейт Менахем».'}, era: Era.present, color: 0xFF0D9488, initials: 'SK'),
    ...historicalFamous(),
  ];

  static List<FamousPerson> historicalFamous() => [
        FamousPerson(
          id: 'famous-kantorovich',
          name: {
            'he': 'לאוניד קנטורוביץ׳',
            'en': 'Leonid Kantorovich',
            'ru': 'Леонид Канторович'
          },
          profession: {
            'he': 'מתמטיקאי וכלכלן, חתן פרס נובל',
            'en': 'Mathematician and economist, Nobel laureate',
            'ru': 'Математик и экономист, лауреат Нобелевской премии'
          },
          bio: {
            'he': 'מתמטיקאי וכלכלן יהודי־רוסי, אבי התכנון הליניארי וחתן פרס נובל לכלכלה (1975). בין 1960–1971 חי בנובוסיבירסק, הקים וניהל את המחלקה למתמטיקה חישובית באוניברסיטת נובוסיבירסק (NSU).',
            'en': 'Jewish-Russian mathematician and economist, father of linear programming and 1975 Nobel laureate in economics. Lived in Novosibirsk in 1960–1971 and founded the computational mathematics department at NSU.',
            'ru': 'Еврейский математик и экономист, основоположник линейного программирования, Нобелевский лауреат 1975 года. В 1960–1971 жил в Новосибирске и создал кафедру вычислительной математики в НГУ.'
          },
          era: Era.past,
          color: 0xFF1D4ED8,
          initials: 'LK',
          photoUrl: 'assets/images/famous/kantorovich.jpg',
        ),
        FamousPerson(
          id: 'famous-budker',
          name: {
            'he': 'גרש בודקר',
            'en': 'Gersh Budker',
            'ru': 'Герш Будкер'
          },
          profession: {
            'he': 'פיזיקאי גרעין, מייסד BINP',
            'en': 'Nuclear physicist, founder of BINP',
            'ru': 'Физик-ядерщик, основатель ИЯФ'
          },
          bio: {
            'he': 'פיזיקאי גרעין יהודי פורץ דרך. ייסד ב־1959 את המכון לפיזיקה גרעינית בנובוסיבירסק (BINP) ועמד בראשו — המכון נקרא כיום על שמו. המציא בעיר את שיטת הקירור האלקטרוני של חלקיקים.',
            'en': 'Pioneering Jewish nuclear physicist. Founded the Budker Institute of Nuclear Physics (BINP) in Novosibirsk in 1959 and invented electron cooling of particles there. The institute now bears his name.',
            'ru': 'Выдающийся физик-ядерщик. В 1959 основал Институт ядерной физики в Новосибирске и изобрёл электронное охлаждение частиц. Институт носит его имя.'
          },
          era: Era.past,
          color: 0xFF7C3AED,
          initials: 'GB',
          photoUrl: 'assets/images/famous/budker.jpg',
        ),
        FamousPerson(
          id: 'famous-sokolov',
          name: {
            'he': 'ארסני סוקולוב',
            'en': 'Arseny Sokolov',
            'ru': 'Арсений Соколов'
          },
          profession: {
            'he': 'פיזיקאי תאורטי',
            'en': 'Theoretical physicist',
            'ru': 'Физик-теоретик'
          },
          bio: {
            'he': 'פיזיקאי תאורטי יהודי נודע, שותף לפיתוח תיאוריית קרינת הסינכרוטרון. נולד בנובוסיבירסק ב־1910.',
            'en': 'Noted Jewish theoretical physicist who helped develop synchrotron radiation theory. Born in Novosibirsk in 1910.',
            'ru': 'Известный физик-теоретик, один из авторов теории синхротронного излучения. Родился в Новосибирске в 1910 году.'
          },
          era: Era.past,
          color: 0xFF0F766E,
          initials: 'AS',
          photoUrl: 'assets/images/famous/sokolov.jpg',
        ),
        FamousPerson(
          id: 'famous-vengerov',
          name: {
            'he': 'מקסים ונגרוב',
            'en': 'Maxim Vengerov',
            'ru': 'Максим Венгеров'
          },
          profession: {
            'he': 'כנר, ויולן ומנצח',
            'en': 'Violinist, violist and conductor',
            'ru': 'Скрипач, альтист и дирижёр'
          },
          bio: {
            'he': 'כנר וירטואוז מהשורה הראשונה בעולם. נולד בנובוסיבירסק ב־1974 להורים מוזיקאים יהודים, עלה לישראל וקיבל אזרחות ישראלית.',
            'en': 'World-renowned violinist. Born in Novosibirsk in 1974 to local Jewish musicians, later made aliyah and became an Israeli citizen.',
            'ru': 'Скрипач мирового уровня. Родился в Новосибирске в 1974 году в еврейской музыкальной семье, репатриировался в Израиль.'
          },
          era: Era.present,
          color: 0xFFB45309,
          initials: 'MV',
          photoUrl: 'assets/images/famous/vengerov.jpg',
        ),
        FamousPerson(
          id: 'famous-zak',
          name: {
            'he': 'איזידור זאק',
            'en': 'Isidor Zak',
            'ru': 'Исидор Зак'
          },
          profession: {
            'he': 'מנצח, מייסד תיאטרון האופרה',
            'en': 'Conductor, opera theatre founder',
            'ru': 'Дирижёр, основатель театра оперы'
          },
          bio: {
            'he': 'מנצח ואיש מוזיקה יהודי בולט. ממייסדיו ומנהלו המוזיקלי הראשון של תיאטרון האופרה והבלט של נובוסיבירסק — המבנה הגדול בעיר וסמלה התרבותי.',
            'en': 'Prominent Jewish conductor. Co-founder and first music director of the Novosibirsk Opera and Ballet Theatre, the city’s largest cultural landmark.',
            'ru': 'Выдающийся дирижёр. Один из основателей и первый музыкальный руководитель Новосибирского театра оперы и балета — главного культурного символа города.'
          },
          era: Era.past,
          color: 0xFF9F1239,
          initials: 'IZ',
          photoUrl: 'assets/images/famous/zak.jpg',
        ),
        FamousPerson(
          id: 'famous-rabinovich',
          name: {
            'he': 'אלכסנדר רבינוביץ׳',
            'en': 'Aleksandr Rabinovich',
            'ru': 'Александр Рабинович'
          },
          profession: {
            'he': 'מוזיקולוג ומלחין',
            'en': 'Musicologist and composer',
            'ru': 'Музыковед и композитор'
          },
          bio: {
            'he': 'מוזיקולוג ומלחין יהודי חשוב שנולד בסנקט פטרבורג. פעל, יצר ונפטר בנובוסיבירסק ב־1943, בתקופת פינוי אנשי הרוח במלחמת העולם השנייה.',
            'en': 'Important Jewish musicologist and composer, born in Saint Petersburg. Worked and died in Novosibirsk in 1943 during the wartime evacuation of intellectuals.',
            'ru': 'Крупный музыковед и композитор, уроженец Санкт-Петербурга. Работал и умер в Новосибирске в 1943 году во время эвакуации деятелей культуры.'
          },
          era: Era.past,
          color: 0xFF334155,
          initials: 'AR',
        ),
        FamousPerson(
          id: 'famous-vaksberg',
          name: {
            'he': 'ארקדי ואקסברג',
            'en': 'Arkady Vaksberg',
            'ru': 'Аркадий Ваксберг'
          },
          profession: {
            'he': 'משפטן, היסטוריון ועיתונאי',
            'en': 'Lawyer, historian and journalist',
            'ru': 'Юрист, историк и журналист'
          },
          bio: {
            'he': 'משפטן, היסטוריון, עיתונאי חוקר וסופר יהודי־רוסי. נולד בנובוסיבירסק ב־1927 וכתב עשרות ספרים על מאחורי הקלעים של המשטר הסובייטי, ובהם «סטלין נגד היהודים».',
            'en': 'Jewish-Russian lawyer, historian and investigative journalist. Born in Novosibirsk in 1927; wrote many books on the Soviet regime, including Stalin Against the Jews.',
            'ru': 'Юрист, историк и журналист-расследователь. Родился в Новосибирске в 1927 году; автор книг о советской власти, в том числе «Сталин против евреев».'
          },
          era: Era.past,
          color: 0xFF155E75,
          initials: 'AV',
          photoUrl: 'assets/images/famous/vaksberg.jpg',
        ),
      ];

  void _ensureHistoricalFamous() {
    final have = {for (final p in famous) p.id: p};
    for (final p in historicalFamous()) {
      final existing = have[p.id];
      if (existing == null) {
        famous.add(p);
        _noteId(p.id);
        continue;
      }
      if ((existing.photoUrl == null || existing.photoUrl!.trim().isEmpty) &&
          p.photoUrl != null) {
        existing.photoUrl = p.photoUrl;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cemetery (live kaddish API, with bundled JSON as fallback)
  // ---------------------------------------------------------------------------
  late final List<Grave> graves = [];

  Future<void> refreshKaddishGraves() => _loadKaddishGraves();

  Grave? graveById(String id) {
    try {
      return graves.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch full person details from the kaddish API, including biography.
  /// Tries /api/board/person/:id first (live endpoint), then /api/people/:id as fallback.
  /// CORS is allowed (Access-Control-Allow-Origin: *), so no proxy needed.
  Future<Grave?> fetchPersonDetail(String id) async {
    // Extract numeric ID from kaddish-XXX format
    final numericId = id.replaceFirst('kaddish-', '');
    
    // Try /api/board/person/:id first (live endpoint with biographies)
    try {
      final boardUrl = '$kaddishBoardPersonApi/$numericId';
      final res = await http.get(Uri.parse(boardUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        final person = personFromApiResponse(json);
        if (person != null) {
          return graveFromKaddish(person);
        }
      }
    } catch (_) {
      // Continue to people API fallback
    }
    
    // Fallback to /api/people/:id (currently 404, will be available later)
    try {
      final peopleUrl = '$kaddishPeopleApi/$numericId';
      final res = await http.get(Uri.parse(peopleUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        final person = personFromApiResponse(json);
        if (person != null) {
          return graveFromKaddish(person);
        }
      }
    } catch (_) {
      // API not available or error
    }
    
    // Final fallback to existing grave data
    return graveById(id);
  }

  Future<void> _loadKaddishGraves() async {
    final bundled = await _loadBundledKaddishGraves();
    if (bundled.isNotEmpty) {
      _applyKaddishGraves(bundled);
    }
    final live = await _fetchLiveKaddishGraves();
    final fromFile = mergeKaddishGraves(live, bundled);
    if (fromFile.isEmpty) return;
    _applyKaddishGraves(fromFile);
  }

  void _applyKaddishGraves(List<Grave> fromFile) {
    final custom = graves.where((g) => !g.id.startsWith('kaddish-')).toList();
    graves
      ..clear()
      ..addAll(fromFile)
      ..addAll(custom);
    _notifyUi();
  }

  Future<List<Grave>> _loadBundledKaddishGraves() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/kaddish_novosibirsk.json');
      return [
        for (final item in peopleFromKaddishJson(jsonDecode(raw)))
          graveFromKaddish(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Grave>> _fetchLiveKaddishGraves() async {
    for (final url in [kaddishPeopleApi, kaddishBoardApi]) {
      try {
        final res = await CorsProxy.getDirectOrProxy(url);
        if (res.statusCode < 200 || res.statusCode >= 300) continue;
        final people = peopleFromKaddishJson(jsonDecode(res.body));
        if (people.isEmpty) continue;
        return [for (final person in people) graveFromKaddish(person)];
      } catch (_) {}
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // History + tour
  // ---------------------------------------------------------------------------
  final List<HistoryEvent> history = [
    HistoryEvent(year: '1893', title: {'he': 'ראשית הקהילה', 'en': 'Community founded', 'ru': 'Основание общины'}, description: {'he': 'הקהילה היהודית בנובו־ניקולאייבסק (לימים נובוסיבירסק) נוסדת. בין החברים: סוחרים, בעלי מלאכה וגולים.', 'en': 'The Jewish community of Novo-Nikolayevsk (later Novosibirsk) is formed — merchants, craftsmen and exiles.', 'ru': 'Еврейская община Новониколаевска (затем Новосибирск) образована: купцы, мастеровые и ссыльные.'}),
    HistoryEvent(year: '1926', title: {'he': 'נובוסיבירסק', 'en': 'The city is renamed', 'ru': 'Город переименован'}, description: {'he': 'שם העיר משתנה לנובוסיבירסק. החיים היהודיים ממשיכים תחת לחץ סובייטי גובר.', 'en': 'The city is renamed Novosibirsk. Jewish life continues under growing Soviet pressure.', 'ru': 'Город получает имя Новосибирск. Еврейская жизнь — под нарастающим советским давлением.'}),
    HistoryEvent(year: '1990s', title: {'he': 'התחדשות', 'en': 'Revival', 'ru': 'Возрождение'}, description: {'he': 'עם הפשרה הפוליטית הקהילה מתחדשת ומצטרפת לפדרציית הקהילות היהודיות ברוסיה (FEOR). פועלים גם הסוכנות היהודית וחסד «אתיקווה».', 'en': 'With political thaw the community revives and joins FEOR. The Jewish Agency and Hesed Atikva also operate in the city.', 'ru': 'С оттепелью община возрождается и входит в ФЕОР. Работают Сохнут и хесед «Атиква».'}),
    HistoryEvent(year: '1999', title: {'he': 'שליחות חב״ד', 'en': 'Chabad arrives', 'ru': 'Приезд Хабада'}, description: {'he': 'הרב שניאור זלמן זקלס מגיע לעיר כרב מוסמך ראשון בהיסטוריה של נובוסיבירסק, שליח הרבי מליובאוויטש. העירייה מקצה קרקע במרכז העיר לבית כנסת.', 'en': 'Rabbi Shneur Zalman Zaklos arrives as the first ordained rabbi in the city\'s history, a Chabad emissary. The municipality grants land downtown for a synagogue.', 'ru': 'Раввин Шнеур Залман Заклос — первый дипломированный раввин в истории города, посланник Ребе. Мэрия выделяет участок в центре под синагогу.'}),
    HistoryEvent(year: '2000', title: {'he': 'אור אבנר', 'en': 'Or Avner', 'ru': 'Ор Авнер'}, description: {'he': 'נפתח בית הספר היהודי אור אבנר עם גן לגיל הרך.', 'en': 'Or Avner Jewish school and preschool open.', 'ru': 'Открывается еврейский лицей «Ор Авнер» с дошкольной группой.'}),
    HistoryEvent(year: '2013', title: {'he': 'חנוכת בית מנחם', 'en': 'Beit Menachem opens', 'ru': 'Открытие Бейт Менахем'}, description: {'he': 'ב־28 באוגוסט נחנך המרכז (~3,400 מ״ר) ברחוב שצ׳טינקינה 68, על שם הרבי. בטקס: הרב ברל לזר, ראש העיר גורודצקי, ויותר מאלף אורחים. הבנייה נמשכה כ־13 שנה מתרומות.', 'en': 'On 28 August the ~3,400 m² center at 68 Shchetinkina St. opens, named for the Rebbe. Chief Rabbi Berel Lazar, Mayor Gorodetsky and 1,000+ guests attend. Construction took about 13 years, funded by donations.', 'ru': '28 августа открыт центр (~3400 м²) на ул. Щетинкина, 68, в честь Ребе. Берл Лазар, мэр Городецкий и более тысячи гостей. Строительство около 13 лет на пожертвования.'}),
    HistoryEvent(year: 'today', title: {'he': 'קהילה חיה בסיביר', 'en': 'A living community in Siberia', 'ru': 'Живая община Сибири'}, description: {'he': 'תפילות יומיות, מקווה, חנות כשרה, נוער, אור אבנר ומרכז לב. באזור כ־12,000 יהודים. בית מנחם הוא הבית הרוחני של יהדות נובוסיבירסק.', 'en': 'Daily prayers, mikveh, kosher shop, youth, Or Avner and Lev. About 12,000 Jews in the region. Beit Menachem is the spiritual home of Novosibirsk Jewry.', 'ru': 'Ежедневные молитвы, миква, кошерный магазин, молодёжь, «Ор Авнер» и «Лев». Около 12 000 евреев в регионе. Бейт Менахем — духовный дом евреев Новосибирска.'}),
  ];

  late final List<TourStop> tour = [
    TourStop(
      id: _newId(), 
      name: {'he': 'בית מנחם', 'en': 'Beit Menachem', 'ru': 'Бейт Менахем'}, 
      description: {'he': 'בית הכנסת והמרכז הקהילתי, רחוב שצ׳טינקינה 68. כיפה ומגן דוד — לב יהדות נובוסיבירסק.', 'en': 'Synagogue and community center, 68 Shchetinkina St. Dome and Star of David — the heart of Novosibirsk Jewry.', 'ru': 'Синагога и общинный центр, ул. Щетинкина, 68. Купол и звезда Давида — сердце еврейского Новосибирска.'}, 
      color: 0xFF1D4ED8, 
      icon: Icons.synagogue,
      panoramaUrl: _imgSynagogue,
      photos: [
        GalleryShot(id: _newId(), imageUrl: _imgSynagogue),
        GalleryShot(id: _newId(), imageUrl: _imgHall),
      ],
    ),
    TourStop(
      id: _newId(), 
      name: {'he': 'מקווה וחנות כשרה', 'en': 'Mikveh & kosher shop', 'ru': 'Миква и кошерный магазин'}, 
      description: {'he': 'בתוך אותו בניין: מקווה לגברים ולנשים, חנות כשרה ואולם אירועים.', 'en': 'In the same building: men\'s and women\'s mikveh, kosher shop and banquet hall.', 'ru': 'В том же здании: миквы, кошерный магазин и праздничный зал.'}, 
      color: 0xFF0D9488, 
      icon: Icons.water_drop,
      panoramaUrl: _imgHall,
      photos: [
        GalleryShot(id: _newId(), imageUrl: _imgHall),
      ],
    ),
    TourStop(
      id: _newId(), 
      name: {'he': 'בית ספר אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'}, 
      description: {'he': 'בית הספר היהודי וגן הילדים, רחוב שקספיר 9ב.', 'en': 'The Jewish school and preschool, 9b Shakspira St.', 'ru': 'Еврейский лицей и детская группа, ул. Шекспира, 9Б.'}, 
      color: 0xFF3B82F6, 
      icon: Icons.school,
      panoramaUrl: _imgSynagogue,
    ),
    TourStop(
      id: _newId(), 
      name: {'he': 'מרכז לב', 'en': 'Lev center', 'ru': 'Центр Лев'}, 
      description: {'he': 'מרכז לילדים עם צרכים מיוחדים ובריכה, רחוב שקספיר 9א.', 'en': 'Center for children with special needs and a pool, 9a Shakspira St.', 'ru': 'Центр для детей с ОВЗ и бассейн, ул. Шекспира, 9А.'}, 
      color: 0xFFEC4899, 
      icon: Icons.favorite,
      panoramaUrl: _imgHall,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Tourist Info
  // ---------------------------------------------------------------------------
  late final List<TouristInfo> touristInfo = [
    TouristInfo(
      id: _newId(),
      title: {'he': 'תפילות והשתתפות בחיי הקהילה', 'en': 'Prayer services and community participation', 'ru': 'Молитвы и участие в жизни общины'},
      description: {
        'he': 'ברוכים הבאים לבית הכנסת בית מנחם! תפילות בימי שני וחמישי ב־09:30, בשבת ב־10:00. המבנה פתוח כל יום 09:00–17:00. סיורים בתיאום מראש. כתובת: רחוב שצ׳טינקינה 68.',
        'en': 'Welcome to Beit Menachem synagogue! Prayer Monday and Thursday at 09:30, Shabbat at 10:00. Building open daily 09:00–17:00. Tours by appointment. Address: 68 Shchetinkina St.',
        'ru': 'Добро пожаловать в синагогу Бейт Менахем! Молитвы в понедельник и четверг в 09:30, в субботу в 10:00. Здание открыто каждый день 09:00–17:00. Экскурсии по записи. Адрес: ул. Щетинкина, 68.',
      },
      category: TouristCategory.synagogue,
      icon: Icons.synagogue,
      color: 0xFF1D4ED8,
      imageUrl: _imgSynagogue,
    ),
    TouristInfo(
      id: _newId(),
      title: {'he': 'חנות כשרה בבית מנחם', 'en': 'Kosher shop at Beit Menachem', 'ru': 'Кошерный магазин в Бейт Менахем'},
      description: {
        'he': 'החנות הכשרה בבית מנחם מציעה יודאיקה, ספרים קדושים, יין כשר, מצות ומזון כשר. פתוח ימי א׳–ה׳ 10:00–17:00. לקראת חגים — סעודות חמות להזמנה: +7 (383) 222-20-23.',
        'en': 'The kosher shop at Beit Menachem offers judaica, holy books, kosher wine, matzah and kosher food. Open Sun–Thu 10:00–17:00. For holidays — hot meals to order: +7 (383) 222-20-23.',
        'ru': 'Кошерный магазин в Бейт Менахем: иудаика, святые книги, кошерное вино, маца и кошерные продукты. Открыто вс–чт 10:00–17:00. К праздникам — горячие трапезы на заказ: +7 (383) 222-20-23.',
      },
      category: TouristCategory.kosherFood,
      icon: Icons.storefront,
      color: 0xFF059669,
    ),
    TouristInfo(
      id: _newId(),
      title: {'he': 'מלון מרינס פארק', 'en': 'Marins Park Hotel', 'ru': 'Отель Маринс Парк'},
      description: {
        'he': 'מלון בדירוג 4 כוכבים, 10 דקות הליכה מבית מנחם. חדרים נוחים, ארוחת בוקר, WiFi. כתובת: רחוב Oktyabrskaya 42. טלפון: +7 (383) 227-00-00.',
        'en': '4-star hotel, 10-minute walk from Beit Menachem. Comfortable rooms, breakfast, WiFi. Address: 42 Oktyabrskaya St. Phone: +7 (383) 227-00-00.',
        'ru': 'Отель 4 звезды, 10 минут пешком от Бейт Менахем. Комфортные номера, завтрак, WiFi. Адрес: ул. Октябрьская, 42. Телефон: +7 (383) 227-00-00.',
      },
      category: TouristCategory.hotels,
      icon: Icons.hotel,
      color: 0xFF7C3AED,
    ),
    TouristInfo(
      id: _newId(),
      title: {'he': 'תיאטרון האופרה והבלט', 'en': 'Opera and Ballet Theatre', 'ru': 'Театр оперы и балета'},
      description: {
        'he': 'בניין תיאטרון האופרה והבלט של נובוסיבירסק הוא הגדול ברוסיה וסמל העיר. הוקם ב־1945, ואחד ממייסדיו היה המנצח היהודי איזידור זאק. כתובת: Krasny Prospekt 36.',
        'en': 'The Novosibirsk Opera and Ballet Theatre building is the largest in Russia and the city\'s symbol. Opened in 1945; Jewish conductor Isidor Zak was a co-founder. Address: 36 Krasny Prospekt.',
        'ru': 'Новосибирский театр оперы и балета — крупнейший в России и символ города. Открыт в 1945; один из основателей — дирижёр Исидор Зак. Адрес: Красный проспект, 36.',
      },
      category: TouristCategory.attractions,
      icon: Icons.theater_comedy,
      color: 0xFFDB2777,
    ),
    TouristInfo(
      id: _newId(),
      title: {'he': 'אגם אוב והחוף', 'en': 'Ob Sea and beach', 'ru': 'Обское море и пляж'},
      description: {
        'he': 'מאגר מים ענק צפונית לעיר. בקיץ — חופים, שיט וספורט מים. מרחק כ־40 דקות נסיעה מנובוסיבירסק. אידיאלי לטיול יום.',
        'en': 'A huge reservoir north of the city. In summer — beaches, boating and water sports. About 40-minute drive from Novosibirsk. Ideal for a day trip.',
        'ru': 'Огромное водохранилище к северу от города. Летом — пляжи, катание на лодках и водные виды спорта. Около 40 минут езды от Новосибирска. Идеально для однодневной поездки.',
      },
      category: TouristCategory.dayTrips,
      icon: Icons.water,
      color: 0xFF0EA5E9,
    ),
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
    Shiur(
      id: _newId(),
      title: {
        'he': 'הכנה לימים הנוראים',
        'en': 'Preparing for the High Holidays',
        'ru': 'Подготовка к Высоким праздникам',
      },
      rabbi: {
        'he': 'הרב שניאור זלמן זקלס',
        'en': 'Rabbi Shneur Zalman Zaklos',
        'ru': 'Раввин Шнеур Залман Заклос',
      },
      topic: {'he': 'חגים', 'en': 'Holidays', 'ru': 'Праздники'},
      durationMinutes: 45,
      date: DateTime.now().subtract(const Duration(days: 1)),
      weekday: DateTime.sunday,
      weeklyTime: '11:00',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'פרשת השבוע למעשה',
        'en': 'The weekly parasha in practice',
        'ru': 'Недельная глава на практике',
      },
      rabbi: {
        'he': 'הרב שניאור זלמן זקלס',
        'en': 'Rabbi Shneur Zalman Zaklos',
        'ru': 'Раввин Шнеур Залман Заклос',
      },
      topic: {'he': 'פרשה', 'en': 'Parasha', 'ru': 'Глава'},
      durationMinutes: 42,
      date: DateTime.now().subtract(const Duration(days: 2)),
      weekday: DateTime.saturday,
      weeklyTime: '12:30',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'יסודות התניא',
        'en': 'Foundations of Tanya',
        'ru': 'Основы Тании',
      },
      rabbi: {
        'he': 'הרב שניאור זלמן זקלס',
        'en': 'Rabbi Shneur Zalman Zaklos',
        'ru': 'Раввин Шнеур Залман Заклос',
      },
      topic: {'he': 'חסידות', 'en': 'Chassidut', 'ru': 'Хасидизм'},
      durationMinutes: 55,
      date: DateTime.now().subtract(const Duration(days: 9)),
      weekday: DateTime.thursday,
      weeklyTime: '19:00',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'הלכות שבת למעשה',
        'en': 'Practical laws of Shabbat',
        'ru': 'Законы субботы на практике',
      },
      rabbi: {
        'he': 'הרב שניאור זלמן זקלס',
        'en': 'Rabbi Shneur Zalman Zaklos',
        'ru': 'Раввин Шнеур Залман Заклос',
      },
      topic: {'he': 'הלכה', 'en': 'Halacha', 'ru': 'Алаха'},
      durationMinutes: 38,
      date: DateTime.now().subtract(const Duration(days: 16)),
      weekday: DateTime.friday,
      weeklyTime: '10:30',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'כולל תורה',
        'en': 'Kollel Torah',
        'ru': 'Колель Тора',
      },
      rabbi: {
        'he': 'הרב שניאור זלמן זקלס',
        'en': 'Rabbi Shneur Zalman Zaklos',
        'ru': 'Раввин Шнеур Залман Заклос',
      },
      topic: {'he': 'גמרא', 'en': 'Gemara', 'ru': 'Гемара'},
      durationMinutes: 60,
      date: DateTime.now().subtract(const Duration(days: 23)),
      weekday: DateTime.monday,
      weeklyTime: '09:30',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'מסע הנשמה — המכתב על המחט והמים',
        'en': 'The journey of the soul — the needle and the water',
        'ru': 'Путь души — игла и вода',
      },
      rabbi: {
        'he': 'הרב יוסף יצחק יעקבסון',
        'en': 'Rabbi YY Jacobson',
        'ru': 'Раввин Й. Й. Джейкобсон',
      },
      topic: {'he': 'חסידות', 'en': 'Chassidut', 'ru': 'Хасидизм'},
      durationMinutes: 75,
      date: DateTime(2021, 6, 1),
      youtubeUrl: 'https://www.youtube.com/watch?v=OVKQe9fiNu8',
    ),
    Shiur(
      id: _newId(),
      title: {
        'he': 'האם הקב״ה צריך אותנו? שיחה על נח והמרגלים',
        'en': 'Does G-d need us? On Noah and the spies',
        'ru': 'Нужен ли нам Бог? Ноах и разведчики',
      },
      rabbi: {
        'he': 'הרב מניס פרידמן',
        'en': 'Rabbi Manis Friedman',
        'ru': 'Раввин Манис Фридман',
      },
      topic: {'he': 'חסידות', 'en': 'Chassidut', 'ru': 'Хасидизм'},
      durationMinutes: 53,
      date: DateTime(2021, 12, 1),
      youtubeUrl: 'https://www.youtube.com/watch?v=nQlfH43G1mg',
    ),
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
    {'he': 'בית ספר אור אבנר', 'en': 'Or Avner school', 'ru': 'Лицей Ор Авнер'},
    {'he': 'מרכז לב', 'en': 'Lev special-needs center', 'ru': 'Центр Лев'},
    {'he': 'חסד ומצות לפסח', 'en': 'Chesed & Passover matzah', 'ru': 'Хесед и маца к Песаху'},
    {'he': 'הימים הנוראים תשפ״ז', 'en': 'High Holidays 5787', 'ru': 'Высокие праздники 5787'},
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
    unawaited(_publicDoc(
      'subscribers',
      email.replaceAll('/', '_'),
      subscriberToJson(subscribers.first),
    ));
    unawaited(SiteNotify.subscriber(
      subscriberEmail: email,
      email: contact.email,
      notifyChatId: links.notifyChatId,
    ));
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
    final lead = Lead(
      id: _newId(),
      name: name,
      email: email,
      phone: phone,
      topic: topic,
      date: DateTime.now(),
      source: source,
    );
    leads.insert(0, lead);
    notifyListeners();
    unawaited(_publicDoc('leads', lead.id, leadToJson(lead)));
    unawaited(SiteNotify.lead(
      lead: lead,
      email: contact.email,
      notifyChatId: links.notifyChatId,
    ));
  }

  void setLeadStatus(Lead lead, LeadStatus status) {
    lead.status = status;
    notifyListeners();
  }

  void addDonation({required String donor, required double amount, required Loc campaign}) {
    final d = Donation(
      id: _newId(),
      donor: donor.isEmpty ? 'Anonymous' : donor,
      amount: amount,
      campaign: campaign,
      date: DateTime.now(),
    );
    donations.insert(0, d);
    notifyListeners();
    unawaited(_publicDoc('donations', d.id, donationToJson(d)));
  }

  Future<void> _publicDoc(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await CloudSync.instance.submitPublic(
        collection: collection,
        id: id,
        data: data,
      );
    } catch (_) {}
  }

  FamousPerson newBlankFamous() => FamousPerson(
        id: _newId(),
        name: {'he': '', 'en': '', 'ru': ''},
        profession: {'he': '', 'en': '', 'ru': ''},
        bio: {'he': '', 'en': '', 'ru': ''},
        era: Era.present,
      );

  void addFamous(FamousPerson p) {
    famous.add(p);
    notifyListeners();
  }

  void deleteFamous(String id) {
    famous.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  HistoryEvent newBlankHistory() => HistoryEvent(
        id: _newId(),
        year: '${DateTime.now().year}',
        title: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
      );

  void addHistory(HistoryEvent e) {
    history.add(e);
    notifyListeners();
  }

  void deleteHistory(String id) {
    history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void moveHistory(int from, int to) => _moveIn(history, from, to);

  void reorderHistory(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    moveHistory(oldIndex, newIndex);
  }

  TourStop newBlankTour() => TourStop(
        id: _newId(),
        name: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
        color: 0xFF1D4ED8,
      );

  void addTour(TourStop s) {
    tour.add(s);
    notifyListeners();
  }

  void deleteTour(String id) {
    tour.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void moveTour(int from, int to) => _moveIn(tour, from, to);

  void reorderTour(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    moveTour(oldIndex, newIndex);
  }

  void addTourPhotos(TourStop stop, List<Uint8List> files) {
    for (final bytes in files) {
      stop.photos.add(GalleryShot(id: _newId(), imageBytes: bytes));
    }
    notifyListeners();
  }

  void deleteTourPhoto(TourStop stop, String photoId) {
    stop.photos.removeWhere((p) => p.id == photoId);
    notifyListeners();
  }

  TouristInfo newBlankTouristInfo() => TouristInfo(
        id: _newId(),
        title: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
        category: TouristCategory.synagogue,
      );

  void addTouristInfo(TouristInfo t) {
    touristInfo.add(t);
    notifyListeners();
  }

  void deleteTouristInfo(String id) {
    touristInfo.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void moveTouristInfo(int from, int to) => _moveIn(touristInfo, from, to);

  void reorderTouristInfo(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    moveTouristInfo(oldIndex, newIndex);
  }

  void _moveIn<T>(List<T> list, int from, int to) {
    if (from == to || from < 0 || from >= list.length) return;
    final dest = to.clamp(0, list.length - 1);
    final item = list.removeAt(from);
    list.insert(dest, item);
    notifyListeners();
  }

  Shiur newBlankShiur() => Shiur(
        id: _newId(),
        title: {'he': '', 'en': '', 'ru': ''},
        rabbi: {'he': '', 'en': '', 'ru': ''},
        topic: {'he': '', 'en': '', 'ru': ''},
        durationMinutes: 40,
        date: DateTime.now(),
        youtubeUrl: '',
      );

  void addShiur(Shiur s) {
    shiurim.insert(0, s);
    notifyListeners();
  }

  void deleteShiur(String id) {
    shiurim.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  bool _hasPic(Uint8List? bytes, String? url) =>
      (bytes != null && bytes.isNotEmpty) ||
      (url != null && url.trim().isNotEmpty);

  List<AdminReminder> adminReminders(String lang) {
    final out = <AdminReminder>[];
    final newsMissing = news.where((n) => !_hasPic(n.imageBytes, n.imageUrl)).length;
    if (newsMissing > 0) {
      out.add(AdminReminder(
        id: 'news-photos',
        jump: AdminJump.news,
        icon: Icons.image_not_supported_outlined,
        color: const Color(0xFFEA580C),
        title: trLoc({
          'he': 'חסרות תמונות בחדשות ($newsMissing)',
          'en': 'News missing photos ($newsMissing)',
          'ru': 'Нет фото в новостях ($newsMissing)',
        }, lang),
        body: trLoc({
          'he': 'הוסיפו תמונה לכל כתבה — כך דף החדשות נראה ייצוגי.',
          'en': 'Add a photo to each article so the News page looks complete.',
          'ru': 'Добавьте фото к каждой новости — страница будет представительной.',
        }, lang),
      ));
    }
    final progMissing =
        programs.where((p) => !_hasPic(p.imageBytes, p.imageUrl)).length;
    if (progMissing > 0) {
      out.add(AdminReminder(
        id: 'program-photos',
        jump: AdminJump.programs,
        icon: Icons.photo_outlined,
        color: const Color(0xFF2563EB),
        title: trLoc({
          'he': 'חסרות תמונות בתוכניות ($progMissing)',
          'en': 'Programs missing photos ($progMissing)',
          'ru': 'Нет фото у программ ($progMissing)',
        }, lang),
        body: trLoc({
          'he': 'אור אבנר, מרכז לב וחוג נשים עדיין בלי תמונה מהמקום.',
          'en': 'Or Avner, Lev and the Women\'s Circle still need on-site photos.',
          'ru': '«Ор Авнер», «Лев» и женский клуб всё ещё без фото с места.',
        }, lang),
      ));
    }
    final emptyAlbums = gallery.where((a) {
      final cover = _hasPic(a.imageBytes, a.imageUrl);
      final shots = a.photos.any((s) => s.hasImage);
      return !cover && !shots;
    }).toList();
    if (emptyAlbums.isNotEmpty) {
      final names = emptyAlbums
          .map((a) => trLoc(a.event, lang))
          .where((s) => s.isNotEmpty)
          .take(3)
          .join(' · ');
      out.add(AdminReminder(
        id: 'gallery-empty',
        jump: AdminJump.gallery,
        icon: Icons.photo_library_outlined,
        color: const Color(0xFF7C3AED),
        title: trLoc({
          'he': 'אלבומים בלי תמונות (${emptyAlbums.length})',
          'en': 'Albums without photos (${emptyAlbums.length})',
          'ru': 'Альбомы без фото (${emptyAlbums.length})',
        }, lang),
        body: names.isEmpty
            ? trLoc({
                'he': 'העלו תמונות אמיתיות מחגים — לא תמונות של הבניין במקומן.',
                'en': 'Upload real holiday photos — do not substitute building shots.',
                'ru': 'Загрузите настоящие праздничные фото, не заменяйте снимками здания.',
              }, lang)
            : names,
      ));
    }
    final noVideo =
        shiurim.where((s) => youtubeIdFrom(s.youtubeUrl) == null).length;
    if (noVideo > 0) {
      out.add(AdminReminder(
        id: 'shiur-youtube',
        jump: AdminJump.library,
        icon: Icons.smart_display_outlined,
        color: const Color(0xFFDC2626),
        title: trLoc({
          'he': 'שיעורים בלי קישור יוטיוב ($noVideo)',
          'en': 'Classes without a YouTube link ($noVideo)',
          'ru': 'Уроки без ссылки YouTube ($noVideo)',
        }, lang),
        body: trLoc({
          'he': 'הדביקו קישור watch/youtu.be בדף השיעורים במנהל — הצפייה באתר תעבוד מיד.',
          'en': 'Paste a watch/youtu.be link in the admin library — playback on the site starts immediately.',
          'ru': 'Вставьте ссылку watch/youtu.be в библиотеке админки — просмотр на сайте заработает сразу.',
        }, lang),
      ));
    }
    if (!TelegramService.instance.hasToken) {
      out.add(AdminReminder(
        id: 'telegram',
        jump: AdminJump.bots,
        icon: Icons.send,
        color: const Color(0xFF0284C7),
        title: trLoc({
          'he': 'בוט הטלגרם עדיין לא מחובר',
          'en': 'Telegram bot is not connected yet',
          'ru': 'Telegram-бот ещё не подключён',
        }, lang),
        body: trLoc({
          'he': 'צרו בוט ב-@BotFather, הדביקו טוקן, הוסיפו אותו כמנהל ב-@jewishsib, ואז בדיקת חיבור ומשיכת חדשות.',
          'en': 'Create a bot with @BotFather, paste the token, add it as admin of @jewishsib, then Check connection and Pull news.',
          'ru': 'Создайте бота у @BotFather, вставьте токен, сделайте его админом @jewishsib, затем проверка связи и загрузка новостей.',
        }, lang),
      ));
    }
    for (final y in upcomingYahrzeits(graves, withinDays: 14)) {
      final who = y.grave.hebrewName.isNotEmpty
          ? y.grave.hebrewName
          : y.grave.name;
      out.add(AdminReminder(
        id: 'yahrzeit-${y.grave.id}',
        jump: AdminJump.cemetery,
        icon: Icons.local_florist_outlined,
        color: const Color(0xFF0F766E),
        title: trLoc({
          'he': 'יארצייט · $who · בעוד ${y.days} ימים',
          'en': 'Yahrzeit · $who · in ${y.days} days',
          'ru': 'Йорцайт · $who · через ${y.days} дн.',
        }, lang),
        body: trLoc({
          'he': 'תאריך פטירה ${y.grave.deathLabel}. אפשר לשלוח תזכורת בטלגרם מהמנהל.',
          'en': 'Passed ${y.grave.deathLabel}. Send a Telegram reminder from admin.',
          'ru': 'Дата ${y.grave.deathLabel}. Напоминание в Telegram — из админки.',
        }, lang),
      ));
    }
    final freshLeads = leads.where((l) => l.status == LeadStatus.fresh).length;
    if (freshLeads > 0) {
      out.add(AdminReminder(
        id: 'leads-fresh',
        jump: AdminJump.crm,
        icon: Icons.mark_email_unread_outlined,
        color: const Color(0xFFB45309),
        title: trLoc({
          'he': 'פניות חדשות ($freshLeads)',
          'en': 'New inquiries ($freshLeads)',
          'ru': 'Новые обращения ($freshLeads)',
        }, lang),
        body: trLoc({
          'he': 'חזרו לפונים או סמנו «נוצר קשר» ב-CRM.',
          'en': 'Reply or mark them Contacted in CRM.',
          'ru': 'Ответьте или отметьте «связались» в CRM.',
        }, lang),
      ));
    }
    for (final h in upcomingHolidays(withinDays: 45)) {
      final days = daysUntilHoliday(h);
      final when = days == 0
          ? trLoc({'he': 'היום', 'en': 'today', 'ru': 'сегодня'}, lang)
          : days == 1
              ? trLoc({'he': 'מחר', 'en': 'tomorrow', 'ru': 'завтра'}, lang)
              : trLoc({
                  'he': 'בעוד $days ימים',
                  'en': 'in $days days',
                  'ru': 'через $days дн.',
                }, lang);
      out.add(AdminReminder(
        id: 'holiday-${h.start.toIso8601String()}',
        jump: AdminJump.news,
        icon: Icons.event_outlined,
        color: const Color(0xFFC9A227),
        title: '${trLoc(h.name, lang)} · $when',
        body: trLoc({
          'he': 'פרסמו שעות תפילה, סעודות ותמונות מהחג. אלבום הגלריה עדיין ריק אם אין העלאה.',
          'en': 'Publish prayer times, meals and holiday photos. Gallery albums stay empty until you upload.',
          'ru': 'Опубликуйте часы молитв, трапезы и фото праздника. Альбомы пусты, пока нет загрузки.',
        }, lang),
      ));
    }
    return out;
  }

  void addCampaign(Loc campaign, [Loc? note]) {
    campaigns.add(campaign);
    campaignNotes.add(note ?? {'he': '', 'en': '', 'ru': ''});
    notifyListeners();
  }

  void deleteCampaignAt(int index) {
    if (index < 0 || index >= campaigns.length) return;
    campaigns.removeAt(index);
    if (index < campaignNotes.length) campaignNotes.removeAt(index);
    notifyListeners();
  }

  Loc campaignNoteAt(int index) =>
      index >= 0 && index < campaignNotes.length ? campaignNotes[index] : {};

  void setCampaignNoteAt(int index, Loc note) {
    while (campaignNotes.length <= index) {
      campaignNotes.add({});
    }
    campaignNotes[index] = note;
    notifyListeners();
  }

  CommunityEvent newBlankEvent() => CommunityEvent(
        id: _newId(),
        title: {'he': '', 'en': '', 'ru': ''},
        description: {'he': '', 'en': '', 'ru': ''},
        place: {'he': '', 'en': '', 'ru': ''},
        startsAt: DateTime.now().add(const Duration(days: 7)),
        capacity: 40,
      );

  void addEvent(CommunityEvent e) {
    events.add(e);
    notifyListeners();
  }

  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  String? rsvpEvent({
    required CommunityEvent event,
    required String name,
    required String phone,
    String email = '',
    int guests = 1,
  }) {
    if (name.trim().isEmpty || phone.trim().isEmpty) return 'required';
    if (event.isFull) return 'full';
    final rsvp = EventRsvp(
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      guests: guests < 1 ? 1 : guests,
    );
    event.rsvps.add(rsvp);
    event.reserved += rsvp.guests;
    notifyListeners();
    unawaited(_publicDoc('rsvps', '${event.id}-${rsvp.at.millisecondsSinceEpoch}', {
      'eventId': event.id,
      ...rsvpToJson(rsvp),
    }));
    unawaited(SiteNotify.rsvp(
      event: event,
      rsvp: rsvp,
      email: contact.email,
      notifyChatId: links.notifyChatId,
    ));
    return null;
  }

  StoreOrder placeOrder({
    required String name,
    required String phone,
    required String fulfillment,
    String email = '',
    String address = '',
    String note = '',
    required String lang,
  }) {
    final lines = <OrderLine>[
      for (final e in _cart.entries)
        if (products.any((p) => p.id == e.key))
          OrderLine(
            productId: e.key,
            name: trLoc(products.firstWhere((p) => p.id == e.key).name, lang),
            qty: e.value,
            price: products.firstWhere((p) => p.id == e.key).price,
          ),
    ];
    final order = StoreOrder(
      id: _newId(),
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      fulfillment: fulfillment,
      address: address.trim(),
      note: note.trim(),
      lines: lines,
      total: cartTotal,
      date: DateTime.now(),
    );
    orders.insert(0, order);
    clearCart();
    unawaited(_publicDoc('orders', order.id, orderToJson(order)));
    unawaited(SiteNotify.order(
      order: order,
      email: contact.email,
      notifyChatId: links.notifyChatId,
    ));
    return order;
  }

  String exportBackupJson() {
    final snap = _encodeSnapshot();
    snap['exportedAt'] = DateTime.now().toIso8601String();
    return const JsonEncoder.withIndent('  ').convert(snap);
  }

  String? importBackupJson(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return 'invalid';
      _applySnapshot(Map<String, dynamic>.from(m));
      notifyListeners();
      return null;
    } catch (_) {
      return 'invalid';
    }
  }

  Grave newBlankGrave() => Grave(
        id: _newId(),
        name: '',
        hebrewName: '',
        birthYear: null,
        deathYear: DateTime.now().year,
        section: '',
        row: '',
        notes: {'he': '', 'en': '', 'ru': ''},
      );

  void addGrave(Grave g) {
    _gravesEdited = true;
    graves.insert(0, g);
    notifyListeners();
  }

  void deleteGrave(String id) {
    _gravesEdited = true;
    graves.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void markGravesEdited() {
    _gravesEdited = true;
    notifyListeners();
  }

  GalleryPhoto newBlankGallery() => GalleryPhoto(
        id: _newId(),
        event: {'he': '', 'en': '', 'ru': ''},
        year: DateTime.now().year,
        tags: const [],
        color: 0xFF1D4ED8,
        photos: [],
      );

  void addGalleryPhoto(GalleryPhoto p) {
    gallery.insert(0, p);
    notifyListeners();
  }

  void deleteGalleryPhoto(String id) {
    gallery.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  NewsArticle? newsById(String id) {
    for (final a in news) {
      if (a.id == id) return a;
    }
    return null;
  }

  Program? programById(String id) {
    for (final p in programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  GalleryPhoto? galleryById(String id) {
    for (final p in gallery) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _ensureAlbumPhotos(GalleryPhoto album) {
    if (album.photos.isNotEmpty) return;
    if (_hasBytes(album.imageBytes) ||
        (album.imageUrl != null && album.imageUrl!.isNotEmpty)) {
      album.photos.add(GalleryShot(
        id: '${album.id}_cover',
        imageBytes: album.imageBytes,
        imageUrl: album.imageUrl,
      ));
    }
  }

  void addGalleryShots(GalleryPhoto album, List<Uint8List> files) {
    _ensureAlbumPhotos(album);
    for (final raw in files) {
      if (raw.isEmpty) continue;
      album.photos.add(GalleryShot(
        id: _newId(),
        imageBytes: compressSiteImage(raw),
      ));
    }
    if (!_hasBytes(album.imageBytes) && album.photos.isNotEmpty) {
      album.imageBytes = album.photos.first.imageBytes;
      album.imageUrl = album.photos.first.imageUrl;
    }
    notifyListeners();
  }

  void deleteGalleryShot(GalleryPhoto album, String shotId) {
    album.photos.removeWhere((s) => s.id == shotId);
    if (album.photos.isEmpty) {
      album.imageBytes = null;
      album.imageUrl = null;
    } else {
      album.imageBytes = album.photos.first.imageBytes;
      album.imageUrl = album.photos.first.imageUrl;
    }
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

  PageBanner bannerFor(String route) {
    if (banners.containsKey(route)) return banners[route]!;
    if (route.startsWith('/gallery/') ||
        route.startsWith('/programs/') ||
        route.startsWith('/news/')) {
      final base = '/${route.split('/')[1]}';
      return banners[base] ?? banners['/'] ?? PageBanner();
    }
    return banners['/'] ?? PageBanner();
  }

  void setBannerImage(String route, Uint8List bytes) =>
      addBannerSlide(route, bytes);

  void addBannerSlide(String route, Uint8List bytes) {
    final current = banners.putIfAbsent(route, PageBanner.new);
    final compressed = compressSiteImage(bytes);
    if (!current.hasImage) {
      current.bytes = compressed;
      current.imageUrl = null;
      current.alignY = -0.2;
    } else {
      current.extra.add(BannerSlide(bytes: compressed, alignY: -0.2));
    }
    notifyListeners();
  }

  void removeBannerSlide(String route, int index) {
    final current = banners[route];
    if (current == null) return;
    if (index <= 0) {
      if (current.extra.isNotEmpty) {
        final next = current.extra.removeAt(0);
        current.bytes = next.bytes;
        current.imageUrl = next.imageUrl;
        current.alignX = next.alignX;
        current.alignY = next.alignY;
      } else {
        current.bytes = null;
        current.imageUrl = null;
      }
    } else {
      final i = index - 1;
      if (i >= 0 && i < current.extra.length) current.extra.removeAt(i);
    }
    notifyListeners();
  }

  void setBannerAlign(String route, {double? x, double? y}) =>
      setSlideAlign(route, 0, x: x, y: y);

  void setSlideAlign(String route, int index, {double? x, double? y}) {
    final current = banners.putIfAbsent(route, PageBanner.new);
    if (index <= 0) {
      if (x != null) current.alignX = x;
      if (y != null) current.alignY = y;
    } else {
      final i = index - 1;
      if (i < 0) return;
      while (current.extra.length <= i) {
        current.extra.add(BannerSlide());
      }
      if (x != null) current.extra[i].alignX = x;
      if (y != null) current.extra[i].alignY = y;
    }
    notifyListeners();
  }

  void clearBanner(String route) {
    banners[route] = PageBanner();
    notifyListeners();
  }

  Uint8List? emblemBytes;
  String? emblemUrl = 'assets/images/chabad-emblem.png';

  bool get hasCustomEmblem =>
      (emblemBytes != null && emblemBytes!.isNotEmpty) ||
      (emblemUrl != null &&
          emblemUrl!.isNotEmpty &&
          emblemUrl != 'assets/images/chabad-emblem.png');

  void setEmblemImage(Uint8List bytes) {
    emblemBytes = compressSiteImage(bytes);
    emblemUrl = null;
    notifyListeners();
  }

  void clearEmblem() {
    emblemBytes = null;
    emblemUrl = 'assets/images/chabad-emblem.png';
    unawaited(persistDelete('${_imgPrefix}emblem:logo'));
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
          route: '/news/${a.id}',
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
          route: '/programs/${p.id}',
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
    for (final a in gallery) {
      if (_locHas(a.event, q) ||
          a.tags.any((t) => t.toLowerCase().contains(q))) {
        hits.add(SearchHit(
          groupKey: 'search.group.gallery',
          title: trLoc(a.event, lang),
          subtitle: '${a.year}',
          route: '/gallery/${a.id}',
          icon: Icons.photo_library_outlined,
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
    for (final e in events) {
      if (_locHas(e.title, q) ||
          _locHas(e.description, q) ||
          _locHas(e.place, q)) {
        hits.add(SearchHit(
          groupKey: 'search.group.events',
          title: trLoc(e.title, lang),
          subtitle: trLoc(e.place, lang),
          route: '/events',
          icon: Icons.event_outlined,
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

  void _ensureUniqueIds<T>(
    List<T> items,
    String Function(T) idOf,
    void Function(T, String) setId,
  ) {
    final seen = <String>{};
    for (final item in items) {
      var id = idOf(item);
      if (id.isEmpty || id == 'null' || !seen.add(id)) {
        id = _newId();
        setId(item, id);
        seen.add(id);
      }
      _noteId(id);
    }
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
        'paletteId': paletteId,
        'location': locationToJson(location),
        'siteCopy': siteCopyToJson(siteCopy),
        'contact': contactToJson(contact),
        'famous': [for (final p in famous) famousToJson(p)],
        'history': [for (final e in history) historyToJson(e)],
        'tour': [for (final s in tour) tourToJson(s)],
        'touristInfo': [for (final t in touristInfo) touristInfoToJson(t)],
        'shiurim': [for (final s in shiurim) shiurToJson(s)],
        'campaigns': [for (final c in campaigns) locTo(c)],
        'campaignNotes': [for (final n in campaignNotes) locTo(n)],
        'links': linksToJson(links),
        'events': [for (final e in events) eventToJson(e)],
        'orders': [for (final o in orders) orderToJson(o)],
        if (_gravesEdited)
          'graves': [
            for (final g in graves)
              if (!g.id.startsWith('kaddish-')) graveToJson(g),
          ],
        'news': [for (final a in news) newsToJson(a)],
        'programs': [for (final p in programs) programToJson(p)],
        'products': [for (final p in products) productToJson(p)],
        'gallery': [for (final p in gallery) galleryToJson(p)],
        'banners': {
          for (final e in banners.entries) e.key: bannerToJson(e.value),
        },
        if (emblemUrl != null && emblemUrl!.isNotEmpty) 'emblemUrl': emblemUrl,
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
    paletteId = SitePalettes.byId('${m['paletteId'] ?? paletteId}').id;
    location = locationFromJson(m['location'], location);
    _persistLocation();
    siteCopyFromJson(siteCopy, m['siteCopy']);
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
    final emblem = '${m['emblemUrl'] ?? ''}'.trim();
    if (emblem.isNotEmpty) emblemUrl = emblem;
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
    if (m['famous'] is List) {
      famous
        ..clear()
        ..addAll((m['famous'] as List).map(famousFromJson));
    }
    if (m['history'] is List) {
      history
        ..clear()
        ..addAll((m['history'] as List).map(historyFromJson));
    }
    if (m['tour'] is List) {
      final loaded = (m['tour'] as List).map(tourFromJson).toList();
      // Only replace seed data if cloud has non-empty tour stops
      if (loaded.isNotEmpty) {
        tour
          ..clear()
          ..addAll(loaded);
      }
    }
    if (m['touristInfo'] is List) {
      final loaded = (m['touristInfo'] as List).map(touristInfoFromJson).toList();
      // Only replace seed data if cloud has non-empty tourist info
      if (loaded.isNotEmpty) {
        touristInfo
          ..clear()
          ..addAll(loaded);
      }
    }
    if (m['shiurim'] is List) {
      shiurim
        ..clear()
        ..addAll((m['shiurim'] as List).map(shiurFromJson));
    }
    final loadedCampaigns = campaignsFromJson(m['campaigns']);
    if (loadedCampaigns.isNotEmpty) {
      campaigns
        ..clear()
        ..addAll(loadedCampaigns);
    }
    if (m['campaignNotes'] != null) {
      campaignNotes
        ..clear()
        ..addAll(campaignNotesFromJson(m['campaignNotes'], campaigns.length));
    } else {
      while (campaignNotes.length < campaigns.length) {
        campaignNotes.add({});
      }
    }
    linksFromJson(links, m['links']);
    if (m['events'] is List) {
      events
        ..clear()
        ..addAll((m['events'] as List).map(eventFromJson));
    }
    if (m['orders'] is List) {
      orders
        ..clear()
        ..addAll((m['orders'] as List).map(orderFromJson));
    }
    if (m['graves'] is List) {
      final loaded = [
        for (final item in m['graves'] as List) graveFromJson(item),
      ];
      final custom =
          loaded.where((g) => !g.id.startsWith('kaddish-')).toList();
      if (custom.isNotEmpty) {
        _gravesEdited = true;
        final kaddish =
            graves.where((g) => g.id.startsWith('kaddish-')).toList();
        graves
          ..clear()
          ..addAll(kaddish)
          ..addAll(custom);
      }
    }

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
    for (final p in famous) {
      _noteId(p.id);
    }
    for (final e in history) {
      _noteId(e.id);
    }
    for (final s in tour) {
      _noteId(s.id);
    }
    _ensureUniqueIds(history, (e) => e.id, (e, id) => e.id = id);
    _ensureUniqueIds(tour, (s) => s.id, (s, id) => s.id = id);
    for (final s in shiurim) {
      _noteId(s.id);
    }
    for (final e in events) {
      _noteId(e.id);
    }
    for (final o in orders) {
      _noteId(o.id);
    }
    for (final g in graves) {
      _noteId(g.id);
    }
    _ensureHistoricalFamous();
  }

  Future<void> _hydrate() async {
    final raw = await persistGet(_snapKey);
    Map<String, dynamic>? m;
    if (raw != null && raw.isNotEmpty) {
      try {
        m = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (m != null) {
      final seed = (m['seed'] as num?)?.toInt() ?? 0;
      if (seed >= _contentSeed) {
        _applySnapshot(m);
      } else {
        _mergeUserContent(m);
      }
    }
    await _hydrateLocalImages(m);
    _ensureHistoricalFamous();
  }

  bool _jsonHasUpload(Map item) {
    final imageId = item['imageId'];
    if (imageId is String && imageId.isNotEmpty) return true;
    final image = item['image'];
    if (image is String && image.isNotEmpty) return true;
    final url = item['imageUrl'] ?? item['url'];
    if (url is String && url.isNotEmpty && !url.startsWith('assets/')) {
      return true;
    }
    final photos = item['photos'];
    if (photos is List && photos.isNotEmpty) return true;
    return false;
  }

  void _mergeUserContent(Map<String, dynamic> m) {
    if (m['news'] is List) {
      final byId = {for (final a in news) a.id: a};
      for (final item in m['news'] as List) {
        if (item is! Map || !_jsonHasUpload(Map<String, dynamic>.from(item))) {
          continue;
        }
        final a = newsFromJson(item);
        if (!byId.containsKey(a.id)) {
          news.add(a);
          byId[a.id] = a;
          _noteId(a.id);
        }
      }
    }
    if (m['programs'] is List) {
      final byId = {for (final p in programs) p.id: p};
      for (final item in m['programs'] as List) {
        if (item is! Map || !_jsonHasUpload(Map<String, dynamic>.from(item))) {
          continue;
        }
        final p = programFromJson(item);
        if (!byId.containsKey(p.id)) {
          programs.add(p);
          byId[p.id] = p;
          _noteId(p.id);
        }
      }
    }
    if (m['products'] is List) {
      final byId = {for (final p in products) p.id: p};
      for (final item in m['products'] as List) {
        if (item is! Map || !_jsonHasUpload(Map<String, dynamic>.from(item))) {
          continue;
        }
        final p = productFromJson(item);
        if (!byId.containsKey(p.id)) {
          products.add(p);
          byId[p.id] = p;
          _noteId(p.id);
        }
      }
    }
    if (m['gallery'] is List) {
      final byId = {for (final p in gallery) p.id: p};
      for (final item in m['gallery'] as List) {
        if (item is! Map || !_jsonHasUpload(Map<String, dynamic>.from(item))) {
          continue;
        }
        final p = galleryFromJson(item);
        if (!byId.containsKey(p.id)) {
          gallery.add(p);
          byId[p.id] = p;
          _noteId(p.id);
        }
      }
    }
    if (m['banners'] is Map) {
      final raw = Map<String, dynamic>.from(m['banners'] as Map);
      for (final e in raw.entries) {
        final incoming = bannerFromJson(e.value);
        final current = banners.putIfAbsent(e.key, PageBanner.new);
        if (incoming.bytes != null && incoming.bytes!.isNotEmpty) {
          current.bytes = incoming.bytes;
        }
        if (incoming.imageUrl != null &&
            incoming.imageUrl!.isNotEmpty &&
            !incoming.imageUrl!.startsWith('assets/')) {
          current.imageUrl = incoming.imageUrl;
        }
        if (incoming.alignX != 0) current.alignX = incoming.alignX;
        if (incoming.alignY != 0) current.alignY = incoming.alignY;
        for (var i = 0; i < incoming.extra.length; i++) {
          while (current.extra.length <= i) {
            current.extra.add(BannerSlide());
          }
          final src = incoming.extra[i];
          if (src.bytes != null && src.bytes!.isNotEmpty) {
            current.extra[i].bytes = src.bytes;
          }
          if (src.imageUrl != null &&
              src.imageUrl!.isNotEmpty &&
              !src.imageUrl!.startsWith('assets/')) {
            current.extra[i].imageUrl = src.imageUrl;
          }
          current.extra[i].alignX = src.alignX;
          current.extra[i].alignY = src.alignY;
        }
      }
    }
    final emblem = '${m['emblemUrl'] ?? ''}'.trim();
    if (emblem.isNotEmpty && emblemBytes == null) emblemUrl = emblem;
  }

  _UploadKeep _captureUploads() => _UploadKeep(
        news: [for (final a in news) if (_hasBytes(a.imageBytes)) a],
        programs: [for (final p in programs) if (_hasBytes(p.imageBytes)) p],
        products: [for (final p in products) if (_hasBytes(p.imageBytes)) p],
        gallery: [
          for (final p in gallery)
            if (_hasBytes(p.imageBytes) ||
                p.photos.any((s) => _hasBytes(s.imageBytes)))
              p
        ],
        banners: {
          for (final e in banners.entries)
            if (e.value.hasImage)
              e.key: PageBanner(
                bytes: e.value.bytes,
                imageUrl: e.value.imageUrl,
                alignX: e.value.alignX,
                alignY: e.value.alignY,
                extra: [for (final s in e.value.extra) s.copy()],
              ),
        },
        emblemBytes: emblemBytes,
        famous: [for (final p in famous) if (_hasBytes(p.photoBytes)) p],
      );

  void _restoreUploads(_UploadKeep saved) {
    for (final a in saved.news) {
      final i = news.indexWhere((e) => e.id == a.id);
      if (i < 0) {
        news.add(a);
        _noteId(a.id);
      } else if (!_hasBytes(news[i].imageBytes)) {
        news[i].imageBytes = a.imageBytes;
      }
    }
    for (final p in saved.programs) {
      final i = programs.indexWhere((e) => e.id == p.id);
      if (i < 0) {
        programs.add(p);
        _noteId(p.id);
      } else if (!_hasBytes(programs[i].imageBytes)) {
        programs[i].imageBytes = p.imageBytes;
      }
    }
    for (final p in saved.products) {
      final i = products.indexWhere((e) => e.id == p.id);
      if (i < 0) {
        products.add(p);
        _noteId(p.id);
      } else if (!_hasBytes(products[i].imageBytes)) {
        products[i].imageBytes = p.imageBytes;
      }
    }
    for (final p in saved.gallery) {
      final i = gallery.indexWhere((e) => e.id == p.id);
      if (i < 0) {
        gallery.add(p);
        _noteId(p.id);
      } else {
        if (!_hasBytes(gallery[i].imageBytes)) {
          gallery[i].imageBytes = p.imageBytes;
        }
        for (final shot in p.photos) {
          final si = gallery[i].photos.indexWhere((s) => s.id == shot.id);
          if (si < 0) {
            gallery[i].photos.add(shot);
            _noteId(shot.id);
          } else if (!_hasBytes(gallery[i].photos[si].imageBytes)) {
            gallery[i].photos[si].imageBytes = shot.imageBytes;
          }
        }
      }
    }
    for (final e in saved.banners.entries) {
      final current = banners.putIfAbsent(e.key, PageBanner.new);
      if (!_hasBytes(current.bytes) && _hasBytes(e.value.bytes)) {
        current.bytes = e.value.bytes;
      }
      for (var i = 0; i < e.value.extra.length; i++) {
        while (current.extra.length <= i) {
          current.extra.add(BannerSlide());
        }
        if (!_hasBytes(current.extra[i].bytes) &&
            _hasBytes(e.value.extra[i].bytes)) {
          current.extra[i].bytes = e.value.extra[i].bytes;
        }
      }
    }
    if (!_hasBytes(emblemBytes) && _hasBytes(saved.emblemBytes)) {
      emblemBytes = saved.emblemBytes;
    }
    for (final p in saved.famous) {
      final i = famous.indexWhere((e) => e.id == p.id);
      if (i < 0) {
        famous.add(p);
        _noteId(p.id);
      } else if (!_hasBytes(famous[i].photoBytes)) {
        famous[i].photoBytes = p.photoBytes;
      }
    }
  }

  /// Selective version: only restore images to items that still exist.
  /// Does NOT re-add deleted items. Used after cloud pull to prevent resurrection.
  void _restoreUploadsSelective(_UploadKeep saved) {
    // Only restore images to existing items; don't resurrect deleted items
    for (final a in saved.news) {
      final i = news.indexWhere((e) => e.id == a.id);
      if (i >= 0 && !_hasBytes(news[i].imageBytes)) {
        news[i].imageBytes = a.imageBytes;
      }
    }
    for (final p in saved.programs) {
      final i = programs.indexWhere((e) => e.id == p.id);
      if (i >= 0 && !_hasBytes(programs[i].imageBytes)) {
        programs[i].imageBytes = p.imageBytes;
      }
    }
    for (final p in saved.products) {
      final i = products.indexWhere((e) => e.id == p.id);
      if (i >= 0 && !_hasBytes(products[i].imageBytes)) {
        products[i].imageBytes = p.imageBytes;
      }
    }
    for (final p in saved.gallery) {
      final i = gallery.indexWhere((e) => e.id == p.id);
      if (i >= 0) {
        if (!_hasBytes(gallery[i].imageBytes)) {
          gallery[i].imageBytes = p.imageBytes;
        }
        for (final shot in p.photos) {
          final si = gallery[i].photos.indexWhere((s) => s.id == shot.id);
          if (si >= 0 && !_hasBytes(gallery[i].photos[si].imageBytes)) {
            gallery[i].photos[si].imageBytes = shot.imageBytes;
          }
        }
      }
    }
    for (final e in saved.banners.entries) {
      final current = banners[e.key];
      if (current != null) {
        if (!_hasBytes(current.bytes) && _hasBytes(e.value.bytes)) {
          current.bytes = e.value.bytes;
        }
        for (var i = 0; i < e.value.extra.length && i < current.extra.length; i++) {
          if (!_hasBytes(current.extra[i].bytes) &&
              _hasBytes(e.value.extra[i].bytes)) {
            current.extra[i].bytes = e.value.extra[i].bytes;
          }
        }
      }
    }
    if (!_hasBytes(emblemBytes) && _hasBytes(saved.emblemBytes)) {
      emblemBytes = saved.emblemBytes;
    }
    for (final p in saved.famous) {
      final i = famous.indexWhere((e) => e.id == p.id);
      if (i >= 0 && !_hasBytes(famous[i].photoBytes)) {
        famous[i].photoBytes = p.photoBytes;
      }
    }
  }

  bool _hasBytes(Uint8List? bytes) => bytes != null && bytes.isNotEmpty;

  Future<void> _hydrateLocalImages(Map<String, dynamic>? m) async {
    final keys = <String>[
      if (m != null && m['imageKeys'] is List)
        for (final k in m['imageKeys'] as List) '$k',
    ];
    try {
      for (final full in await persistKeys(prefix: _imgPrefix)) {
        keys.add(full.substring(_imgPrefix.length));
      }
    } catch (_) {}
    if (keys.isEmpty) {
      keys.addAll(_collectImages().keys);
      keys.addAll([
        for (final e in banners.entries) 'banner:${e.key}',
        for (final a in news) 'news:${a.id}',
        for (final p in programs) 'program:${p.id}',
        for (final p in products) 'product:${p.id}',
        for (final p in gallery) ...[
          'gallery:${p.id}',
          for (final s in p.photos) 'gallery:${p.id}:${s.id}',
        ],
        for (final p in famous) 'famous:${p.id}',
      ]);
    }
    for (final key in keys.toSet()) {
      if (key.isEmpty) continue;
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
      for (var i = 0; i < e.value.extra.length; i++) {
        final sb = e.value.extra[i].bytes;
        if (sb != null && sb.isNotEmpty) {
          out['banner:${e.key}|$i'] = sb;
        }
      }
    }
    if (emblemBytes != null && emblemBytes!.isNotEmpty) {
      out['emblem:logo'] = emblemBytes!;
    }
    for (final p in famous) {
      final b = p.photoBytes;
      if (b != null && b.isNotEmpty) out['famous:${p.id}'] = b;
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
    for (final t in touristInfo) {
      final b = t.imageBytes;
      if (b != null && b.isNotEmpty) out['tourist:${t.id}'] = b;
    }
    for (final p in gallery) {
      final b = p.imageBytes;
      if (b != null && b.isNotEmpty) out['gallery:${p.id}'] = b;
      for (final s in p.photos) {
        final sb = s.imageBytes;
        if (sb != null && sb.isNotEmpty) {
          out['gallery:${p.id}:${s.id}'] = sb;
        }
      }
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
        final pipe = id.lastIndexOf('|');
        if (pipe > 0 && int.tryParse(id.substring(pipe + 1)) != null) {
          final route = id.substring(0, pipe);
          final idx = int.parse(id.substring(pipe + 1));
          final b = banners.putIfAbsent(route, PageBanner.new);
          while (b.extra.length <= idx) {
            b.extra.add(BannerSlide());
          }
          b.extra[idx].bytes = bytes;
        } else {
          banners.putIfAbsent(id, PageBanner.new).bytes = bytes;
        }
      case 'emblem':
        emblemBytes = bytes;
      case 'famous':
        final existing = famous.where((p) => p.id == id);
        if (existing.isNotEmpty) {
          existing.first.photoBytes = bytes;
        } else {
          famous.add(FamousPerson(
            id: id,
            name: const {'he': '', 'en': '', 'ru': ''},
            profession: const {'he': '', 'en': '', 'ru': ''},
            bio: const {'he': '', 'en': '', 'ru': ''},
            era: Era.past,
            photoBytes: bytes,
          ));
          _noteId(id);
        }
      case 'news':
        final existing = news.where((a) => a.id == id);
        if (existing.isNotEmpty) {
          existing.first.imageBytes = bytes;
        } else {
          news.add(NewsArticle(
            id: id,
            title: const {'he': '', 'en': '', 'ru': ''},
            body: const {'he': '', 'en': '', 'ru': ''},
            date: DateTime.now(),
            category: const {'he': '', 'en': '', 'ru': ''},
            imageBytes: bytes,
          ));
          _noteId(id);
        }
      case 'program':
        final existing = programs.where((p) => p.id == id);
        if (existing.isNotEmpty) {
          existing.first.imageBytes = bytes;
        } else {
          programs.add(Program(
            id: id,
            title: const {'he': '', 'en': '', 'ru': ''},
            description: const {'he': '', 'en': '', 'ru': ''},
            schedule: const {'he': '', 'en': '', 'ru': ''},
            audience: const {'he': '', 'en': '', 'ru': ''},
            imageBytes: bytes,
          ));
          _noteId(id);
        }
      case 'product':
        final existing = products.where((p) => p.id == id);
        if (existing.isNotEmpty) {
          existing.first.imageBytes = bytes;
        } else {
          products.add(Product(
            id: id,
            name: const {'he': '', 'en': '', 'ru': ''},
            description: const {'he': '', 'en': '', 'ru': ''},
            price: 0,
            category: ProductCategory.judaica,
            imageBytes: bytes,
          ));
          _noteId(id);
        }
      case 'tourist':
        final existing = touristInfo.where((t) => t.id == id);
        if (existing.isNotEmpty) {
          existing.first.imageBytes = bytes;
        } else {
          touristInfo.add(TouristInfo(
            id: id,
            title: const {'he': '', 'en': '', 'ru': ''},
            description: const {'he': '', 'en': '', 'ru': ''},
            category: TouristCategory.synagogue,
            imageBytes: bytes,
          ));
          _noteId(id);
        }
      case 'gallery':
        final split = id.split(':');
        final albumId = split.first;
        final shotId = split.length > 1 ? split.sublist(1).join(':') : null;
        GalleryPhoto? album;
        for (final p in gallery) {
          if (p.id == albumId) {
            album = p;
            break;
          }
        }
        if (album == null) {
          album = GalleryPhoto(
            id: albumId,
            event: const {'he': '', 'en': '', 'ru': ''},
            year: DateTime.now().year,
            tags: const [],
            color: 0xFF1D4ED8,
            imageBytes: shotId == null ? bytes : null,
          );
          gallery.add(album);
          _noteId(albumId);
        }
        if (shotId == null) {
          album.imageBytes = bytes;
          if (album.photos.isEmpty) {
            album.photos.add(GalleryShot(
              id: '${albumId}_cover',
              imageBytes: bytes,
            ));
          }
        } else {
          final existingShot = album.photos.where((s) => s.id == shotId);
          if (existingShot.isNotEmpty) {
            existingShot.first.imageBytes = bytes;
          } else {
            album.photos.add(GalleryShot(id: shotId, imageBytes: bytes));
            _noteId(shotId);
          }
        }
    }
  }

  Future<void> _pullCloud() async {
    final cloud = await CloudSync.instance.pull();
    if (cloud == null) {
      _cloudPulled = true;
      return;
    }
    _cloudSeen = true;
    
    // Save items with local-only images (not yet uploaded)
    final saved = _captureUploads();
    
    final seed = (cloud.snapshot['seed'] as num?)?.toInt() ?? 0;
    if (seed >= _contentSeed) {
      _applySnapshot(cloud.snapshot);
    } else {
      _mergeUserContent(cloud.snapshot);
    }
    
    // Restore local images to cloud items
    for (final e in cloud.images.entries) {
      _applyLocalImage(e.key, e.value);
    }
    
    // Only restore uploads for items that still exist after cloud merge
    // This prevents deleted items from being resurrected
    _restoreUploadsSelective(saved);
    
    _ensureHistoricalFamous();
    _cloudPulled = true;
    
    try {
      await persistPut(_snapKey, jsonEncode(_encodeSnapshot()));
      for (final e in cloud.images.entries) {
        await persistPut('$_imgPrefix${e.key}', bytesToB64(e.value)!);
      }
      for (final e in _collectImages().entries) {
        await persistPut('$_imgPrefix${e.key}', bytesToB64(e.value)!);
      }
    } catch (_) {}
    if (_hydrated) notifyListeners();
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
    final err = await CloudSync.instance.push(
      snapshot: snap,
      images: images,
      prune: _cloudSeen,
    );
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

class _UploadKeep {
  _UploadKeep({
    required this.news,
    required this.programs,
    required this.products,
    required this.gallery,
    required this.banners,
    this.emblemBytes,
    this.famous = const [],
  });
  final List<NewsArticle> news;
  final List<Program> programs;
  final List<Product> products;
  final List<GalleryPhoto> gallery;
  final Map<String, PageBanner> banners;
  final Uint8List? emblemBytes;
  final List<FamousPerson> famous;
}
