import 'package:flutter/material.dart';

/// Remote photo that still shows when the host does not send CORS headers.
///
/// Uses native HTML <img> elements (via webHtmlElementStrategy.prefer) which
/// can display cross-origin images without CORS headers. CORS is only required
/// when reading pixel data (e.g. canvas); browsers allow <img> display without it.
///
/// Uses Stack + Positioned.fill to fix HtmlElementView RTL positioning bug where
/// platform views are positioned off-screen to the right in RTL contexts.
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
    // Stack with fallback as base and image overlay fixes RTL positioning.
    // Positioned.fill forces the HtmlElementView to fill the Stack's box
    // rather than using global screen coordinates.
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Show error widget as base layer (fallback if image fails)
          if (error != null) error!,
          // Overlay the actual image with explicit LTR + Positioned.fill
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Image.network(
                url,
                fit: fit,
                alignment: alignment,
                filterQuality: FilterQuality.medium,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, err, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
