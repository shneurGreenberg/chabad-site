import 'package:flutter/material.dart';

import 'youtube_embed_stub.dart'
    if (dart.library.js_interop) 'youtube_embed_web.dart' as impl;

class YoutubeEmbed extends StatelessWidget {
  const YoutubeEmbed({super.key, required this.videoId});
  final String videoId;

  @override
  Widget build(BuildContext context) => impl.YoutubeIFrame(videoId: videoId);
}

void openYoutubeWatch(String videoId) => impl.openYoutubeWatch(videoId);
