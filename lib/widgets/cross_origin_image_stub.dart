import 'package:flutter/material.dart';

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
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, error, stackTrace) =>
          this.error ?? const SizedBox.shrink(),
    );
  }
}
