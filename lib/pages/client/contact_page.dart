import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  Loc? _topic;

  final List<Loc> _topics = const [
    {'he': 'ארוחות שבת', 'en': 'Shabbat meals', 'ru': 'Субботние трапезы'},
    {'he': 'שיעורי תורה', 'en': 'Torah classes', 'ru': 'Уроки Торы'},
    {'he': 'אירועים וחגים', 'en': 'Events & holidays', 'ru': 'События и праздники'},
    {'he': 'גן וחינוך', 'en': 'Kindergarten & education', 'ru': 'Сад и образование'},
    {'he': 'ארגון נשים', 'en': "Women's Circle", 'ru': 'Женский клуб'},
    {'he': 'יוצאי העיר', 'en': 'City alumni', 'ru': 'Земляки'},
    {'he': 'התנדבות', 'en': 'Volunteering', 'ru': 'Волонтёрство'},
  ];

  @override
  void initState() {
    super.initState();
    _topic = _topics.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.read<AppRepository>();
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
              color: Colors.white,
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
                      for (final t in _topics)
                        ChoiceChip(
                          label: Text(trLoc(t, loc.lang)),
                          selected: _topic == t,
                          onSelected: (_) => setState(() => _topic = t),
                        ),
                    ],
                  ),
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
                        icon: Icons.phone_outlined);
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
                    onPressed: () => _submit(context, repo, loc),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    icon: const Icon(Icons.send),
                    label: Text(loc.t('common.send')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {IconData? icon, bool required = false, bool email = false}) {
    return TextFormField(
      controller: c,
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

  void _submit(BuildContext context, AppRepository repo, LocaleController loc) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    repo.addLead(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      topic: _topic!,
    );
    _name.clear();
    _email.clear();
    _phone.clear();
    _message.clear();
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
