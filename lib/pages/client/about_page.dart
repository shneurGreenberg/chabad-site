import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/map_embed.dart';
import '../../widgets/site_scaffold.dart';

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
              _row(Icons.email_outlined, repo.contact.email),
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
              Icon(icon, color: AppColors.primary),
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

  Widget _row(IconData icon, String text, {bool phone = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: phone
                ? PhoneText(text, style: const TextStyle(height: 1.4))
                : Text(text, style: const TextStyle(height: 1.4)),
          ),
        ]),
      );

  Widget _map(BuildContext context, AppRepository repo, LocaleController loc) {
    final address = trLoc(repo.contact.address, loc.lang);
    final key = repo.googleMapsApiKey.trim();
    final url = key.isNotEmpty
        ? googleMapsEmbedUrl(
            apiKey: key,
            lat: repo.location.latitude,
            lon: repo.location.longitude,
            address: address,
          )
        : osmEmbedUrl(repo.location.latitude, repo.location.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: MapEmbed(url: url)),
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10)
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.place, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      address.isEmpty ? loc.t('about.address') : address,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
