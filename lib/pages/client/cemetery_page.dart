import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/kaddish.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../services/web_prefs.dart';
import '../../services/yahrzeit.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/cross_origin_image.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';
import '../../widgets/playful_icons.dart';

class CemeteryPage extends StatefulWidget {
  const CemeteryPage({super.key, this.highlightId});
  final String? highlightId;
  @override
  State<CemeteryPage> createState() => _CemeteryPageState();
}

class _CemeteryPageState extends State<CemeteryPage> {
  String _query = '';
  bool _upcomingOnly = false;

  static const _kaddishUrl =
      'https://synagogue-kadish-shneur.amvera.io/s/novosibirsk';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppRepository>().refreshKaddishGraves();
    });
  }

  bool _matches(Grave g, String q, String raw, String lang) {
    if (widget.highlightId != null && g.id == widget.highlightId) return true;
    if (q.isEmpty) return true;
    return g.name.toLowerCase().contains(q) ||
        g.name.contains(raw) ||
        g.hebrewName.toLowerCase().contains(q) ||
        g.hebrewName.contains(raw) ||
        g.deathLabel.contains(raw) ||
        g.hebrewDeathLabel.toLowerCase().contains(q) ||
        g.hebrewDeathLabel.contains(raw) ||
        trLoc(g.notes, lang).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final raw = _query.trim();
    final q = raw.toLowerCase();
    var graves = repo.graves.where((g) => _matches(g, q, raw, loc.lang)).toList();
    if (_upcomingOnly) {
      final soon = upcomingYahrzeits(graves, withinDays: 45)
          .map((y) => y.grave.id)
          .toSet();
      graves = graves.where((g) => soon.contains(g.id)).toList();
    }

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
                icon: const PlayfulIcon(Icons.open_in_new, size: 18),
                label: Text(loc.t('cemetery.source')),
              ).hoverLift(),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const PlayfulIcon(Icons.search),
                  hintText: loc.t('cemetery.search'),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              FilterChip(
                selected: _upcomingOnly,
                label: Text(loc.t('cemetery.upcoming')),
                onSelected: (v) => setState(() => _upcomingOnly = v),
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
                  // Note: GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())
                  // would still build all cells to measure extent (not virtualized).
                  // ResponsiveGrid is simpler. Real perf win is removing HtmlElementView.
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
      child: InkWell(
        onTap: () => context.go('/cemetery/${grave.id}'),
        borderRadius: BorderRadius.circular(12),
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
                    if (grave.hebrewDeathLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(grave.hebrewDeathLabel,
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ],
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
        child: const PlayfulIcon(Icons.star, color: Colors.white54, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    if (src.isEmpty) return _fallback();
    
    final localUrl = resolveKaddishPhotoUrl(src);
    if (localUrl.isEmpty) return _fallback();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CrossOriginImage(
        url: localUrl,
        width: 72,
        height: 96,
        fit: BoxFit.cover,
        error: _fallback(),
      ),
    );
  }
}

/// Cemetery person detail page showing biography and full information.
class CemeteryPersonPage extends StatefulWidget {
  const CemeteryPersonPage({super.key, required this.id});
  final String id;

  @override
  State<CemeteryPersonPage> createState() => _CemeteryPersonPageState();
}

class _CemeteryPersonPageState extends State<CemeteryPersonPage> {
  Grave? _person;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  Future<void> _loadPerson() async {
    if (!mounted) return;
    final repo = context.read<AppRepository>();
    final person = await repo.fetchPersonDetail(widget.id);
    if (!mounted) return;
    setState(() {
      _person = person;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;

    if (_loading) {
      return SiteScaffold(
        currentRoute: '/cemetery',
        children: [
          const PageHero(
            title: '',
            subtitle: '',
            icon: Icons.hourglass_empty,
          ),
          Section(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      );
    }

    if (_person == null) {
      return SiteScaffold(
        currentRoute: '/cemetery',
        children: [
          PageHero(
            title: loc.t('nav.cemetery'),
            subtitle: loc.t('common.empty'),
            icon: Icons.person_outline,
          ),
          Section(
            child: TextButton.icon(
              onPressed: () => context.go('/cemetery'),
              icon: const PlayfulIcon(Icons.arrow_back),
              label: Text(loc.t('nav.cemetery')),
            ),
          ),
        ],
      );
    }

    final title = _person!.hebrewName.isNotEmpty
        ? _person!.hebrewName
        : _person!.name;
    final subtitle =
        _person!.hebrewName.isNotEmpty ? _person!.name : '';
    final death = _person!.deathLabel;

    return SiteScaffold(
      currentRoute: '/cemetery',
      children: [
        Section(
          padTop: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/cemetery'),
                icon: const PlayfulIcon(Icons.arrow_back),
                label: Text(loc.t('nav.cemetery')),
              ).hoverLift(),
              const SizedBox(height: 24),
              // Photo and name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_person!.photoUrl != null &&
                      _person!.photoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CrossOriginImage(
                        url: _person!.photoUrl!,
                        width: 160,
                        height: 210,
                        fit: BoxFit.cover,
                        error: _photoFallback(160, 210),
                      ),
                    )
                  else
                    _photoFallback(160, 210),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Death dates
                        if (_person!.hebrewDeathLabel.isNotEmpty) ...[
                          _infoRow(
                            Icons.calendar_today,
                            _person!.hebrewDeathLabel,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (death.isNotEmpty)
                          _infoRow(
                            Icons.event,
                            death,
                          ),
                        const SizedBox(height: 8),
                        // Birth year
                        if (_person!.birthYear != null)
                          _infoRow(
                            Icons.cake_outlined,
                            '${loc.t('cemetery.born')} ${_person!.birthYear}',
                          ),
                        // Location
                        if (_person!.section.isNotEmpty ||
                            _person!.row.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.place_outlined,
                            [
                              if (_person!.section.isNotEmpty)
                                '${loc.t('cemetery.section')} ${_person!.section}',
                              if (_person!.row.isNotEmpty)
                                '${loc.t('cemetery.row')} ${_person!.row}',
                            ].join(' · '),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Biography
              if (_person!.biographyHtml != null &&
                  _person!.biographyHtml!.trim().isNotEmpty) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Html(
                  data: _person!.biographyHtml!,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(16.5),
                      lineHeight: const LineHeight(1.6),
                      color: AppColors.ink,
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 12),
                    ),
                    'h1, h2, h3, h4, h5, h6': Style(
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(top: 16, bottom: 8),
                    ),
                  },
                  // Disable script execution and sanitize
                  onLinkTap: (url, attributes, element) {
                    if (url != null && url.isNotEmpty) {
                      openUrl(url);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64748B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const PlayfulIcon(Icons.star, color: Colors.white54, size: 40),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        PlayfulIcon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
