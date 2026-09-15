import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class MapIFrame extends StatelessWidget {
  const MapIFrame({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: ValueKey(url),
      tagName: 'iframe',
      onElementCreated: (element) {
        final iframe = element as web.HTMLIFrameElement;
        iframe.src = url;
        iframe.allowFullscreen = true;
        iframe.title = 'Map';
        iframe.style
          ..border = 'none'
          ..width = '100%'
          ..height = '100%'
          ..display = 'block';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        iframe.setAttribute(
          'allow',
          'geolocation; fullscreen; clipboard-write',
        );
      },
    );
  }
}
