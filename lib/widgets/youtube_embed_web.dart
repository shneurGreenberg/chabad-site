import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../util/youtube.dart';

class YoutubeIFrame extends StatefulWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  State<YoutubeIFrame> createState() => _YoutubeIFrameState();
}

class _YoutubeIFrameState extends State<YoutubeIFrame> {
  web.HTMLIFrameElement? _iframe;

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  void _teardown() {
    final iframe = _iframe;
    _iframe = null;
    if (iframe != null) {
      iframe.src = 'about:blank';
      iframe.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = youtubeEmbedUrl(widget.videoId);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: HtmlElementView.fromTagName(
        key: ValueKey(url),
        tagName: 'div',
        onElementCreated: (element) {
          final div = element as web.HTMLDivElement;
          div.style
            ..position = 'relative'
            ..overflow = 'hidden'
            ..width = '100%'
            ..height = '100%';
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
