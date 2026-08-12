import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class NavItem {
  const NavItem(this.route, this.labelKey, this.icon);
  final String route;
  final String labelKey;
  final IconData icon;
}

const primaryNav = [
  NavItem('/', 'nav.home', Icons.home_outlined),
  NavItem('/news', 'nav.news', Icons.article_outlined),
  NavItem('/zmanim', 'nav.zmanim', Icons.schedule),
  NavItem('/programs', 'nav.programs', Icons.groups_outlined),
  NavItem('/gallery', 'nav.gallery', Icons.photo_library_outlined),
  NavItem('/store', 'nav.store', Icons.storefront_outlined),
];

const moreNav = [
  NavItem('/cemetery', 'nav.cemetery', Icons.grid_view_outlined),
  NavItem('/famous', 'nav.famous', Icons.star_outline),
  NavItem('/history', 'nav.history', Icons.account_balance_outlined),
  NavItem('/library', 'nav.library', Icons.menu_book_outlined),
  NavItem('/about', 'nav.about', Icons.info_outline),
];

/// Shared client chrome: sticky header, scrolling body, footer.
/// Pages pass their sections via [children]; the shell in [appRouter]
/// keeps this chrome mounted so navigation does not rebuild the header.
class SiteScaffold extends StatelessWidget {
  const SiteScaffold({
    super.key,
    required this.children,
    this.currentRoute = '/',
  });
  final List<Widget> children;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Persistent site frame used by [ShellRoute].
/// Uses a dedicated scroll controller (not the Scaffold primary one) so
/// the previous page's offset is never applied to the next page.
class SiteShell extends StatefulWidget {
  const SiteShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });
  final String currentRoute;
  final Widget child;

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell> {
  late ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(SiteShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final previous = _scroll;
      _scroll = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous.dispose();
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _SiteHeader(currentRoute: widget.currentRoute),
      drawer: mobile ? _SiteDrawer(currentRoute: widget.currentRoute) : null,
      body: PrimaryScrollController.none(
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                layoutBuilder: (currentChild, _) =>
                    currentChild ?? const SizedBox.shrink(),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey(widget.currentRoute),
                  child: widget.child,
                ),
              ),
              const SizedBox(height: 40),
              const _SiteFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget implements PreferredSizeWidget {
  const _SiteHeader({required this.currentRoute});
  final String currentRoute;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final mobile = isMobile(context);
    final compact = isTablet(context);
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.goldGradient)),
            SizedBox(
          height: 72,
          child: MaxWidthBox(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _Logo(),
                if (!mobile) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final item in primaryNav)
                            if (!(compact &&
                                (item.route == '/store' ||
                                    item.route == '/gallery')))
                              _NavLink(
                                item: item,
                                active: currentRoute == item.route,
                              ),
                          _MoreMenu(currentRoute: currentRoute),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LanguageSwitcher(),
                  const SizedBox(width: 4),
                  const _CartButton(),
                  const SizedBox(width: 4),
                  if (!compact) ...[
                    OutlinedButton.icon(
                      onPressed: () => context.go('/contact'),
                      icon: const Icon(Icons.app_registration, size: 18),
                      label: Text(loc.t('nav.contact')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => context.go('/donate'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primaryDark),
                      icon: const Icon(Icons.favorite_outline, size: 18),
                      label: Text(loc.t('nav.donate')),
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    IconButton(
                      tooltip: loc.t('nav.contact'),
                      onPressed: () => context.go('/contact'),
                      icon: const Icon(Icons.app_registration),
                    ),
                    IconButton(
                      tooltip: loc.t('nav.donate'),
                      onPressed: () => context.go('/donate'),
                      icon: const Icon(Icons.favorite_outline),
                    ),
                  ],
                  IconButton(
                    tooltip: loc.t('nav.admin'),
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                ] else ...[
                  const Spacer(),
                  const _CartButton(),
                  const LanguageSwitcher(),
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: loc.t('nav.menu'),
                      icon: const Icon(Icons.menu),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ],
            ),
          ),
            ),
            Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return InkWell(
      onTap: () => context.go('/'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: loc.t('site.name'),
              image: true,
              child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.55), width: 1.4),
              ),
              child: const Icon(Icons.synagogue, color: AppColors.accentSoft, size: 24),
            ),
            ),
            const SizedBox(width: 10),
            if (!isTablet(context))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.t('site.name'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink)),
                  Text(loc.t('site.city'),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item, required this.active});
  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return _NavChrome(
      icon: item.icon,
      label: loc.t(item.labelKey),
      active: active,
      onTap: () => context.go(item.route),
    );
  }
}

/// Shared nav-item chrome so "Menu" sits on the same baseline as the links.
class _NavChrome extends StatelessWidget {
  const _NavChrome({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.ink;
    final body = SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14.5,
                    color: color,
                    height: 1.1,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 2),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: active ? 22 : 0,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: body,
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.currentRoute});
  final String currentRoute;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final compact = isTablet(context);
    final extras = compact
        ? primaryNav.where((i) =>
            i.route == '/store' || i.route == '/gallery')
        : const <NavItem>[];
    final moreItems = [...extras, ...moreNav];
    final moreActive = moreItems.any((i) => i.route == currentRoute);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<String>(
        tooltip: loc.t('nav.menu'),
        padding: EdgeInsets.zero,
        onSelected: (route) => context.go(route),
        position: PopupMenuPosition.under,
        itemBuilder: (context) => [
          for (final item in moreItems)
            PopupMenuItem(
              value: item.route,
              child: Row(children: [
                Icon(item.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(loc.t(item.labelKey)),
              ]),
            ),
        ],
        child: _NavChrome(
          icon: Icons.menu,
          label: loc.t('nav.menu'),
          active: moreActive,
          trailing: Icon(Icons.expand_more,
              size: 16,
              color: moreActive ? AppColors.primary : AppColors.ink),
        ),
      ),
    );
  }
}

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return PopupMenuButton<String>(
      tooltip: loc.t('common.language'),
      onSelected: loc.setLang,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final code in supportedLangs)
          PopupMenuItem(
            value: code,
            child: Row(children: [
              if (loc.lang == code)
                const Icon(Icons.check, size: 16, color: AppColors.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(langNames[code]!),
            ]),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, size: 18),
          const SizedBox(width: 6),
          Text(loc.lang.toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, height: 1)),
        ]),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();
  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppRepository>().cartCount;
    final loc = context.locWatch;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: loc.t('store.cart'),
          onPressed: () => context.go('/store'),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
        if (count > 0)
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark)),
            ),
          ),
      ],
    );
  }
}

class _SiteDrawer extends StatelessWidget {
  const _SiteDrawer({required this.currentRoute});
  final String currentRoute;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    // De-duplicate while keeping order.
    final seen = <String>{};
    final items = [
      for (final i in [...primaryNav, ...moreNav])
        if (seen.add(i.route)) i
    ];
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Row(children: [
                const Icon(Icons.synagogue, color: AppColors.accent, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(loc.t('site.name'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ]),
            ),
            for (final item in items)
              ListTile(
                leading: Icon(item.icon,
                    color: currentRoute == item.route
                        ? AppColors.primary
                        : Colors.black54),
                title: Text(loc.t(item.labelKey)),
                selected: currentRoute == item.route,
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.route);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.app_registration, color: AppColors.primary),
              title: Text(loc.t('nav.contact')),
              onTap: () {
                Navigator.pop(context);
                context.go('/contact');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.accent),
              title: Text(loc.t('nav.donate')),
              onTap: () {
                Navigator.pop(context);
                context.go('/donate');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(loc.t('nav.admin')),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteFooter extends StatelessWidget {
  const _SiteFooter();
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.read<AppRepository>();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        children: [
          Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.goldGradient)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 44),
            child: MaxWidthBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 40,
              runSpacing: 28,
              children: [
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.synagogue,
                            color: AppColors.accent, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(loc.t('site.name'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(loc.t('site.tagline'),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5)),
                      const SizedBox(height: 14),
                      Text(loc.t('footer.follow'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _social(Icons.facebook),
                        _social(Icons.telegram),
                        _social(Icons.camera_alt_outlined),
                        _social(Icons.smart_display_outlined),
                      ]),
                    ],
                  ),
                ),
                _footerLinks(context, loc.t('footer.quicklinks'), primaryNav),
                _footerLinks(context, loc.t('nav.menu'), moreNav),
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('about.contact'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 12),
                      _contactRow(Icons.location_on_outlined,
                          trLoc(repo.contact.address, loc.lang)),
                      _contactRow(Icons.phone_outlined, repo.contact.phone),
                      _contactRow(Icons.email_outlined, repo.contact.email),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} ${loc.t('site.name')} · ${loc.t('footer.rights')}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(IconData icon) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _footerLinks(BuildContext context, String title, List<NavItem> items) {
    final loc = context.read<LocaleController>();
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go(item.route),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.75)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(loc.t(item.labelKey),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accentSoft, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4)),
            ),
          ],
        ),
      );
}
