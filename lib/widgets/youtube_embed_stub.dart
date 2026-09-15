import 'package:flutter/material.dart';

import '../theme.dart';
import 'playful_icons.dart';

class YoutubeIFrame extends StatefulWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  State<YoutubeIFrame> createState() => YoutubeIFrameState();
}

class YoutubeIFrameState extends State<YoutubeIFrame> {
  Future<void> teardown() async {}

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Center(
        child: PlayfulIcon(
          Icons.play_circle_fill,
          color: AppColors.accent.withValues(alpha: 0.9),
          size: 64,
        ),
      ),
    );
  }
}

void openYoutubeWatch(String videoId) {}
