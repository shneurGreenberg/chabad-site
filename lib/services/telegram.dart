import 'dart:convert';
import 'dart:typed_data';

import 'cors_proxy.dart';
import 'persist.dart';
import 'web_prefs.dart';

const _tokenKey = 'chabad_tg_bot_token';
const _channelKey = 'chabad_tg_channel';
const _offsetKey = 'chabad_tg_update_offset';
const _nameKey = 'chabad_tg_bot_name';
const _userKey = 'chabad_tg_bot_user';

class TelegramException implements Exception {
  TelegramException(this.messageKey, {this.detail});
  final String messageKey;
  final String? detail;
}

class TelegramBotInfo {
  TelegramBotInfo({required this.name, this.username, this.chatTitle});
  final String name;
  final String? username;
  final String? chatTitle;
}

class TelegramPost {
  TelegramPost({
    required this.messageId,
    required this.text,
    required this.date,
    this.imageBytes,
  });
  final int messageId;
  final String text;
  final DateTime date;
  final Uint8List? imageBytes;
}

class TelegramService {
  TelegramService._();
  static final TelegramService instance = TelegramService._();

  String _token = '';
  String _channel = '';
  int _offset = 0;
  String _botName = '';
  String _botUser = '';

  String get channel => _channel;
  bool get hasToken => _token.trim().isNotEmpty;
  bool get isConnected => hasToken && _channel.isNotEmpty;
  String get botName => _botName;
  String get botUsername => _botUser;

  /// Token is never exposed in logs; UI may show a masked hint only.
  String get maskedToken {
    final t = _token.trim();
    if (t.length < 8) return t.isEmpty ? '' : '••••';
    return '${t.substring(0, 6)}…';
  }

  void loadSaved() {
    final token = (readPref(_tokenKey) ?? '').trim();
    if (token.isNotEmpty) _token = token;
    final channel = (readPref(_channelKey) ?? '').trim();
    if (channel.isNotEmpty) _channel = channel;
    final offset = int.tryParse(readPref(_offsetKey) ?? '');
    if (offset != null) _offset = offset;
    final name = (readPref(_nameKey) ?? '').trim();
    if (name.isNotEmpty) _botName = name;
    final user = (readPref(_userKey) ?? '').trim();
    if (user.isNotEmpty) _botUser = user;
  }

  Future<void> loadSavedAsync() async {
    loadSaved();
    try {
      final token = (await persistGet(_tokenKey))?.trim() ?? '';
      if (token.isNotEmpty) _token = token;
      final channel = (await persistGet(_channelKey))?.trim() ?? '';
      if (channel.isNotEmpty) _channel = channel;
      final offset = int.tryParse((await persistGet(_offsetKey)) ?? '');
      if (offset != null) _offset = offset;
      final name = (await persistGet(_nameKey))?.trim() ?? '';
      if (name.isNotEmpty) _botName = name;
      final user = (await persistGet(_userKey))?.trim() ?? '';
      if (user.isNotEmpty) _botUser = user;
    } catch (_) {}
    if (_token.isNotEmpty || _channel.isNotEmpty) {
      await _persistCreds();
    }
  }

  void save({required String token, required String channel}) {
    _token = token.trim();
    _channel = normalizeChannel(channel);
    writePref(_tokenKey, _token);
    writePref(_channelKey, _channel);
    Future<void>.microtask(_persistCreds);
  }

  Future<void> _persistCreds() async {
    try {
      await persistPut(_tokenKey, _token);
      await persistPut(_channelKey, _channel);
      await persistPut(_offsetKey, '$_offset');
      await persistPut(_nameKey, _botName);
      await persistPut(_userKey, _botUser);
    } catch (_) {}
  }

  static String normalizeChannel(String raw) {
    var s = raw.trim();
    s = s.replaceFirst(RegExp(r'^https?://t\.me/s/'), '');
    s = s.replaceFirst(RegExp(r'^https?://t\.me/'), '');
    if (s.startsWith('@')) s = s.substring(1);
    s = s.split(RegExp(r'[/?#]')).first;
    return s;
  }

  static String escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  Future<TelegramBotInfo> connect({
    String token = '',
    required String channel,
  }) async {
    final next = token.trim().isEmpty ? _token : token.trim();
    save(token: next, channel: channel);
    if (_token.isEmpty) {
      throw TelegramException('admin.tg.err.token');
    }
    if (_channel.isEmpty) {
      throw TelegramException('admin.tg.err.channel');
    }

    await _clearWebhook();
    final me = await _api('getMe');
    _throwIfNotOk(me, 'admin.tg.err.token');
    final result = me['result'] as Map<String, dynamic>? ?? {};
    final name = (result['first_name'] as String?)?.trim() ?? 'Bot';
    final username = result['username'] as String?;
    _botName = name;
    _botUser = username ?? '';
    writePref(_nameKey, _botName);
    writePref(_userKey, _botUser);
    await _persistCreds();

    String? chatTitle;
    try {
      final chat = await _api('getChat', {'chat_id': '@$_channel'});
      if (chat['ok'] == true) {
        final cr = chat['result'] as Map<String, dynamic>? ?? {};
        chatTitle = (cr['title'] as String?) ?? _channel;
      }
    } catch (_) {}

    return TelegramBotInfo(name: name, username: username, chatTitle: chatTitle);
  }

  Future<List<TelegramPost>> pullPosts() async {
    if (_token.isEmpty || _channel.isEmpty) {
      throw TelegramException('admin.tg.err.token');
    }
    await _clearWebhook();

    try {
      final fromUpdates = await _fromGetUpdates();
      if (fromUpdates.isNotEmpty) return fromUpdates;
    } on TelegramException {
      rethrow;
    }

    Object? previewErr;
    for (final url in [
      'https://t.me/s/$_channel',
      'https://r.jina.ai/https://t.me/s/$_channel',
    ]) {
      try {
        final res = await CorsProxy.getDirectOrProxy(url);
        final posts = await _parsePreviewWithImages(res.body);
        if (posts.isNotEmpty) return posts;
      } catch (e) {
        previewErr = e;
      }
    }
    if (previewErr != null) {
      throw TelegramException(
        'admin.tg.err.pull',
        detail: CorsProxy.redact('$previewErr'),
      );
    }
    return const [];
  }

  Future<int> publishToChannel({
    required String text,
    String? photoUrl,
  }) async {
    if (_token.isEmpty || _channel.isEmpty) {
      throw TelegramException('admin.tg.err.token');
    }
    await _clearWebhook();
    final photo = photoUrl?.trim() ?? '';
    final usePhoto = photo.startsWith('http://') || photo.startsWith('https://');
    final json = usePhoto
        ? await _api('sendPhoto', {
            'chat_id': '@$_channel',
            'photo': photo,
            'caption': _clip(text, 1024),
            'parse_mode': 'HTML',
          })
        : await _api('sendMessage', {
            'chat_id': '@$_channel',
            'text': _clip(text, 4000),
            'parse_mode': 'HTML',
            'disable_web_page_preview': 'false',
          });
    _throwIfNotOk(json, 'admin.tg.err.publish');
    final result = json['result'];
    if (result is Map) {
      return (result['message_id'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> _clearWebhook() async {
    try {
      await _api('deleteWebhook');
    } catch (_) {}
  }

  Future<List<TelegramPost>> _fromGetUpdates() async {
    final params = <String, String>{
      'timeout': '0',
      'limit': '100',
      'allowed_updates': jsonEncode(['channel_post', 'message']),
    };
    if (_offset > 0) params['offset'] = '${_offset + 1}';

    final json = await _api('getUpdates', params);
    _throwIfNotOk(json, 'admin.tg.err.pull');
    final list = json['result'] as List? ?? const [];
    final posts = <TelegramPost>[];
    var maxId = _offset;
    for (final raw in list) {
      if (raw is! Map) continue;
      final updateId = (raw['update_id'] as num?)?.toInt() ?? 0;
      if (updateId > maxId) maxId = updateId;
      final post = raw['channel_post'] ?? raw['message'];
      if (post is! Map) continue;
      final parsed = await _parseApiMessage(Map<String, dynamic>.from(post));
      if (parsed != null) posts.add(parsed);
    }
    if (maxId > _offset) {
      _offset = maxId;
      writePref(_offsetKey, '$_offset');
    }
    return posts;
  }

  Future<TelegramPost?> _parseApiMessage(Map<String, dynamic> msg) async {
    final chat = msg['chat'];
    if (chat is Map) {
      final uname = (chat['username'] as String?)?.toLowerCase();
      if (uname != null && uname != _channel.toLowerCase()) return null;
    }
    final id = (msg['message_id'] as num?)?.toInt();
    if (id == null) return null;
    final text = ((msg['text'] ?? msg['caption']) as String?)?.trim() ?? '';
    final dateUnix = (msg['date'] as num?)?.toInt();
    final date = dateUnix == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000);

    Uint8List? image;
    final photos = msg['photo'];
    if (photos is List && photos.isNotEmpty) {
      Map<String, dynamic>? best;
      var bestW = 0;
      for (final p in photos) {
        if (p is! Map) continue;
        final w = (p['width'] as num?)?.toInt() ?? 0;
        if (w >= bestW) {
          bestW = w;
          best = Map<String, dynamic>.from(p);
        }
      }
      final fileId = best?['file_id'] as String?;
      if (fileId != null) {
        image = await _downloadFile(fileId);
      }
    }
    if (text.isEmpty && image == null) return null;
    return TelegramPost(
      messageId: id,
      text: text,
      date: date,
      imageBytes: image,
    );
  }

  Future<Uint8List?> _downloadFile(String fileId) async {
    try {
      final json = await _api('getFile', {'file_id': fileId});
      if (json['ok'] != true) return null;
      final path = (json['result'] as Map?)?['file_path'] as String?;
      if (path == null || path.isEmpty) return null;
      final fileUrl = 'https://api.telegram.org/file/bot$_token/$path';
      final res = await CorsProxy.getDirectOrProxy(fileUrl);
      final bytes = res.bodyBytes;
      if (bytes.length < 40) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<List<TelegramPost>> _parsePreviewWithImages(String html) async {
    final idRe = RegExp(
        r'(?:https://t\.me/|t\.me/)' +
            RegExp.escape(_channel) +
            r'/(\d+)',
        caseSensitive: false);
    final blocks = html.contains('tgme_widget_message')
        ? html.split('class="tgme_widget_message ')
        : html.split('\n');
    final posts = <TelegramPost>[];
    if (html.contains('tgme_widget_message')) {
      for (final block in blocks.skip(1)) {
        final idMatch = idRe.firstMatch(block);
        if (idMatch == null) continue;
        final id = int.tryParse(idMatch.group(1) ?? '');
        if (id == null) continue;
        if (posts.any((p) => p.messageId == id)) continue;

        String text = '';
        final textMatch = RegExp(
          r'tgme_widget_message_text[^>]*>([\s\S]*?)</div>',
          caseSensitive: false,
        ).firstMatch(block);
        if (textMatch != null) {
          text = _stripHtml(textMatch.group(1) ?? '');
        }

        Uint8List? image;
        final bg = RegExp(
          r'''background-image:url\(['"]([^'"]+)['"]\)''',
          caseSensitive: false,
        ).firstMatch(block);
        final photoUrl = bg?.group(1);
        if (photoUrl != null && photoUrl.startsWith('http')) {
          try {
            final img = await CorsProxy.getDirectOrProxy(photoUrl);
            if (img.bodyBytes.length > 80) image = img.bodyBytes;
          } catch (_) {}
        }
        if (text.isEmpty && image == null) continue;
        posts.add(TelegramPost(
          messageId: id,
          text: text,
          date: DateTime.now(),
          imageBytes: image,
        ));
        if (posts.length >= 12) break;
      }
    } else {
      for (final m in idRe.allMatches(html)) {
        final id = int.tryParse(m.group(1) ?? '');
        if (id == null || posts.any((p) => p.messageId == id)) continue;
        posts.add(TelegramPost(
          messageId: id,
          text: '',
          date: DateTime.now(),
        ));
        if (posts.length >= 12) break;
      }
    }
    return posts.reversed.toList();
  }

  Future<Map<String, dynamic>> _api(
    String method, [
    Map<String, String>? query,
  ]) async {
    final url = 'https://api.telegram.org/bot$_token/$method';
    try {
      final res = (query == null || query.isEmpty)
          ? await CorsProxy.getDirectOrProxy(url)
          : await CorsProxy.postForm(url, query);
      final body = res.body.trim();
      if (body.startsWith('<')) {
        throw TelegramException('admin.tg.err.proxy');
      }
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) return json;
      throw TelegramException('admin.tg.err.generic');
    } on TelegramException {
      rethrow;
    } on CorsProxyException {
      throw TelegramException('admin.tg.err.proxy');
    } catch (e) {
      final msg = CorsProxy.redact('$e');
      if (msg.contains('XMLHttpRequest') ||
          msg.contains('Failed to fetch') ||
          msg.contains('CORS')) {
        throw TelegramException('admin.tg.err.proxy');
      }
      throw TelegramException('admin.tg.err.generic', detail: msg);
    }
  }

  void _throwIfNotOk(Map<String, dynamic> json, String fallbackKey) {
    if (json['ok'] == true) return;
    final desc = '${json['description'] ?? ''}'.trim();
    throw TelegramException(fallbackKey, detail: desc.isEmpty ? null : desc);
  }

  static String _clip(String s, int max) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }

  static String _stripHtml(String raw) {
    var s = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
