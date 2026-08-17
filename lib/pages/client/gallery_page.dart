import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String? _face;
  int? _year;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final years = <int>{for (final p in repo.gallery) p.year}.toList()
      ..sort((a, b) => b.compareTo(a));
    final albums = repo.gallery.where((p) {
      final faceOk = _face == null || p.tags.contains(_face);
      final yearOk = _year == null || p.year == _year;
      return faceOk && yearOk;
    }).toList();

    return SiteScaffold(
      currentRoute: '/gallery',
      children: [
        PageHero(
          title: loc.t('nav.gallery'),
          subtitle: loc.t('gallery.subtitle'),
          icon: Icons.photo_library_outlined,
        ),
        Section(child: _faceSearch(context, repo, loc)),
        Section(
          padTop: 20,
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
                    for (final p in albums) PhotoCard(p, highlightFace: _face),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _faceSearch(
      BuildContext context, AppRepository repo, LocaleController loc) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('gallery.faceSearch'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(loc.t('gallery.faceSearch.hint'),
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final face in repo.faces) _faceAvatar(face, _face == face),
              if (_face != null)
                ActionChip(
                  avatar: const Icon(Icons.clear, size: 16),
                  label: Text(loc.t('common.all')),
                  onPressed: () => setState(() => _face = null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faceAvatar(String name, bool selected) {
    final color = selected ? AppColors.accent : AppColors.primary;
    return HoverScale(
      child: InkWell(
        onTap: () => setState(() => _face = selected ? null : name),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: color.withValues(alpha: selected ? 0.6 : 0.15)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.face, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(name,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 6),
          ]),
        ),
      ),
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
    if (album == null) {
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
              icon: const Icon(Icons.arrow_back),
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
                icon: const Icon(Icons.arrow_back),
                label: Text(loc.t('gallery.back')),
              ),
              if (album.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in album.tags)
                      Pill(tag, icon: Icons.face, color: AppColors.primary),
                  ],
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
      builder: (ctx) => _AlbumLightbox(shots: shots, initialIndex: index),
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

class _AlbumLightbox extends StatefulWidget {
  const _AlbumLightbox({required this.shots, required this.initialIndex});
  final List<GalleryShot> shots;
  final int initialIndex;

  @override
  State<_AlbumLightbox> createState() => _AlbumLightboxState();
}

class _AlbumLightboxState extends State<_AlbumLightbox> {
  late final _page = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: widget.shots.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          if (widget.shots.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / ${widget.shots.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
