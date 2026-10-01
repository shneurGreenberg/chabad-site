import 'l10n/strings.dart';

/// Headings whose text is the name of a real page, in every language.
///
/// The home section titles ("תוכניות הקהילה" and the news, events, and times
/// headings) are included along with the menu labels themselves.
const sectionHeadingRoutes = <String, String>{
  'home.programs.title': '/programs',
  'home.news.title': '/news',
  'home.events.title': '/events',
  'home.zmanim.title': '/zmanim',
  'nav.home': '/',
  'nav.news': '/news',
  'nav.zmanim': '/zmanim',
  'nav.programs': '/programs',
  'nav.gallery': '/gallery',
  'nav.store': '/store',
  'nav.events': '/events',
  'nav.cemetery': '/cemetery',
  'nav.famous': '/famous',
  'nav.history': '/history',
  'nav.library': '/library',
  'nav.tourist': '/tourist',
  'nav.about': '/about',
  'nav.donate': '/donate',
  'nav.contact': '/contact',
};

/// Route opened by [heading] when that text names a page, otherwise null.
String? sectionHeadingRoute(String heading) {
  final needle = _norm(heading);
  if (needle.isEmpty) return null;
  for (final entry in sectionHeadingRoutes.entries) {
    for (final lang in supportedLangs) {
      if (_norm(uiText(entry.key, lang)) == needle) return entry.value;
    }
  }
  return null;
}

String _norm(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
