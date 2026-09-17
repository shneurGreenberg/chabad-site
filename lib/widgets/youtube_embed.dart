import 'youtube_embed_stub.dart'
    if (dart.library.js_interop) 'youtube_embed_web.dart' as impl;

export 'youtube_embed_stub.dart'
    if (dart.library.js_interop) 'youtube_embed_web.dart'
    show YoutubeIFrame, YoutubeIFrameState;

import 'package:flutter/material.dart';

class YoutubeEmbed extends StatelessWidget {
  const YoutubeEmbed({
    super.key,
    this.playerKey,
    required this.videoId,
  });

  /// Key for [YoutubeIFrameState.teardown] — must not use [key] (that stays on this wrapper).
  final GlobalKey<impl.YoutubeIFrameState>? playerKey;
  final String videoId;

  @override
  Widget build(BuildContext context) =>
      impl.YoutubeIFrame(key: playerKey, videoId: videoId);
}

void openYoutubeWatch(String videoId) => impl.openYoutubeWatch(videoId);
