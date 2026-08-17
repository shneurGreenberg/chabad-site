import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../models.dart';
import '../services/auto_translate.dart';
import '../services/image_compress.dart';
import '../theme.dart';
import 'cards.dart';
import 'common.dart';
import 'hover.dart';

/// Trilingual (he / en / ru) fields with an auto-translate button from Hebrew.
class LocFieldGroup extends StatefulWidget {
  const LocFieldGroup({
    super.key,
    required this.label,
    required this.controllers,
    this.maxLines = 1,
  });
  final String label;
  final Map<String, TextEditingController> controllers;
  final int maxLines;

  @override
  State<LocFieldGroup> createState() => _LocFieldGroupState();
}

class _LocFieldGroupState extends State<LocFieldGroup> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.controllers.values) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in widget.controllers.values) {
      c.removeListener(_onChanged);
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _showTranslate {
    final he = widget.controllers['he']?.text.trim() ?? '';
    if (he.isEmpty) return false;
    final en = widget.controllers['en']?.text.trim() ?? '';
    final ru = widget.controllers['ru']?.text.trim() ?? '';
    return en.isEmpty || ru.isEmpty;
  }

  Future<void> _translate() async {
    final loc = context.loc;
    final he = widget.controllers['he']?.text.trim() ?? '';
    if (he.isEmpty) return;
    setState(() => _loading = true);
    try {
      final out = await AutoTranslate.fromHebrew(he);
      var filled = 0;
      for (final lang in ['en', 'ru']) {
        final c = widget.controllers[lang];
        if (c == null) continue;
        if (c.text.trim().isNotEmpty) continue;
        final t = out[lang]?.trim() ?? '';
        if (t.isEmpty) continue;
        c.text = t;
        filled++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filled == 0
              ? loc.t('admin.translate.skip')
              : loc.t('admin.translate.ok')),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.translate.error'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
              if (_showTranslate)
                TextButton.icon(
                  onPressed: _loading ? null : _translate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate, size: 18),
                  label: Text(loc.t('admin.translate')),
                ).hoverLift(),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in supportedLangs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: widget.controllers[l],
                maxLines: widget.maxLines,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 44, minHeight: 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cover-crop preview + photo picker (same in-memory bytes pattern as banners).
class CoverImagePicker extends StatelessWidget {
  const CoverImagePicker({
    super.key,
    required this.bytes,
    required this.onChanged,
    this.color = 0xFF1E3A8A,
    this.icon = Icons.image_outlined,
    this.height = 160,
  });
  final Uint8List? bytes;
  final ValueChanged<Uint8List?> onChanged;
  final int color;
  final IconData icon;
  final double height;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 86,
    );
    if (picked == null) return;
    onChanged(compressSiteImage(await picked.readAsBytes()));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final has = bytes != null && bytes!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('admin.image'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(loc.t('admin.image.preview'),
            style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: has
                ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
                : GradientImage(color: color, icon: icon, height: height),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(loc.t('admin.image.choose')),
            ).hoverLift(),
            if (has)
              OutlinedButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(loc.t('admin.image.remove')),
              ).hoverLift(),
          ],
        ),
      ],
    );
  }
}

/// Pick several photos at once for a gallery album.
class AlbumPhotosPicker extends StatelessWidget {
  const AlbumPhotosPicker({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });
  final List<GalleryShot> photos;
  final Future<void> Function() onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('admin.gallery.photos'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (photos.isNotEmpty)
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final shot = photos[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: ShotImage(shot),
                      ),
                    ),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onRemove(shot.id),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          Text(loc.t('gallery.emptyAlbum'),
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(loc.t('admin.gallery.addPhotos')),
        ).hoverLift(),
      ],
    );
  }
}
