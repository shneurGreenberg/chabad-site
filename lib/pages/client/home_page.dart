import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/',
      children: [
        const _Hero(),
        Section(
          child: ResponsiveGrid(
            columns: gridColumns(context, max: 4) < 2 ? 2 : gridColumns(context, max: 4),
            children: [
              StatCard(value: '480+', label: loc.t('home.stats.families'), icon: Icons.family_restroom, color: AppColors.primary),
              StatCard(value: '120', label: loc.t('home.stats.events'), icon: Icons.event, color: const Color(0xFFDB2777)),
              StatCard(value: '34', label: loc.t('home.stats.years'), icon: Icons.verified, color: const Color(0xFF0D9488)),
              StatCard(value: '5,200', label: loc.t('home.stats.meals'), icon: Icons.restaurant, color: const Color(0xFFF59E0B)),
            ],
          ),
        ),
        Section(child: _ZmanimStrip(repo: repo)),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(context, loc.t('home.news.title'), '/news'),
              const SizedBox(height: 18),
              ResponsiveGrid(
                columns: gridColumns(context, max: 3),
                children: [
                  for (final a in repo.news.take(3)) NewsCard(a),
                ],
              ),
            ],
          ),
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(context, loc.t('home.programs.title'), '/programs'),
              const SizedBox(height: 18),
              ResponsiveGrid(
                columns: gridColumns(context, max: 3),
                children: [
                  for (final p in repo.programs.take(3)) ProgramCard(p),
                ],
              ),
            ],
          ),
        ),
        const Section(child: _ReconnectBand()),
      ],
    );
  }

  Widget _headerRow(BuildContext context, String title, String route) {
    final loc = context.read<LocaleController>();
    return Row(
      children: [
        Expanded(child: SectionHeader(title: title)),
        TextButton(
          onPressed: () => context.go(route),
          child: Row(children: [
            Text(loc.t('common.viewAll')),
            const Icon(Icons.chevron_left, size: 18),
          ]),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      width: double.infinity,
      child: MaxWidthBox(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(loc.t('site.city'),
                color: AppColors.accent, icon: Icons.location_on),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                loc.t('site.name'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    height: 1.1,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                loc.t('site.tagline'),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 19,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/contact'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 18)),
                  icon: const Icon(Icons.group_add),
                  label: Text(loc.t('home.hero.cta')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/donate'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70, width: 1.4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 17)),
                  icon: const Icon(Icons.favorite_border),
                  label: Text(loc.t('home.hero.donate')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZmanimStrip extends StatelessWidget {
  const _ZmanimStrip({required this.repo});
  final AppRepository repo;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(loc.t('home.zmanim.title'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/zmanim'),
              child: Text(loc.t('common.viewAll')),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final z in repo.zmanim.take(5))
                _zmanChip(trLoc(z.name, loc.lang), z.time, AppColors.primary),
              _zmanChip(loc.t('zmanim.candle'), repo.shabbat['candle']!,
                  AppColors.accent,
                  icon: Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zmanChip(String name, String time, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Text(name, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(width: 10),
        Text(time,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
    );
  }
}

class _ReconnectBand extends StatelessWidget {
  const _ReconnectBand();
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.t('home.reach.title'),
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(loc.t('home.reach.body'),
                    style: const TextStyle(
                        color: AppColors.primaryDark, fontSize: 15, height: 1.5)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/contact'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
            icon: const Icon(Icons.connect_without_contact),
            label: Text(loc.t('home.hero.cta')),
          ),
        ],
      ),
    );
  }
}
