import 'package:flutter/material.dart';

/// Supported UI languages. Hebrew is the primary (RTL) language.
const supportedLangs = ['he', 'en', 'ru'];

const langNames = {
  'he': 'עברית',
  'en': 'English',
  'ru': 'Русский',
};

/// Holds the currently selected language and exposes translation lookup.
class LocaleController extends ChangeNotifier {
  LocaleController([this._lang = 'he']);

  String _lang;
  String get lang => _lang;
  Locale get locale => Locale(_lang);
  bool get isRtl => _lang == 'he';
  TextDirection get direction =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  void setLang(String lang) {
    if (_lang == lang || !supportedLangs.contains(lang)) return;
    _lang = lang;
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
    'he': 'בית חב"ד ליובאוויטש',
    'en': 'Chabad Lubavitch Center',
    'ru': 'Центр Хабад Любавич',
  },
  'site.city': {
    'he': 'העיר שלנו',
    'en': 'Our City',
    'ru': 'Наш город',
  },
  'site.tagline': {
    'he': 'בית חם לכל יהודי — קרוב, מזמין ומחבר',
    'en': 'A warm home for every Jew — welcoming and connecting',
    'ru': 'Тёплый дом для каждого еврея — гостеприимный и объединяющий',
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
    'he': 'משפחות בקהילה',
    'en': 'Community families',
    'ru': 'Семьи в общине'
  },
  'home.stats.events': {
    'he': 'אירועים בשנה',
    'en': 'Events per year',
    'ru': 'Событий в год'
  },
  'home.stats.years': {
    'he': 'שנות פעילות',
    'en': 'Years of activity',
    'ru': 'Лет деятельности'
  },
  'home.stats.meals': {
    'he': 'ארוחות שבת',
    'en': 'Shabbat meals',
    'ru': 'Субботних трапез'
  },
  'home.explore': {
    'he': 'מה מחפשים?',
    'en': 'Explore',
    'ru': 'Разделы'
  },
  'home.reach.title': {
    'he': 'גרתם פעם בעיר?',
    'en': 'Once lived here?',
    'ru': 'Когда-то жили здесь?'
  },
  'home.reach.body': {
    'he':
        'אנחנו מחפשים יהודים שגרו בעיר ועברו לגור במקום אחר בעולם. השאירו פרטים ונשמור על קשר.',
    'en':
        'We are reconnecting with Jews who once lived here and moved elsewhere in the world. Leave your details and we will keep in touch.',
    'ru':
        'Мы восстанавливаем связь с евреями, которые жили здесь и переехали. Оставьте данные, и мы будем на связи.'
  },
  'common.readMore': {
    'he': 'קראו עוד',
    'en': 'Read more',
    'ru': 'Читать далее'
  },
  'common.viewAll': {'he': 'לכל', 'en': 'View all', 'ru': 'Смотреть все'},
  'common.search': {'he': 'חיפוש', 'en': 'Search', 'ru': 'Поиск'},
  'common.all': {'he': 'הכל', 'en': 'All', 'ru': 'Все'},
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
    'he': 'שיעורים, חוגים ופעילויות לכל המשפחה',
    'en': 'Classes, clubs and activities for the whole family',
    'ru': 'Уроки, кружки и мероприятия для всей семьи'
  },
  'programs.audience': {
    'he': 'קהל יעד',
    'en': 'Audience',
    'ru': 'Аудитория'
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
    'he': 'מאגר המצבות מבית החיים היהודי',
    'en': 'Jewish cemetery gravestone database',
    'ru': 'База надгробий еврейского кладбища'
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
    'he': 'יהודים שהשאירו חותם בעיר — בהווה ובעבר',
    'en': 'Jews who left a mark on the city — present and past',
    'ru': 'Евреи, оставившие след в городе — в настоящем и прошлом'
  },
  'famous.present': {'he': 'בהווה', 'en': 'Present', 'ru': 'Настоящее'},
  'famous.past': {'he': 'בעבר', 'en': 'Past', 'ru': 'Прошлое'},

  // History
  'history.subtitle': {
    'he': 'ההיסטוריה היהודית של העיר',
    'en': 'The Jewish history of the city',
    'ru': 'Еврейская история города'
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
    'he': 'יודאיקה, ספרים ואוכל כשר — משלוח מהחנות המרכזית',
    'en': 'Judaica, books and kosher food — shipped from the central store',
    'ru': 'Иудаика, книги и кошерная еда — доставка с центрального склада'
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
    'he': 'ספריית שיעורי תורה של הרב',
    'en': "The Rabbi's Torah class library",
    'ru': 'Библиотека уроков Торы раввина'
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
    'he': 'פרטים, שעות פתיחה וכתובת',
    'en': 'Details, opening hours and address',
    'ru': 'Детали, часы работы и адрес'
  },
  'about.hours': {'he': 'שעות פתיחה', 'en': 'Opening hours', 'ru': 'Часы работы'},
  'about.address': {'he': 'כתובת', 'en': 'Address', 'ru': 'Адрес'},
  'about.contact': {'he': 'צור קשר', 'en': 'Contact', 'ru': 'Контакты'},

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

  // Admin
  'admin.login.title': {
    'he': 'כניסת מנהל',
    'en': 'Admin Login',
    'ru': 'Вход администратора'
  },
  'admin.login.hint': {
    'he': 'הדגמה: כל אימייל וסיסמה יתקבלו',
    'en': 'Demo: any email and password will work',
    'ru': 'Демо: подойдут любые почта и пароль'
  },
  'admin.login.button': {'he': 'כניסה', 'en': 'Log in', 'ru': 'Войти'},
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
  'admin.recent': {
    'he': 'פעילות אחרונה',
    'en': 'Recent activity',
    'ru': 'Последняя активность'
  },
  'admin.newItem': {'he': 'פריט חדש', 'en': 'New item', 'ru': 'Новый элемент'},
};
