import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../util/youtube.dart';

class YoutubeIFrame extends StatelessWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  Widget build(BuildContext context) {
    final url = youtubeEmbedUrl(videoId);
    return HtmlElementView.fromTagName(
      key: ValueKey(url),
      tagName: 'iframe',
      onElementCreated: (element) {
        final iframe = element as web.HTMLIFrameElement;
        iframe.src = url;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('allowfullscreen', 'true');
        iframe.setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; '
          'gyroscope; picture-in-picture; web-share',
        );
        iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
        iframe.title = 'YouTube';
      },
    );
  }
}

void openYoutubeWatch(String videoId) {
  web.window.open(youtubeWatchUrl(videoId), '_blank');
}
