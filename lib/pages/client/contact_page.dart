import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class _RegTopic {
  const _RegTopic(this.id, this.label, this.icon);
  final String id;
  final Loc label;
  final IconData icon;
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key, this.programId});
  final String? programId;
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  final _selected = <String>{};
  String? _topicError;

  static const _topics = <_RegTopic>[
    _RegTopic(
        'shabbat',
        {'he': 'ארוחות שבת', 'en': 'Shabbat meals', 'ru': 'Субботние трапезы'},
        Icons.restaurant),
    _RegTopic(
        'torah',
        {'he': 'שיעורי תורה', 'en': 'Torah classes', 'ru': 'Уроки Торы'},
        Icons.menu_book_outlined),
    _RegTopic(
        'events',
        {'he': 'אירועים וחגים', 'en': 'Events & holidays', 'ru': 'События и праздники'},
        Icons.celebration_outlined),
    _RegTopic(
        'school',
        {'he': 'גן וחינוך', 'en': 'Kindergarten & education', 'ru': 'Сад и образование'},
        Icons.child_care_outlined),
    _RegTopic(
        'women',
        {'he': 'ארגון נשים', 'en': "Women's Circle", 'ru': 'Женский клуб'},
        Icons.woman),
    _RegTopic(
        'alumni',
        {'he': 'יוצאי העיר', 'en': 'City alumni', 'ru': 'Земляки'},
        Icons.groups_outlined),
    _RegTopic(
        'volunteer',
        {'he': 'התנדבות', 'en': 'Volunteering', 'ru': 'Волонтёрство'},
        Icons.volunteer_activism_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final pid = widget.programId;
    if (pid != null && pid.isNotEmpty) {
      _selected.add('program:$pid');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  List<_RegTopic> _allTopics(AppRepository repo) {
    final seen = <String>{};
    final out = <_RegTopic>[];

    String norm(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[־\-–·,.&]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    Set<String> labelsOf(Loc label) => {
          for (final lang in supportedLangs) norm(trLoc(label, lang)),
        }..removeWhere((s) => s.isEmpty);

    Set<String> wordsOf(Loc label) => {
          for (final text in labelsOf(label))
            ...text.split(' ').where((w) => w.length >= 3),
        };

    void add(_RegTopic t, {bool allowOverlap = false}) {
      final labels = labelsOf(t.label);
      if (labels.isEmpty) return;
      if (labels.any(seen.contains)) return;
      final words = wordsOf(t.label);
      if (!allowOverlap && words.any(seen.contains)) return;
      seen
        ..addAll(labels)
        ..addAll(words);
      out.add(t);
    }

    for (final t in _topics) {
      add(t, allowOverlap: true);
    }
    for (final p in repo.programs) {
      add(
        _RegTopic('program:${p.id}', p.title, p.icon),
        allowOverlap: widget.programId == p.id,
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final topics = _allTopics(repo);
    return SiteScaffold(
      currentRoute: '/contact',
      children: [
        PageHero(
          title: loc.t('nav.contact'),
          subtitle: loc.t('contact.subtitle'),
          icon: Icons.app_registration,
        ),
        Section(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('contact.chooseTopic'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in topics)
                        if (trLoc(t.label, loc.lang).trim().isNotEmpty)
                          FilterChip(
                          showCheckmark: false,
                          avatar: Icon(t.icon, size: 18),
                          label: Text(trLoc(t.label, loc.lang)),
                          selected: _selected.contains(t.id),
                          onSelected: (on) => setState(() {
                            _topicError = null;
                            if (on) {
                              _selected.add(t.id);
                            } else {
                              _selected.remove(t.id);
                            }
                          }),
                        ).hoverScale(scale: 1.04),
                    ],
                  ),
                  if (_topicError != null) ...[
                    const SizedBox(height: 8),
                    Text(_topicError!,
                        style: const TextStyle(
                            color: Color(0xFFB91C1C), fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(builder: (context, c) {
                    final two = c.maxWidth > 620;
                    final name = _field(_name, loc.t('common.name'),
                        icon: Icons.person_outline, required: true);
                    final email = _field(_email, loc.t('common.email'),
                        icon: Icons.email_outlined,
                        required: true,
                        email: true);
                    final phone = _field(_phone, loc.t('common.phone'),
                        icon: Icons.phone_outlined, phone: true);
                    if (!two) {
                      return Column(children: [
                        name,
                        const SizedBox(height: 14),
                        email,
                        const SizedBox(height: 14),
                        phone,
                      ]);
                    }
                    return Column(children: [
                      Row(children: [
                        Expanded(child: name),
                        const SizedBox(width: 14),
                        Expanded(child: email),
                      ]),
                      const SizedBox(height: 14),
                      phone,
                    ]);
                  }),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _message,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.t('common.message'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _submit(context, repo, loc, topics),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    icon: const Icon(Icons.send),
                    label: Text(loc.t('common.send')),
                  ).hoverLift(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {IconData? icon,
      bool required = false,
      bool email = false,
      bool phone = false}) {
    return TextFormField(
      controller: c,
      textDirection: phone ? TextDirection.ltr : null,
      keyboardType: phone ? TextInputType.phone : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return context.loc.t('common.required');
        }
        if (email && v != null && v.isNotEmpty && !v.contains('@')) {
          return context.loc.t('common.emailInvalid');
        }
        return null;
      },
    );
  }

  void _submit(BuildContext context, AppRepository repo, LocaleController loc,
      List<_RegTopic> topics) {
    if (_selected.isEmpty) {
      setState(() => _topicError = loc.t('contact.needTopic'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final picked = [
      for (final t in topics)
        if (_selected.contains(t.id)) t,
    ];
    final topic = <String, String>{
      for (final lang in supportedLangs)
        lang: [
          for (final t in picked) trLoc(t.label, lang),
        ].join(' · '),
    };
    repo.addLead(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      topic: topic,
    );
    _name.clear();
    _email.clear();
    _phone.clear();
    _message.clear();
    setState(() {
      _selected.clear();
      _topicError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.t('contact.thanks')),
        backgroundColor: AppColors.primary,
      ),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 46),
        title: Text(loc.t('contact.thanks')),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check, size: 18),
            label: Text(loc.t('common.close')),
          ),
        ],
      ),
    );
  }
}
