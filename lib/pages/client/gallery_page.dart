import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/public_content.dart';
import '../../data/repository.dart';
import '../../services/gallery_viewer_history.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';
import '../../widgets/playful_icons.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final years = <int>{for (final p in repo.publicGallery) p.year}.toList()
      ..sort((a, b) => b.compareTo(a));
    final albums = repo.publicGallery.where((p) {
      final yearOk = _year == null || p.year == _year;
      return yearOk;
    }).toList();

    return SiteScaffold(
      currentRoute: '/gallery',
      children: [
        PageHero(
          title: loc.t('nav.gallery'),
          subtitle: loc.t('gallery.subtitle'),
          icon: Icons.photo_library_outlined,
        ),
        Section(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text('${albums.length} ${loc.t('gallery.results')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              _yearFilter(loc, years),
            ],
          ),
        ),
        Section(
          padTop: 12,
          child: albums.isEmpty
              ? const EmptyHint(icon: Icons.photo_library_outlined)
              : ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final p in albums) PhotoCard(p),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _yearFilter(LocaleController loc, List<int> years) {
    return DropdownButton<int?>(
      value: _year,
      hint: Text(loc.t('gallery.year')),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(loc.t('common.all'))),
        for (final y in years)
          DropdownMenuItem<int?>(value: y, child: Text('$y')),
      ],
      onChanged: (v) => setState(() => _year = v),
    );
  }
}

class GalleryAlbumPage extends StatelessWidget {
  const GalleryAlbumPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final album = repo.galleryById(id);
    if (album == null || !galleryAlbumIsPublic(album)) {
      return SiteScaffold(
        currentRoute: '/gallery',
        children: [
          PageHero(
            title: loc.t('nav.gallery'),
            subtitle: loc.t('gallery.emptyAlbum'),
            icon: Icons.photo_library_outlined,
          ),
          Section(
            child: TextButton.icon(
              onPressed: () => context.go('/gallery'),
              icon: const PlayfulIcon(Icons.arrow_back),
              label: Text(loc.t('gallery.back')),
            ),
          ),
        ],
      );
    }

    final shots = album.displayPhotos;
    return SiteScaffold(
      currentRoute: '/gallery',
      children: [
        PageHero(
          title: trLoc(album.event, loc.lang),
          subtitle: '${album.year} · ${shots.length} ${loc.t('gallery.photos')}',
          icon: album.icon,
        ),
        Section(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/gallery'),
                icon: const PlayfulIcon(Icons.arrow_back),
                label: Text(loc.t('gallery.back')),
              ),
            ],
          ),
        ),
        Section(
          padTop: 8,
          child: shots.isEmpty
              ? EmptyHint(
                  icon: Icons.photo_outlined,
                  label: loc.t('gallery.emptyAlbum'),
                )
              : ResponsiveGrid(
                  columns: gridColumns(context, max: 4),
                  children: [
                    for (var i = 0; i < shots.length; i++)
                      _AlbumShotTile(
                        shot: shots[i],
                        onOpen: () => _openLightbox(context, shots, i),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _openLightbox(
      BuildContext context, List<GalleryShot> shots, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GalleryLightbox(shots: shots, initialIndex: index),
    );
  }
}

class _AlbumShotTile extends StatelessWidget {
  const _AlbumShotTile({required this.shot, required this.onOpen});
  final GalleryShot shot;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: ShotImage(shot),
            ),
          ),
        ),
      ),
    );
  }
}

class GalleryLightbox extends StatefulWidget {
  const GalleryLightbox({
    super.key,
    required this.shots,
    required this.initialIndex,
    this.history,
  });
  final List<GalleryShot> shots;
  final int initialIndex;

  /// Injected in tests. The browser build pushes a history entry itself.
  final GalleryViewerHistory? history;

  @override
  State<GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<GalleryLightbox> {
  late final _page = PageController(initialPage: widget.initialIndex);
  late final _thumbs = ScrollController();
  late int _index = widget.initialIndex;
  late final GalleryViewerHistory _history =
      widget.history ?? GalleryViewerHistory.platform();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _history.bindClose(_popViewer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closing) return;
      _history.open();
    });
  }

  @override
  void dispose() {
    _history.abandonIfStillOpen();
    _history.detach();
    _page.dispose();
    _thumbs.dispose();
    super.dispose();
  }

  void _popViewer() {
    if (_closing || !mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _closing = true;
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _requestClose() {
    final waitForPop = _history.closeFromUi();
    if (!waitForPop) _popViewer();
  }

  void _go(int index) {
    if (index < 0 || index >= widget.shots.length || index == _index) return;
    _page.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _revealThumb(int index) {
    if (!_thumbs.hasClients) return;
    const stride = 72.0;
    final target = index * stride - 3 * stride;
    final max = _thumbs.position.maxScrollExtent;
    _thumbs.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final many = widget.shots.length > 1;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(_index - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(_index + 1),
        const SingleActivator(LogicalKeyboardKey.escape): _requestClose,
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          onTap: _requestClose,
          child: Stack(
            children: [
              PageView.builder(
                controller: _page,
                itemCount: widget.shots.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _revealThumb(i));
                },
                itemBuilder: (context, i) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(72, 24, 72, 120),
                      child: GestureDetector(
                        onTap: () {},
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: ShotImage(widget.shots[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                },
              ),
              PositionedDirectional(
                top: 16,
                end: 16,
                child: IconButton(
                  key: const ValueKey('gallery-close'),
                  tooltip: loc.t('common.close'),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: _requestClose,
                  icon: const PlayfulIcon(Icons.close, color: Colors.white),
                ),
              ),
              if (many && _index > 0)
                PositionedDirectional(
                  start: 12,
                  top: 0,
                  bottom: 108,
                  child: Center(
                    child: _GalleryNavButton(
                      key: const ValueKey('gallery-prev'),
                      tooltip: loc.t('gallery.prev'),
                      icon: Icons.arrow_back,
                      onPressed: () => _go(_index - 1),
                    ),
                  ),
                ),
              if (many && _index < widget.shots.length - 1)
                PositionedDirectional(
                  end: 12,
                  top: 0,
                  bottom: 108,
                  child: Center(
                    child: _GalleryNavButton(
                      key: const ValueKey('gallery-next'),
                      tooltip: loc.t('gallery.next'),
                      icon: Icons.arrow_forward,
                      onPressed: () => _go(_index + 1),
                    ),
                  ),
                ),
              if (many)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_index + 1} / ${widget.shots.length}',
                          key: const ValueKey('gallery-counter'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            controller: _thumbs,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: widget.shots.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final selected = i == _index;
                              return GestureDetector(
                                key: ValueKey('gallery-thumb-$i'),
                                onTap: () => _go(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFE8D48A)
                                          : Colors.white24,
                                      width: selected ? 2.4 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: selected ? 1 : 0.72,
                                      child: ShotImage(widget.shots[i]),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  const _GalleryNavButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    );
  }
}
