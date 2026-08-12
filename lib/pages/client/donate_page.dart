import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});
  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '180');
  Loc? _campaign;
  final _presets = [54, 100, 180, 360, 1000];

  @override
  void initState() {
    super.initState();
    _campaign = context.read<AppRepository>().campaigns.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/donate',
      children: [
        PageHero(
          title: loc.t('nav.donate'),
          subtitle: loc.t('donate.subtitle'),
          icon: Icons.favorite_border,
        ),
        Section(
          child: LayoutBuilder(builder: (context, c) {
            final form = _form(context, repo, loc);
            final recent = _recent(context, repo, loc);
            if (c.maxWidth < 860) {
              return Column(children: [form, const SizedBox(height: 20), recent]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: recent),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, AppRepository repo, LocaleController loc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('donate.give'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text('\$$p'),
                  selected: _amount.text == '$p',
                  onSelected: (_) => setState(() => _amount.text = '$p'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.t('common.amount'),
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Loc>(
            initialValue: _campaign,
            decoration: InputDecoration(labelText: loc.t('donate.campaign')),
            items: [
              for (final c in repo.campaigns)
                DropdownMenuItem(value: c, child: Text(trLoc(c, loc.lang))),
            ],
            onChanged: (v) => setState(() => _campaign = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: loc.t('common.name')),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _submit(context, repo, loc),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size.fromHeight(50)),
            icon: const Icon(Icons.favorite),
            label: Text('${loc.t('donate.give')}  \$${_amount.text}'),
          ),
        ],
      ),
    );
  }

  Widget _recent(BuildContext context, AppRepository repo, LocaleController loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('admin.stats.donations'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const Divider(height: 22),
          for (final d in repo.donations.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0x1416336B),
                  child: Icon(Icons.volunteer_activism,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.donor,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(trLoc(d.campaign, loc.lang),
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12.5)),
                    ],
                  ),
                ),
                Text('\$${d.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, AppRepository repo, LocaleController loc) {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) return;
    repo.addDonation(
        donor: _name.text.trim(), amount: amount, campaign: _campaign!);
    _name.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.favorite, color: AppColors.accent, size: 46),
        title: Text(loc.t('donate.thanks')),
        content: Text('\$${amount.toStringAsFixed(0)} · ${trLoc(_campaign!, loc.lang)}',
            textAlign: TextAlign.center),
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
