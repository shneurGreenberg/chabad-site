import 'package:flutter/material.dart';

import '../theme.dart';

class YoutubeIFrame extends StatelessWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Center(
        child: Icon(Icons.play_circle_fill,
            color: AppColors.accent.withValues(alpha: 0.9), size: 64),
      ),
    );
  }
}

void openYoutubeWatch(String videoId) {}
