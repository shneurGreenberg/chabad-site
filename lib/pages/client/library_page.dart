import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

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
    return Card(
      child: InkWell(
        onTap: () => _play(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(trLoc(shiur.topic, loc.lang), color: AppColors.accent),
                    const SizedBox(height: 8),
                    Text(trLoc(shiur.title, loc.lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(trLoc(shiur.rabbi, loc.lang),
                              style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text('${shiur.durationMinutes} ${loc.t('library.minutes')}',
                              style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _play(context),
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: Text(loc.t('library.watch')),
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

  void _play(BuildContext context) {
    final loc = context.read<LocaleController>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: const Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 72),
                  ),
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
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(loc.t('common.close')),
                      ),
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
