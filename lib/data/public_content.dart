import '../models.dart';
import 'snapshot.dart';

/// Public launch rules. Visitors should not see empty cards, packaged demos,
/// or a stored placeholder where a city name belongs.

bool locHasText(Loc map) => map.values.any((v) => v.trim().isNotEmpty);

bool programIsPublic(Program program) => locHasText(program.title);

/// A store card with neither a name nor a price is not a product.
bool productIsPublic(Product product) =>
    locHasText(product.name) || product.price > 0;

const hiddenGalleryAlbumTitle = 'Зубные щетки';

bool galleryAlbumIsPublic(GalleryPhoto album) => !album.event.values
    .any((v) => v.trim() == hiddenGalleryAlbumTitle);

const _demoYoutubeIds = ['OVKQe9fiNu8', 'nQlfH43G1mg'];

const _demoShiurTitles = {
  'הכנה לימים הנוראים',
  'Preparing for the High Holidays',
  'Подготовка к Высоким праздникам',
  'פרשת השבוע למעשה',
  'The weekly parasha in practice',
  'Недельная глава на практике',
  'יסודות התניא',
  'Foundations of Tanya',
  'Основы Тании',
  'הלכות שבת למעשה',
  'Practical laws of Shabbat',
  'Законы субботы на практике',
  'כולל תורה',
  'Kollel Torah',
  'Колель Тора',
  'מסע הנשמה — המכתב על המחט והמים',
  'The journey of the soul — the needle and the water',
  'Путь души — игла и вода',
  'האם הקב״ה צריך אותנו? שיחה על נח והמרגלים',
  'Does G-d need us? On Noah and the spies',
  'Нужен ли нам Бог? Ноах и разведчики',
};

bool shiurIsPackagedDemo(Shiur shiur) {
  final url = shiur.youtubeUrl;
  if (_demoYoutubeIds.any(url.contains)) return true;
  return shiur.title.values.any((v) => _demoShiurTitles.contains(v.trim()));
}

List<Shiur> visibleShiurim(Iterable<Shiur> all) =>
    [for (final s in all) if (!shiurIsPackagedDemo(s)) s];

/// A missing or empty cloud list means there are no published lessons.
/// Packaged demo lessons are dropped either way.
List<Shiur> shiurimAfterSnapshot(List<Shiur> current, Object? raw) {
  if (raw is List) {
    return visibleShiurim(raw.map(shiurFromJson));
  }
  return visibleShiurim(current);
}

bool donationIsSeededDemo(Donation donation) {
  final name = donation.donor.trim().toLowerCase();
  final amount = donation.amount.round();
  return (name == 'anonymous' && amount == 360) ||
      (name == 'm. roth' && amount == 1000) ||
      (name == 'a. fishman' && amount == 180);
}

List<Donation> visibleDonations(Iterable<Donation> all) =>
    [for (final d in all) if (!donationIsSeededDemo(d)) d];

const _locationPlaceholders = {
  'מיקום נוכחי',
  'Текущее местоположение',
  'Current location',
};

/// Novosibirsk in the active language when the stored city is the GPS placeholder.
/// Coordinates are left untouched.
String displayCityName(String stored, String lang) {
  if (!_locationPlaceholders.contains(stored.trim())) return stored;
  switch (lang) {
    case 'en':
      return 'Novosibirsk';
    case 'ru':
      return 'Новосибирск';
    default:
      return 'נובוסיבירסק';
  }
}

const liveCommunitySite = 'https://jewishsib-shneur.mia0.amvera.tech/';

/// Rewrites only the dead jewishsib.com host. Any other URL is returned as stored.
String publicWebsiteUrl(String stored) {
  final raw = stored.trim();
  if (raw.isEmpty) return raw;
  var parsed = Uri.tryParse(raw);
  if (parsed == null || parsed.host.isEmpty) {
    parsed = Uri.tryParse('https://$raw');
  }
  final host = parsed?.host.toLowerCase() ?? '';
  if (host == 'jewishsib.com' || host == 'www.jewishsib.com') {
    return liveCommunitySite;
  }
  return raw;
}

final _hebrew = RegExp(r'[\u0590-\u05FF]');
final _cyrillic = RegExp(r'[А-Яа-яЁё]');
final _latin = RegExp(r'[A-Za-z]');

/// Day–day.month and day.month, optional year. Times (18:30) are not dates.
final _eventRange = RegExp(
  r'(\d{1,2})\s*[–—\-]\s*(\d{1,2})\.(\d{1,2})(?:\.(\d{2,4}))?',
);
final _eventSingle = RegExp(
  r'(?<!\d)(\d{1,2})\.(\d{1,2})(?:\.(\d{2,4}))?(?!\d)',
);

DateTime? _eventDate(int day, int month, String? yearRaw, int fallbackYear) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  var year = fallbackYear;
  if (yearRaw != null && yearRaw.isNotEmpty) {
    final n = int.tryParse(yearRaw);
    if (n == null) return null;
    year = n < 100 ? 2000 + n : n;
  }
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  return DateTime(date.year, date.month, date.day);
}

/// True when the article names event dates and every one of them is already over.
bool newsEventDatesArePast(NewsArticle article, DateTime today) {
  final text = [
    ...article.title.values,
    ...article.body.values,
  ].join('\n');
  final todayDate = DateTime(today.year, today.month, today.day);
  final ends = <DateTime>[];
  for (final m in _eventRange.allMatches(text)) {
    final date = _eventDate(
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      m.group(4),
      today.year,
    );
    if (date != null) ends.add(date);
  }
  for (final m in _eventSingle.allMatches(text)) {
    final date = _eventDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      m.group(3),
      today.year,
    );
    if (date != null) ends.add(date);
  }
  if (ends.isEmpty) return false;
  return ends.every((d) => d.isBefore(todayDate));
}

bool _titleFitsLanguage(String text, String lang) {
  if (text.trim().isEmpty) return false;
  if (lang == 'ru') return _cyrillic.hasMatch(text) || !_hebrew.hasMatch(text);
  if (lang == 'en') return _latin.hasMatch(text) || !_hebrew.hasMatch(text);
  return true;
}

/// Home strip only. A Hebrew-only item is not the Russian (or English) story.
bool featuredOnHomeStrip(NewsArticle article, String lang, DateTime today) {
  if (!article.published) return false;
  if (newsEventDatesArePast(article, today)) return false;
  final shown = trLoc(article.title, lang);
  return _titleFitsLanguage(shown, lang);
}

List<NewsArticle> featuredHomeNews(
  Iterable<NewsArticle> news,
  String lang,
  DateTime today,
) =>
    [
      for (final a in news)
        if (featuredOnHomeStrip(a, lang, today)) a,
    ];
