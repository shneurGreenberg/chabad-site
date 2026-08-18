import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';
import 'hover.dart';

String fmtDate(BuildContext context, DateTime d) {
  final lang = context.read<LocaleController>().lang;
  return DateFormat.yMMMd(lang).format(d);
}

class NewsCard extends StatelessWidget {
  const NewsCard(this.article, {super.key});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return HoverLift(
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Card(
      child: InkWell(
        onTap: () => context.go('/news/${article.id}'),
        mouseCursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientImage(
              color: article.imageColor,
              icon: article.icon,
              height: 150,
              bytes: article.imageBytes,
              url: article.imageUrl,
              badge: article.source == NewsSource.telegram
                  ? const Pill('Telegram', color: Color(0xFF0EA5E9), icon: Icons.send)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(trLoc(article.category, loc.lang), color: AppColors.accent),
                      Text(fmtDate(context, article.date),
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(trLoc(article.title, loc.lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(trLoc(article.body, loc.lang),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text(loc.t('common.readMore'),
                        style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    ),
    );
  }
}

class ProgramCard extends StatelessWidget {
  const ProgramCard(this.program, {super.key});
  final Program program;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final color = Color(program.color);
    return HoverLift(
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/programs/${program.id}'),
          mouseCursor: SystemMouseCursors.click,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientImage(
              color: program.color,
              icon: program.icon,
              height: 120,
              bytes: program.imageBytes,
              url: program.imageUrl,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(program.icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(trLoc(program.title, loc.lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(trLoc(program.description, loc.lang),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text(loc.t('common.readMore'),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ]),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.read<AppRepository>();
    return HoverLift(
      child: Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientImage(
              color: product.color,
              icon: product.icon,
              height: 130,
              bytes: product.imageBytes,
              url: product.imageUrl),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trLoc(product.name, loc.lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(trLoc(product.description, loc.lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 10),
                Row(children: [
                  Text('\$${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.primary)),
                  const Spacer(),
                  Tooltip(
                    message: loc.t('store.addToCart'),
                    child: FilledButton(
                      onPressed: () {
                        repo.addToCart(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(trLoc(product.name, loc.lang)),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      child: const Icon(Icons.add_shopping_cart, size: 18),
                    ).hoverLift(scale: 1.05),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class PersonCard extends StatelessWidget {
  const PersonCard(this.person, {super.key});
  final FamousPerson person;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final color = Color(person.color);
    return HoverLift(
      child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(person.initials,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trLoc(person.name, loc.lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(trLoc(person.profession, loc.lang),
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(trLoc(person.bio, loc.lang),
                style: TextStyle(color: AppColors.muted, height: 1.5)),
          ],
        ),
      ),
    ),
    );
  }
}

class PhotoCard extends StatelessWidget {
  const PhotoCard(this.photo, {super.key, this.highlightFace});
  final GalleryPhoto photo;
  final String? highlightFace;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return HoverLift(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/gallery/${photo.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientImage(
                color: photo.color,
                icon: photo.icon,
                height: 160,
                bytes: photo.coverBytes,
                url: photo.coverUrl,
                badge: Pill(
                  '${photo.year}',
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trLoc(photo.event, loc.lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 16, color: Color(photo.color)),
                        const SizedBox(width: 6),
                        Text(
                          '${photo.photoCount} ${loc.t('gallery.photos')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(photo.color),
                          ),
                        ),
                      ],
                    ),
                    if (photo.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in photo.tags)
                            Pill(
                              tag,
                              icon: Icons.face,
                              color: tag == highlightFace
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShotImage extends StatelessWidget {
  const ShotImage(this.shot, {super.key, this.fit = BoxFit.cover});
  final GalleryShot shot;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (shot.imageBytes != null && shot.imageBytes!.isNotEmpty) {
      return Image.memory(
        shot.imageBytes!,
        fit: fit,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: imageDecodePx(context, 480),
      );
    }
    final url = shot.imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF1E3A8A),
        child: Center(child: Icon(Icons.photo, color: Colors.white54)),
      );
    }
    final cacheW = imageDecodePx(context, fit == BoxFit.contain ? 1200 : 480);
    if (url.startsWith('assets/')) {
      return Image.asset(url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheW);
    }
    return Image.network(url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheW,
        filterQuality: FilterQuality.medium);
  }
}
