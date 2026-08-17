import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';

class AppearancePanel extends StatelessWidget {
  const AppearancePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('admin.appearance'),
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(loc.t('admin.appearance.subtitle'),
              style: TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final p in SitePalettes.all)
                _PaletteCard(
                  palette: p,
                  selected: repo.paletteId == p.id,
                  onTap: () => repo.setPaletteId(p.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final SitePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return HoverScale(
      scale: 1.03,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.ink.withValues(alpha: 0.08),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: selected ? AppColors.cardShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _swatch(palette.primaryDark),
                  _swatch(palette.primary),
                  _swatch(palette.accent),
                  _swatch(palette.surface),
                  _swatch(palette.card),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trLoc(palette.name, loc.lang),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                palette.isDark
                    ? loc.t('admin.appearance.dark')
                    : loc.t('admin.appearance.light'),
                style: TextStyle(
                    color: palette.isDark ? AppColors.accent : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 28,
        height: 28,
        margin: const EdgeInsetsDirectional.only(end: 6),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        ),
      );
}
