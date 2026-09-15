import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../util/youtube.dart';

class YoutubeIFrame extends StatefulWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  State<YoutubeIFrame> createState() => YoutubeIFrameState();
}

/// Public state so dialogs can await teardown before Navigator.pop (Flutter web
/// leaves a transparent iframe overlay that freezes the site if popped too early).
class YoutubeIFrameState extends State<YoutubeIFrame> {
  web.HTMLDivElement? _host;
  web.HTMLIFrameElement? _iframe;
  bool _tornDown = false;

  Future<void> teardown() async {
    if (_tornDown) return;
    _tornDown = true;
    final iframe = _iframe;
    final host = _host;
    _iframe = null;
    _host = null;
    try {
      if (iframe != null) {
        iframe.style.pointerEvents = 'none';
        iframe.style.display = 'none';
        iframe.src = 'about:blank';
        iframe.remove();
      }
      if (host != null) {
        host.style.pointerEvents = 'none';
        host.replaceChildren();
      }
    } catch (_) {}
    // Let the browser drop the plugin surface before Flutter removes the view.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  void dispose() {
    unawaited(teardown());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tornDown) {
      return const ColoredBox(color: Color(0xFF111827));
    }
    final url = youtubeEmbedUrl(widget.videoId);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: HtmlElementView.fromTagName(
        key: ValueKey('yt_$url'),
        tagName: 'div',
        onElementCreated: (element) {
          if (_tornDown) return;
          final div = element as web.HTMLDivElement;
          _host = div;
          div.style
            ..position = 'relative'
            ..overflow = 'hidden'
            ..width = '100%'
            ..height = '100%'
            ..pointerEvents = 'auto';
          final iframe = web.HTMLIFrameElement()
            ..src = url
            ..allowFullscreen = true
            ..title = 'YouTube';
          iframe.style
            ..border = 'none'
            ..position = 'absolute'
            ..left = '0'
            ..top = '0'
            ..width = '100%'
            ..height = '100%';
          iframe.setAttribute('loading', 'lazy');
          iframe.setAttribute(
            'allow',
            'accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; web-share',
          );
          iframe.setAttribute(
            'referrerpolicy',
            'strict-origin-when-cross-origin',
          );
          div.append(iframe);
          _iframe = iframe;
        },
      ),
    );
  }
}

void openYoutubeWatch(String videoId) {
  web.window.open(youtubeWatchUrl(videoId), '_blank');
}
