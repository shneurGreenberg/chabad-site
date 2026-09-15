import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../services/links.dart';
import '../../services/web_prefs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/map_embed.dart';
import '../../widgets/site_scaffold.dart';
import '../../widgets/playful_icons.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/about',
      children: [
        PageHero(
          title: loc.t('nav.about'),
          subtitle: copyOf(context, repo.siteCopy.aboutSubtitle, 'about.subtitle'),
          icon: Icons.info_outline,
        ),
        Section(
          child: _card(
            icon: Icons.synagogue,
            title: loc.t('about.story'),
            child: Text(copyOf(context, repo.siteCopy.aboutBody, 'about.story.body'),
                style: const TextStyle(height: 1.55, fontSize: 15.5)),
          ),
        ),
        Section(
          child: LayoutBuilder(builder: (context, c) {
            final info = _infoCards(context, repo, loc);
            final map = _map(context, repo, loc);
            if (c.maxWidth < 860) {
              return Column(children: [info, const SizedBox(height: 20), map]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: info),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: map),
              ],
            );
          }),
        ),
        if (repo.touristInfo.any((t) => t.category == TouristCategory.hotels))
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: loc.t('about.hotels'),
                  subtitle: loc.t('about.hotels.sub'),
                ),
                const SizedBox(height: 16),
                ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final h in repo.touristInfo
                        .where((t) => t.category == TouristCategory.hotels))
                      _PlaceCard(h),
                  ],
                ),
              ],
            ),
          ),
        if (repo.touristInfo
            .any((t) => t.category == TouristCategory.attractions))
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: loc.t('about.attractions'),
                  subtitle: loc.t('about.attractions.sub'),
                ),
                const SizedBox(height: 16),
                ResponsiveGrid(
                  columns: gridColumns(context, max: 3),
                  children: [
                    for (final a in repo.touristInfo
                        .where((t) => t.category == TouristCategory.attractions))
                      _PlaceCard(a),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _infoCards(BuildContext context, AppRepository repo, LocaleController loc) {
    return Column(
      children: [
        _card(
          icon: Icons.access_time,
          title: loc.t('about.hours'),
          child: Column(
            children: [
              for (final h in repo.contact.hours)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(trLoc(h.key, loc.lang),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(trLoc(h.value, loc.lang),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: AppColors.muted, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              if (trLoc(repo.contact.holidayHours, loc.lang).trim().isNotEmpty) ...[
                const Divider(height: 22),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(loc.t('about.holidayHours'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                Text(trLoc(repo.contact.holidayHours, loc.lang),
                    style: TextStyle(color: AppColors.muted, height: 1.4)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          icon: Icons.contact_phone_outlined,
          title: loc.t('about.contact'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(Icons.location_on_outlined, trLoc(repo.contact.address, loc.lang)),
              _row(Icons.phone_outlined, repo.contact.phone, phone: true),
              _row(Icons.email_outlined, repo.contact.email, email: true),
              for (final s in repo.contact.staff) ...[
                const SizedBox(height: 6),
                _row(
                  Icons.badge_outlined,
                  '${trLoc(s.name, loc.lang)} · ${trLoc(s.role, loc.lang)}',
                ),
                _row(Icons.phone_outlined, s.phone, phone: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(
      {required IconData icon, required String title, required Widget child}) {
    return Builder(builder: (context) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              PlayfulIcon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
              ),
            ]),
            const Divider(height: 22),
            child,
          ],
        ),
      );
    });
  }

  Widget _row(IconData icon, String text,
          {bool phone = false, bool email = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PlayfulIcon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: phone
                ? PhoneText(text, style: const TextStyle(height: 1.4))
                : email || looksLikeEmail(text)
                    ? EmailText(text, style: const TextStyle(height: 1.4))
                    : LinkedContactText(text, style: const TextStyle(height: 1.4)),
          ),
        ]),
      );

  Widget _map(BuildContext context, AppRepository repo, LocaleController loc) {
    final address = trLoc(repo.contact.address, loc.lang);
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final googleMapsUrl = googleMapsSearchUrl(
      lat: repo.location.latitude,
      lon: repo.location.longitude,
      address: address,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationMap(
              lat: repo.location.latitude,
              lon: repo.location.longitude,
              height: wide ? 420 : 280,
              onOpen: () => openUrl(googleMapsUrl),
            ),
            Material(
              color: AppColors.card,
              child: InkWell(
                onTap: () => openUrl(googleMapsUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(children: [
                    PlayfulIcon(Icons.place, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.isEmpty ? loc.t('about.address') : address,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.t('about.openMaps'),
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PlayfulIcon(Icons.open_in_new,
                        size: 16, color: AppColors.muted),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard(this.info);
  final TouristInfo info;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final title = trLoc(info.title, loc.lang);
    final desc = trLoc(info.description, loc.lang);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            PlayfulIcon(info.icon, color: Color(info.color)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ]),
          if (info.rating != null) ...[
            const SizedBox(height: 8),
            _RatingRow(info.rating!),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            LinkedContactText(
              desc,
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13.5),
            ),
          ],
          if (info.websiteUrl.trim().isNotEmpty ||
              info.mapsUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (info.websiteUrl.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => openUrl(info.websiteUrl.trim()),
                  icon: const PlayfulIcon(Icons.language, size: 16),
                  label: Text(loc.t('about.website')),
                ),
              if (info.mapsUrl.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => openUrl(info.mapsUrl.trim()),
                  icon: const PlayfulIcon(Icons.map_outlined, size: 16),
                  label: Text(loc.t('about.google')),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow(this.rating);
  final double rating;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final half = (rating - full) >= 0.4;
    return Row(children: [
      for (var i = 0; i < 5; i++)
        Icon(
          i < full
              ? Icons.star
              : (half && i == full)
                  ? Icons.star_half
                  : Icons.star_border,
          size: 16,
          color: const Color(0xFFC9A227),
        ),
      const SizedBox(width: 6),
      Text(rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ]);
  }
}
