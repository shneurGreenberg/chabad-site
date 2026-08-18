import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
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

class ProgramDetailPage extends StatelessWidget {
  const ProgramDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final program = repo.programById(id);
    if (program == null) {
      return SiteScaffold(
        currentRoute: '/programs',
        children: [
          PageHero(
            title: loc.t('nav.programs'),
            subtitle: loc.t('common.empty'),
            icon: Icons.groups_outlined,
          ),
          Section(
            child: TextButton.icon(
              onPressed: () => context.go('/programs'),
              icon: const Icon(Icons.arrow_back),
              label: Text(loc.t('nav.programs')),
            ),
          ),
        ],
      );
    }
    final color = Color(program.color);
    return SiteScaffold(
      currentRoute: '/programs',
      children: [
        GradientImage(
          color: program.color,
          icon: program.icon,
          height: 280,
          bytes: program.imageBytes,
          url: program.imageUrl,
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/programs'),
                icon: const Icon(Icons.arrow_back),
                label: Text(loc.t('nav.programs')),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(program.icon, color: color, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(trLoc(program.title, loc.lang),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 18),
              Text(trLoc(program.description, loc.lang),
                  style: TextStyle(
                      color: AppColors.ink, height: 1.55, fontSize: 16)),
              const SizedBox(height: 18),
              _meta(Icons.schedule, loc.t('programs.schedule'),
                  trLoc(program.schedule, loc.lang)),
              const SizedBox(height: 8),
              _meta(Icons.people_outline, loc.t('programs.audience'),
                  trLoc(program.audience, loc.lang)),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/contact?p=${program.id}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                icon: const Icon(Icons.how_to_reg, size: 20),
                label: Text(loc.t('programs.register')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
