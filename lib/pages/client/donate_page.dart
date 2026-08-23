import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/web_prefs.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/playful_icons.dart';
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('donate.give'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 8),
          Text(loc.t('donate.honest'),
              style: TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 18),
          for (int i = 0; i < repo.campaigns.length; i++)
            if (trLoc(repo.campaignNoteAt(i), loc.lang).trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${trLoc(repo.campaigns[i], loc.lang)} — ${trLoc(repo.campaignNoteAt(i), loc.lang)}',
                  style: const TextStyle(height: 1.4, fontSize: 13.5),
                ),
              ),
          if (repo.links.bankDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(loc.t('donate.bank'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SelectableText(repo.links.bankDetails,
                style: TextStyle(color: AppColors.muted, height: 1.4)),
          ],
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
                ).hoverScale(scale: 1.04),
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
            icon: const PlayfulIcon(Icons.favorite),
            label: Text('${loc.t('donate.give')}  \$${_amount.text}'),
          ).hoverLift(),
        ],
      ),
    );
  }

  Widget _recent(BuildContext context, AppRepository repo, LocaleController loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0x1416336B),
                  child: PlayfulIcon(Icons.volunteer_activism,
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
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Text('\$${d.amount.toStringAsFixed(0)}',
                    style: TextStyle(
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
    final pay = repo.links.donateUrl.trim();
    if (pay.isNotEmpty) {
      openUrl(pay);
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: PlayfulIcon(Icons.favorite, color: AppColors.accent, size: 46),
        title: Text(pay.isEmpty
            ? loc.t('donate.pledge')
            : loc.t('donate.redirect')),
        content: Text('\$${amount.toStringAsFixed(0)} · ${trLoc(_campaign!, loc.lang)}',
            textAlign: TextAlign.center),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const PlayfulIcon(Icons.check, size: 18),
            label: Text(loc.t('common.close')),
          ),
        ],
      ),
    );
  }
}
