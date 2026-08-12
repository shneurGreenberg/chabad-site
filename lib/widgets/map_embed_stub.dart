import 'package:flutter/material.dart';

import '../theme.dart';

class MapIFrame extends StatelessWidget {
  const MapIFrame({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFDCE7F5),
      child: Center(
        child: Icon(Icons.map_outlined, color: AppColors.primary.withValues(alpha: 0.45), size: 48),
      ),
    );
  }
}
