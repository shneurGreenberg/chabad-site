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
    
    // Safe access to touristInfo with null check
    final touristInfo = repo.touristInfo;
    final hasTouristInfo = touristInfo.isNotEmpty;
    
    final sections = [
      _buildSection(
        context,
        TouristCategory.synagogue,
        loc.t('tourist.synagogue'),
        Icons.synagogue,
        touristInfo
            .where((t) => t.category == TouristCategory.synagogue)
            .toList(),
      ),
      _buildSection(
        context,
        TouristCategory.kosherFood,
        loc.t('tourist.kosherFood'),
        Icons.restaurant,
        touristInfo
            .where((t) => t.category == TouristCategory.kosherFood)
            .toList(),
      ),
      _buildSection(
        context,
        TouristCategory.hotels,
        loc.t('tourist.hotels'),
        Icons.hotel,
        touristInfo
            .where((t) => t.category == TouristCategory.hotels)
            .toList(),
      ),
      _buildSection(
        context,
        TouristCategory.attractions,
        loc.t('tourist.attractions'),
        Icons.attractions,
        touristInfo
            .where((t) => t.category == TouristCategory.attractions)
            .toList(),
      ),
      _buildSection(
        context,
        TouristCategory.dayTrips,
        loc.t('tourist.dayTrips'),
        Icons.explore,
        touristInfo
            .where((t) => t.category == TouristCategory.dayTrips)
            .toList(),
      ),
    ];
    
    return SiteScaffold(
      currentRoute: '/tourist',
      children: [
        PageHero(
          title: loc.t('nav.tourist'),
          subtitle: loc.t('tourist.subtitle'),
          icon: Icons.info_outline,
        ),
        if (!hasTouristInfo)
          Section(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  loc.lang == 'he'
                      ? 'אין עדיין מידע לתיירים'
                      : loc.lang == 'ru'
                          ? 'Информация для туристов пока недоступна'
                          : 'No tourist information available yet',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )
        else
          ...sections,
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
    
    // Safe title extraction with fallback
    final title = info.title[loc.lang] ?? 
                  info.title['en'] ?? 
                  info.title['he'] ?? 
                  '';
    
    // Safe description extraction with fallback
    final description = info.description[loc.lang] ?? 
                        info.description['en'] ?? 
                        info.description['he'] ?? 
                        '';
    
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
                    ? Image.memory(info.imageBytes!, 
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: color.withValues(alpha: 0.1),
                          child: Icon(info.icon, color: color, size: 48),
                        ))
                    : info.imageUrl != null && info.imageUrl!.isNotEmpty
                        ? (info.imageUrl!.startsWith('assets/')
                            ? Image.asset(info.imageUrl!, 
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: color.withValues(alpha: 0.1),
                                  child: Icon(info.icon, color: color, size: 48),
                                ))
                            : Image.network(info.imageUrl!, 
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: color.withValues(alpha: 0.1),
                                  child: Icon(info.icon, color: color, size: 48),
                                )))
                        : Container(
                            color: color.withValues(alpha: 0.1),
                            child: Icon(info.icon, color: color, size: 48),
                          ),
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
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppColors.ink,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
