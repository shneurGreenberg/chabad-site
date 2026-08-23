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
import '../../widgets/playful_icons.dart';

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
            PlayfulIcon(Icons.shopping_cart_outlined, color: AppColors.primary),
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
            Text(loc.t('store.fulfill.hint'),
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _checkout(context, repo),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              icon: const PlayfulIcon(Icons.storefront_outlined, size: 18),
              label: Text(loc.t('store.order')),
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
          icon: const PlayfulIcon(Icons.remove_circle_outline, size: 20),
        ).hoverScale(),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => repo.addToCart(id),
          icon: const PlayfulIcon(Icons.add_circle_outline, size: 20),
        ).hoverScale(),
      ]),
    );
  }

  void _checkout(BuildContext context, AppRepository repo) {
    final loc = context.read<LocaleController>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final note = TextEditingController();
    var fulfillment = 'pickup';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(loc.t('store.order')),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${loc.t('store.total')}: \$${repo.cartTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(loc.t('store.fulfill.hint'),
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'pickup', label: Text(loc.t('store.pickup'))),
                      ButtonSegment(
                          value: 'delivery',
                          label: Text(loc.t('store.delivery'))),
                    ],
                    selected: {fulfillment},
                    onSelectionChanged: (s) =>
                        setLocal(() => fulfillment = s.first),
                  ),
                  TextField(
                    controller: name,
                    decoration:
                        InputDecoration(labelText: loc.t('common.name')),
                  ),
                  TextField(
                    controller: phone,
                    decoration:
                        InputDecoration(labelText: loc.t('common.phone')),
                  ),
                  TextField(
                    controller: email,
                    decoration:
                        InputDecoration(labelText: loc.t('common.email')),
                  ),
                  if (fulfillment == 'delivery')
                    TextField(
                      controller: address,
                      decoration:
                          InputDecoration(labelText: loc.t('store.address')),
                    ),
                  TextField(
                    controller: note,
                    decoration:
                        InputDecoration(labelText: loc.t('store.note')),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.t('common.close')),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
                  return;
                }
                repo.placeOrder(
                  name: name.text,
                  phone: phone.text,
                  email: email.text,
                  fulfillment: fulfillment,
                  address: address.text,
                  note: note.text,
                  lang: loc.lang,
                );
                Navigator.pop(ctx, true);
              },
              child: Text(loc.t('store.order')),
            ),
          ],
        ),
      ),
    ).then((ok) {
      name.dispose();
      phone.dispose();
      email.dispose();
      address.dispose();
      note.dispose();
      if (ok == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('store.order.thanks'))),
        );
      }
    });
  }
}
