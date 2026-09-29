import 'package:flutter/material.dart';

import '../data/kaddish.dart';

/// Remote photo optimized for canvas rendering on web.
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
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Decode on one axis only. Setting both cacheWidth and cacheHeight uses
    // ResizeImagePolicy.exact, which squashes the bitmap into the frame and
    // looks smeared. The width matches the longer on-screen edge so a small
    // jpeg is not scaled up past the file.
    final cacheW = (width != null || height != null)
        ? sharpPhotoPixels(width ?? height!, height ?? width!, dpr)
        : null;

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      cacheWidth: cacheW,
      errorBuilder: (_, error, stackTrace) =>
          this.error ?? const SizedBox.shrink(),
    );
  }
}
