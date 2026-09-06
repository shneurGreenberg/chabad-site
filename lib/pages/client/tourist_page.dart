import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';
import '../../widgets/playful_icons.dart';

class TouristPage extends StatelessWidget {
  const TouristPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/tourist',
      children: [
        PageHero(
          title: loc.t('nav.tourist'),
          subtitle: loc.t('tourist.subtitle'),
          icon: Icons.info_outline,
        ),
        _buildSection(
          context,
          TouristCategory.synagogue,
          loc.t('tourist.synagogue'),
          Icons.synagogue,
          repo.touristInfo
              .where((t) => t.category == TouristCategory.synagogue)
              .toList(),
        ),
        _buildSection(
          context,
          TouristCategory.kosherFood,
          loc.t('tourist.kosherFood'),
          Icons.restaurant,
          repo.touristInfo
              .where((t) => t.category == TouristCategory.kosherFood)
              .toList(),
        ),
        _buildSection(
          context,
          TouristCategory.hotels,
          loc.t('tourist.hotels'),
          Icons.hotel,
          repo.touristInfo
              .where((t) => t.category == TouristCategory.hotels)
              .toList(),
        ),
        _buildSection(
          context,
          TouristCategory.attractions,
          loc.t('tourist.attractions'),
          Icons.attractions,
          repo.touristInfo
              .where((t) => t.category == TouristCategory.attractions)
              .toList(),
        ),
        _buildSection(
          context,
          TouristCategory.dayTrips,
          loc.t('tourist.dayTrips'),
          Icons.explore,
          repo.touristInfo
              .where((t) => t.category == TouristCategory.dayTrips)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    TouristCategory category,
    String title,
    IconData icon,
    List<TouristInfo> items,
  ) {
    final loc = context.locWatch;
    if (items.isEmpty) return const SizedBox.shrink();
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PlayfulIcon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ResponsiveGrid(
            columns: gridColumns(context, max: 2),
            children: [
              for (final item in items) TouristInfoCard(item),
            ],
          ),
        ],
      ),
    );
  }
}

class TouristInfoCard extends StatelessWidget {
  const TouristInfoCard(this.info, {super.key});
  final TouristInfo info;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final color = Color(info.color);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: info.imageBytes != null && info.imageBytes!.isNotEmpty
                    ? Image.memory(info.imageBytes!, fit: BoxFit.cover)
                    : info.imageUrl!.startsWith('assets/')
                        ? Image.asset(info.imageUrl!, fit: BoxFit.cover)
                        : Image.network(info.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          if (info.hasImage) const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PlayfulIcon(info.icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                trLoc(info.title, loc.lang),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            trLoc(info.description, loc.lang),
            style: TextStyle(
              color: AppColors.ink,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
