/// Parse a YouTube watch / share / embed URL (or a bare 11-character id).
String? youtubeIdFrom(String? raw) {
  if (raw == null) return null;
  final u = raw.trim();
  if (u.isEmpty) return null;
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(u)) return u;
  final patterns = [
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
    RegExp(r'[?&]v=([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube-nocookie\.com/embed/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/live/([A-Za-z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(u);
    if (m != null) return m.group(1);
  }
  return null;
}

String youtubeThumbnail(String id) =>
    'https://img.youtube.com/vi/$id/hqdefault.jpg';

String youtubeWatchUrl(String id) => 'https://www.youtube.com/watch?v=$id';

String youtubeEmbedUrl(String id) =>
    'https://www.youtube-nocookie.com/embed/$id?rel=0&modestbranding=1';
