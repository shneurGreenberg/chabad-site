import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final categories = <String>{
      for (final a in repo.news) trLoc(a.category, loc.lang)
    }.toList();
    final items = repo.news
        .where((a) =>
            a.published &&
            (widget.highlightId == a.id ||
                _category == 'all' ||
                trLoc(a.category, loc.lang) == _category))
        .toList();
    return SiteScaffold(
      currentRoute: '/news',
      children: [
        PageHero(
          title: loc.t('nav.news'),
          subtitle: loc.t('home.news.title'),
          icon: Icons.article_outlined,
        ),
        Section(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(loc.t('common.all'), 'all'),
              for (final c in categories) _chip(c, c),
            ],
          ),
        ),
        Section(
          padTop: 8,
          child: items.isEmpty
              ? const EmptyHint(icon: Icons.article_outlined)
              : ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final a in items)
                      HighlightAnchor(
                        id: a.id,
                        highlightId: widget.highlightId,
                        child: NewsCard(a),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _category == value;
    return HoverScale(
      child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
    ),
    );
  }
}

class NewsArticlePage extends StatelessWidget {
  const NewsArticlePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final article = repo.newsById(id);
    if (article == null) {
      return SiteScaffold(
        currentRoute: '/news',
        children: [
          PageHero(
            title: loc.t('nav.news'),
            subtitle: loc.t('common.empty'),
            icon: Icons.article_outlined,
          ),
          Section(
            child: TextButton.icon(
              onPressed: () => context.go('/news'),
              icon: const Icon(Icons.arrow_back),
              label: Text(loc.t('nav.news')),
            ),
          ),
        ],
      );
    }
    return SiteScaffold(
      currentRoute: '/news',
      children: [
        GradientImage(
          color: article.imageColor,
          icon: article.icon,
          height: 280,
          bytes: article.imageBytes,
          url: article.imageUrl,
          badge: article.source == NewsSource.telegram
              ? const Pill('Telegram',
                  color: Color(0xFF0EA5E9), icon: Icons.send)
              : null,
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/news'),
                icon: const Icon(Icons.arrow_back),
                label: Text(loc.t('nav.news')),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pill(trLoc(article.category, loc.lang),
                      color: AppColors.accent),
                  Text(fmtDate(context, article.date),
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              Text(trLoc(article.title, loc.lang),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 16),
              Text(trLoc(article.body, loc.lang),
                  style: TextStyle(
                      color: AppColors.ink, height: 1.6, fontSize: 16.5)),
            ],
          ),
        ),
      ],
    );
  }
}
