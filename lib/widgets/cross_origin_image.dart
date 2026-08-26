import 'package:flutter/material.dart';

/// Remote photo that still shows when the host does not send CORS headers.
class CrossOriginImage extends StatelessWidget {
  const CrossOriginImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    // HtmlElementView coordinates break under RTL; keep the overlay LTR.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, error, stackTrace) =>
            this.error ?? const SizedBox.shrink(),
      ),
    );
  }
}
