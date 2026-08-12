import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
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
            (_category == 'all' || trLoc(a.category, loc.lang) == _category))
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
                  children: [for (final a in items) NewsCard(a)],
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
    );
  }
}
