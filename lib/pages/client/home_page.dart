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
          padTop: 24,
          padBottom: 0,
          child: ResponsiveGrid(
              columns: gridColumns(context, max: 4) < 2
                  ? 2
                  : gridColumns(context, max: 4),
              children: [
                StatCard(
                    value: '480+',
                    label: loc.t('home.stats.families'),
                    icon: Icons.family_restroom,
                    color: AppColors.primary),
                StatCard(
                    value: '120',
                    label: loc.t('home.stats.events'),
                    icon: Icons.event,
                    color: const Color(0xFFC2410C)),
                StatCard(
                    value: '34',
                    label: loc.t('home.stats.years'),
                    icon: Icons.verified,
                    color: const Color(0xFF0F766E)),
                StatCard(
                    value: '5,200',
                    label: loc.t('home.stats.meals'),
                    icon: Icons.restaurant,
                    color: AppColors.accent),
              ],
            ),
        ),
        Section(
          padTop: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: loc.t('home.explore')),
              const SizedBox(height: 18),
              const _QuickLinks(),
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
        TextButton.icon(
          onPressed: () => context.go(route),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(loc.t('common.viewAll')),
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
    final repo = context.watch<AppRepository>();
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final parasha = switch (loc.lang) {
      'he' => repo.shabbat['parasha_he']!,
      'ru' => repo.shabbat['parasha_ru']!,
      _ => repo.shabbat['parasha_en']!,
    };

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(loc.t('site.city'), color: AppColors.accentSoft, icon: Icons.location_on),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            loc.t('site.name'),
            style: TextStyle(
                color: Colors.white,
                fontSize: wide ? 52 : 40,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 14)]),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            loc.t('site.tagline'),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 19,
                height: 1.55,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 10)]),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/contact'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
              icon: const Icon(Icons.group_add),
              label: Text(loc.t('home.hero.cta')),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/donate'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 1.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 17)),
              icon: const Icon(Icons.favorite_border),
              label: Text(loc.t('home.hero.donate')),
            ),
          ],
        ),
      ],
    );

    final shabbatCard = _ShabbatCard(
      parasha: parasha,
      candle: repo.shabbat['candle']!,
      havdala: repo.shabbat['havdala']!,
    );

    final banner = repo.bannerFor('/');
    return Container(
      decoration: banner.hasImage
          ? const BoxDecoration(color: AppColors.primaryDark)
          : const BoxDecoration(gradient: AppColors.heroGradient),
      width: double.infinity,
      child: Stack(
        children: [
          BannerFill(banner: banner),
          if (!banner.hasImage) ...[
          PositionedDirectional(
            end: -80,
            top: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.16), width: 28),
              ),
            ),
          ),
          PositionedDirectional(
            start: 40,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          ],
          MaxWidthBox(
            padding: EdgeInsets.fromLTRB(20, wide ? 72 : 48, 20, 72),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: copy),
                      const SizedBox(width: 40),
                      Expanded(flex: 4, child: shabbatCard),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 28),
                      shabbatCard,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShabbatCard extends StatelessWidget {
  const _ShabbatCard({
    required this.parasha,
    required this.candle,
    required this.havdala,
  });
  final String parasha;
  final String candle;
  final String havdala;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xF20B1C3A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.local_fire_department, color: AppColors.accentSoft),
                const SizedBox(width: 8),
                Text(loc.t('zmanim.shabbat'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ]),
              const SizedBox(height: 8),
              Text(parasha,
                  style: TextStyle(
                      color: AppColors.accentSoft.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5)),
              const SizedBox(height: 18),
              _row(loc.t('zmanim.candle'), candle),
              const SizedBox(height: 10),
              _row(loc.t('zmanim.havdala'), havdala),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/zmanim'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(loc.t('home.zmanim.title')),
                ),
              ),
            ],
          ),
    );
  }

  Widget _row(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        ),
        Text(time,
            style: const TextStyle(
                color: AppColors.accentSoft,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
      ]),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final items = [
      (Icons.schedule, loc.t('nav.zmanim'), '/zmanim', const Color(0xFF1D4ED8)),
      (Icons.groups_outlined, loc.t('nav.programs'), '/programs', const Color(0xFF0F766E)),
      (Icons.photo_library_outlined, loc.t('nav.gallery'), '/gallery', const Color(0xFF7C3AED)),
      (Icons.storefront_outlined, loc.t('nav.store'), '/store', const Color(0xFFC2410C)),
      (Icons.menu_book_outlined, loc.t('nav.library'), '/library', const Color(0xFF0E7490)),
      (Icons.favorite_outline, loc.t('nav.donate'), '/donate', AppColors.accent),
    ];
    return ResponsiveGrid(
      columns: gridColumns(context, max: 6).clamp(2, 6),
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          InkWell(
            onTap: () => context.go(item.$3),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$1, color: item.$4),
                  ),
                  const SizedBox(height: 10),
                  Text(item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                ],
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule, color: AppColors.primary),
              ),
              Text(loc.t('home.zmanim.title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 20)),
              Pill(
                '${loc.t('zmanim.forCity')} ${repo.location.cityName}',
                icon: Icons.place_outlined,
              ),
              TextButton.icon(
                onPressed: () => context.go('/zmanim'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(loc.t('common.viewAll')),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Text(name, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.t('home.reach.title'),
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(loc.t('home.reach.body'),
                    style: const TextStyle(
                        color: AppColors.primaryDark, fontSize: 15.5, height: 1.55)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/contact'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
            icon: const Icon(Icons.connect_without_contact),
            label: Text(loc.t('home.hero.cta')),
          ),
        ],
      ),
    );
  }
}
