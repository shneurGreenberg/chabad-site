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
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        iframe.setAttribute('allowfullscreen', 'true');
        iframe.setAttribute(
          'allow',
          'geolocation; fullscreen; clipboard-write',
        );
      },
    );
  }
}
