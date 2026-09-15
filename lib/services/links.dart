String digitsPhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// Unicode LTR isolate so phone digits keep visual order inside RTL (Hebrew) text.
String isolateLtr(String raw) => '\u2066$raw\u2069';

String? telUrl(String raw) {
  final d = digitsPhone(raw);
  if (d.length < 7) return null;
  return 'tel:+$d';
}

String? waMeUrl(String raw) {
  var d = digitsPhone(raw);
  if (d.length < 10) return null;
  if (d.startsWith('8') && d.length == 11) d = '7${d.substring(1)}';
  return 'https://wa.me/$d';
}

String? mailtoUrl({
  required String email,
  String subject = '',
  String body = '',
}) {
  final to = email.trim();
  if (to.isEmpty || !to.contains('@')) return null;
  final q = <String>[
    if (subject.trim().isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
    if (body.trim().isNotEmpty) 'body=${Uri.encodeComponent(body)}',
  ];
  return 'mailto:$to${q.isEmpty ? '' : '?${q.join('&')}'}';
}

final emailPattern = RegExp(
  r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}',
  caseSensitive: false,
);

/// International / local phone numbers, including +7 (383) 222-20-23.
final phonePattern = RegExp(
  r'(?:\+|00)?\d[\d\s().\-]{6,}\d',
);

class ContactMatch {
  const ContactMatch({
    required this.start,
    required this.end,
    required this.text,
    required this.url,
    required this.isEmail,
  });
  final int start;
  final int end;
  final String text;
  final String url;
  final bool isEmail;
}

/// Emails and phone numbers in [text], left-to-right, no overlaps.
List<ContactMatch> findContactMatches(String text) {
  final out = <ContactMatch>[];
  void add(ContactMatch m) {
    if (m.start < 0 || m.end > text.length || m.start >= m.end) return;
    if (out.any((e) => m.start < e.end && m.end > e.start)) return;
    out.add(m);
  }

  for (final m in emailPattern.allMatches(text)) {
    final raw = m.group(0)!;
    final url = mailtoUrl(email: raw);
    if (url == null) continue;
    add(ContactMatch(
      start: m.start,
      end: m.end,
      text: raw,
      url: url,
      isEmail: true,
    ));
  }
  for (final m in phonePattern.allMatches(text)) {
    final raw = m.group(0)!;
    if (raw.contains('@')) continue;
    final url = telUrl(raw);
    if (url == null) continue;
    add(ContactMatch(
      start: m.start,
      end: m.end,
      text: raw.trim(),
      url: url,
      isEmail: false,
    ));
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

/// True when [text] looks like a single email (not a sentence).
bool looksLikeEmail(String text) {
  final t = text.trim();
  return emailPattern.hasMatch(t) && !t.contains(' ') && t.contains('@');
}
