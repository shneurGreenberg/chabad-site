import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

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
    return Card(
      child: InkWell(
        onTap: () => context.go('/news'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientImage(
              color: article.imageColor,
              icon: article.icon,
              height: 150,
              badge: article.source == NewsSource.telegram
                  ? const Pill('Telegram', color: Color(0xFF0EA5E9), icon: Icons.send)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Pill(trLoc(article.category, loc.lang), color: AppColors.accent),
                    const Spacer(),
                    Text(fmtDate(context, article.date),
                        style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  ]),
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
                      style: const TextStyle(color: Colors.black54, height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text(loc.t('common.readMore'),
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
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

class ProgramCard extends StatelessWidget {
  const ProgramCard(this.program, {super.key});
  final Program program;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final color = Color(program.color);
    return Card(
      child: Padding(
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(trLoc(program.description, loc.lang),
                style: const TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.schedule, size: 15, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(trLoc(program.schedule, loc.lang),
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.people_outline, size: 15, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(trLoc(program.audience, loc.lang),
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ),
            ]),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.go('/contact'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                foregroundColor: color,
                side: BorderSide(color: color),
              ),
              child: Text(loc.t('programs.register')),
            ),
          ],
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientImage(
              color: product.color, icon: product.icon, height: 130),
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
                    style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                const SizedBox(height: 10),
                Row(children: [
                  Text('\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.primary)),
                  const Spacer(),
                  FilledButton(
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
                  ),
                ]),
              ],
            ),
          ),
        ],
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
    return Card(
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
                style: const TextStyle(color: Colors.black54, height: 1.5)),
          ],
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientImage(
            color: photo.color,
            icon: photo.icon,
            height: 160,
            badge: Pill('${photo.year}', color: Colors.black.withValues(alpha: 0.4)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trLoc(photo.event, loc.lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Text('${loc.t('gallery.tagged')}:',
                    style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
                const SizedBox(height: 6),
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
            ),
          ),
        ],
      ),
    );
  }
}
