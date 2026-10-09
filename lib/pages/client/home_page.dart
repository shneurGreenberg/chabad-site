import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/public_content.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/newsletter.dart';
import '../../widgets/playful_icons.dart';
import '../../tenant/tenant_runtime.dart';
import '../../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final homeNews =
        featuredHomeNews(repo.news, loc.lang, DateTime.now()).take(6).toList();
    final homeStats = TenantRuntime.instance.config.homeStats;
    return SiteScaffold(
      currentRoute: '/',
      children: [
        const _Hero(),
        if (homeNews.isNotEmpty)
          Section(
            padTop: 12,
            padBottom: 0,
            child: HomeNewsTicker(articles: homeNews),
          ),
        if (homeStats.isNotEmpty)
          Section(
            padTop: 24,
            padBottom: 0,
            child: ResponsiveGrid(
              columns: gridColumns(context, max: 4) < 2
                  ? 2
                  : gridColumns(context, max: 4),
              children: [
                for (final stat in homeStats)
                  StatCard(
                    value: stat.value,
                    label: trLoc(stat.label, loc.lang),
                    icon: stat.icon,
                    color: stat.color,
                  ),
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
        if (repo.publicPrograms.isNotEmpty)
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(context, loc.t('home.programs.title'), '/programs'),
                const SizedBox(height: 18),
                ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final p in repo.publicPrograms.take(3)) ProgramCard(p),
                  ],
                ),
              ],
            ),
          ),
        const Section(child: _ReconnectBand()),
        const Section(
          padTop: 8,
          child: _HomeNewsletter(),
        ),
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
          icon: const PlayfulIcon(Icons.arrow_forward, size: 18),
          label: Text(loc.t('common.viewAll')),
        ).hoverLift(),
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

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(copyOf(context, repo.siteCopy.city, 'site.city'),
            color: AppColors.accentSoft, icon: Icons.location_on),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            copyOf(context, repo.siteCopy.name, 'site.name'),
            style: TextStyle(
                color: Colors.white,
                fontSize: wide ? 52 : 40,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 14)]),
          ),
        ),
        if (trLoc(repo.siteCopy.tagline, loc.lang).isNotEmpty) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              trLoc(repo.siteCopy.tagline, loc.lang),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 19,
                  height: 1.55,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 10)
                  ]),
            ),
          ),
        ],
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
              icon: const PlayfulIcon(Icons.group_add),
              label: Text(loc.t('home.hero.cta')),
            ).hoverLift(),
            OutlinedButton.icon(
              onPressed: () => context.go('/donate'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 1.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 17)),
              icon: const PlayfulIcon(Icons.favorite_border, color: Colors.white),
              label: Text(loc.t('home.hero.donate')),
            ).hoverLift(),
          ],
        ),
      ],
    );

    final register = const HomeRegisterBanner();

    final banner = repo.bannerFor('/');
    return Container(
      decoration: banner.hasMedia
          ? BoxDecoration(color: AppColors.primaryDark)
          : BoxDecoration(gradient: AppColors.heroGradient),
      width: double.infinity,
      child: Stack(
        children: [
          BannerFill(banner: banner),
          if (!banner.hasMedia) ...[
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
                      const SizedBox(width: 28),
                      Expanded(flex: 5, child: register),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 28),
                      register,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class HomeRegisterBanner extends StatelessWidget {
  const HomeRegisterBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('home-register-banner'),
        onTap: () => context.go('/contact'),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                PlayfulIcon(Icons.group_add, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.t('home.register.title'),
                    style: const TextStyle(
                      color: Color(0xFF0B1C3A),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.15,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                loc.t('home.register.body'),
                style: const TextStyle(
                  color: Color(0xFF0B1C3A),
                  fontSize: 16.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go('/contact'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                icon: const PlayfulIcon(Icons.app_registration, size: 18),
                label: Text(loc.t('home.register.cta')),
              ).hoverLift(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact latest-news strip. One item is visible; the next slides in from the side.
const homeNewsInterval = Duration(seconds: 5);

class HomeNewsTicker extends StatefulWidget {
  const HomeNewsTicker({
    super.key,
    required this.articles,
    this.interval = homeNewsInterval,
  });
  final List<NewsArticle> articles;
  final Duration interval;

  @override
  State<HomeNewsTicker> createState() => _HomeNewsTickerState();
}

class _HomeNewsTickerState extends State<HomeNewsTicker> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant HomeNewsTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.articles.length) _index = 0;
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    if (widget.articles.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.articles.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final articles = widget.articles;
    if (articles.isEmpty) return const SizedBox.shrink();
    final loc = context.locWatch;
    final i = _index.clamp(0, articles.length - 1);
    final article = articles[i];
    final fromSide = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        key: const ValueKey('home-news-ticker'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/news/${article.id}'),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PlayfulIcon(Icons.article_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == ValueKey('home-news-${article.id}');
                      final begin = incoming ? Offset(fromSide, 0) : Offset(-fromSide, 0);
                      return SlideTransition(
                        position: Tween<Offset>(begin: begin, end: Offset.zero)
                            .animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Align(
                      key: ValueKey('home-news-${article.id}'),
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          linkIfSectionHeading(
                            context,
                            loc.t('home.news.title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            trLoc(article.title, loc.lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/news'),
                child: Text(loc.t('common.viewAll')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreTile {
  const _ExploreTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    this.body,
    this.tileKey,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final String? body;
  final Key? tileKey;
}

/// One cube per main-menu page, plus donate and the kaddish screen.
class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final items = <_ExploreTile>[
      for (final nav in [...primaryNav, ...moreNav])
        if (nav.route != '/')
          _ExploreTile(
            icon: nav.icon,
            label: loc.t(nav.labelKey),
            route: nav.route,
            color: _exploreColor(nav.route),
            tileKey: switch (nav.route) {
              '/cemetery' => const ValueKey('home-cemetery-tile'),
              '/tourist' => const ValueKey('home-tourist-tile'),
              _ => null,
            },
          ),
      _ExploreTile(
        icon: Icons.favorite_outline,
        label: loc.t('nav.donate'),
        route: '/donate',
        color: AppColors.accent,
      ),
      _ExploreTile(
        icon: Icons.tv_outlined,
        label: loc.t('home.kaddish.title'),
        route: '/cemetery',
        color: const Color(0xFF312E81),
        body: loc.t('home.kaddish.body'),
        tileKey: const ValueKey('home-kaddish-tile'),
      ),
    ];
    return ResponsiveGrid(
      columns: () {
        final w = MediaQuery.sizeOf(context).width;
        if (w < 620) return 2;
        if (w < 1100) return 3;
        return 6;
      }(),
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items) _ExploreTileCard(item: item),
      ],
    );
  }
}

class _ExploreTileCard extends StatelessWidget {
  const _ExploreTileCard({required this.item});
  final _ExploreTile item;

  @override
  Widget build(BuildContext context) {
    final body = item.body;
    return HoverLift(
      child: InkWell(
        key: item.tileKey,
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: PlayfulIcon(item.icon, color: item.color),
              ),
              const SizedBox(height: 10),
              Text(item.label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              if (body != null && body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color _exploreColor(String route) {
  return switch (route) {
    '/news' => const Color(0xFF0369A1),
    '/zmanim' => const Color(0xFF1D4ED8),
    '/programs' => const Color(0xFF0F766E),
    '/gallery' => const Color(0xFF7C3AED),
    '/store' => const Color(0xFFC2410C),
    '/events' => const Color(0xFFB45309),
    '/cemetery' => const Color(0xFF334155),
    '/famous' => const Color(0xFFCA8A04),
    '/history' => const Color(0xFF1E3A5F),
    '/library' => const Color(0xFF0E7490),
    '/tourist' => const Color(0xFF047857),
    '/about' => const Color(0xFF475569),
    _ => AppColors.primary,
  };
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
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(loc.t('home.reach.body'),
                    style: TextStyle(
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
            icon: const PlayfulIcon(Icons.connect_without_contact),
            label: Text(loc.t('home.hero.cta')),
          ).hoverLift(),
        ],
      ),
    );
  }
}

class _HomeNewsletter extends StatelessWidget {
  const _HomeNewsletter();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: const NewsletterSignup(),
    );
  }
}
