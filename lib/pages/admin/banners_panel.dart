import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
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
    repo.setBannerImage(slot.route, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final banner = repo.bannerFor(slot.route);
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
                label: Text(loc.t('admin.banners.upload')),
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
                  if (banner.bytes != null && banner.bytes!.isNotEmpty)
                    Image.memory(
                      banner.bytes!,
                      fit: BoxFit.cover,
                      alignment: banner.alignment,
                      gaplessPlayback: true,
                    )
                  else if (banner.imageUrl != null &&
                      banner.imageUrl!.isNotEmpty)
                    Image.network(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                      alignment: banner.alignment,
                    )
                  else
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
                  if (banner.hasImage)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x440B1C3A), Color(0x880B1C3A)],
                        ),
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
          if (banner.hasImage) ...[
            const SizedBox(height: 14),
            Text(loc.t('admin.banners.alignX'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: banner.alignX,
              min: -1,
              max: 1,
              label: banner.alignX.toStringAsFixed(2),
              onChanged: (v) => repo.setBannerAlign(slot.route, x: v),
            ),
            Text(loc.t('admin.banners.alignY'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: banner.alignY,
              min: -1,
              max: 1,
              label: banner.alignY.toStringAsFixed(2),
              onChanged: (v) => repo.setBannerAlign(slot.route, y: v),
            ),
          ],
        ],
      ),
    );
  }
}
