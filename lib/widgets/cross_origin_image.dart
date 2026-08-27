import 'package:flutter/material.dart';

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
    final cacheW = width != null ? (width! * dpr * 2).round() : null;
    final cacheH = height != null ? (height! * dpr * 2).round() : null;
    
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      errorBuilder: (_, error, stackTrace) =>
          this.error ?? const SizedBox.shrink(),
    );
  }
}
