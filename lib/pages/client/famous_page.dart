import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class FamousPage extends StatefulWidget {
  const FamousPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  State<FamousPage> createState() => _FamousPageState();
}

class _FamousPageState extends State<FamousPage> {
  Era? _era;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final people = repo.famous
        .where((p) =>
            (widget.highlightId != null && p.id == widget.highlightId) ||
            _era == null ||
            p.era == _era)
        .toList();
    return SiteScaffold(
      currentRoute: '/famous',
      children: [
        PageHero(
          title: loc.t('nav.famous'),
          subtitle: loc.t('famous.subtitle'),
          icon: Icons.star_outline,
        ),
        Section(
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(loc.t('common.all')),
                selected: _era == null,
                onSelected: (_) => setState(() => _era = null),
              ),
              ChoiceChip(
                label: Text(loc.t('famous.present')),
                selected: _era == Era.present,
                onSelected: (_) => setState(() => _era = Era.present),
              ),
              ChoiceChip(
                label: Text(loc.t('famous.past')),
                selected: _era == Era.past,
                onSelected: (_) => setState(() => _era = Era.past),
              ),
            ],
          ),
        ),
        Section(
          padTop: 16,
          child: people.isEmpty
              ? const EmptyHint(icon: Icons.star_outline)
              : ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final p in people)
                      HighlightAnchor(
                        id: p.id,
                        highlightId: widget.highlightId,
                        child: PersonCard(p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
