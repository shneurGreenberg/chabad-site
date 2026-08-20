import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../util/youtube.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';
import '../../widgets/youtube_embed.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/library',
      children: [
        PageHero(
          title: loc.t('nav.library'),
          subtitle: loc.t('library.subtitle'),
          icon: Icons.menu_book_outlined,
        ),
        Section(
          child: ResponsiveGrid(
            columns: gridColumns(context, max: 2),
            children: [
              for (final s in repo.shiurim)
                HighlightAnchor(
                  id: s.id,
                  highlightId: highlightId,
                  child: _ShiurCard(s),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiurCard extends StatelessWidget {
  const _ShiurCard(this.shiur);
  final Shiur shiur;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final id = youtubeIdFrom(shiur.youtubeUrl);
    return HoverLift(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _play(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (id != null)
                      Image.network(
                        youtubeThumbnail(id),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackThumb(),
                      )
                    else
                      _fallbackThumb(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          id == null
                              ? Icons.hourglass_empty
                              : Icons.play_arrow_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Pill(trLoc(shiur.topic, loc.lang),
                          color: AppColors.accent),
                    ),
                    if (id != null)
                      PositionedDirectional(
                        bottom: 10,
                        end: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xCC111827),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${shiur.durationMinutes} ${loc.t('library.minutes')}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trLoc(shiur.title, loc.lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trLoc(shiur.rabbi, loc.lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _play(context),
                      icon: Icon(
                        id == null
                            ? Icons.schedule
                            : Icons.play_circle_outline,
                        size: 18,
                      ),
                      label: Text(id == null
                          ? loc.t('library.comingSoon')
                          : loc.t('library.watch')),
                    ).hoverLift(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: const SizedBox.expand(),
    );
  }

  void _play(BuildContext context) {
    final loc = context.read<LocaleController>();
    final id = youtubeIdFrom(shiur.youtubeUrl);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: id == null
                    ? DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: AppColors.heroGradient),
                        child: const Center(
                          child: Icon(Icons.menu_book_outlined,
                              color: Colors.white, size: 64),
                        ),
                      )
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: YoutubeEmbed(videoId: id),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trLoc(shiur.title, loc.lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(trLoc(shiur.rabbi, loc.lang),
                        style: const TextStyle(color: Colors.black54)),
                    if (id == null) ...[
                      const SizedBox(height: 10),
                      Text(loc.t('library.noVideo'),
                          style: TextStyle(
                              color: AppColors.muted, height: 1.4)),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (id != null)
                          OutlinedButton.icon(
                            onPressed: () => openYoutubeWatch(id),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Text(loc.t('library.openYoutube')),
                          ).hoverLift(),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(loc.t('common.close')),
                        ).hoverLift(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
