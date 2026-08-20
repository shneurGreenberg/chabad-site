import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class CrossOriginImageView extends StatelessWidget {
  const CrossOriginImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView.fromTagName(
        key: ValueKey(url),
        tagName: 'img',
        onElementCreated: (element) {
          final img = element as web.HTMLImageElement;
          img.src = url;
          img.alt = '';
          img.referrerPolicy = 'no-referrer';
          img.style.border = 'none';
          img.style.width = '100%';
          img.style.height = '100%';
          img.style.objectFit = switch (fit) {
            BoxFit.contain => 'contain',
            BoxFit.fill => 'fill',
            BoxFit.fitWidth => 'contain',
            BoxFit.fitHeight => 'contain',
            BoxFit.none => 'none',
            BoxFit.scaleDown => 'scale-down',
            _ => 'cover',
          };
          img.style.objectPosition = 'center';
          img.style.display = 'block';
        },
      ),
    );
  }
}
