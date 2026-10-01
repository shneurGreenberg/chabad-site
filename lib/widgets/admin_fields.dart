import 'dart:typed_data';
import 'playful_icons.dart';

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
    final filled = widget.controllers.values
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    return filled > 0 && filled < widget.controllers.length;
  }

  Future<void> _translate() async {
    final loc = context.loc;
    final fields = {
      for (final e in widget.controllers.entries) e.key: e.value.text,
    };
    if (fields.values.every((v) => v.trim().isEmpty)) return;
    setState(() => _loading = true);
    try {
      final out = await AutoTranslate.fillEmpty(fields);
      var filled = 0;
      for (final lang in out.keys) {
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
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                      : const PlayfulIcon(Icons.translate, size: 18),
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
    this.url,
    this.color = 0xFF1E3A8A,
    this.icon = Icons.image_outlined,
    this.height = 160,
    this.alignY = 0,
    this.onAlignY,
  });
  final Uint8List? bytes;
  final String? url;
  final ValueChanged<Uint8List?> onChanged;
  final int color;
  final IconData icon;
  final double height;
  final double alignY;
  final ValueChanged<double>? onAlignY;

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
    final hasBytes = bytes != null && bytes!.isNotEmpty;
    final fallback = url?.trim() ?? '';
    final hasUrl = fallback.isNotEmpty;
    final alignment = Alignment(0, alignY);
    Widget preview;
    if (hasBytes) {
      preview = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        alignment: alignment,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (hasUrl) {
      preview = fallback.startsWith('assets/')
          ? Image.asset(fallback,
              fit: BoxFit.cover,
              alignment: alignment,
              width: double.infinity,
              height: double.infinity)
          : Image.network(fallback,
              fit: BoxFit.cover,
              alignment: alignment,
              width: double.infinity,
              height: double.infinity);
    } else {
      preview = GradientImage(color: color, icon: icon, height: height);
    }
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
            child: LayoutBuilder(builder: (context, box) {
              final image = preview;
              if (onAlignY == null || !(hasBytes || hasUrl)) return image;
              return GestureDetector(
                onVerticalDragUpdate: (d) {
                  final ny = (alignY - d.delta.dy / (box.maxHeight / 2))
                      .clamp(-1.0, 1.0);
                  onAlignY!(ny);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: image,
                ),
              );
            }),
          ),
        ),
        if (onAlignY != null && (hasBytes || hasUrl)) ...[
          const SizedBox(height: 8),
          Text(loc.t('admin.banners.alignY'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Slider(
            value: alignY.clamp(-1.0, 1.0),
            min: -1,
            max: 1,
            label: alignY.toStringAsFixed(2),
            onChanged: onAlignY,
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _pick,
              icon: const PlayfulIcon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(loc.t('admin.image.choose')),
            ).hoverLift(),
            if (hasBytes)
              OutlinedButton.icon(
                onPressed: () => onChanged(null),
                icon: const PlayfulIcon(Icons.delete_outline, size: 18),
                label: Text(loc.t('admin.image.remove')),
              ).hoverLift(),
          ],
        ),
      ],
    );
  }
}

/// Small admin-list thumbnail: photo if present, otherwise the color icon,
/// plus a badge so it is obvious which items still need an image.
class AdminMediaThumb extends StatelessWidget {
  const AdminMediaThumb({
    super.key,
    this.bytes,
    this.url,
    required this.color,
    required this.icon,
    this.size = 48,
  });

  final Uint8List? bytes;
  final String? url;
  final int color;
  final IconData icon;
  final double size;

  bool get hasImage =>
      (bytes != null && bytes!.isNotEmpty) ||
      (url != null && url!.isNotEmpty);

  Widget _fallback() => ColoredBox(
        color: Color(color).withValues(alpha: 0.18),
        child: PlayfulIcon(icon, color: Color(color), size: size * 0.42),
      );

  Widget _photo() {
    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: 96,
      );
    }
    final src = url!;
    if (src.startsWith('assets/')) {
      return Image.asset(src, fit: BoxFit.cover, cacheWidth: 96);
    }
    return Image.network(
      src,
      fit: BoxFit.cover,
      cacheWidth: 96,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final has = hasImage;
    return Tooltip(
      message: loc.t(has ? 'admin.image.has' : 'admin.image.none'),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: has ? _photo() : _fallback(),
              ),
            ),
            PositionedDirectional(
              end: 2,
              bottom: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: has ? const Color(0xFF0D9488) : AppColors.muted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 1.5),
                ),
                child: PlayfulIcon(
                  has ? Icons.check : Icons.hide_image_outlined,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminImageCountLine extends StatelessWidget {
  const AdminImageCountLine({super.key, required this.have, required this.total});
  final int have;
  final int total;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        loc
            .t('admin.image.count')
            .replaceAll('{have}', '$have')
            .replaceAll('{total}', '$total'),
        style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3),
      ),
    );
  }
}

/// Pick several photos at once for a gallery album.
///
/// Every shot is in the list. The dialog scrolls through them. A star or a
/// drag to the first row chooses the cover.
class AlbumPhotosPicker extends StatelessWidget {
  const AlbumPhotosPicker({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.onMakeCover,
    this.onReorder,
  });
  final List<GalleryShot> photos;
  final Future<void> Function() onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String>? onMakeCover;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('admin.gallery.photos'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (photos.isEmpty)
          Text(loc.t('gallery.emptyAlbum'),
              style: TextStyle(color: AppColors.muted, fontSize: 13))
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              var target = newIndex;
              if (target > oldIndex) target -= 1;
              onReorder?.call(oldIndex, target);
            },
            children: [
              for (var i = 0; i < photos.length; i++)
                _albumShotRow(loc, photos[i], i),
            ],
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const PlayfulIcon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(loc.t('admin.gallery.addPhotos')),
        ).hoverLift(),
      ],
    );
  }

  Widget _albumShotRow(LocaleController loc, GalleryShot shot, int index) {
    final cover = index == 0;
    return Material(
      key: ValueKey('album-shot-${shot.id}'),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: ShotImage(shot),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cover ? loc.t('admin.gallery.cover') : '${index + 1}',
                style: TextStyle(
                  fontWeight: cover ? FontWeight.w800 : FontWeight.w600,
                  color: cover ? AppColors.primary : AppColors.muted,
                ),
              ),
            ),
            IconButton(
              key: ValueKey('album-cover-${shot.id}'),
              tooltip: loc.t('admin.gallery.makeCover'),
              onPressed: () => onMakeCover?.call(shot.id),
              icon: Icon(
                cover ? Icons.star : Icons.star_border,
                color: cover ? const Color(0xFFC9A227) : AppColors.muted,
              ),
            ),
            IconButton(
              key: ValueKey('album-delete-${shot.id}'),
              tooltip: loc.t('common.delete'),
              onPressed: () => onRemove(shot.id),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress card shown while a batch of gallery photos is compressed and added.
class GalleryUploadOverlay extends StatefulWidget {
  const GalleryUploadOverlay({
    super.key,
    required this.done,
    required this.total,
    this.preparing = false,
  });
  final int done;
  final int total;
  final bool preparing;

  @override
  State<GalleryUploadOverlay> createState() => _GalleryUploadOverlayState();
}

class _GalleryUploadOverlayState extends State<GalleryUploadOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    if (widget.preparing) {
      return ColoredBox(
        key: const ValueKey('gallery-upload-preparing'),
        color: const Color(0xCC0B1C3A),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(
                      loc.t('admin.gallery.preparing'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final done = widget.done;
    final total = widget.total;
    final progress =
        total <= 0 ? null : (done / total).clamp(0.0, 1.0).toDouble();
    final label = loc
        .t('admin.gallery.uploadProgress')
        .replaceAll('{done}', '$done')
        .replaceAll('{total}', '$total');
    return ColoredBox(
      key: const ValueKey('gallery-upload-progress'),
      color: const Color(0xCC0B1C3A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -6 * _pulse.value),
                      child: child,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('admin.gallery.uploading'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    key: const ValueKey('gallery-upload-count'),
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
