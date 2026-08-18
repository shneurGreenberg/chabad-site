import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key, this.highlightId});
  final String? highlightId;
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  ProductCategory? _cat;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final products = repo.products
        .where((p) =>
            (widget.highlightId != null && p.id == widget.highlightId) ||
            _cat == null ||
            p.category == _cat)
        .toList();
    return SiteScaffold(
      currentRoute: '/store',
      children: [
        PageHero(
          title: loc.t('nav.store'),
          subtitle: loc.t('store.subtitle'),
          icon: Icons.storefront_outlined,
        ),
        Section(
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(loc.t('common.all'), null),
            _chip(loc.t('store.judaica'), ProductCategory.judaica),
            _chip(loc.t('store.books'), ProductCategory.books),
            _chip(loc.t('store.food'), ProductCategory.food),
          ]),
        ),
        Section(
          padTop: 16,
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 900;
            final grid = products.isEmpty
                ? const EmptyHint(icon: Icons.storefront_outlined)
                : ResponsiveGrid(
                    columns: wide ? 3 : gridColumns(context, max: 3),
                    children: [
                      for (final p in products)
                        HighlightAnchor(
                          id: p.id,
                          highlightId: widget.highlightId,
                          child: ProductCard(p),
                        ),
                    ],
                  );
            if (!wide) {
              return Column(children: [
                _CartPanel(repo: repo),
                const SizedBox(height: 20),
                grid,
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: grid),
                const SizedBox(width: 20),
                SizedBox(width: 300, child: _CartPanel(repo: repo)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _chip(String label, ProductCategory? cat) => ChoiceChip(
        label: Text(label),
        selected: _cat == cat,
        onSelected: (_) => setState(() => _cat = cat),
      );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.repo});
  final AppRepository repo;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final entries = repo.cart.entries.toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(loc.t('store.cart'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            Pill('${repo.cartCount}', color: AppColors.accent),
          ]),
          const Divider(height: 24),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(loc.t('store.cart.empty'),
                    style: TextStyle(color: AppColors.muted)),
              ),
            )
          else ...[
            for (final e in entries)
              _cartRow(context, repo, e.key, e.value, loc),
            const Divider(height: 24),
            Row(children: [
              Text(loc.t('store.total'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('\$${repo.cartTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _checkout(context, repo),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(loc.t('store.checkout')),
            ).hoverLift(),
          ],
        ],
      ),
    );
  }

  Widget _cartRow(BuildContext context, AppRepository repo, String id, int qty,
      LocaleController loc) {
    final p = repo.products.firstWhere((e) => e.id == id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
          child: Text(trLoc(p.name, loc.lang),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => repo.removeFromCart(id),
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ).hoverScale(),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => repo.addToCart(id),
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ).hoverScale(),
      ]),
    );
  }

  void _checkout(BuildContext context, AppRepository repo) {
    final loc = context.read<LocaleController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 46),
        title: Text(loc.t('store.checkout')),
        content: Text(
          '${loc.t('store.total')}: \$${repo.cartTotal.toStringAsFixed(0)}\n\n'
          '${loc.t('donate.thanks')}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              repo.clearCart();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(loc.t('common.close')),
          ),
        ],
      ),
    );
  }
}
