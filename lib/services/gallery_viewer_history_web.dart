import 'dart:js_interop';

import 'package:web/web.dart' as web;

class GalleryPopSubscription {
  GalleryPopSubscription(this._handler);
  final JSFunction _handler;

  void cancel() {
    web.window.removeEventListener('popstate', _handler);
  }
}

void galleryHistoryPush() {
  web.window.history.pushState(
    {'galleryViewer': true}.jsify(),
    '',
    web.window.location.href,
  );
}

void galleryHistoryBack() {
  web.window.history.back();
}

const bool galleryHistoryBackEmitsPop = true;

GalleryPopSubscription listenGalleryPopState(void Function() onPop) {
  void handler(web.Event _) => onPop();
  final js = handler.toJS;
  web.window.addEventListener('popstate', js);
  return GalleryPopSubscription(js);
}
