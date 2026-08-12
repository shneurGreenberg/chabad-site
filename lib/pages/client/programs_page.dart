import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/programs',
      children: [
        PageHero(
          title: loc.t('nav.programs'),
          subtitle: loc.t('programs.subtitle'),
          icon: Icons.groups_outlined,
        ),
        Section(
          child: ResponsiveGrid(
            columns: gridColumns(context, max: 3),
            children: [
              for (final p in repo.programs)
                HighlightAnchor(
                  id: p.id,
                  highlightId: highlightId,
                  child: ProgramCard(p),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
