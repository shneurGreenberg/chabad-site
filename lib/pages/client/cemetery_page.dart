import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../services/web_prefs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/cross_origin_image.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class CemeteryPage extends StatefulWidget {
  const CemeteryPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  State<CemeteryPage> createState() => _CemeteryPageState();
}

class _CemeteryPageState extends State<CemeteryPage> {
  String _query = '';

  static const _kaddishUrl =
      'https://synagogue-kadish-shneur.amvera.io/s/novosibirsk';

  bool _matches(Grave g, String q, String raw, String lang) {
    if (widget.highlightId != null && g.id == widget.highlightId) return true;
    if (q.isEmpty) return true;
    return g.name.toLowerCase().contains(q) ||
        g.name.contains(raw) ||
        g.hebrewName.toLowerCase().contains(q) ||
        g.hebrewName.contains(raw) ||
        g.deathLabel.contains(raw) ||
        trLoc(g.notes, lang).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final raw = _query.trim();
    final q = raw.toLowerCase();
    final graves = repo.graves.where((g) => _matches(g, q, raw, loc.lang)).toList();

    return SiteScaffold(
      currentRoute: '/cemetery',
      children: [
        PageHero(
          title: loc.t('nav.cemetery'),
          subtitle: loc.t('cemetery.subtitle'),
          icon: Icons.grid_view_outlined,
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => openUrl(_kaddishUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(loc.t('cemetery.source')),
              ).hoverLift(),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.t('cemetery.search'),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        Section(
          padTop: 16,
          child: graves.isEmpty
              ? const EmptyHint(icon: Icons.search_off)
              : ResponsiveGrid(
                  columns: gridColumns(context, max: 2),
                  children: [
                    for (final g in graves)
                      HighlightAnchor(
                        id: g.id,
                        highlightId: widget.highlightId,
                        child: _GraveCard(g),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GraveCard extends StatelessWidget {
  const _GraveCard(this.grave);
  final Grave grave;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final title = grave.hebrewName.isNotEmpty ? grave.hebrewName : grave.name;
    final subtitle = grave.hebrewName.isNotEmpty ? grave.name : '';
    final notes = trLoc(grave.notes, loc.lang);
    final death = grave.deathLabel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GravePhoto(url: grave.photoUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(notes,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (grave.birthYear != null)
                      Pill(
                          '${loc.t('cemetery.born')} ${grave.birthYear}',
                          color: const Color(0xFF0D9488)),
                    if (death.isNotEmpty)
                      Pill('${loc.t('cemetery.passed')} $death',
                          color: const Color(0xFF64748B)),
                    if (grave.section.isNotEmpty || grave.row.isNotEmpty)
                      Pill(
                          [
                            if (grave.section.isNotEmpty)
                              '${loc.t('cemetery.section')} ${grave.section}',
                            if (grave.row.isNotEmpty)
                              '${loc.t('cemetery.row')} ${grave.row}',
                          ].join(' · '),
                          color: AppColors.primary,
                          icon: Icons.place_outlined),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GravePhoto extends StatelessWidget {
  const _GravePhoto({this.url});
  final String? url;

  Widget _fallback() => Container(
        width: 72,
        height: 96,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64748B), Color(0xFF334155)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.star, color: Colors.white54, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    if (src.isEmpty) return _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CrossOriginImage(
        url: src,
        width: 72,
        height: 96,
        fit: BoxFit.cover,
        error: _fallback(),
      ),
    );
  }
}
