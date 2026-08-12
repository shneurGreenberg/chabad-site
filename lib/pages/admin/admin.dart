import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../state/auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart' show LanguageSwitcher;
import 'banners_panel.dart';

/// Entry point for /admin — shows the login screen or the admin shell.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return auth.isLoggedIn ? const AdminShell() : const AdminLogin();
  }
}

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _email = TextEditingController(text: 'admin@chabad-city.org');
  final _password = TextEditingController(text: 'demo');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final auth = context.read<AuthController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: AppColors.accent, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(loc.t('admin.login.title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(loc.t('admin.login.hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13)),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: loc.t('common.email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        if (auth.login(_email.text, _password.text)) {
                          // rebuild handled by provider
                        }
                      },
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: Text(loc.t('admin.login.button')),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(loc.t('admin.viewSite')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final narrow = MediaQuery.sizeOf(context).width < 900;

    final sections = <_AdminSection>[
      _AdminSection(loc.t('admin.dashboard'), Icons.dashboard_outlined,
          const DashboardPanel()),
      _AdminSection(loc.t('admin.banners'), Icons.image_outlined,
          const BannersPanel()),
      _AdminSection(loc.t('admin.manage.news'), Icons.article_outlined,
          const ManageNewsPanel()),
      _AdminSection(loc.t('admin.manage.programs'), Icons.groups_outlined,
          const ManageProgramsPanel()),
      _AdminSection(loc.t('admin.manage.store'), Icons.storefront_outlined,
          const ManageStorePanel()),
      _AdminSection(loc.t('admin.crm'), Icons.contacts_outlined, const CrmPanel()),
      _AdminSection(loc.t('admin.bots'), Icons.smart_toy_outlined, const BotsPanel()),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: narrow
          ? Drawer(child: _railList(context, sections, loc, inDrawer: true))
          : null,
      body: Row(
        children: [
          if (!narrow)
            Container(
              width: 260,
              color: AppColors.primaryDark,
              child: _railList(context, sections, loc),
            ),
          Expanded(
            child: Column(
              children: [
                _topBar(context, loc, sections[_index].title, narrow),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: sections[_index].panel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railList(BuildContext context, List<_AdminSection> sections,
      LocaleController loc,
      {bool inDrawer = false}) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.synagogue, color: AppColors.accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(loc.t('nav.admin'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
            ]),
          ),
          for (int i = 0; i < sections.length; i++)
            _railTile(context, sections[i], i, inDrawer),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(context.read<AuthController>().email,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _railTile(
      BuildContext context, _AdminSection s, int i, bool inDrawer) {
    final selected = _index == i;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(s.icon,
              color: selected ? AppColors.accent : Colors.white70, size: 22),
          title: Text(s.title,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14)),
          onTap: () {
            setState(() => _index = i);
            if (inDrawer) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, LocaleController loc, String title,
      bool narrow) {
    final auth = context.read<AuthController>();
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          if (narrow)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Spacer(),
          const LanguageSwitcher(),
          const SizedBox(width: 8),
          if (!narrow)
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(loc.t('admin.viewSite')),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              auth.logout();
              context.go('/');
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            icon: const Icon(Icons.logout, size: 16),
            label: Text(loc.t('admin.logout')),
          ),
        ]),
      ),
    );
  }
}

class _AdminSection {
  _AdminSection(this.title, this.icon, this.panel);
  final String title;
  final IconData icon;
  final Widget panel;
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final totalDon = repo.donations.fold<double>(0, (a, b) => a + b.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          columns: gridColumns(context, max: 4) < 2 ? 2 : gridColumns(context, max: 4),
          children: [
            StatCard(value: '${repo.leads.length}', label: loc.t('admin.stats.leads'), icon: Icons.contacts, color: AppColors.primary),
            StatCard(value: '\$${totalDon.toStringAsFixed(0)}', label: loc.t('admin.stats.donations'), icon: Icons.volunteer_activism, color: const Color(0xFFC9A227)),
            StatCard(value: '${repo.news.length}', label: loc.t('admin.stats.news'), icon: Icons.article, color: const Color(0xFF0D9488)),
            StatCard(value: '${repo.products.length}', label: loc.t('admin.stats.products'), icon: Icons.inventory_2, color: const Color(0xFF9333EA)),
          ],
        ),
        const SizedBox(height: 24),
        _panelCard(
          title: loc.t('admin.recent'),
          child: Column(
            children: [
              for (final lead in repo.leads.take(6))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                  ),
                  title: Text(lead.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(trLoc(lead.topic, loc.lang)),
                  trailing: _LeadStatusChip(status: lead.status),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _panelCard({required String title, required Widget child, List<Widget>? actions}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Spacer(),
          ...?actions,
        ]),
        const Divider(height: 24),
        child,
      ],
    ),
  );
}

class _LeadStatusChip extends StatelessWidget {
  const _LeadStatusChip({required this.status});
  final LeadStatus status;
  @override
  Widget build(BuildContext context) {
    final map = {
      LeadStatus.fresh: (const Color(0xFF2563EB), 'New'),
      LeadStatus.contacted: (const Color(0xFFC9A227), 'Contacted'),
      LeadStatus.member: (const Color(0xFF0D9488), 'Member'),
    };
    final (color, label) = map[status]!;
    return Pill(label, color: color);
  }
}

// ---------------------------------------------------------------------------
// Manage News
// ---------------------------------------------------------------------------
class ManageNewsPanel extends StatelessWidget {
  const ManageNewsPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panelCard(
      title: loc.t('admin.manage.news'),
      actions: [
        FilledButton.icon(
          onPressed: () => _edit(context, repo, repo.newBlankNews(), isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final a in repo.news)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(a.imageColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, color: Color(a.imageColor), size: 22),
              ),
              title: Text(trLoc(a.title, loc.lang),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${trLoc(a.category, loc.lang)} · ${DateFormat.yMMMd(loc.lang).format(a.date)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (a.source == NewsSource.telegram)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.send, size: 16, color: Color(0xFF0EA5E9)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(context, repo, a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteNews(a.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, NewsArticle article,
      {bool isNew = false}) {
    showDialog(
      context: context,
      builder: (_) => _NewsEditor(article: article, isNew: isNew, repo: repo),
    );
  }
}

class _NewsEditor extends StatefulWidget {
  const _NewsEditor(
      {required this.article, required this.isNew, required this.repo});
  final NewsArticle article;
  final bool isNew;
  final AppRepository repo;
  @override
  State<_NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<_NewsEditor> {
  late final Map<String, TextEditingController> _title = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.article.title[l] ?? '')
  };
  late final Map<String, TextEditingController> _body = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.article.body[l] ?? '')
  };
  late final Map<String, TextEditingController> _cat = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.article.category[l] ?? '')
  };

  @override
  void dispose() {
    for (final c in [..._title.values, ..._body.values, ..._cat.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Text(widget.isNew ? loc.t('admin.newItem') : loc.t('common.edit'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _LocFieldGroup(label: loc.t('common.name'), controllers: _title),
                    const SizedBox(height: 8),
                    _LocFieldGroup(label: loc.t('common.category'), controllers: _cat),
                    const SizedBox(height: 8),
                    _LocFieldGroup(
                        label: loc.t('common.message'),
                        controllers: _body,
                        maxLines: 3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.t('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(loc.t('common.save')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    for (final l in supportedLangs) {
      widget.article.title[l] = _title[l]!.text;
      widget.article.body[l] = _body[l]!.text;
      widget.article.category[l] = _cat[l]!.text;
    }
    if (widget.isNew) {
      widget.repo.addNews(widget.article);
    } else {
      widget.repo.updateNews();
    }
    Navigator.pop(context);
  }
}

/// Three stacked inputs (he/en/ru) bound to a [Loc] map's controllers.
class _LocFieldGroup extends StatelessWidget {
  const _LocFieldGroup(
      {required this.label, required this.controllers, this.maxLines = 1});
  final String label;
  final Map<String, TextEditingController> controllers;
  final int maxLines;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 8),
          for (final l in supportedLangs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controllers[l],
                maxLines: maxLines,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.toUpperCase(),
                        style: const TextStyle(
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

// ---------------------------------------------------------------------------
// Manage Programs
// ---------------------------------------------------------------------------
class ManageProgramsPanel extends StatelessWidget {
  const ManageProgramsPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panelCard(
      title: loc.t('admin.manage.programs'),
      actions: [
        FilledButton.icon(
          onPressed: () => _add(context, repo, loc),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final p in repo.programs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(p.color).withValues(alpha: 0.15),
                child: Icon(p.icon, color: Color(p.color), size: 20),
              ),
              title: Text(trLoc(p.title, loc.lang)),
              subtitle: Text(trLoc(p.schedule, loc.lang)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Color(0xFFEF4444)),
                onPressed: () => repo.deleteProgram(p.id),
              ),
            ),
        ],
      ),
    );
  }

  void _add(BuildContext context, AppRepository repo, LocaleController loc) {
    final title = TextEditingController();
    final desc = TextEditingController();
    final sched = TextEditingController();
    final aud = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('admin.newItem')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: InputDecoration(labelText: loc.t('common.name'))),
              const SizedBox(height: 10),
              TextField(controller: desc, decoration: InputDecoration(labelText: loc.t('common.message'))),
              const SizedBox(height: 10),
              TextField(controller: sched, decoration: const InputDecoration(labelText: 'Schedule')),
              const SizedBox(height: 10),
              TextField(controller: aud, decoration: InputDecoration(labelText: loc.t('programs.audience'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.t('common.cancel'))),
          FilledButton(
            onPressed: () {
              final p = repo.newBlankProgram();
              for (final l in supportedLangs) {
                p.title[l] = title.text;
                p.description[l] = desc.text;
                p.schedule[l] = sched.text;
                p.audience[l] = aud.text;
              }
              repo.addProgram(p);
              Navigator.pop(context);
            },
            child: Text(loc.t('common.save')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manage Store
// ---------------------------------------------------------------------------
class ManageStorePanel extends StatelessWidget {
  const ManageStorePanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panelCard(
      title: loc.t('admin.manage.store'),
      actions: [
        FilledButton.icon(
          onPressed: () => _add(context, repo, loc),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final p in repo.products)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(p.color).withValues(alpha: 0.15),
                child: Icon(p.icon, color: Color(p.color), size: 20),
              ),
              title: Text(trLoc(p.name, loc.lang)),
              subtitle: Text('\$${p.price.toStringAsFixed(0)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Color(0xFFEF4444)),
                onPressed: () => repo.deleteProduct(p.id),
              ),
            ),
        ],
      ),
    );
  }

  void _add(BuildContext context, AppRepository repo, LocaleController loc) {
    final name = TextEditingController();
    final desc = TextEditingController();
    final price = TextEditingController(text: '0');
    ProductCategory cat = ProductCategory.judaica;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return AlertDialog(
          title: Text(loc.t('admin.newItem')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: InputDecoration(labelText: loc.t('common.name'))),
                const SizedBox(height: 10),
                TextField(controller: desc, decoration: InputDecoration(labelText: loc.t('common.message'))),
                const SizedBox(height: 10),
                TextField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: loc.t('common.amount'))),
                const SizedBox(height: 10),
                DropdownButtonFormField<ProductCategory>(
                  initialValue: cat,
                  decoration: InputDecoration(labelText: loc.t('common.category')),
                  items: [
                    DropdownMenuItem(value: ProductCategory.judaica, child: Text(loc.t('store.judaica'))),
                    DropdownMenuItem(value: ProductCategory.books, child: Text(loc.t('store.books'))),
                    DropdownMenuItem(value: ProductCategory.food, child: Text(loc.t('store.food'))),
                  ],
                  onChanged: (v) => setLocal(() => cat = v ?? cat),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.t('common.cancel'))),
            FilledButton(
              onPressed: () {
                final p = repo.newBlankProduct();
                for (final l in supportedLangs) {
                  p.name[l] = name.text;
                  p.description[l] = desc.text;
                }
                p.price = double.tryParse(price.text) ?? 0;
                p.category = cat;
                repo.addProduct(p);
                Navigator.pop(context);
              },
              child: Text(loc.t('common.save')),
            ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// CRM
// ---------------------------------------------------------------------------
class CrmPanel extends StatelessWidget {
  const CrmPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panelCard(
      title: loc.t('admin.crm'),
      actions: [
        Flexible(
          child: Text(loc.t('admin.crm.note'),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black45, fontSize: 12)),
        ),
      ],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(loc.t('common.name'))),
            DataColumn(label: Text(loc.t('common.email'))),
            DataColumn(label: Text(loc.t('common.phone'))),
            DataColumn(label: Text(loc.t('common.topic'))),
            DataColumn(label: Text(loc.t('common.date'))),
            DataColumn(label: Text(loc.t('common.status'))),
          ],
          rows: [
            for (final lead in repo.leads)
              DataRow(cells: [
                DataCell(Text(lead.name)),
                DataCell(Text(lead.email)),
                DataCell(Text(lead.phone)),
                DataCell(Text(trLoc(lead.topic, loc.lang))),
                DataCell(Text(DateFormat.yMMMd(loc.lang).format(lead.date))),
                DataCell(
                  PopupMenuButton<LeadStatus>(
                    onSelected: (s) => repo.setLeadStatus(lead, s),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: LeadStatus.fresh, child: Text('New')),
                      PopupMenuItem(value: LeadStatus.contacted, child: Text('Contacted')),
                      PopupMenuItem(value: LeadStatus.member, child: Text('Member')),
                    ],
                    child: _LeadStatusChip(status: lead.status),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bots
// ---------------------------------------------------------------------------
class BotsPanel extends StatelessWidget {
  const BotsPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return Column(
      children: [
        _BotCard(
          title: loc.t('admin.bots.telegram'),
          bot: repo.telegramBot,
          icon: Icons.send,
          color: const Color(0xFF0EA5E9),
          onRun: () {
            final a = repo.runTelegramImport();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(trLoc(a.title, loc.lang))),
            );
          },
        ),
        const SizedBox(height: 16),
        _BotCard(
          title: loc.t('admin.bots.social'),
          bot: repo.socialBot,
          icon: Icons.share,
          color: const Color(0xFF9333EA),
          onRun: () {
            repo.runSocialPush();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Posted to FB · IG · X · VK')),
            );
          },
        ),
      ],
    );
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.title,
    required this.bot,
    required this.icon,
    required this.color,
    required this.onRun,
  });
  final String title;
  final BotConfig bot;
  final IconData icon;
  final Color color;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.read<AppRepository>();
    return _panelCard(
      title: title,
      actions: [
        Switch(
          value: bot.enabled,
          onChanged: (v) {
            bot.enabled = v;
            repo.refresh();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bot.handle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  bot.enabled ? loc.t('admin.bots.enabled') : '—',
                  style: TextStyle(
                      color: bot.enabled ? const Color(0xFF0D9488) : Colors.black45,
                      fontSize: 12.5),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 18),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _metric(loc.t('admin.bots.lastSync'),
                  DateFormat.MMMd(loc.lang).add_Hm().format(bot.lastSync)),
              _metric('${bot.itemsSynced}', loc.t('admin.bots.synced')),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: bot.enabled ? onRun : null,
            style: FilledButton.styleFrom(backgroundColor: color),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(loc.t('admin.bots.runNow')),
          ),
        ],
      ),
    );
  }

  Widget _metric(String a, String b) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(b, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
        ],
      );
}
