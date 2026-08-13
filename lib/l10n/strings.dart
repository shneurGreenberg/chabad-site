import 'package:flutter/material.dart';

import '../services/web_prefs.dart';

/// Supported UI languages. Hebrew is the primary (RTL) language.
const supportedLangs = ['he', 'en', 'ru'];

const langNames = {
  'he': 'עברית',
  'en': 'English',
  'ru': 'Русский',
};

String _savedLang() {
  final saved = readPref('lang');
  if (saved != null && supportedLangs.contains(saved)) return saved;
  return 'he';
}

/// Holds the currently selected language and exposes translation lookup.
class LocaleController extends ChangeNotifier {
  LocaleController([String? lang]) : _lang = lang ?? _savedLang();

  String _lang;
  String get lang => _lang;
  Locale get locale => Locale(_lang);
  bool get isRtl => _lang == 'he';
  TextDirection get direction =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  void setLang(String lang) {
    if (_lang == lang || !supportedLangs.contains(lang)) return;
    _lang = lang;
    writePref('lang', lang);
    notifyListeners();
  }

  /// Translate a UI [key].
  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[_lang] ?? entry['en'] ?? entry.values.first;
  }
}

/// All UI chrome strings keyed by string id, then locale code.
const Map<String, Map<String, String>> _strings = {
  'site.name': {
    'he': 'בית חב״ד בית מנחם',
    'en': 'Chabad Beit Menachem',
    'ru': 'Хабад Бейт Менахем',
  },
  'site.city': {
    'he': 'נובוסיבירסק',
    'en': 'Novosibirsk',
    'ru': 'Новосибирск',
  },
  'site.tagline': {
    'he': 'בית הכנסת והמרכז הקהילתי היהודי היחיד בנובוסיבירסק — בית חם לכל יהודי סיביר',
    'en': 'The only synagogue and Jewish community center in Novosibirsk — a home for every Jew in Siberia',
    'ru': 'Единственная синагога и еврейский общинный центр Новосибирска — дом для каждого еврея Сибири',
  },
  // Navigation
  'nav.home': {'he': 'בית', 'en': 'Home', 'ru': 'Главная'},
  'nav.news': {'he': 'חדשות', 'en': 'News', 'ru': 'Новости'},
  'nav.zmanim': {'he': 'זמנים', 'en': 'Times', 'ru': 'Времена'},
  'nav.programs': {'he': 'תוכניות', 'en': 'Programs', 'ru': 'Программы'},
  'nav.gallery': {'he': 'גלריה', 'en': 'Gallery', 'ru': 'Галерея'},
  'nav.cemetery': {'he': 'בית החיים', 'en': 'Cemetery', 'ru': 'Кладбище'},
  'nav.famous': {
    'he': 'יהודים מפורסמים',
    'en': 'Notable Jews',
    'ru': 'Известные евреи'
  },
  'nav.history': {'he': 'היסטוריה', 'en': 'History', 'ru': 'История'},
  'nav.store': {'he': 'חנות', 'en': 'Store', 'ru': 'Магазин'},
  'nav.library': {
    'he': 'שיעורי תורה',
    'en': 'Torah Library',
    'ru': 'Уроки Торы'
  },
  'nav.donate': {'he': 'תרומה', 'en': 'Donate', 'ru': 'Пожертвовать'},
  'nav.contact': {'he': 'הרשמה', 'en': 'Register', 'ru': 'Регистрация'},
  'nav.about': {'he': 'אודות', 'en': 'About', 'ru': 'О нас'},
  'nav.admin': {'he': 'ניהול', 'en': 'Admin', 'ru': 'Админ'},
  'nav.menu': {'he': 'תפריט', 'en': 'Menu', 'ru': 'Меню'},

  // Home
  'home.hero.cta': {
    'he': 'הצטרפו לקהילה',
    'en': 'Join the community',
    'ru': 'Присоединяйтесь'
  },
  'home.hero.donate': {
    'he': 'תרמו עכשיו',
    'en': 'Donate now',
    'ru': 'Пожертвовать'
  },
  'home.zmanim.title': {
    'he': 'זמני היום',
    'en': "Today's Times",
    'ru': 'Времена дня'
  },
  'home.news.title': {
    'he': 'חדשות אחרונות',
    'en': 'Latest News',
    'ru': 'Последние новости'
  },
  'home.programs.title': {
    'he': 'תוכניות הקהילה',
    'en': 'Community Programs',
    'ru': 'Программы общины'
  },
  'home.events.title': {
    'he': 'אירועים קרובים',
    'en': 'Upcoming Events',
    'ru': 'Предстоящие события'
  },
  'home.stats.families': {
    'he': 'יהודים באזור',
    'en': 'Jews in the region',
    'ru': 'Евреев в регионе'
  },
  'home.stats.events': {
    'he': 'חנוכת בית מנחם',
    'en': 'Beit Menachem opened',
    'ru': 'Открытие Бейт Менахем'
  },
  'home.stats.years': {
    'he': 'שנות שליחות חב״ד',
    'en': 'Years of Chabad shlichut',
    'ru': 'Лет миссии Хабада'
  },
  'home.stats.meals': {
    'he': 'ליד אור אבנר',
    'en': 'Or Avner school since',
    'ru': 'Лицей Ор Авнер с'
  },
  'home.explore': {
    'he': 'מה מחפשים?',
    'en': 'Explore',
    'ru': 'Разделы'
  },
  'home.reach.title': {
    'he': 'יהודי נובוסיבירסק בעולם?',
    'en': 'Novosibirsk Jews abroad?',
    'ru': 'Евреи Новосибирска в мире?'
  },
  'home.reach.body': {
    'he':
        'אם גדלתם בנובוסיבירסק, למדתם באור אבנר, או משפחתכם מהקהילה — השאירו פרטים. בית מנחם נשאר הבית שלכם.',
    'en':
        'If you grew up in Novosibirsk, studied at Or Avner, or your family is from the community — leave your details. Beit Menachem is still your home.',
    'ru':
        'Если вы выросли в Новосибирске, учились в «Ор Авнер» или ваша семья из общины — оставьте контакты. Бейт Менахем по-прежнему ваш дом.'
  },
  'common.readMore': {
    'he': 'קראו עוד',
    'en': 'Read more',
    'ru': 'Читать далее'
  },
  'common.viewAll': {'he': 'לכל', 'en': 'View all', 'ru': 'Смотреть все'},
  'common.search': {'he': 'חיפוש', 'en': 'Search', 'ru': 'Поиск'},
  'common.all': {'he': 'הכל', 'en': 'All', 'ru': 'Все'},
  'common.required': {
    'he': 'שדה חובה',
    'en': 'Required',
    'ru': 'Обязательное поле'
  },
  'common.emailInvalid': {
    'he': 'כתובת אימייל לא תקינה',
    'en': 'Enter a valid email',
    'ru': 'Некорректный email'
  },
  'common.empty': {
    'he': 'אין פריטים להצגה',
    'en': 'Nothing to show yet',
    'ru': 'Пока ничего нет'
  },
  'common.password': {'he': 'סיסמה', 'en': 'Password', 'ru': 'Пароль'},
  'common.previous': {'he': 'הקודם', 'en': 'Previous', 'ru': 'Назад'},
  'common.next': {'he': 'הבא', 'en': 'Next', 'ru': 'Далее'},
  'common.language': {'he': 'שפה', 'en': 'Language', 'ru': 'Язык'},
  'common.send': {'he': 'שליחה', 'en': 'Send', 'ru': 'Отправить'},
  'common.save': {'he': 'שמירה', 'en': 'Save', 'ru': 'Сохранить'},
  'common.cancel': {'he': 'ביטול', 'en': 'Cancel', 'ru': 'Отмена'},
  'common.add': {'he': 'הוספה', 'en': 'Add', 'ru': 'Добавить'},
  'common.edit': {'he': 'עריכה', 'en': 'Edit', 'ru': 'Редактировать'},
  'common.delete': {'he': 'מחיקה', 'en': 'Delete', 'ru': 'Удалить'},
  'common.close': {'he': 'סגירה', 'en': 'Close', 'ru': 'Закрыть'},
  'common.name': {'he': 'שם', 'en': 'Name', 'ru': 'Имя'},
  'common.email': {'he': 'אימייל', 'en': 'Email', 'ru': 'Эл. почта'},
  'common.phone': {'he': 'טלפון', 'en': 'Phone', 'ru': 'Телефон'},
  'common.message': {'he': 'הודעה', 'en': 'Message', 'ru': 'Сообщение'},
  'common.topic': {'he': 'נושא', 'en': 'Topic', 'ru': 'Тема'},
  'common.amount': {'he': 'סכום', 'en': 'Amount', 'ru': 'Сумма'},
  'common.date': {'he': 'תאריך', 'en': 'Date', 'ru': 'Дата'},
  'common.status': {'he': 'סטטוס', 'en': 'Status', 'ru': 'Статус'},
  'common.category': {'he': 'קטגוריה', 'en': 'Category', 'ru': 'Категория'},

  // Zmanim
  'zmanim.subtitle': {
    'he': 'זמני תפילה, הדלקת נרות והלכות היום',
    'en': 'Prayer times, candle lighting and daily halachot',
    'ru': 'Времена молитв, зажигания свечей и алахот дня'
  },
  'zmanim.shabbat': {'he': 'שבת קודש', 'en': 'Shabbat', 'ru': 'Суббота'},
  'zmanim.candle': {
    'he': 'הדלקת נרות',
    'en': 'Candle lighting',
    'ru': 'Зажигание свечей'
  },
  'zmanim.havdala': {'he': 'צאת השבת', 'en': 'Havdalah', 'ru': 'Исход субботы'},

  // Programs
  'programs.subtitle': {
    'he': 'בית כנסת, סעודת שבת, פעילות ילדים ביום ראשון, אור אבנר, מרכז לב, נוער, מקווה וחסד',
    'en': 'Synagogue, Shabbat meal, Sunday children, Or Avner, Lev, youth, mikveh and chesed',
    'ru': 'Синагога, субботняя трапеза, детская программа в воскресенье, Ор Авнер, Лев, молодёжь, миква и хесед'
  },
  'programs.audience': {
    'he': 'קהל יעד',
    'en': 'Audience',
    'ru': 'Аудитория'
  },
  'programs.schedule': {
    'he': 'לוח זמנים',
    'en': 'Schedule',
    'ru': 'Расписание'
  },
  'programs.register': {
    'he': 'הרשמה לתוכנית',
    'en': 'Register for program',
    'ru': 'Записаться'
  },

  // Gallery
  'gallery.subtitle': {
    'he': 'רגעים מתוך שנות הפעילות של הקהילה',
    'en': 'Moments from years of community life',
    'ru': 'Моменты из жизни общины за годы'
  },
  'gallery.faceSearch': {
    'he': 'חיפוש פרצופים (AI)',
    'en': 'Face search (AI)',
    'ru': 'Поиск лиц (ИИ)'
  },
  'gallery.faceSearch.hint': {
    'he': 'בחרו אדם כדי למצוא את כל התמונות שבהן הוא מזוהה',
    'en': 'Pick a person to find every photo where they are recognized',
    'ru': 'Выберите человека, чтобы найти все фото, где он распознан'
  },
  'gallery.year': {'he': 'שנה', 'en': 'Year', 'ru': 'Год'},
  'gallery.tagged': {
    'he': 'מתויגים בתמונה',
    'en': 'Tagged in photo',
    'ru': 'Отмечены на фото'
  },
  'gallery.results': {
    'he': 'תמונות נמצאו',
    'en': 'photos found',
    'ru': 'фото найдено'
  },

  // Cemetery
  'cemetery.subtitle': {
    'he': 'שמות מבית החיים היהודי בנובוסיבירסק, לפי מאגר הקדיש של בית מנחם. חיפוש לפי שם בעברית או ברוסית.',
    'en': 'Names from the Jewish cemetery in Novosibirsk, from the Beit Menachem kaddish registry. Search by Hebrew or Russian name.',
    'ru': 'Имена с еврейского кладбища Новосибирска — реестр кадиша Бейт Менахем. Поиск по имени на иврите или русском.'
  },
  'cemetery.source': {
    'he': 'מאגר הקדיש המלא בנובוסיבירסק',
    'en': 'Full Novosibirsk kaddish registry',
    'ru': 'Полный реестр кадиша Новосибирска'
  },
  'cemetery.search': {
    'he': 'חיפוש לפי שם',
    'en': 'Search by name',
    'ru': 'Поиск по имени'
  },
  'cemetery.section': {'he': 'חלקה', 'en': 'Section', 'ru': 'Участок'},
  'cemetery.row': {'he': 'שורה', 'en': 'Row', 'ru': 'Ряд'},
  'cemetery.born': {'he': 'נולד/ה', 'en': 'Born', 'ru': 'Родился'},
  'cemetery.passed': {'he': 'נפטר/ה', 'en': 'Passed', 'ru': 'Ушёл'},

  // Famous
  'famous.subtitle': {
    'he': 'שליחי חב״ד וראשי הקהילה היהודית בנובוסיבירסק',
    'en': 'Chabad emissaries and leaders of the Novosibirsk Jewish community',
    'ru': 'Посланники Хабада и лидеры еврейской общины Новосибирска'
  },
  'famous.present': {'he': 'בהווה', 'en': 'Present', 'ru': 'Настоящее'},
  'famous.past': {'he': 'בעבר', 'en': 'Past', 'ru': 'Прошлое'},

  // History
  'history.subtitle': {
    'he': 'מהקהילה ב־1893 ועד בית מנחם — הסיפור היהודי של נובוסיבירסק',
    'en': 'From the 1893 community to Beit Menachem — the Jewish story of Novosibirsk',
    'ru': 'От общины 1893 года до Бейт Менахем — еврейская история Новосибирска'
  },
  'history.tour': {
    'he': 'סיור וירטואלי',
    'en': 'Virtual tour',
    'ru': 'Виртуальный тур'
  },
  'history.tour.cta': {
    'he': 'התחילו סיור',
    'en': 'Start tour',
    'ru': 'Начать тур'
  },

  // Store
  'store.subtitle': {
    'he': 'החנות הכשרה בבית מנחם — יודאיקה, ספרים ומזון כשר',
    'en': 'The kosher shop at Beit Menachem — judaica, books and kosher food',
    'ru': 'Кошерный магазин в Бейт Менахем — иудаика, книги и кошерные продукты'
  },
  'store.judaica': {'he': 'יודאיקה', 'en': 'Judaica', 'ru': 'Иудаика'},
  'store.books': {'he': 'ספרים', 'en': 'Books', 'ru': 'Книги'},
  'store.food': {'he': 'אוכל כשר', 'en': 'Kosher food', 'ru': 'Кошерная еда'},
  'store.addToCart': {'he': 'הוספה לסל', 'en': 'Add to cart', 'ru': 'В корзину'},
  'store.cart': {'he': 'סל קניות', 'en': 'Cart', 'ru': 'Корзина'},
  'store.cart.empty': {
    'he': 'הסל ריק',
    'en': 'Your cart is empty',
    'ru': 'Корзина пуста'
  },
  'store.checkout': {
    'he': 'לתשלום',
    'en': 'Checkout',
    'ru': 'Оформить'
  },
  'store.total': {'he': 'סה"כ', 'en': 'Total', 'ru': 'Итого'},

  // Library
  'library.subtitle': {
    'he': 'שיעורי תורה של הרב שניאור זלמן זקלס — בית מנחם נובוסיבירסק',
    'en': 'Torah classes by Rabbi Shneur Zalman Zaklos — Beit Menachem Novosibirsk',
    'ru': 'Уроки Торы раввина Шнеура Залмана Заклоса — Бейт Менахем Новосибирск'
  },
  'library.watch': {'he': 'צפייה', 'en': 'Watch', 'ru': 'Смотреть'},
  'library.minutes': {'he': 'דקות', 'en': 'min', 'ru': 'мин'},

  // Donate
  'donate.subtitle': {
    'he': 'התרומה שלכם מחזיקה את הבית ומגיעה לכל יהודי',
    'en': 'Your donation sustains the house and reaches every Jew',
    'ru': 'Ваше пожертвование поддерживает дом и доходит до каждого'
  },
  'donate.campaign': {'he': 'ייעוד התרומה', 'en': 'Campaign', 'ru': 'Кампания'},
  'donate.give': {'he': 'תרמו', 'en': 'Give', 'ru': 'Пожертвовать'},
  'donate.thanks': {
    'he': 'תודה רבה על תרומתכם!',
    'en': 'Thank you for your donation!',
    'ru': 'Спасибо за ваше пожертвование!'
  },

  // Contact / registration
  'contact.subtitle': {
    'he': 'הרשמה לפי נושאים, אירועים ושיעורים',
    'en': 'Register by topics, events and classes',
    'ru': 'Регистрация по темам, событиям и урокам'
  },
  'contact.chooseTopic': {
    'he': 'בחרו נושא להרשמה',
    'en': 'Choose a topic',
    'ru': 'Выберите тему'
  },
  'contact.thanks': {
    'he': 'תודה! נחזור אליכם בהקדם.',
    'en': "Thank you! We'll be in touch soon.",
    'ru': 'Спасибо! Мы скоро свяжемся.'
  },

  // About
  'about.subtitle': {
    'he': 'בית הכנסת בית מנחם, רחוב שצ׳טינקינה 68, נובוסיבירסק',
    'en': 'Beit Menachem synagogue, 68 Shchetinkina St., Novosibirsk',
    'ru': 'Синагога Бейт Менахем, ул. Щетинкина, 68, Новосибирск'
  },
  'about.story': {
    'he': 'אודות הקהילה',
    'en': 'About the community',
    'ru': 'Об общине'
  },
  'about.story.body': {
    'he':
        'בית מנחם הוא המרכז הקהילתי היהודי ובית הכנסת היחיד בנובוסיבירסק. הוא נקרא על שם הרבי מליובאוויטש, רבי מנחם מנדל שניאורסון. בראש הקהילה עומדים שליחי חב״ד הרב שניאור זלמן זקלס ורעייתו הרבנית מרים. המבנה נחנך ב־28 באוגוסט 2013: בית כנסת, מקווה לגברים ולנשים, ספרייה, אולם אירועים, חנות כשרה ומרכז ילדים. ליד הקהילה פועלים ליד אור אבנר (משנת 2000) ומרכז «לב» לילדים עם צרכים מיוחדים.',
    'en':
        'Beit Menachem is the Jewish community center and the only synagogue in Novosibirsk, named for the Lubavitcher Rebbe, Rabbi Menachem Mendel Schneerson. It is led by Chabad emissaries Rabbi Shneur Zalman Zaklos and Rebbetzin Miriam. The building opened on 28 August 2013: sanctuary, men\'s and women\'s mikveh, library, banquet hall, kosher shop and children\'s center. The community also runs Or Avner school (since 2000) and the Lev center for children with special needs.',
    'ru':
        '«Бейт Менахем» — еврейский общинный центр и единственная синагога Новосибирска, названная в честь Любавичского Ребе Менахема-Мендла Шнеерсона. Общину возглавляют посланники Хабада раввин Шнеур Залман Заклос и раббанит Мириам. Здание открыто 28 августа 2013 года: синагога, мужская и женская миквы, библиотека, праздничный зал, кошерный магазин и детский центр. При общине работают лицей «Ор Авнер» (с 2000) и центр «Лев» для детей с особыми потребностями.'
  },
  'about.hours': {'he': 'שעות פתיחה', 'en': 'Opening hours', 'ru': 'Часы работы'},
  'about.address': {'he': 'כתובת', 'en': 'Address', 'ru': 'Адрес'},
  'about.contact': {'he': 'צור קשר', 'en': 'Contact', 'ru': 'Контакты'},
  'about.map': {'he': 'מפה', 'en': 'Map', 'ru': 'Карта'},

  // Footer
  'footer.quicklinks': {
    'he': 'קישורים',
    'en': 'Quick links',
    'ru': 'Ссылки'
  },
  'footer.follow': {'he': 'עקבו אחרינו', 'en': 'Follow us', 'ru': 'Мы в сети'},
  'footer.rights': {
    'he': 'כל הזכויות שמורות',
    'en': 'All rights reserved',
    'ru': 'Все права защищены'
  },
  'footer.newsletter': {
    'he': 'הרשמה לעדכונים',
    'en': 'Newsletter',
    'ru': 'Рассылка'
  },
  'newsletter.hint': {
    'he': 'קבלו חדשות, זמנים ואירועים ישירות למייל',
    'en': 'Get news, times and events in your inbox',
    'ru': 'Новости, времена и события на почту'
  },
  'newsletter.join': {
    'he': 'הרשמה',
    'en': 'Subscribe',
    'ru': 'Подписаться'
  },
  'newsletter.thanks': {
    'he': 'נרשמתם בהצלחה. תודה!',
    'en': 'You are subscribed. Thank you!',
    'ru': 'Вы подписались. Спасибо!'
  },
  'newsletter.duplicate': {
    'he': 'כתובת זו כבר רשומה',
    'en': 'This email is already subscribed',
    'ru': 'Этот адрес уже подписан'
  },
  'search.hint': {
    'he': 'חיפוש בחדשות, תוכניות, חנות ועוד',
    'en': 'Search news, programs, store and more',
    'ru': 'Поиск по новостям, программам, магазину'
  },
  'search.empty': {
    'he': 'לא נמצאו תוצאות',
    'en': 'No results',
    'ru': 'Ничего не найдено'
  },
  'search.group.news': {'he': 'חדשות', 'en': 'News', 'ru': 'Новости'},
  'search.group.programs': {
    'he': 'תוכניות',
    'en': 'Programs',
    'ru': 'Программы'
  },
  'search.group.products': {'he': 'חנות', 'en': 'Store', 'ru': 'Магазин'},
  'search.group.famous': {
    'he': 'יהודים מפורסמים',
    'en': 'Notable Jews',
    'ru': 'Известные евреи'
  },
  'search.group.cemetery': {
    'he': 'בית החיים',
    'en': 'Cemetery',
    'ru': 'Кладбище'
  },
  'search.group.library': {
    'he': 'שיעורי תורה',
    'en': 'Torah Library',
    'ru': 'Уроки Торы'
  },
  'admin.persist.note': {
    'he': 'התוכן נשמר בדפדפן תמיד. כדי שיעלה לשרת: Firestore → Rules, הדביקו את הכללים מהמנהל, Publish. בלי Storage ובלי תשלום.',
    'en': 'Content always saves in this browser. To reach the server: Firestore → Rules, paste the admin rules, Publish. No Storage, no paid plan.',
    'ru': 'Контент всегда в браузере. Чтобы на сервер: Firestore → Rules, вставьте правила, Publish. Без Storage и оплаты.'
  },
  'admin.cloud.publish': {
    'he': 'שמור לשרת',
    'en': 'Save to server',
    'ru': 'Сохранить на сервер'
  },
  'admin.cloud.ok': {
    'he': 'נשמר ב-Firestore',
    'en': 'Saved to Firestore',
    'ru': 'Сохранено в Firestore'
  },
  'admin.cloud.blocked': {
    'he': 'השרת חוסם כתיבה. זה לא Storage ולא תשלום — רק כללי Firestore. בקונסול, טאב Rules, מחקו הכל, הדביקו את הטקסט למטה, Publish, ואז «שמור לשרת».',
    'en': 'The server is blocking writes. Not Storage and not a paid plan — just Firestore rules. Rules tab: replace with the text below, Publish, then Save to server.',
    'ru': 'Сервер блокирует запись. Не Storage и не оплата — правила Firestore. Вкладка Rules, вставьте текст ниже, Publish, затем «Сохранить на сервер».'
  },
  'admin.cloud.rulesTitle': {
    'he': 'הדביקו ב-Firestore → Rules ואז Publish:',
    'en': 'Paste into Firestore → Rules, then Publish:',
    'ru': 'Вставьте в Firestore → Rules и Publish:'
  },
  'admin.cloud.console': {
    'he': 'פתיחת קונסול Firestore',
    'en': 'Open Firestore console',
    'ru': 'Открыть консоль Firestore'
  },

  'admin.settings.mapsKey': {
    'he': 'מפתח Google Maps (רשות)',
    'en': 'Google Maps API key (optional)',
    'ru': 'Ключ Google Maps (необязательно)'
  },
  'admin.settings.mapsHint': {
    'he': 'אם אין מפתח, תוצג מפת OpenStreetMap אמיתית לפי הכתובת והמיקום.',
    'en': 'Without a key, a real OpenStreetMap is shown from the address and location.',
    'ru': 'Без ключа показывается настоящая карта OpenStreetMap по адресу и месту.'
  },
  'admin.newsletter': {
    'he': 'נרשמים לעדכונים',
    'en': 'Newsletter subscribers',
    'ru': 'Подписчики рассылки'
  },
  'admin.newsletter.empty': {
    'he': 'עדיין אין נרשמים',
    'en': 'No subscribers yet',
    'ru': 'Подписчиков пока нет'
  },

  // Admin
  'admin.login.title': {
    'he': 'כניסת מנהל',
    'en': 'Admin Login',
    'ru': 'Вход администратора'
  },
  'admin.login.hint': {
    'he': 'כל אימייל וסיסמה יפתחו את המנהל. השמירה עולה ל-Firestore (בלי Storage).',
    'en': 'Any email and password open admin. Saves go to Firestore (no Storage).',
    'ru': 'Любые почта и пароль откроют админку. Сохранение идёт в Firestore (без Storage).'
  },
  'admin.login.firebaseHint': {
    'he': 'אם Authentication פעיל — התחברו עם המשתמש. אחרת כל אימייל/סיסמה יעבדו, והשמירה ל-Firestore תנסה בכל מקרה.',
    'en': 'If Authentication is on, sign in with that user. Otherwise any email/password works, and Firestore writes are still attempted.',
    'ru': 'Если Authentication включён — войдите этим пользователем. Иначе подойдут любые данные, запись в Firestore всё равно пробуется.'
  },
  'admin.login.button': {'he': 'כניסה', 'en': 'Log in', 'ru': 'Войти'},
  'admin.login.error': {
    'he': 'אימייל או סיסמה שגויים',
    'en': 'Incorrect email or password',
    'ru': 'Неверный email или пароль'
  },
  'admin.login.empty': {
    'he': 'נא למלא אימייל וסיסמה',
    'en': 'Please enter email and password',
    'ru': 'Введите email и пароль'
  },
  'admin.login.unavailable': {
    'he': 'Firebase לא זמין כרגע — בדקו שהשירותים פעילים בקונסול',
    'en': 'Firebase is unavailable — enable it in the console',
    'ru': 'Firebase недоступен — включите сервисы в консоли'
  },
  'admin.logout': {'he': 'יציאה', 'en': 'Log out', 'ru': 'Выйти'},
  'admin.dashboard': {'he': 'לוח בקרה', 'en': 'Dashboard', 'ru': 'Панель'},
  'admin.viewSite': {
    'he': 'צפייה באתר',
    'en': 'View site',
    'ru': 'Открыть сайт'
  },
  'admin.section.content': {'he': 'תוכן', 'en': 'Content', 'ru': 'Контент'},
  'admin.section.community': {
    'he': 'קהילה',
    'en': 'Community',
    'ru': 'Община'
  },
  'admin.section.automation': {
    'he': 'אוטומציה',
    'en': 'Automation',
    'ru': 'Автоматизация'
  },
  'admin.crm': {'he': 'CRM / נרשמים', 'en': 'CRM / Leads', 'ru': 'CRM / Заявки'},
  'admin.crm.note': {
    'he': 'הנתונים מגיעים ממערכת ה-CRM החיצונית (מוק דאטא)',
    'en': 'Data arrives from the external CRM system (mock data)',
    'ru': 'Данные поступают из внешней CRM (демоданные)'
  },
  'admin.bots': {'he': 'בוטים', 'en': 'Bots', 'ru': 'Боты'},
  'admin.bots.telegram': {
    'he': 'בוט טלגרם — משיכת חדשות',
    'en': 'Telegram bot — news import',
    'ru': 'Telegram-бот — импорт новостей'
  },
  'admin.bots.social': {
    'he': 'בוט רשתות — פרסום אוטומטי',
    'en': 'Social bot — auto-posting',
    'ru': 'Соцбот — автопубликация'
  },
  'admin.bots.lastSync': {
    'he': 'סנכרון אחרון',
    'en': 'Last sync',
    'ru': 'Синхронизация'
  },
  'admin.bots.synced': {
    'he': 'פריטים סונכרנו',
    'en': 'items synced',
    'ru': 'элементов'
  },
  'admin.bots.runNow': {
    'he': 'הרצה עכשיו',
    'en': 'Run now',
    'ru': 'Запустить'
  },
  'admin.bots.enabled': {'he': 'פעיל', 'en': 'Enabled', 'ru': 'Включён'},
  'admin.lead.fresh': {'he': 'חדש', 'en': 'New', 'ru': 'Новый'},
  'admin.lead.contacted': {
    'he': 'נוצר קשר',
    'en': 'Contacted',
    'ru': 'Связались'
  },
  'admin.lead.member': {
    'he': 'חבר קהילה',
    'en': 'Member',
    'ru': 'Участник'
  },
  'admin.bots.posted': {
    'he': 'פורסם בפייסבוק, אינסטגרם, X ו-VK',
    'en': 'Posted to FB · IG · X · VK',
    'ru': 'Опубликовано в FB · IG · X · VK'
  },
  'admin.stats.leads': {'he': 'נרשמים', 'en': 'Leads', 'ru': 'Заявки'},
  'admin.stats.donations': {
    'he': 'תרומות',
    'en': 'Donations',
    'ru': 'Пожертвования'
  },
  'admin.stats.news': {'he': 'כתבות', 'en': 'Articles', 'ru': 'Статьи'},
  'admin.stats.products': {'he': 'מוצרים', 'en': 'Products', 'ru': 'Товары'},
  'admin.manage.news': {
    'he': 'ניהול חדשות',
    'en': 'Manage News',
    'ru': 'Новости'
  },
  'admin.manage.programs': {
    'he': 'ניהול תוכניות',
    'en': 'Manage Programs',
    'ru': 'Программы'
  },
  'admin.manage.store': {
    'he': 'ניהול חנות',
    'en': 'Manage Store',
    'ru': 'Магазин'
  },
  'admin.manage.gallery': {
    'he': 'ניהול גלריה',
    'en': 'Manage Gallery',
    'ru': 'Галерея'
  },
  'admin.banners': {
    'he': 'באנרים ותמונות',
    'en': 'Banners & photos',
    'ru': 'Баннеры'
  },
  'admin.banners.subtitle': {
    'he': 'העלו תמונה במקום הבאנר הכחול. בתצוגה המקדימה רואים בדיוק איך היא תיחתך באתר.',
    'en': 'Upload a photo instead of the blue banner. The preview shows exactly how it will be cropped.',
    'ru': 'Загрузите фото вместо синего баннера. В превью видно, как оно обрежется.'
  },
  'admin.banners.upload': {
    'he': 'בחירת תמונה',
    'en': 'Choose photo',
    'ru': 'Выбрать фото'
  },
  'admin.banners.remove': {
    'he': 'הסרת תמונה',
    'en': 'Remove photo',
    'ru': 'Удалить фото'
  },
  'admin.banners.preview': {
    'he': 'תצוגה מקדימה (חיתוך כמו באתר)',
    'en': 'Preview (cropped as on the site)',
    'ru': 'Превью (обрезка как на сайте)'
  },
  'admin.banners.alignX': {
    'he': 'מיקוד אופקי',
    'en': 'Horizontal focus',
    'ru': 'Горизонталь'
  },
  'admin.banners.alignY': {
    'he': 'מיקוד אנכי',
    'en': 'Vertical focus',
    'ru': 'Вертикаль'
  },
  'admin.banners.empty': {
    'he': 'באנר כחול כברירת מחדל',
    'en': 'Default blue banner',
    'ru': 'Синий баннер по умолчанию'
  },
  'admin.banners.hint': {
    'he': 'גררו את המחוונים כדי לבחור איזה חלק מהתמונה יוצג. מה שמחוץ למסגרת ייחתך.',
    'en': 'Drag the sliders to choose which part of the photo is shown. Anything outside the frame is cropped.',
    'ru': 'Ползунки выбирают видимую часть фото. Всё за рамкой обрезается.'
  },
  'admin.recent': {
    'he': 'פעילות אחרונה',
    'en': 'Recent activity',
    'ru': 'Последняя активность'
  },
  'admin.newItem': {'he': 'פריט חדש', 'en': 'New item', 'ru': 'Новый элемент'},
  'admin.translate': {
    'he': 'תרגום אוטומטי',
    'en': 'Auto-translate',
    'ru': 'Автоперевод'
  },
  'admin.translate.ok': {
    'he': 'התרגום מולא בשדות הריקים',
    'en': 'Empty fields were filled from Hebrew',
    'ru': 'Пустые поля заполнены с иврита'
  },
  'admin.translate.skip': {
    'he': 'אין שדות ריקים למילוי',
    'en': 'Nothing empty to fill',
    'ru': 'Нет пустых полей'
  },
  'admin.translate.error': {
    'he': 'התרגום נכשל. נסו שוב בעוד רגע.',
    'en': 'Translation failed. Try again in a moment.',
    'ru': 'Перевод не удался. Попробуйте позже.'
  },
  'admin.image': {'he': 'תמונה', 'en': 'Photo', 'ru': 'Фото'},
  'admin.image.choose': {
    'he': 'בחירת תמונה',
    'en': 'Choose photo',
    'ru': 'Выбрать фото'
  },
  'admin.image.remove': {
    'he': 'הסרת תמונה',
    'en': 'Remove photo',
    'ru': 'Удалить фото'
  },
  'admin.image.preview': {
    'he': 'תצוגה מקדימה (חיתוך כמו בכרטיס)',
    'en': 'Preview (cropped as on the card)',
    'ru': 'Превью (обрезка как на карточке)'
  },
  'admin.settings': {'he': 'הגדרות', 'en': 'Settings', 'ru': 'Настройки'},
  'admin.settings.subtitle': {
    'he': 'כתבו את שם העיר של בית חב"ד. הזמנים והפרשה באתר יתעדכנו לפי המקום הזה.',
    'en': 'Enter the city of this Chabad house. Times and the weekly Torah portion will update for that place.',
    'ru': 'Введите город дома Хабада. Времена и недельная глава обновятся по этому месту.'
  },
  'admin.settings.city': {
    'he': 'עיר או כתובת',
    'en': 'City or address',
    'ru': 'Город или адрес'
  },
  'admin.settings.search': {'he': 'חפש', 'en': 'Search', 'ru': 'Найти'},
  'admin.settings.useGps': {
    'he': 'שימוש במיקום הנוכחי',
    'en': 'Use current location',
    'ru': 'Использовать моё место'
  },
  'admin.settings.resolved': {
    'he': 'המקום שנשמר',
    'en': 'Saved place',
    'ru': 'Сохранённое место'
  },
  'admin.settings.saved': {
    'he': 'המיקום נשמר. הזמנים מתעדכנים.',
    'en': 'Location saved. Times are updating.',
    'ru': 'Место сохранено. Времена обновляются.'
  },
  'admin.settings.noResults': {
    'he': 'לא נמצאה עיר. נסו שם אחר.',
    'en': 'No city found. Try another name.',
    'ru': 'Город не найден. Попробуйте другое имя.'
  },
  'admin.settings.error': {
    'he': 'החיפוש נכשל. בדקו את החיבור לאינטרנט.',
    'en': 'Search failed. Check your internet connection.',
    'ru': 'Поиск не удался. Проверьте интернет.'
  },
  'admin.settings.geoError': {
    'he': 'לא הצלחנו לקרוא את המיקום. אשרו גישה למיקום בדפדפן.',
    'en': 'Could not read your location. Allow location access in the browser.',
    'ru': 'Не удалось определить место. Разрешите геолокацию в браузере.'
  },
  'admin.settings.timesError': {
    'he': 'המיקום נשמר, אבל עדכון הזמנים נכשל. נסו שוב.',
    'en': 'Location saved, but updating times failed. Try again.',
    'ru': 'Место сохранено, но времена не обновились. Попробуйте снова.'
  },
  'admin.settings.lat': {'he': 'קו רוחב', 'en': 'Latitude', 'ru': 'Широта'},
  'admin.settings.lon': {'he': 'קו אורך', 'en': 'Longitude', 'ru': 'Долгота'},
  'admin.settings.tz': {
    'he': 'אזור זמן',
    'en': 'Timezone',
    'ru': 'Часовой пояс'
  },
  'zmanim.forCity': {
    'he': 'זמנים לפי',
    'en': 'Times for',
    'ru': 'Времена для'
  },
  'admin.tg.subtitle': {
    'he': 'חברו את ערוץ הטלגרם של הקהילה — הפוסטים יופיעו בחדשות.',
    'en': 'Connect the community Telegram channel — posts will appear in News.',
    'ru': 'Подключите Telegram-канал общины — посты появятся в новостях.'
  },
  'admin.tg.guideTitle': {
    'he': 'איך מחברים, שלב אחרי שלב',
    'en': 'How to connect, step by step',
    'ru': 'Как подключить, шаг за шагом'
  },
  'admin.tg.step1': {
    'he': 'פתחו את טלגרם בטלפון.',
    'en': 'Open Telegram on your phone.',
    'ru': 'Откройте Telegram на телефоне.'
  },
  'admin.tg.step2': {
    'he': 'חפשו @BotFather והקישו Start.',
    'en': 'Search @BotFather and tap Start.',
    'ru': 'Найдите @BotFather и нажмите Start.'
  },
  'admin.tg.step3': {
    'he': 'שלחו /newbot, בחרו שם, ואז שם משתמש שמסתיים ב-bot.',
    'en': 'Send /newbot, pick a name, then a username ending with bot.',
    'ru': 'Отправьте /newbot, выберите имя, затем имя пользователя с bot.'
  },
  'admin.tg.step4': {
    'he': 'BotFather שולח קוד (טוקן) — העתיקו אותו. הוא נראה כמו 123456:ABC...',
    'en': 'BotFather sends a token — copy it. It looks like 123456:ABC...',
    'ru': 'BotFather пришлёт токен — скопируйте. Вид: 123456:ABC...'
  },
  'admin.tg.step5': {
    'he': 'הדביקו את הקוד בשדה כאן.',
    'en': 'Paste the token in the field here.',
    'ru': 'Вставьте токен в поле здесь.'
  },
  'admin.tg.step6': {
    'he': 'פתחו את ערוץ הקהילה והוסיפו את הבוט כמנהל (כדי שיוכל לקרוא פוסטים).',
    'en': 'Open the community channel and add the bot as administrator (so it can read posts).',
    'ru': 'Откройте канал общины и добавьте бота администратором.'
  },
  'admin.tg.step7': {
    'he': 'הדביקו את שם הערוץ (למשל @mychannel).',
    'en': 'Paste the channel username (e.g. @mychannel).',
    'ru': 'Вставьте имя канала (например @mychannel).'
  },
  'admin.tg.step8': {
    'he': 'לחצו «בדיקת חיבור» — אמור להופיע שם הבוט.',
    'en': 'Tap “Check connection” — the bot name should appear.',
    'ru': 'Нажмите «Проверить связь» — должно появиться имя бота.'
  },
  'admin.tg.step9': {
    'he': 'לחצו «משיכת חדשות» — פוסטים חדשים יופיעו בעמוד החדשות.',
    'en': 'Tap “Pull news” — new channel posts appear on the News page.',
    'ru': 'Нажмите «Загрузить новости» — новые посты появятся на странице новостей.'
  },
  'admin.tg.token': {
    'he': 'קוד הבוט (טוקן)',
    'en': 'Bot token',
    'ru': 'Токен бота'
  },
  'admin.tg.channel': {
    'he': 'שם הערוץ',
    'en': 'Channel username',
    'ru': 'Имя канала'
  },
  'admin.tg.connect': {
    'he': 'בדיקת חיבור',
    'en': 'Check connection',
    'ru': 'Проверить связь'
  },
  'admin.tg.pull': {
    'he': 'משיכת חדשות עכשיו',
    'en': 'Pull news now',
    'ru': 'Загрузить новости'
  },
  'admin.tg.connected': {
    'he': 'מחובר',
    'en': 'Connected',
    'ru': 'Подключено'
  },
  'admin.tg.imported': {
    'he': 'נמשכו {n} כתבות חדשות',
    'en': 'Imported {n} new articles',
    'ru': 'Загружено {n} новых записей'
  },
  'admin.tg.noPosts': {
    'he': 'אין פוסטים חדשים. פרסמו בערוץ ואז לחצו שוב. הבוט קורא פוסטים אחרי שמוסיפים אותו כמנהל.',
    'en': 'No new posts. Publish in the channel, then tap again. The bot reads posts after you add it as admin.',
    'ru': 'Нет новых постов. Опубликуйте в канале и нажмите снова. Бот читает посты после назначения админом.'
  },
  'admin.tg.err.proxy': {
    'he': 'לא הצלחנו לדבר עם טלגרם מהדפדפן. נסו לרענן, או לכבות חוסם פרסומות, או לנסות שוב בעוד דקה.',
    'en': 'Could not reach Telegram from the browser. Refresh, pause an ad blocker, or try again in a minute.',
    'ru': 'Не удалось связаться с Telegram из браузера. Обновите страницу, отключите блокировщик рекламы или попробуйте позже.'
  },
  'admin.tg.err.token': {
    'he': 'הקוד לא נכון. העתיקו שוב מ-BotFather (בלי רווחים).',
    'en': 'The token is not correct. Copy it again from BotFather (no spaces).',
    'ru': 'Токен неверный. Скопируйте снова у BotFather (без пробелов).'
  },
  'admin.tg.err.channel': {
    'he': 'חסר שם ערוץ. כתבו למשל @mychannel.',
    'en': 'Channel username is missing. Enter e.g. @mychannel.',
    'ru': 'Нет имени канала. Введите, например, @mychannel.'
  },
  'admin.tg.err.generic': {
    'he': 'משהו לא עבד. בדקו את הקוד ואת שם הערוץ ונסו שוב.',
    'en': 'Something went wrong. Check the token and channel name, then try again.',
    'ru': 'Что-то пошло не так. Проверьте токен и имя канала.'
  },
};
