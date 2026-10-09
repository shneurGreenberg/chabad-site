import '../models.dart';
import '../theme.dart';
import 'tenant_config.dart';

/// Bundled Novosibirsk (nsk) tenant — exact production defaults.
final TenantConfig nskTenantConfig = TenantConfig(
  tenantId: 'nsk',
  communityName: {
    'he': 'בית חב״ד בית מנחם',
    'en': 'Chabad Beit Menachem',
    'ru': 'Хабад Бейт Менахем',
  },
  cityName: {
    'he': 'נובוסיבירסק',
    'en': 'Novosibirsk',
    'ru': 'Новосибирск',
  },
  tagline: {
    'he':
        'בית הכנסת והמרכז הקהילתי היהודי בנובוסיבירסק — בית חם לכל יהודי סיביר',
    'en':
        'The synagogue and Jewish community center in Novosibirsk — a home for every Jew in Siberia',
    'ru':
        'Синагога и еврейский общинный центр Новосибирска — дом для каждого еврея Сибири',
  },
  aboutSubtitle: {
    'he': 'בית הכנסת בית מנחם, רחוב שצ׳טינקינה 68, נובוסיבירסק',
    'en': 'Beit Menachem synagogue, 68 Shchetinkina St., Novosibirsk',
    'ru': 'Синагога Бейт Менахем, ул. Щетинкина, 68, Новосибирск',
  },
  aboutBody: {
    'he':
        'בית מנחם הוא המרכז הקהילתי היהודי ובית הכנסת בנובוסיבירסק. הוא נקרא על שם הרבי מליובאוויטש, רבי מנחם מנדל שניאורסון. בראש הקהילה עומדים שליחי חב״ד הרב שניאור זלמן זקלס ורעייתו הרבנית מירים. המבנה נחנך ב־28 באוגוסט 2013: בית כנסת, מקווה לגברים ולנשים, ספרייה, אולם אירועים, חנות כשרה ומרכז ילדים. ליד הקהילה פועל בית ספר אור אבנר (משנת 2000) ומרכז «לב» לילדים עם צרכים מיוחדים.',
    'en':
        'Beit Menachem is the Jewish community center and synagogue in Novosibirsk, named for the Lubavitcher Rebbe, Rabbi Menachem Mendel Schneerson. It is led by Chabad emissaries Rabbi Shneur Zalman Zaklos and Rebbetzin Miriam. The building opened on 28 August 2013: sanctuary, men\'s and women\'s mikveh, library, banquet hall, kosher shop and children\'s center. The community also runs Or Avner school (since 2000) and the Lev center for children with special needs.',
    'ru':
        '«Бейт Менахем» — еврейский общинный центр и синагога Новосибирска, названная в честь Любавичского Ребе Менахема-Мендла Шнеерсона. Общину возглавляют посланники Хабада раввин Шнеур Залман Заклос и раббанит Мириам. Здание открыто 28 августа 2013 года: синагога, мужская и женская миква, библиотека, праздничный зал, кошерный магазин и детский центр. При общине работают лицей «Ор Авнер» (с 2000) и центр «Лев» для детей с особыми потребностями.',
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
      {
        'he': 'שני וחמישי',
        'en': 'Monday & Thursday',
        'ru': 'Понедельник и четверг',
      },
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
        'ru': 'Молитва 10:00 · субботная трапеза 13:00',
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
  social: TenantSocialLinks(
    telegram: 'https://t.me/jewishsib',
    vk: 'https://vk.com/jewishsib',
    youtube: '',
    facebook: '',
    instagram: '',
    website: 'http://jewishsib.com',
    donateUrl: '',
    bankDetails: '',
  ),
  whatsAppDigits: '79039004320',
  defaultAdminEmails: 'admin@chabad-city.org',
  defaultPaletteId: SitePalettes.classic.id,
  emblemAssetPath: 'assets/images/community-emblem.png',
  locationQuery: 'Novosibirsk',
  latitude: 55.0284,
  longitude: 82.9283,
  timezone: 'Asia/Novosibirsk',
  kaddishHost: 'https://synagogue-kadish-shneur.amvera.io',
  kaddishServiceId: 'novosibirsk',
  seoTitle: 'בית חב״ד בית מנחם — נובוסיבירסק',
  enabledLanguages: const ['he', 'en', 'ru'],
  defaultLanguage: 'ru',
  telegramChannelHint: 'jewishsib',
  landlineDigits: '73832222023',
);
