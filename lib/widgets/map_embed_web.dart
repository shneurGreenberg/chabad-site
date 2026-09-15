import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class MapIFrame extends StatefulWidget {
  const MapIFrame({super.key, required this.url});
  final String url;

  @override
  State<MapIFrame> createState() => _MapIFrameState();
}

class _MapIFrameState extends State<MapIFrame> {
  web.HTMLIFrameElement? _iframe;

  @override
  void dispose() {
    final iframe = _iframe;
    _iframe = null;
    if (iframe != null) {
      iframe.src = 'about:blank';
      iframe.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: ValueKey(widget.url),
      tagName: 'div',
      onElementCreated: (element) {
        final div = element as web.HTMLDivElement;
        div.style
          ..position = 'relative'
          ..overflow = 'hidden'
          ..width = '100%'
          ..height = '100%'
          ..minHeight = '240px';
        final iframe = web.HTMLIFrameElement()
          ..src = widget.url
          ..allowFullscreen = true
          ..title = 'Map';
        iframe.style
          ..border = 'none'
          ..position = 'absolute'
          ..left = '0'
          ..top = '0'
          ..width = '100%'
          ..height = '100%';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        iframe.setAttribute(
          'allow',
          'geolocation; fullscreen; clipboard-write',
        );
        div.append(iframe);
        _iframe = iframe;
      },
    );
  }
}
