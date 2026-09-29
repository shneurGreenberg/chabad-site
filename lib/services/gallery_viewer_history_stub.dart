class GalleryPopSubscription {
  void cancel() {}
}

void galleryHistoryPush() {}

void galleryHistoryBack() {}

const bool galleryHistoryBackEmitsPop = false;

GalleryPopSubscription listenGalleryPopState(void Function() onPop) {
  return GalleryPopSubscription();
}
