import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';

class BannersPanel extends StatelessWidget {
  const BannersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EmblemEditor(),
        const SizedBox(height: 22),
        Text(loc.t('admin.banners.subtitle'),
            style: TextStyle(color: AppColors.muted, height: 1.45, fontSize: 15)),
        const SizedBox(height: 8),
        Text(loc.t('admin.banners.hint'),
            style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4)),
        const SizedBox(height: 22),
        for (final slot in bannerSlots) ...[
          _BannerEditor(slot: slot),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _EmblemEditor extends StatelessWidget {
  const _EmblemEditor();

  Future<void> _pick(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 92,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    context.read<AppRepository>().setEmblemImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const ChabadEmblem(size: 64),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('admin.emblem'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 4),
                Text(loc.t('admin.emblem.hint'),
                    style: TextStyle(color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(loc.t('admin.emblem.upload')),
          ).hoverLift(),
          if (repo.hasCustomEmblem)
            OutlinedButton.icon(
              onPressed: repo.clearEmblem,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(loc.t('admin.emblem.reset')),
            ).hoverLift(),
        ],
      ),
    );
  }
}

class _BannerEditor extends StatelessWidget {
  const _BannerEditor({required this.slot});
  final BannerSlot slot;

  Future<void> _pick(BuildContext context) async {
    final repo = context.read<AppRepository>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    repo.addBannerSlide(slot.route, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final banner = repo.bannerFor(slot.route);
    final slides = banner.allSlides;
    final previewH = slot.tall ? 220.0 : 148.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(slot.tall ? Icons.home_outlined : Icons.web_asset,
                  color: AppColors.primary),
              Text(loc.t(slot.labelKey),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
              FilledButton.icon(
                onPressed: () => _pick(context),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(slides.isEmpty
                    ? loc.t('admin.banners.upload')
                    : loc.t('admin.banners.addSlide')),
              ).hoverLift(),
              if (banner.hasImage)
                OutlinedButton.icon(
                  onPressed: () => repo.clearBanner(slot.route),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(loc.t('admin.banners.remove')),
                ).hoverLift(),
            ],
          ),
          const SizedBox(height: 6),
          Text(loc.t('admin.banners.preview'),
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: previewH,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BannerFill(banner: banner, positioned: false),
                  if (!banner.hasImage)
                    Container(
                      decoration:
                          BoxDecoration(gradient: AppColors.heroGradient),
                      child: Center(
                        child: Text(loc.t('admin.banners.empty'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  PositionedDirectional(
                    start: 18,
                    bottom: 16,
                    child: Text(
                      loc.t(slot.labelKey),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < slides.length; i++) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${loc.t('admin.banners.slide')} ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  tooltip: loc.t('admin.banners.remove'),
                  onPressed: () => repo.removeBannerSlide(slot.route, i),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Text(loc.t('admin.banners.alignX'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: slides[i].alignX,
              min: -1,
              max: 1,
              label: slides[i].alignX.toStringAsFixed(2),
              onChanged: (v) => repo.setSlideAlign(slot.route, i, x: v),
            ),
            Text(loc.t('admin.banners.alignY'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: slides[i].alignY,
              min: -1,
              max: 1,
              label: slides[i].alignY.toStringAsFixed(2),
              onChanged: (v) => repo.setSlideAlign(slot.route, i, y: v),
            ),
          ],
        ],
      ),
    );
  }
}
