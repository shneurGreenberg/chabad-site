import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../util/youtube.dart';

class YoutubeIFrame extends StatefulWidget {
  const YoutubeIFrame({super.key, required this.videoId});
  final String videoId;

  @override
  State<YoutubeIFrame> createState() => YoutubeIFrameState();
}

/// Public state so dialogs can await teardown before Navigator.pop.
///
/// Flutter web [HtmlElementView] inside an RTL (`dir=rtl`) CanvasKit tree
/// applies a CSS matrix that can paint the YouTube iframe (and nearby UI)
/// rotated 90°. The player is therefore a `position:fixed` overlay on
/// `document.body`, sized from the placeholder's screen rect — no platform
/// view transform, no accelerometer/gyroscope orientation hints.
class YoutubeIFrameState extends State<YoutubeIFrame> {
  final GlobalKey _slotKey = GlobalKey();
  web.HTMLIFrameElement? _iframe;
  Timer? _sync;
  bool _tornDown = false;

  Future<void> teardown() async {
    if (_tornDown) return;
    _tornDown = true;
    _sync?.cancel();
    _sync = null;
    final iframe = _iframe;
    _iframe = null;
    try {
      if (iframe != null) {
        iframe.style.pointerEvents = 'none';
        iframe.style.display = 'none';
        iframe.src = 'about:blank';
        iframe.remove();
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tornDown) _mountOverlay();
    });
  }

  @override
  void didUpdateWidget(covariant YoutubeIFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId && !_tornDown) {
      unawaited(_retarget());
    }
  }

  Future<void> _retarget() async {
    final iframe = _iframe;
    if (iframe == null) {
      _mountOverlay();
      return;
    }
    iframe.src = youtubeEmbedUrl(widget.videoId);
  }

  @override
  void dispose() {
    unawaited(teardown());
    super.dispose();
  }

  void _mountOverlay() {
    if (_tornDown || _iframe != null) return;
    final url = youtubeEmbedUrl(widget.videoId);
    final iframe = web.HTMLIFrameElement()
      ..src = url
      ..allowFullscreen = true
      ..title = 'YouTube';
    iframe.dir = 'ltr';
    iframe.setAttribute('loading', 'eager');
    iframe.setAttribute(
      'allow',
      'autoplay; clipboard-write; encrypted-media; '
      'picture-in-picture; web-share; fullscreen',
    );
    iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
    iframe.setAttribute('allowfullscreen', 'true');
    iframe.style
      ..position = 'fixed'
      ..border = 'none'
      ..margin = '0'
      ..padding = '0'
      ..zIndex = '2147483646'
      ..pointerEvents = 'auto'
      ..backgroundColor = '#111827';
    iframe.style.setProperty('transform', 'none');
    iframe.style.setProperty('transform-origin', '0 0');
    iframe.style.setProperty('writing-mode', 'horizontal-tb');
    iframe.style.setProperty('direction', 'ltr');
    web.document.body?.append(iframe);
    _iframe = iframe;
    _positionOverlay();
    _sync = Timer.periodic(const Duration(milliseconds: 32), (_) {
      _positionOverlay();
    });
  }

  void _positionOverlay() {
    final iframe = _iframe;
    if (iframe == null || _tornDown) return;
    final ctx = _slotKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width < 2 || size.height < 2) {
      iframe.style.display = 'none';
      return;
    }
    iframe.style
      ..display = 'block'
      ..left = '${origin.dx.toStringAsFixed(1)}px'
      ..top = '${origin.dy.toStringAsFixed(1)}px'
      ..width = '${size.width.toStringAsFixed(1)}px'
      ..height = '${size.height.toStringAsFixed(1)}px';
  }

  @override
  Widget build(BuildContext context) {
    if (_tornDown) {
      return const ColoredBox(color: Color(0xFF111827));
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF111827),
        child: KeyedSubtree(
          key: _slotKey,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

void openYoutubeWatch(String videoId) {
  web.window.open(youtubeWatchUrl(videoId), '_blank');
}
