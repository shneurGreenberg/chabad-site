import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/admin_fields.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';

Map<String, TextEditingController> _locCtrls(Loc map) => {
      for (final l in supportedLangs)
        l: TextEditingController(text: map[l] ?? ''),
    };

void _applyLoc(Loc target, Map<String, TextEditingController> ctrls) {
  for (final l in supportedLangs) {
    target[l] = ctrls[l]!.text;
  }
}

void _disposeAll(Iterable<TextEditingController> ctrls) {
  for (final c in ctrls) {
    c.dispose();
  }
}

Widget _panel({
  required String title,
  required Widget child,
  List<Widget>? actions,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink)),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            for (final a in actions) HoverLift(child: a),
          ],
        ]),
        const Divider(height: 24),
        child,
      ],
    ),
  );
}

Future<void> _showEditor({
  required BuildContext context,
  required String title,
  required Widget child,
  required VoidCallback onSave,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(ctx.loc.t('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      onSave();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(ctx.loc.t('common.save')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SiteContentPanel extends StatefulWidget {
  const SiteContentPanel({super.key});
  @override
  State<SiteContentPanel> createState() => _SiteContentPanelState();
}

class _SiteContentPanelState extends State<SiteContentPanel> {
  late final Map<String, TextEditingController> _name;
  late final Map<String, TextEditingController> _city;
  late final Map<String, TextEditingController> _tagline;
  late final Map<String, TextEditingController> _aboutSub;
  late final Map<String, TextEditingController> _aboutBody;
  late final Map<String, TextEditingController> _orgName;
  late final Map<String, TextEditingController> _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late List<_HourRow> _hours;
  late List<_StaffRow> _staff;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AppRepository>();
    _name = _locCtrls(repo.siteCopy.name);
    _city = _locCtrls(repo.siteCopy.city);
    _tagline = _locCtrls(repo.siteCopy.tagline);
    _aboutSub = _locCtrls(repo.siteCopy.aboutSubtitle);
    _aboutBody = _locCtrls(repo.siteCopy.aboutBody);
    _orgName = _locCtrls(repo.contact.name);
    _address = _locCtrls(repo.contact.address);
    _phone = TextEditingController(text: repo.contact.phone);
    _email = TextEditingController(text: repo.contact.email);
    _hours = [
      for (final h in repo.contact.hours) _HourRow(h.key, h.value),
    ];
    _staff = [
      for (final s in repo.contact.staff) _StaffRow(s),
    ];
  }

  @override
  void dispose() {
    _disposeAll([
      ..._name.values,
      ..._city.values,
      ..._tagline.values,
      ..._aboutSub.values,
      ..._aboutBody.values,
      ..._orgName.values,
      ..._address.values,
      _phone,
      _email,
      for (final h in _hours) ...[...h.day.values, ...h.hours.values],
      for (final s in _staff) ...[...s.name.values, ...s.role.values, s.phone],
    ]);
    super.dispose();
  }

  void _save() {
    final repo = context.read<AppRepository>();
    _applyLoc(repo.siteCopy.name, _name);
    _applyLoc(repo.siteCopy.city, _city);
    _applyLoc(repo.siteCopy.tagline, _tagline);
    _applyLoc(repo.siteCopy.aboutSubtitle, _aboutSub);
    _applyLoc(repo.siteCopy.aboutBody, _aboutBody);
    _applyLoc(repo.contact.name, _orgName);
    _applyLoc(repo.contact.address, _address);
    repo.contact.phone = _phone.text.trim();
    repo.contact.email = _email.text.trim();
    repo.contact.hours
      ..clear()
      ..addAll([
        for (final h in _hours)
          MapEntry(
            {for (final l in supportedLangs) l: h.day[l]!.text},
            {for (final l in supportedLangs) l: h.hours[l]!.text},
          ),
      ]);
    repo.contact.staff
      ..clear()
      ..addAll([
        for (final s in _staff)
          StaffContact(
            name: {for (final l in supportedLangs) l: s.name[l]!.text},
            role: {for (final l in supportedLangs) l: s.role[l]!.text},
            phone: s.phone.text.trim(),
          ),
      ]);
    repo.refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.loc.t('admin.settings.saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Column(
      children: [
        _panel(
          title: loc.t('admin.siteContent'),
          actions: [
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(loc.t('common.save')),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('admin.siteContent.subtitle'),
                  style: TextStyle(color: AppColors.muted, height: 1.45)),
              const SizedBox(height: 16),
              LocFieldGroup(label: loc.t('admin.site.name'), controllers: _name),
              LocFieldGroup(label: loc.t('admin.site.city'), controllers: _city),
              LocFieldGroup(
                  label: loc.t('admin.site.tagline'),
                  controllers: _tagline,
                  maxLines: 3),
              LocFieldGroup(
                  label: loc.t('admin.site.aboutSubtitle'),
                  controllers: _aboutSub,
                  maxLines: 2),
              LocFieldGroup(
                  label: loc.t('admin.site.aboutBody'),
                  controllers: _aboutBody,
                  maxLines: 6),
              LocFieldGroup(
                  label: loc.t('nav.about'), controllers: _orgName),
              LocFieldGroup(
                  label: loc.t('about.address'),
                  controllers: _address,
                  maxLines: 2),
              TextField(
                controller: _phone,
                decoration: InputDecoration(labelText: loc.t('common.phone')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: InputDecoration(labelText: loc.t('common.email')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: loc.t('admin.hours'),
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _hours.add(_HourRow({}, {}))),
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.t('common.add')),
            ),
          ],
          child: Column(
            children: [
              for (int i = 0; i < _hours.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [
                          LocFieldGroup(
                              label: loc.t('admin.hours.day'),
                              controllers: _hours[i].day),
                          LocFieldGroup(
                              label: loc.t('admin.hours.value'),
                              controllers: _hours[i].hours,
                              maxLines: 2),
                        ]),
                      ),
                      IconButton(
                        tooltip: loc.t('common.delete'),
                        onPressed: () => setState(() {
                          _hours[i].dispose();
                          _hours.removeAt(i);
                        }),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: loc.t('admin.staff'),
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _staff.add(_StaffRow(StaffContact(
                    name: {'he': '', 'en': '', 'ru': ''},
                    role: {'he': '', 'en': '', 'ru': ''},
                    phone: '',
                  )))),
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.t('common.add')),
            ),
          ],
          child: Column(
            children: [
              for (int i = 0; i < _staff.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [
                          LocFieldGroup(
                              label: loc.t('common.name'),
                              controllers: _staff[i].name),
                          LocFieldGroup(
                              label: loc.t('admin.staff.role'),
                              controllers: _staff[i].role),
                          TextField(
                            controller: _staff[i].phone,
                            decoration: InputDecoration(
                                labelText: loc.t('common.phone')),
                          ),
                        ]),
                      ),
                      IconButton(
                        tooltip: loc.t('common.delete'),
                        onPressed: () => setState(() {
                          _staff[i].dispose();
                          _staff.removeAt(i);
                        }),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HourRow {
  _HourRow(Loc day, Loc hours)
      : day = _locCtrls(day),
        hours = _locCtrls(hours);
  final Map<String, TextEditingController> day;
  final Map<String, TextEditingController> hours;
  void dispose() => _disposeAll([...day.values, ...hours.values]);
}

class _StaffRow {
  _StaffRow(StaffContact s)
      : name = _locCtrls(s.name),
        role = _locCtrls(s.role),
        phone = TextEditingController(text: s.phone);
  final Map<String, TextEditingController> name;
  final Map<String, TextEditingController> role;
  final TextEditingController phone;
  void dispose() => _disposeAll([...name.values, ...role.values, phone]);
}

class ManageFamousPanel extends StatelessWidget {
  const ManageFamousPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panel(
      title: loc.t('admin.manage.famous'),
      actions: [
        FilledButton.icon(
          onPressed: () => _edit(context, repo, repo.newBlankFamous(), isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final p in repo.famous)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(p.color).withValues(alpha: 0.15),
                child: Text(p.initials.isEmpty ? '•' : p.initials,
                    style: TextStyle(
                        color: Color(p.color), fontWeight: FontWeight.w800)),
              ),
              title: Text(trLoc(p.name, loc.lang)),
              subtitle: Text(trLoc(p.profession, loc.lang)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _edit(context, repo, p)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteFamous(p.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, FamousPerson person,
      {bool isNew = false}) {
    final name = _locCtrls(person.name);
    final profession = _locCtrls(person.profession);
    final bio = _locCtrls(person.bio);
    final initials = TextEditingController(text: person.initials);
    var era = person.era;
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: StatefulBuilder(builder: (context, setSt) {
        final loc = context.locWatch;
        return Column(children: [
          LocFieldGroup(label: loc.t('common.name'), controllers: name),
          LocFieldGroup(label: loc.t('admin.staff.role'), controllers: profession),
          LocFieldGroup(
              label: loc.t('common.message'), controllers: bio, maxLines: 4),
          TextField(
            controller: initials,
            decoration: InputDecoration(labelText: loc.t('admin.initials')),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Era>(
            initialValue: era,
            decoration: InputDecoration(labelText: loc.t('common.category')),
            items: [
              DropdownMenuItem(
                  value: Era.present, child: Text(loc.t('famous.present'))),
              DropdownMenuItem(
                  value: Era.past, child: Text(loc.t('famous.past'))),
            ],
            onChanged: (v) => setSt(() => era = v ?? era),
          ),
        ]);
      }),
      onSave: () {
        _applyLoc(person.name, name);
        _applyLoc(person.profession, profession);
        _applyLoc(person.bio, bio);
        person.initials = initials.text.trim();
        person.era = era;
        if (isNew) {
          repo.addFamous(person);
        } else {
          repo.refresh();
        }
        _disposeAll([...name.values, ...profession.values, ...bio.values, initials]);
      },
    );
  }
}

class ManageHistoryPanel extends StatelessWidget {
  const ManageHistoryPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return Column(
      children: [
        _panel(
          title: loc.t('admin.manage.history'),
          actions: [
            FilledButton.icon(
              onPressed: () =>
                  _editHist(context, repo, repo.newBlankHistory(), isNew: true),
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.t('common.add')),
            ),
          ],
          child: Column(
            children: [
              for (final e in repo.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    child: Text(e.year,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
                  title: Text(trLoc(e.title, loc.lang)),
                  subtitle: Text(trLoc(e.description, loc.lang),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editHist(context, repo, e)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Color(0xFFEF4444)),
                      onPressed: () => repo.deleteHistory(e.id),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: loc.t('admin.manage.tour'),
          actions: [
            FilledButton.icon(
              onPressed: () =>
                  _editTour(context, repo, repo.newBlankTour(), isNew: true),
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.t('common.add')),
            ),
          ],
          child: Column(
            children: [
              for (final s in repo.tour)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(s.icon, color: Color(s.color)),
                  title: Text(trLoc(s.name, loc.lang)),
                  subtitle: Text(trLoc(s.description, loc.lang),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editTour(context, repo, s)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Color(0xFFEF4444)),
                      onPressed: () => repo.deleteTour(s.id),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _editHist(BuildContext context, AppRepository repo, HistoryEvent event,
      {bool isNew = false}) {
    final title = _locCtrls(event.title);
    final desc = _locCtrls(event.description);
    final year = TextEditingController(text: event.year);
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: Column(children: [
        TextField(
          controller: year,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.year')),
        ),
        const SizedBox(height: 12),
        LocFieldGroup(
            label: context.loc.t('common.name'), controllers: title),
        LocFieldGroup(
            label: context.loc.t('common.message'),
            controllers: desc,
            maxLines: 4),
      ]),
      onSave: () {
        event.year = year.text.trim();
        _applyLoc(event.title, title);
        _applyLoc(event.description, desc);
        if (isNew) {
          repo.addHistory(event);
        } else {
          repo.refresh();
        }
        _disposeAll([...title.values, ...desc.values, year]);
      },
    );
  }

  void _editTour(BuildContext context, AppRepository repo, TourStop stop,
      {bool isNew = false}) {
    final name = _locCtrls(stop.name);
    final desc = _locCtrls(stop.description);
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: Column(children: [
        LocFieldGroup(label: context.loc.t('common.name'), controllers: name),
        LocFieldGroup(
            label: context.loc.t('common.message'),
            controllers: desc,
            maxLines: 4),
      ]),
      onSave: () {
        _applyLoc(stop.name, name);
        _applyLoc(stop.description, desc);
        if (isNew) {
          repo.addTour(stop);
        } else {
          repo.refresh();
        }
        _disposeAll([...name.values, ...desc.values]);
      },
    );
  }
}

class ManageLibraryPanel extends StatelessWidget {
  const ManageLibraryPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panel(
      title: loc.t('admin.manage.library'),
      actions: [
        FilledButton.icon(
          onPressed: () =>
              _edit(context, repo, repo.newBlankShiur(), isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (final s in repo.shiurim)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(trLoc(s.title, loc.lang)),
              subtitle: Text(
                  '${trLoc(s.rabbi, loc.lang)} · ${s.durationMinutes} ${loc.t('admin.shiur.duration')}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _edit(context, repo, s)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteShiur(s.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, Shiur shiur,
      {bool isNew = false}) {
    final title = _locCtrls(shiur.title);
    final rabbi = _locCtrls(shiur.rabbi);
    final topic = _locCtrls(shiur.topic);
    final mins = TextEditingController(text: '${shiur.durationMinutes}');
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: Column(children: [
        LocFieldGroup(label: context.loc.t('common.name'), controllers: title),
        LocFieldGroup(label: context.loc.t('library.rabbi'), controllers: rabbi),
        LocFieldGroup(label: context.loc.t('common.category'), controllers: topic),
        TextField(
          controller: mins,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.shiur.duration')),
        ),
      ]),
      onSave: () {
        _applyLoc(shiur.title, title);
        _applyLoc(shiur.rabbi, rabbi);
        _applyLoc(shiur.topic, topic);
        shiur.durationMinutes = int.tryParse(mins.text) ?? shiur.durationMinutes;
        if (isNew) {
          repo.addShiur(shiur);
        } else {
          repo.refresh();
        }
        _disposeAll([...title.values, ...rabbi.values, ...topic.values, mins]);
      },
    );
  }
}

class ManageDonatePanel extends StatelessWidget {
  const ManageDonatePanel({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return _panel(
      title: loc.t('admin.manage.donate'),
      actions: [
        FilledButton.icon(
          onPressed: () => _edit(context, repo, {'he': '', 'en': '', 'ru': ''},
              isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          for (int i = 0; i < repo.campaigns.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(trLoc(repo.campaigns[i], loc.lang)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _edit(context, repo, repo.campaigns[i],
                        index: i)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteCampaignAt(i),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, Loc campaign,
      {int? index, bool isNew = false}) {
    final ctrls = _locCtrls(campaign);
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: LocFieldGroup(
          label: context.loc.t('common.name'), controllers: ctrls),
      onSave: () {
        final next = {for (final l in supportedLangs) l: ctrls[l]!.text};
        if (isNew) {
          repo.addCampaign(next);
        } else if (index != null) {
          repo.campaigns[index] = next;
          repo.refresh();
        }
        _disposeAll(ctrls.values);
      },
    );
  }
}

class ManageCemeteryPanel extends StatefulWidget {
  const ManageCemeteryPanel({super.key});
  @override
  State<ManageCemeteryPanel> createState() => _ManageCemeteryPanelState();
}

class _ManageCemeteryPanelState extends State<ManageCemeteryPanel> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final q = _q.trim().toLowerCase();
    final items = repo.graves.where((g) {
      if (q.isEmpty) return true;
      return g.name.toLowerCase().contains(q) ||
          g.hebrewName.toLowerCase().contains(q) ||
          g.section.toLowerCase().contains(q);
    }).toList();
    return _panel(
      title: loc.t('admin.manage.cemetery'),
      actions: [
        FilledButton.icon(
          onPressed: () =>
              _edit(context, repo, repo.newBlankGrave(), isNew: true),
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.t('common.add')),
        ),
      ],
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: loc.t('search.hint'),
            ),
          ),
          const SizedBox(height: 12),
          for (final g in items.take(80))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(g.hebrewName.isEmpty ? g.name : g.hebrewName),
              subtitle: Text(
                  [g.name, g.section, g.deathLabel].where((s) => s.isNotEmpty).join(' · ')),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _edit(context, repo, g)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => repo.deleteGrave(g.id),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AppRepository repo, Grave grave,
      {bool isNew = false}) {
    final name = TextEditingController(text: grave.name);
    final hebrew = TextEditingController(text: grave.hebrewName);
    final section = TextEditingController(text: grave.section);
    final row = TextEditingController(text: grave.row);
    final birth = TextEditingController(text: '${grave.birthYear ?? ''}');
    final death = TextEditingController(text: '${grave.deathYear}');
    final notes = _locCtrls(grave.notes);
    _showEditor(
      context: context,
      title: isNew ? context.loc.t('admin.newItem') : context.loc.t('common.edit'),
      child: Column(children: [
        TextField(
          controller: hebrew,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.grave.hebrew')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: name,
          decoration:
              InputDecoration(labelText: context.loc.t('common.name')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: section,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.grave.section')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: row,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.grave.row')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: birth,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.grave.birth')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: death,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: context.loc.t('admin.grave.death')),
        ),
        const SizedBox(height: 12),
        LocFieldGroup(
            label: context.loc.t('common.message'),
            controllers: notes,
            maxLines: 2),
      ]),
      onSave: () {
        grave.name = name.text.trim();
        grave.hebrewName = hebrew.text.trim();
        grave.section = section.text.trim();
        grave.row = row.text.trim();
        grave.birthYear = int.tryParse(birth.text);
        grave.deathYear = int.tryParse(death.text) ?? grave.deathYear;
        _applyLoc(grave.notes, notes);
        if (isNew) {
          repo.addGrave(grave);
        } else {
          repo.markGravesEdited();
        }
        _disposeAll([name, hebrew, section, row, birth, death, ...notes.values]);
      },
    );
  }
}
