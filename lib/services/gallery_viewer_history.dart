import 'gallery_viewer_history_stub.dart'
    if (dart.library.js_interop) 'gallery_viewer_history_web.dart';

/// Browser-back policy for the gallery image viewer.
///
/// Opening the viewer pushes one history entry at the current URL. Back
/// then pops only that entry and closes the viewer, so the gallery page
/// underneath stays put. Closing from the UI calls [historyBack] once and
/// ignores the resulting pop so the site does not navigate further.
class GalleryViewerHistory {
  GalleryViewerHistory({
    required this.pushState,
    required this.historyBack,
    this.backEmitsPop = false,
  });

  factory GalleryViewerHistory.platform() => GalleryViewerHistory(
        pushState: galleryHistoryPush,
        historyBack: galleryHistoryBack,
        backEmitsPop: galleryHistoryBackEmitsPop,
      );

  final void Function() pushState;
  final void Function() historyBack;

  /// True when [historyBack] will emit a popstate the page can observe.
  final bool backEmitsPop;

  bool viewerOpen = false;
  bool _entryPushed = false;
  bool _ignoreNextPop = false;
  void Function()? _closeViewer;
  GalleryPopSubscription? _pops;

  void bindClose(void Function() close) {
    _closeViewer = close;
    _pops ??= listenGalleryPopState(onPopState);
  }

  void detach() {
    _pops?.cancel();
    _pops = null;
  }

  void open() {
    if (_entryPushed || _ignoreNextPop) return;
    viewerOpen = true;
    _entryPushed = true;
    pushState();
  }

  /// Handles a browser popstate.
  ///
  /// Returns true when the event only closes the viewer. Returns false when
  /// the viewer is not open, so the site may follow the history entry.
  bool onPopState() {
    if (_ignoreNextPop) {
      _ignoreNextPop = false;
      viewerOpen = false;
      _entryPushed = false;
      _closeViewer?.call();
      return true;
    }
    if (viewerOpen) {
      viewerOpen = false;
      _entryPushed = false;
      _closeViewer?.call();
      return true;
    }
    return false;
  }

  /// Close button, Escape, or backdrop.
  ///
  /// Returns true when the dialog should stay until the matching popstate
  /// closes it. Returns false when the caller should pop the dialog now
  /// (tests and platforms that do not emit popstate).
  bool closeFromUi() {
    if (viewerOpen && _entryPushed && backEmitsPop) {
      _ignoreNextPop = true;
      viewerOpen = false;
      _entryPushed = false;
      historyBack();
      return true;
    }
    viewerOpen = false;
    _entryPushed = false;
    return false;
  }

  /// Drop a history entry if the viewer is removed without a UI close.
  void abandonIfStillOpen() {
    if (!_entryPushed) return;
    _ignoreNextPop = true;
    viewerOpen = false;
    _entryPushed = false;
    if (backEmitsPop) historyBack();
  }
}
