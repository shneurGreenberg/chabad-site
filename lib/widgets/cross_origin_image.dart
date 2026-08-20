import 'package:flutter/material.dart';

import 'cross_origin_image_stub.dart'
    if (dart.library.js_interop) 'cross_origin_image_web.dart' as impl;

/// Displays a remote photo even when the host does not send CORS headers.
class CrossOriginImage extends StatelessWidget {
  const CrossOriginImage({
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
  Widget build(BuildContext context) => impl.CrossOriginImageView(
        url: url,
        width: width,
        height: height,
        fit: fit,
        error: error,
      );
}
