import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class CemeteryPage extends StatefulWidget {
  const CemeteryPage({super.key});
  @override
  State<CemeteryPage> createState() => _CemeteryPageState();
}

class _CemeteryPageState extends State<CemeteryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final q = _query.trim().toLowerCase();
    final graves = repo.graves.where((g) {
      if (q.isEmpty) return true;
      return g.name.toLowerCase().contains(q) ||
          g.hebrewName.contains(_query.trim()) ||
          trLoc(g.notes, loc.lang).toLowerCase().contains(q);
    }).toList();

    return SiteScaffold(
      currentRoute: '/cemetery',
      children: [
        PageHero(
          title: loc.t('nav.cemetery'),
          subtitle: loc.t('cemetery.subtitle'),
          icon: Icons.grid_view_outlined,
        ),
        Section(
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: loc.t('cemetery.search'),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Section(
          padTop: 16,
          child: ResponsiveGrid(
            columns: gridColumns(context, max: 2),
            children: [for (final g in graves) _GraveCard(g)],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF64748B), Color(0xFF334155)],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28), bottom: Radius.circular(6)),
              ),
              child: const Icon(Icons.star, color: Colors.white54, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grave.hebrewName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(grave.name,
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(trLoc(grave.notes, loc.lang),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Pill(
                        '${loc.t('cemetery.born')} ${grave.birthYear ?? '—'}',
                        color: const Color(0xFF0D9488)),
                    Pill('${loc.t('cemetery.passed')} ${grave.deathYear}',
                        color: const Color(0xFF64748B)),
                    Pill('${loc.t('cemetery.section')} ${grave.section} · ${loc.t('cemetery.row')} ${grave.row}',
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
