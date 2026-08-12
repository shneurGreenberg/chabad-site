import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../state/auth.dart';
import '../../theme.dart';
import '../../widgets/admin_fields.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart' show LanguageSwitcher;
import 'banners_panel.dart';
import 'settings_panel.dart';
import 'telegram_panel.dart';

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
                        labelText: loc.t('common.password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        if (auth.login(_email.text, _password.text)) {
                          // rebuild handled by provider
                        }
                      },
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(loc.t('admin.login.button')),
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
      _AdminSection(loc.t('admin.settings'), Icons.settings_outlined,
          const SettingsPanel()),
      _AdminSection(loc.t('admin.banners'), Icons.image_outlined,
          const BannersPanel()),
      _AdminSection(loc.t('admin.manage.news'), Icons.article_outlined,
          const ManageNewsPanel()),
      _AdminSection(loc.t('admin.manage.programs'), Icons.groups_outlined,
          const ManageProgramsPanel()),
      _AdminSection(loc.t('admin.manage.store'), Icons.storefront_outlined,
          const ManageStorePanel()),
      _AdminSection(loc.t('admin.manage.gallery'), Icons.photo_library_outlined,
          const ManageGalleryPanel()),
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < sections.length; i++)
                  _railTile(context, sections[i], i, inDrawer),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(context.read<AuthController>().email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                tooltip: loc.t('nav.menu'),
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const LanguageSwitcher(),
          const SizedBox(width: 8),
          if (!narrow)
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(loc.t('admin.viewSite')),
            )
          else
            IconButton(
              tooltip: loc.t('admin.viewSite'),
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.open_in_new),
            ),
          const SizedBox(width: 8),
          if (!narrow)
            FilledButton.icon(
              onPressed: () {
                auth.logout();
                context.go('/');
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444)),
              icon: const Icon(Icons.logout, size: 16),
              label: Text(loc.t('admin.logout')),
            )
          else
            IconButton(
              tooltip: loc.t('admin.logout'),
              onPressed: () {
                auth.logout();
                context.go('/');
              },
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Text(loc.t('admin.persist.note'),
              style: const TextStyle(color: AppColors.muted, height: 1.45)),
        ),
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
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
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
    final loc = context.locWatch;
    final map = {
      LeadStatus.fresh: (const Color(0xFF2563EB), loc.t('admin.lead.fresh')),
      LeadStatus.contacted: (const Color(0xFFC9A227), loc.t('admin.lead.contacted')),
      LeadStatus.member: (const Color(0xFF0D9488), loc.t('admin.lead.member')),
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
                    padding: EdgeInsetsDirectional.only(end: 6),
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
                    CoverImagePicker(
                      bytes: widget.article.imageBytes,
                      color: widget.article.imageColor,
                      icon: widget.article.icon,
                      onChanged: (b) =>
                          setState(() => widget.article.imageBytes = b),
                    ),
                    const SizedBox(height: 12),
                    LocFieldGroup(label: loc.t('common.name'), controllers: _title),
                    const SizedBox(height: 8),
                    LocFieldGroup(label: loc.t('common.category'), controllers: _cat),
                    const SizedBox(height: 8),
                    LocFieldGroup(
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
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(loc.t('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(loc.t('common.save')),
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
          onPressed: () => _edit(context, repo, repo.newBlankProgram(), isNew: true),
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
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(context, repo, p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteProgram(p.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, Program program,
      {bool isNew = false}) {
    showDialog(
      context: context,
      builder: (_) => _ProgramEditor(program: program, isNew: isNew, repo: repo),
    );
  }
}

class _ProgramEditor extends StatefulWidget {
  const _ProgramEditor(
      {required this.program, required this.isNew, required this.repo});
  final Program program;
  final bool isNew;
  final AppRepository repo;
  @override
  State<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<_ProgramEditor> {
  late final _title = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.program.title[l] ?? '')
  };
  late final _desc = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.program.description[l] ?? '')
  };
  late final _sched = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.program.schedule[l] ?? '')
  };
  late final _aud = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.program.audience[l] ?? '')
  };

  @override
  void dispose() {
    for (final c in [..._title.values, ..._desc.values, ..._sched.values, ..._aud.values]) {
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Text(widget.isNew ? loc.t('admin.newItem') : loc.t('common.edit'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  CoverImagePicker(
                    bytes: widget.program.imageBytes,
                    color: widget.program.color,
                    icon: widget.program.icon,
                    onChanged: (b) =>
                        setState(() => widget.program.imageBytes = b),
                  ),
                  LocFieldGroup(label: loc.t('common.name'), controllers: _title),
                  LocFieldGroup(
                      label: loc.t('common.message'),
                      controllers: _desc,
                      maxLines: 3),
                  LocFieldGroup(label: loc.t('programs.schedule'), controllers: _sched),
                  LocFieldGroup(label: loc.t('programs.audience'), controllers: _aud),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(loc.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(loc.t('common.save')),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    for (final l in supportedLangs) {
      widget.program.title[l] = _title[l]!.text;
      widget.program.description[l] = _desc[l]!.text;
      widget.program.schedule[l] = _sched[l]!.text;
      widget.program.audience[l] = _aud[l]!.text;
    }
    if (widget.isNew) {
      widget.repo.addProgram(widget.program);
    } else {
      widget.repo.refresh();
    }
    Navigator.pop(context);
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
          onPressed: () =>
              _edit(context, repo, repo.newBlankProduct(), isNew: true),
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
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(context, repo, p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteProduct(p.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, Product product,
      {bool isNew = false}) {
    showDialog(
      context: context,
      builder: (_) =>
          _ProductEditor(product: product, isNew: isNew, repo: repo),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor(
      {required this.product, required this.isNew, required this.repo});
  final Product product;
  final bool isNew;
  final AppRepository repo;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  late final _name = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.product.name[l] ?? '')
  };
  late final _desc = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.product.description[l] ?? '')
  };
  late final _price =
      TextEditingController(text: widget.product.price.toStringAsFixed(0));
  late ProductCategory _cat = widget.product.category;

  @override
  void dispose() {
    for (final c in [..._name.values, ..._desc.values, _price]) {
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
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
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  CoverImagePicker(
                    bytes: widget.product.imageBytes,
                    color: widget.product.color,
                    icon: widget.product.icon,
                    onChanged: (b) =>
                        setState(() => widget.product.imageBytes = b),
                  ),
                  LocFieldGroup(label: loc.t('common.name'), controllers: _name),
                  LocFieldGroup(
                      label: loc.t('common.message'),
                      controllers: _desc,
                      maxLines: 3),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.t('common.amount')),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductCategory>(
                    initialValue: _cat,
                    decoration:
                        InputDecoration(labelText: loc.t('common.category')),
                    items: [
                      DropdownMenuItem(
                          value: ProductCategory.judaica,
                          child: Text(loc.t('store.judaica'))),
                      DropdownMenuItem(
                          value: ProductCategory.books,
                          child: Text(loc.t('store.books'))),
                      DropdownMenuItem(
                          value: ProductCategory.food,
                          child: Text(loc.t('store.food'))),
                    ],
                    onChanged: (v) => setState(() => _cat = v ?? _cat),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(loc.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(loc.t('common.save')),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    for (final l in supportedLangs) {
      widget.product.name[l] = _name[l]!.text;
      widget.product.description[l] = _desc[l]!.text;
    }
    widget.product.price = double.tryParse(_price.text) ?? 0;
    widget.product.category = _cat;
    if (widget.isNew) {
      widget.repo.addProduct(widget.product);
    } else {
      widget.repo.refresh();
    }
    Navigator.pop(context);
  }
}

class ManageGalleryPanel extends StatelessWidget {
  const ManageGalleryPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panelCard(
      title: loc.t('admin.manage.gallery'),
      actions: [
        FilledButton.icon(
          onPressed: () =>
              _edit(context, repo, repo.newBlankGallery(), isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final p in repo.gallery)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: p.imageBytes != null
                      ? Image.memory(p.imageBytes!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Color(p.color).withValues(alpha: 0.15),
                          child: Icon(p.icon, color: Color(p.color), size: 20),
                        ),
                ),
              ),
              title: Text(trLoc(p.event, loc.lang)),
              subtitle: Text('${p.year}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(context, repo, p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteGalleryPhoto(p.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, GalleryPhoto photo,
      {bool isNew = false}) {
    showDialog(
      context: context,
      builder: (_) => _GalleryEditor(photo: photo, isNew: isNew, repo: repo),
    );
  }
}

class _GalleryEditor extends StatefulWidget {
  const _GalleryEditor(
      {required this.photo, required this.isNew, required this.repo});
  final GalleryPhoto photo;
  final bool isNew;
  final AppRepository repo;
  @override
  State<_GalleryEditor> createState() => _GalleryEditorState();
}

class _GalleryEditorState extends State<_GalleryEditor> {
  late final _event = {
    for (final l in supportedLangs)
      l: TextEditingController(text: widget.photo.event[l] ?? '')
  };
  late final _year =
      TextEditingController(text: '${widget.photo.year}');
  late final _tags =
      TextEditingController(text: widget.photo.tags.join(', '));

  @override
  void dispose() {
    for (final c in [..._event.values, _year, _tags]) {
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
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
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  CoverImagePicker(
                    bytes: widget.photo.imageBytes,
                    color: widget.photo.color,
                    icon: widget.photo.icon,
                    onChanged: (b) =>
                        setState(() => widget.photo.imageBytes = b),
                  ),
                  LocFieldGroup(label: loc.t('common.name'), controllers: _event),
                  TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.t('gallery.year')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tags,
                    decoration: InputDecoration(labelText: loc.t('gallery.tagged')),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(loc.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(loc.t('common.save')),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    for (final l in supportedLangs) {
      widget.photo.event[l] = _event[l]!.text;
    }
    widget.photo.year = int.tryParse(_year.text) ?? widget.photo.year;
    widget.photo.tags = _tags.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (widget.isNew) {
      widget.repo.addGalleryPhoto(widget.photo);
    } else {
      widget.repo.refresh();
    }
    Navigator.pop(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelCard(
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
                        itemBuilder: (context) {
                          final loc = context.read<LocaleController>();
                          return [
                            PopupMenuItem(
                                value: LeadStatus.fresh,
                                child: Text(loc.t('admin.lead.fresh'))),
                            PopupMenuItem(
                                value: LeadStatus.contacted,
                                child: Text(loc.t('admin.lead.contacted'))),
                            PopupMenuItem(
                                value: LeadStatus.member,
                                child: Text(loc.t('admin.lead.member'))),
                          ];
                        },
                        child: _LeadStatusChip(status: lead.status),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _panelCard(
          title: loc.t('admin.newsletter'),
          child: repo.subscribers.isEmpty
              ? Text(loc.t('admin.newsletter.empty'),
                  style: const TextStyle(color: AppColors.muted))
              : Column(
                  children: [
                    for (final s in repo.subscribers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mail_outline,
                            color: AppColors.primary),
                        title: Text(s.email),
                        subtitle: Text(
                            DateFormat.yMMMd(loc.lang).add_Hm().format(s.date)),
                        trailing: IconButton(
                          tooltip: loc.t('common.delete'),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => repo.removeSubscriber(s.email),
                        ),
                      ),
                  ],
                ),
        ),
      ],
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
        const TelegramWizard(),
        const SizedBox(height: 16),
        _BotCard(
          title: loc.t('admin.bots.social'),
          bot: repo.socialBot,
          icon: Icons.share,
          color: const Color(0xFF9333EA),
          onRun: () {
            repo.runSocialPush();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.t('admin.bots.posted'))),
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
