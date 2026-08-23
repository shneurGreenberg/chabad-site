String digitsPhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

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
