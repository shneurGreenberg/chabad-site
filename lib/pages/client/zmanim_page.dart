import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class ZmanimPage extends StatelessWidget {
  const ZmanimPage({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final parasha = repo.shabbat['parasha_${loc.lang}'] ?? repo.shabbat['parasha_en']!;
    return SiteScaffold(
      currentRoute: '/zmanim',
      children: [
          PageHero(
          title: loc.t('nav.zmanim'),
          subtitle: loc.t('zmanim.subtitle'),
          icon: Icons.schedule,
        ),
        Section(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Pill(
              '${loc.t('zmanim.forCity')} ${repo.location.cityName}',
              icon: Icons.place_outlined,
            ),
          ),
        ),
        Section(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.local_fire_department, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(loc.t('zmanim.shabbat'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                  const Spacer(),
                  Pill(parasha, color: AppColors.accent),
                ]),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 30,
                  runSpacing: 16,
                  children: [
                    _big(loc.t('zmanim.candle'), repo.shabbat['candle']!),
                    _big(loc.t('zmanim.havdala'), repo.shabbat['havdala']!),
                  ],
                ),
              ],
            ),
          ),
        ),
        Section(
          child: SectionHeader(
              title: loc.t('home.zmanim.title'),
              subtitle: loc.t('zmanim.subtitle')),
        ),
        Section(
          padTop: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < repo.zmanim.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.transparent
                          : AppColors.surface.withValues(alpha: 0.5),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.brightness_5_outlined,
                          color: AppColors.primary),
                      title: Text(trLoc(repo.zmanim[i].name, loc.lang),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(repo.zmanim[i].time,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.primary)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _big(String label, String time) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 4),
          Text(time,
              style: const TextStyle(
                  color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
        ],
      );
}
